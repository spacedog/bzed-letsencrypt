# == Class: dehydrated
#
# Include this class if you would like to create
# Certificates or on your puppetmaster to have you CSRs signed.
#
#
# === Parameters
#
# [*dehydrated_git_url*]
#   URL used to checkout dehydrated using git.
#   Defaults to the upstream github url.
#
# [*hook_source*]
#   Points to the source of the dehydrated hook you'd like to
#   distribute ((as in file { ...: source => })
#   hook_source or hook_content needs to be specified.
#
# [*hook_content*]
#   The actual content (as in file { ...: content => }) of the
#   dehydrated hook.
#   hook_source or hook_content needs to be specified.
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#


class dehydrated::request::handler(
    $dehydrated_git_url,
    $dehydrated_ca,
    $hook_source,
    $hook_content,
    $dehydrated_contact_email,
    $dehydrated_proxy,
){

    require ::dehydrated::params

    $handler_base_dir     = $::dehydrated::params::handler_base_dir
    $handler_requests_dir = $::dehydrated::params::handler_requests_dir
    $letsencrypt_sh_dir = $::dehydrated::params::letsencrypt_sh_dir
    $dehydrated_dir   = $::dehydrated::params::dehydrated_dir
    $dehydrated_hook  = $::dehydrated::params::dehydrated_hook
    $dehydrated_conf  = $::dehydrated::params::dehydrated_conf
    $dehydrated_chain_request  = $::dehydrated::params::dehydrated_chain_request
    $dehydrated_ocsp_request   = $::dehydrated::params::dehydrated_ocsp_request

    user { 'dehydrated' :
        gid        => 'dehydrated',
        home       => $handler_base_dir,
        shell      => '/bin/bash',
        managehome => false,
        password   => '!!',
    }

    File {
        owner => root,
        group => root,
    }

    $migrate_command = join([
        "mv ${::dehydrated::params::old_handler_base_dir} ${::dehydrated::params::handler_base_dir}",
        '&&',
        "ln -s ${::dehydrated::params::handler_base_dir} ${::dehydrated::params::old_handler_base_dir}",
        '&&',
        "find ${::dehydrated::params::handler_base_dir} -group letsencrypt -exec chgrp dehydrated {} +"
    ], ' ')

    exec { 'migrate-old-directories' :
        path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        onlyif  => "test -d ${::dehydrated::params::old_handler_base_dir}",
        user    => 'root',
        group   => 'root',
        command => $migrate_command,
        require => Group['dehydrated'],
        before  => File[$::dehydrated::params::handler_base_dir],
    }


    file { $handler_base_dir :
        ensure => directory,
        mode   => '0755',
        owner  => 'dehydrated',
        group  => 'dehydrated',
    }
    file { "${handler_base_dir}/.acme-challenges" :
        ensure => directory,
        mode   => '0755',
        owner  => 'dehydrated',
        group  => 'dehydrated',
    }
    file { $handler_requests_dir :
        ensure => directory,
        mode   => '0755',
    }

    file { $dehydrated_hook :
        ensure  => file,
        group   => 'dehydrated',
        require => Group['dehydrated'],
        source  => $hook_source,
        content => $hook_content,
        mode    => '0750',
    }

    if ($letsencrypt_sh_dir =~ /.*letsencrypt\.sh/) {
        file { $letsencrypt_sh_dir :
            ensure  => absent,
            force   => true,
            recurse => true,
        }
    } else {
        fail('$letsencrypt_sh_dir seems to be weid')
    }

    vcsrepo { $dehydrated_dir :
        ensure   => latest,
        revision => master,
        provider => git,
        source   => $dehydrated_git_url,
        user     => root,
        require  => [
            File[$handler_base_dir],
            Package['git']
        ],
    }

    # handle switching CAs with different account keys.
    if ($dehydrated_ca =~ /.*acme-v01\.api\.dehydrated\.org.*/) {
        $private_key_name = 'private_key'
    } else {
        $_ca_domain = regsubst(
            $dehydrated_ca,
            '^https?://([^/]+)/.*',
            '\1'
        )
        $_ca_domain_escaped = regsubst(
            $_ca_domain,
            '\.',
            '_',
            'G'
        )
        $private_key_name = "private_key_${_ca_domain_escaped}"
    }
    file { $dehydrated_conf :
        ensure  => file,
        owner   => root,
        group   => dehydrated,
        mode    => '0640',
        content => template('dehydrated/dehydrated.conf.erb'),
    }

    file { $dehydrated_chain_request :
        ensure  => file,
        owner   => root,
        group   => dehydrated,
        mode    => '0755',
        content => template('dehydrated/dehydrated_get_certificate_chain.sh.erb'),
    }

    file { $dehydrated_ocsp_request :
        ensure  => file,
        owner   => root,
        group   => dehydrated,
        mode    => '0755',
        content => template('dehydrated/dehydrated_get_certificate_ocsp.sh.erb'),
    }

    Letsencrypt::Request<<| tag == $::fqdn |>>
}

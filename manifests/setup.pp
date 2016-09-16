# == Class: dehydrated::setup
#
# setup all necessary directories and groups
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#
class dehydrated::setup (
){

    require ::dehydrated::params

    group { 'dehydrated' :
        ensure => present,
    }

    $migrate_command = join([
        "mv ${::dehydrated::params::old_base_dir} ${::dehydrated::params::base_dir}",
        '&&',
        "ln -s ${::dehydrated::params::base_dir} ${::dehydrated::params::old_base_dir}",
        '&&',
        "find ${::dehydrated::params::base_dir} -group letsencrypt -exec chgrp dehydrated {} +"
    ], ' ')

    exec { 'migrate-old-directories' :
        path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        onlyif  => "test -d ${::dehydrated::params::old_base_dir}",
        user    => 'root',
        group   => 'root',
        command => $migrate_command,
        require => Group['dehydrated'],
        before  => File[$::dehydrated::params::base_dir],
    }
    File {
        ensure  => directory,
        owner   => 'root',
        group   => 'dehydrated',
        mode    => '0755',
        require => Group['dehydrated'],
    }

    file { $::dehydrated::params::base_dir :
    }
    file { $::dehydrated::params::csr_dir :
    }
    file { $::dehydrated::params::crt_dir :
    }
    file { $::dehydrated::params::key_dir :
        mode    => '0750',
    }


}

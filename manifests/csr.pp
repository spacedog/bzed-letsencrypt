# = Define: dehydrated::csr
#
# Create a CSR and ask to sign it.
#
# == Parameters:
#
# [*dehydrated_host*]
#   Host the certificates will be signed on
#
# [*challengetype*]
#   challengetype dehydrated should use.
#
#  .... plus various other undocumented parameters
#
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#


define dehydrated::csr(
    $dehydrated_host,
    $challengetype,
    $domain_list = $name,
    $country = undef,
    $state = undef,
    $locality = undef,
    $organization = undef,
    $unit = undef,
    $email = undef,
    $password = undef,
    $ensure = 'present',
    $force = true,
    $dh_param_size = 2048,
) {
    require ::dehydrated::params

    validate_string($dehydrated_host)
    validate_string($country)
    validate_string($organization)
    validate_string($domain_list)
    validate_string($ensure)
    validate_string($state)
    validate_string($locality)
    validate_string($unit)
    validate_string($email)
    validate_integer($dh_param_size)

    $base_dir = $::dehydrated::params::base_dir
    $csr_dir  = $::dehydrated::params::csr_dir
    $key_dir  = $::dehydrated::params::key_dir
    $crt_dir  = $::dehydrated::params::crt_dir

    $domains = split($domain_list, ' ')
    $domain = $domains[0]
    if (size(domains) > 1) {
        $req_ext = true
        $altnames = delete_at($domains, 0)
        $subject_alt_names = $domains
    } else {
        $req_ext = false
        $altnames = []
        $subject_alt_names = []
    }

    $cnf = "${base_dir}/${domain}.cnf"
    $crt = "${crt_dir}/${domain}.crt"
    $key = "${key_dir}/${domain}.key"
    $csr = "${csr_dir}/${domain}.csr"
    $dh  = "${crt_dir}/${domain}.dh"

    $create_dh_unless = join([
        '/usr/bin/test',
        '-f',
        "'${dh}'",
        '&&',
        '/usr/bin/test',
        '$(',
        "/usr/bin/stat -c '%Y' ${dh}",
        ')',
        '-gt',
        '$(',
        "/bin/date --date='1 month ago' '+%s'",
        ')',
    ], ' ')

    exec { "create-dh-${dh}" :
        require => [
            File[$crt_dir]
        ],
        user    => 'root',
        group   => 'dehydrated',
        command => "/usr/bin/openssl dhparam -check ${dh_param_size} -out ${dh}",
        unless  => $create_dh_unless,
        timeout => 30*60,
    }

    file { $dh :
        ensure  => $ensure,
        owner   => 'root',
        group   => 'dehydrated',
        mode    => '0644',
        require => Exec["create-dh-${dh}"],
    }

    file { $cnf :
        ensure  => $ensure,
        owner   => 'root',
        group   => 'dehydrated',
        mode    => '0644',
        content => template('dehydrated/cert.cnf.erb'),
    }

    ssl_pkey { $key :
        ensure   => $ensure,
        password => $password,
        require  => File[$key_dir],
    }
    x509_request { $csr :
        ensure      => $ensure,
        template    => $cnf,
        private_key => $key,
        password    => $password,
        force       => $force,
        require     => File[$cnf],
    }

    exec { "refresh-csr-${csr}" :
        path        => '/sbin:/bin:/usr/sbin:/usr/bin',
        command     => "rm -f ${csr}",
        refreshonly => true,
        user        => 'root',
        group       => 'dehydrated',
        before      => X509_request[$csr],
        subscribe   => File[$cnf],
    }

    file { $key :
        ensure  => $ensure,
        owner   => 'root',
        group   => 'dehydrated',
        mode    => '0640',
        require => Ssl_pkey[$key],
    }
    file { $csr :
        ensure  => $ensure,
        owner   => 'root',
        group   => 'dehydrated',
        mode    => '0644',
        require => X509_request[$csr],
    }

    $csr_content = pick_default(getvar("::dehydrated_csr_${domain}"), '')
    if ($csr_content =~ /CERTIFICATE REQUEST/) {
        @@dehydrated::request { $domain :
            csr           => $csr_content,
            tag           => $dehydrated_host,
            challengetype => $challengetype,
            altnames      => $altnames,
        }
    } else {
        notify { "no CSR from facter for domain ${domain}" : }
    }

}

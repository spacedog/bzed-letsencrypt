# == Define: dehydrated::certificate
#
# Request a certificate for a single domain or a SAN certificate.
#
# === Parameters
#
# [*domain*]
#   Full qualified domain names (== commonname)
#   you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example 'foo.example.com fuzz.example.com'
#
# [*channlengetype*]
#   Challenge type to use, defaults to $::dehydrated::challengetype
#
# [*dehydrated_host*]
#   The host you want to run dehydrated.sh on.
#   Defaults to $::dehydrated::dehydrated_host
#
# [*dh_param_size*]
#   dh parameter size, defaults to $::dehydrated::dh_param_size
#
# === Examples
#   ::letsencryt::certificate( 'foo.example.com' :
#   }
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#
define dehydrated::certificate (
    $domain = $name,
    $challengetype = $::dehydrated::challengetype,
    $dehydrated_host = $::dehydrated::dehydrated_host,
    $dh_param_size = $::dehydrated::dh_param_size,
){

    validate_integer($dh_param_size)
    validate_string($dehydrated_host)
    validate_re($challengetype, '^(http-01|dns-01)$')
    validate_string($domain)

    require ::dehydrated::params
    require ::dehydrated::setup

    ::dehydrated::deploy { $domain :
        dehydrated_host => $dehydrated_host,
    }
    ::dehydrated::csr { $domain :
        dehydrated_host => $dehydrated_host,
        challengetype    => $challengetype,
        dh_param_size    => $dh_param_size,
    }

}

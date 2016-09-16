# = Define: dehydrated::deploy
#
# Collects signed certificates and installs them.
#
# == Parameters:
#
# [*dehydrated_host*]
#   Host the certificates were signed on
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#


define dehydrated::deploy(
    $dehydrated_host,
) {

    $domains = split($name, ' ')
    $domain = $domains[0]

    Letsencrypt::Deploy::Crt <<| tag == $domain and tag == $dehydrated_host |>>

}

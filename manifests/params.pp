# == Class: dehydrated::params
#
# Some basic variables we want to use.
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#



class dehydrated::params {

    $old_base_dir = '/etc/letsencrypt'
    $base_dir = '/etc/dehydrated'
    $csr_dir  = '/etc/dehydrated/csr'
    $key_dir  = '/etc/dehydrated/private'
    $crt_dir  = '/etc/dehydrated/certs'

    $old_handler_base_dir = '/opt/letsencrypt'
    $handler_base_dir = '/opt/dehydrated'
    $handler_requests_dir  = "${handler_base_dir}/requests"

    $letsencrypt_sh_dir  = "${handler_base_dir}/letsencrypt.sh"
    $dehydrated_dir  = "${handler_base_dir}/dehydrated"
    $dehydrated_hook = "${handler_base_dir}/dehydrated_hook"
    $dehydrated_conf = "${handler_base_dir}/dehydrated.conf"
    $dehydrated      = "${dehydrated_dir}/dehydrated"

    $dehydrated_chain_request = "${handler_base_dir}/dehydrated_get_certificate_chain.sh"
    $dehydrated_ocsp_request = "${handler_base_dir}/dehydrated_get_certificate_ocsp.sh"
}

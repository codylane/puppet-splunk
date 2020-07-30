# [target_group]
#   Hash used to define splunk default groups and servers, valid configs are
#   { 'target group name' => 'server/ip' }
#
# [type]
#   Install type. Defaults to Universal Forwarder valid inputs are:
#   uf      : Splunk Universal Forwarder
#   lwf     : Splunk Light Weight Forwarder
#   hwf     : Splunk Heavy Weight Forwarder
#   jobs    : Splunk Jobs Server - Search + Forwarding
#   search  : Splunk Search Head
#   indexer : Splunk Distribuited Index Server
#   Default: uf
#
# [package_source]
#   This controls how you want to install the splunk service.  If you set this
#   be sure that you have the package somewhere locally on the host.
#   Default: undef
#
# [package_provider]
#   This should be set only when you are installing locally.  You will also need
#   to se the package_source option as well.
#   Default: undef
#
# [version]
#   Install package version, defaults to 'installed'. If this is the first time that you
#   are installing this package, then it will install the latest version available in
#   the yum repo.
#
# [replace_passwd]
#   Whether or not to update the content for ${::splunkhome}/etc/passwd.
#   Default: no
#
# === Example of how to install universal forwarder
#
#  class { splunk:
#    type => 'uf',
#  }
# === Example of how to install universal forwarder with deploymentclient
#
#  class { 'splunk':
#    type => 'uf',
#  }
#
#  class { 'splunk::deploymentlcient':
#    targeturi => 'foo.example.com:8089'
#  }
#
#
class splunk (
  $configure_outputs = $::splunk::params::configure_outputs,
  $service_ensure    = $::splunk::params::service_ensure,
  $service_enable    = $::splunk::params::service_enable,
  $index             = $::splunk::params::index,
  $index_hash        = $::splunk::params::index_hash,
  $indexandforward   = false,
  $licenseserver     = undef,
  $output_hash       = $::splunk::params::output_hash,
  $port              = $::splunk::params::port,
  $proxyserver       = $::splunk::params::proxyserver,
  $purge             = $::splunk::params::purge,
  $splunkadmin       = $::splunk::params::splunkadmin,
  $target_group      = $::splunk::params::target_group,
  $type              = $::splunk::params::type,
  $package_source    = undef,
  $package_provider  = undef,
  $version           = $::splunk::params::version,
  $replace_passwd    = $::splunk::params::replace_passwd,
) inherits splunk::params {

  validate_string($type)

  case $type {
    'uf': {
      $pkgname    = 'splunkforwarder'
      $splunkhome = '/opt/splunkforwarder'
      $license    = undef
    }
    'hfw','lwf': {
      $splunkhome = '/opt/splunk'
      $pkgname    = 'splunk'
      $license    = 'puppet:///modules/splunk/noarch/opt/splunk/etc/splunk-forwarder.license'
    }
    default: {
      $splunkhome = '/opt/splunk'
      $pkgname    = 'splunk'
      $license    = undef
    }
  }

  if ( $purge ) {
    validate_bool($purge)
    class { 'splunk::purge': }

  } else {

    if defined("splunk::type::${type}") {
      include "splunk::type::${type}"
    } else {
      fail("Server type: ${type} is not a supported Splunk type.")
    }
  }

}

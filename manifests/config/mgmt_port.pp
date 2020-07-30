#Private Class to enable/disable the Splunk Managment Port
class splunk::config::mgmt_port (
  $disable_default_port = 'True',
  $splunkhome           = $::splunk::splunkhome
) {
  ini_setting { 'Configure Management Port':
    ensure  => present,
    path    => "${splunkhome}/etc/system/local/server.conf",
    section => 'httpServer',
    setting => 'disableDefaultPort',
    value   => $disable_default_port,
    require => Class['splunk::install'],
  }
}

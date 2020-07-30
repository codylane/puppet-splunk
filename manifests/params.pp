class splunk::params {
  $configure_outputs = false
  $index             = 'os'
  $index_hash        = { }
  $splunkadmin       = ':admin:$foobarbaxwhizzlebattywattyfooson::Administrator:admin:changeme@example.com:'
  $target_group      = { example1 => 'server1.example.com',
                        example2 => 'server2.example.com' }
  $type              = 'uf'
  $output_hash       = { }
  $port              = '9997'
  $proxyserver       = undef
  $purge             = undef
  $version           = 'installed'
  $replace_passwd    = 'no'

  if $::mode == maintenance {
    $service_ensure = 'stopped'
    $service_enable = false
  } else {
    $service_ensure = 'running'
    $service_enable = true
  }
}

# for a indexer
#
class splunk::type::indexer(
  $licenseserver = $::splunk::licenseserver,
){
  include splunk::type::base

  class { 'splunk::outputs':
    tcpout_disabled => true
  }

  class { 'splunk::indexes': }

  class { 'splunk::config::lwf':
    status => 'disabled'
  }

  class { 'splunk::config::mgmt_port':
    disable_default_port => 'False'
  }

  class { 'splunk::config::remove_uf': }

  class { 'splunk::config::license':
    server => $licenseserver
  }
}

# for a universal forwarder
#
class splunk::type::uf {
  include splunk::type::base

  class { 'splunk::outputs': }
  class { 'splunk::config::mgmt_port': }
}

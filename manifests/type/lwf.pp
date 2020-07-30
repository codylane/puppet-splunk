# for a light weight forwarder
#
class splunk::type::lwf {
  include splunk::type::base

  class { 'splunk::outputs': }
  class { 'splunk::config::lwf': }
  class { 'splunk::config::mgmt_port': }
  class { 'splunk::config::remove_uf': }

}

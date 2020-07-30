# This class is used for all base types of splunk management.
# All splunk types should include this class in their respective
# definitions.
#
class splunk::type::base {

  class { 'splunk::install':
    notify => Class['splunk::service'],
    before => Class['splunk::outputs'],
  }

  class { 'splunk::service': }
}

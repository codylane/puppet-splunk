class splunk::service {
  service {
    'splunk':
      ensure     => $::splunk::service_ensure,
      hasrestart => true,
      pattern    => 'splunkd',
  }

}

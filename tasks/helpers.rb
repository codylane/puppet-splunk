$PROVISIONED_FILENAME='provisioned'

def has_been_provisioned
  File.exists? $PROVISIONED_FILENAME
end

def set_provisioned_env toggle=false

  if toggle
    ENV['BEAKER_provision'] = 'no'
    ENV['BEAKER_destroy'] = 'no'
  else
    ENV['BEAKER_provision'] = 'no'
    ENV['BEAKER_destroy'] = 'yes'
    File.unlink $PROVISIONED_FILENAME if has_been_provisioned
  end
end

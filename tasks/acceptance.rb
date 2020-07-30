require_relative "helpers"

desc "Acceptance tests"
namespace :acceptance do

  task :tests do
     ENV['SPLUNK_VERSION'] = '6.3.3-f44afce176d0'
     set_provisioned_env(has_been_provisioned)
     Rake::Task[:beaker].invoke

     File.write($PROVISIONED_FILENAME, '')
  end

end

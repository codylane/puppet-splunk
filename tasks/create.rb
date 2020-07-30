require_relative "helpers"

desc "Starts up the VM, provisions and keeps it running so you can run more tests"

task :create do
   ENV['BEAKER_destroy'] = 'no'
   ENV['PUPPET_INSTALL_VERSION'] = '1.3.5'
   ENV['PUPPET_INSTALL_TYPE'] = 'agent'

   ENV['SPLUNK_VERSION'] = '6.3.3-f44afce176d0'

   # Rake::Task[:validate].invoke
   # Rake::Task[:spec].invoke
   Rake::Task[:beaker].invoke

   File.write($PROVISIONED_FILENAME, '')
end

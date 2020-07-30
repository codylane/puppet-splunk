require_relative "helpers"

desc "Starts up the VM, provisions and keeps it running so you can run more tests"
task :converge do
   set_provisioned_env(has_been_provisioned)

   Rake::Task[:validate].invoke
   Rake::Task[:spec].invoke
   Rake::Task[:beaker].invoke

   File.write($PROVISIONED_FILENAME, '')
end

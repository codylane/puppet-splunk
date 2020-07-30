require 'beaker-rspec'
require 'beaker_spec_helper'
require 'beaker/puppet_install_helper'
require 'yaml'
include BeakerSpecHelper

# https://github.com/puppetlabs/beaker-puppet_install_helper
run_puppet_install_helper

def load_hiera_config module_root
  c = YAML.load_file("#{module_root}/spec/fixtures/hiera.yaml")
  return c
end

RSpec.configure do |c|
  # Project root
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  module_name = File.basename(module_root.split('-').last)

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      copy_module_to(host, :source => module_root, :module_name => module_name)

      if Dir.exists?("#{module_root}/spec/fixtures/hieradata")
        copy_hiera_data_to(host, "#{module_root}/spec/fixtures/hieradata")
      end

      # Ensure that the git package is installed (RedHat-specific package name)
      on host, puppet('apply -e "package { \'git\': ensure => installed }"')

      # https://github.com/camptocamp/beaker_spec_helper
      BeakerSpecHelper::spec_prep(host)
    end
  end
end

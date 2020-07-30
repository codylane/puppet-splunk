require 'spec_helper_acceptance'

describe 'splunk::deploymentclient' do
  before :all do
    $pkg_name   = "splunkforwarder-#{ENV['SPLUNK_VERSION']}-linux-2.6-${::architecture}.rpm"
    $pkg_source = "#{ENV['YUM_REPO_URL']}/#{$pkg_name}"

    pp = <<-EOS
      exec { "download_splunkforwarder":
        path    => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
        command => "wget -O /opt/#{$pkg_name} #{$pkg_source}",
        creates => "/opt/#{$pkg_name}",
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)

  end
  describe 'should raise error when targeturi=undef' do
    it 'should raise error' do
      pp = <<-EOS
        class { 'splunk::deploymentclient':
          path => '/opt/splunkforwarder/etc/system/local',
        }
      EOS

      apply_manifest(pp, :expect_failures => true)
    end
  end

  describe 'when installing splunkfowarder it should configure deploymentclient.conf' do
    it do
      pp = <<-EOS
        class { 'splunk':
          type             => 'uf',
          package_source   => "/opt/#{$pkg_name}",
          package_provider => 'rpm',
        } ->

        class { 'splunk::deploymentclient':
          targeturi => 'foo.com:8089'
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe file('/opt/splunkforwarder/etc/system/local/deploymentclient.conf') do
      let(:deploymentclient_conf) do
        <<-EOS
# Managed through Puppet
[deployment-client]

[target-broker:deploymentServer]
targetUri = foo.com:8089
        EOS
      end

      it { is_expected.to be_file }
      it { is_expected.to exist }
      it { is_expected.to be_mode '644' }
      it { is_expected.to be_owned_by 'splunk' }
      it { is_expected.to be_grouped_into 'splunk' }
      its(:content) { is_expected.to eq deploymentclient_conf }
    end
  end
end

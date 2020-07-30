require 'spec_helper'

describe 'splunk::deploymentclient' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context "when 'path=/opt/splunkforwarder'" do
        let(:params) do
          {
            :path => '/opt/splunkforwarder/etc/system/local'
          }
        end

        it { is_expected.to compile.and_raise_error /"targeturi" has not been set, should be in the form of "deploymentserver.splunk.mycompany.com:8089"/ }

        context "when targeturi='foo.example.com:8089'" do
          let(:params) do
            {
              :path      => '/opt/splunkforwarder/etc/system/local',
              :targeturi => 'foo.example.com:8089'
            }
          end

          it {
            is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/deploymentclient.conf').with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]'
            })
          }
        end
      end

      context "when 'path=/opt/splunk'" do
        let(:params) do
          {
            :path => '/opt/splunk/etc/system/local',
          }
        end

        it { is_expected.to compile.and_raise_error /"targeturi" has not been set, should be in the form of "deploymentserver.splunk.mycompany.com:8089"/ }

        context "when targeturi='foo.example.com:8089'" do
          let(:params) do
            {
              :path      => '/opt/splunk/etc/system/local',
              :targeturi => 'foo.example.com:8089'
            }
          end
          let(:deploymentclient_conf) do
            <<-EOS
# Managed through Puppet
[deployment-client]

[target-broker:deploymentServer]
targetUri = foo.example.com:8089
            EOS
          end

          it {
            is_expected.to contain_file('/opt/splunk/etc/system/local/deploymentclient.conf').with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
              :content => deploymentclient_conf,
            })
          }
        end
      end
    end
  end
end

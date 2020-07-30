require 'spec_helper'

describe 'splunk::inputs' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      ['/opt/splunkforwarder', '/opt/splunk'].each do |splunk_path|
        context "when path='#{splunk_path}/etc/system/local'" do
          let(:params) do
            {
              :path => "#{splunk_path}/etc/system/local"
            }
          end

          let(:inputs_content) do
            <<-EOS
# Default inputs.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.
[default]
host = #{facts[:fqdn]}

            EOS
          end

          it {
            is_expected.to contain_file("#{splunk_path}/etc/system/local/inputs.conf").with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
              :content => "#{inputs_content}",
            })
          }
        end

        context 'it should fail when input_hash is not a hash' do
          let(:params) do
            {
              :input_hash => 'boom'
            }
          end

          it { is_expected.to compile.and_raise_error /boom is not a valid hash/ }
        end

        context 'when input_hash is provided' do
          let(:params) do
            {
              :path       => "#{splunk_path}/etc/system/local",
              :input_hash => {
                'somekey' => {
                  'disabled'   => 'true',
                  'index'      => 'os',
                  'interval'   => '3600',
                  'source'     => 'Unix::SSHDConfig',
                  'sourcetype' => 'Unix::SSHDConfig',
                }
              },
            }
          end
          let(:inputs_content) do
            <<-EOS
# Default inputs.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.
[default]
host = #{facts[:fqdn]}

[somekey]
disabled = true
index = os
interval = 3600
source = Unix::SSHDConfig
sourcetype = Unix::SSHDConfig
            EOS
          end

          it {
            is_expected.to contain_file("#{splunk_path}/etc/system/local/inputs.conf").with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
              :content => "#{inputs_content}",
            })
          }

        end
      end
    end
  end

end

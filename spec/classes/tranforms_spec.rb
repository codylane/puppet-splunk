require 'spec_helper'

describe 'splunk::transforms' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      ['/opt/splunk/etc/system/local', '/opt/splunkforwarder/etc/system/local'].each do |splunk_path|
        context "when path='#{splunk_path}'" do
          let(:params) do
            {
              :path => splunk_path
            }
          end
          let(:transforms_conf) do
            <<-EOS
# Local transforms.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.

            EOS
          end

          it {
            is_expected.to contain_file(splunk_path + '/transforms.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
              :content => transforms_conf
            })
          }

          context 'when input_hash is provided' do
            let(:params) do
              {
                :path       => splunk_path,
                :input_hash => {
                  'key' => {
                    'disabled'   => 'true',
                    'index'      => 'os',
                    'interval'   => '3600',
                    'source'     => 'Unix:SSHDConfig',
                    'sourcetype' => 'Unix:SSHDConfig'
                  }
                }
              }
            end

            let(:transforms_conf) do
              <<-EOS
# Local transforms.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.

[key]
disabled = true
index = os
interval = 3600
source = Unix:SSHDConfig
sourcetype = Unix:SSHDConfig

              EOS
            end

            it {
              is_expected.to contain_file(splunk_path + '/transforms.conf').with({
                :ensure  => 'file',
                :owner   => 'splunk',
                :group   => 'splunk',
                :mode    => '0644',
                :require => 'Class[Splunk::Install]',
                :notify  => 'Class[Splunk::Service]',
                :content => transforms_conf,
              })
            }
          end
        end
      end

    end
  end
end

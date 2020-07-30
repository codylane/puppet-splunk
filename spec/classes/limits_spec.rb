require 'spec_helper'

describe 'splunk::limits' do
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
          let(:limits_conf) do
            <<-EOS
# Default limits.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.
            EOS
          end

          it {
            is_expected.to contain_file(splunk_path + '/limits.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
              :content => limits_conf
            })
          }

          context 'when limit_hash is provided' do
            let(:params) do
              {
                :path       => splunk_path,
                :limit_hash => {
                  'search' => {
                    'max_search_per_cpu' => '1',
                  },
                  'thruput' => {
                    'maxKBps' => '10240',
                  }
                }
              }
            end
            let(:limits_conf) do
              <<-EOS
# Default limits.conf file
# Managed through Puppet
# Copyright (C) 2009-2012 Splunk Inc. All Rights Reserved.
[search]
max_search_per_cpu = 1

[thruput]
maxKBps = 10240

              EOS
            end

            it {
              is_expected.to contain_file(splunk_path + '/limits.conf').with({
                :ensure  => 'file',
                :owner   => 'splunk',
                :group   => 'splunk',
                :mode    => '0644',
                :require => 'Class[Splunk::Install]',
                :notify  => 'Class[Splunk::Service]',
                :content => limits_conf
              })
            }
          end
        end
      end

    end
  end
end

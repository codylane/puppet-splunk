require 'spec_helper'

describe 'splunk' do

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) {
        facts
      }

      context 'with defaults for all parameters' do
        it { is_expected.to contain_class('splunk') }

        it {
          is_expected.to contain_class('splunk::install').with({
            :notify => 'Class[Splunk::Service]',
            :before => 'Class[Splunk::Outputs]',
          })
        }

        it { is_expected.to_not contain_class('splunk::purge') }

        it { is_expected.to contain_class('splunk::params') }
        it { is_expected.to contain_class('splunk::type::uf') }
        it { is_expected.to contain_class('splunk::type::base') }
        it { is_expected.to contain_class('splunk::service') }
        it { is_expected.to contain_class('splunk::outputs') }
        it { is_expected.to contain_class('splunk::config::mgmt_port') }

        # splunk::config::mgmt_port tests
        describe 'splunk::config::mgmt_port should contain' do
          it {
            is_expected.to contain_ini_setting('Configure Management Port').with({
              :ensure  => 'present',
              :path    => '/opt/splunkforwarder/etc/system/local/server.conf',
              :section => 'httpServer',
              :value   => 'True',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::service tests
        describe 'splunk::service should contain' do
          it { is_expected.to contain_class('splunk::service') }

          it {
            is_expected.to contain_service('splunk').with({
              :ensure     => 'running',
              :hasrestart => 'true',
              :pattern    => 'splunkd',
            })
          }
        end

        # splunk::outputs tests
        describe 'splunk::outputs should contain' do
          it {
            is_expected.to_not contain_file("/opt/splunkforwarder/etc/system/local/outputs.conf").with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :backup => 'true',
              :notify => 'Class[Splunk::Service]'
            })
          }

          it {
            is_expected.to contain_file("/opt/splunkforwarder/etc/system/local/outputs.conf").with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]'
            })
          }
        end

        # splunk::install tests
        describe 'splunk::install module should contain' do
          it {
            is_expected.to contain_package('splunkforwarder').with({
              :ensure   => 'installed',
              :provider =>  nil,
              :source   => nil,
            })
          }

          it {
            is_expected.to contain_exec('splunk-accept-license').with({
              :command => '/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt',
              :onlyif  => '/usr/bin/test -f /opt/splunkforwarder/ftr',
              :require => 'Package[splunkforwarder]',
              :notify  => 'Exec[splunk-enable-boot]',
            })
          }

          it {
            is_expected.to contain_exec('splunk-enable-boot').with({
              :command     => '/opt/splunkforwarder/bin/splunk enable boot-start',
              :refreshonly => 'true'
            })
          }

          it {
            is_expected.to contain_file('/etc/init.d/splunk').with({
              :ensure => 'present',
              :mode   => '0700',
              :owner  => 'root',
              :group  => 'root',
              :require => 'Exec[splunk-enable-boot]'
            })
          }

          it {
            is_expected.to contain_ini_setting('Server Name').with({
              :ensure  => 'present',
              :path    => "/opt/splunkforwarder/etc/system/local/server.conf",
              :section => 'general',
              :setting => 'serverName',
              :value   => facts[:fqdn]
            })
          }

          it {
            is_expected.to contain_ini_setting('SSL v3 only').with({
              :ensure  => 'present',
              :path    => "/opt/splunkforwarder/etc/system/local/server.conf",
              :section => 'sslConfig',
              :setting => 'supportSSLV3Only',
              :value   => 'True',
            })
          }

          it {
            is_expected.to contain_file("/opt/splunkforwarder/etc/splunk.license").with({
              :ensure => 'present',
              :mode   => '0644',
              :owner  => 'splunk',
              :group  => 'splunk',
              :backup => 'true',
              :source => nil,
            })
          }

          it {
            is_expected.to contain_file("/opt/splunkforwarder/etc/passwd").with({
              :ensure  => 'present',
              :replace => 'no',
              :mode    => '0600',
              :owner   => 'root',
              :group   => 'root',
              :backup  => 'true',
            })
          }
        end
      end

      context 'when purge=true' do
        let(:params) do
          {
            :purge => true
          }
        end

        it { is_expected.to contain_class('splunk::purge') }

        it {
          is_expected.to contain_service('splunk').with({
            :ensure     => 'stopped',
            :hasrestart => 'true',
            :pattern    => 'splunkd',
            :before     => [
                            'Package[splunk]',
                            'Package[splunkforwarder]',
                           ]
          })
        }

        describe 'splunk::purge class should contain the following' do
          it {
            is_expected.to contain_file('/etc/init.d/splunk').with({
              :ensure => 'absent',
            })
          }

          ['splunk', 'splunkforwarder'].each do |splunk_type|
            it {
              is_expected.to contain_file("/opt/#{splunk_type}").with({
                :ensure  => 'absent',
                :force   => 'true',
                :recurse => 'true'
              })
            }
          end

          it { is_expected.to contain_notify("*** NOTICE Purge running on node: #{facts[:fqdn]} ***") }
        end
      end

      context 'when type="lwf"' do
        let(:params) do
          {
            :type => 'lwf'
          }
        end

        it { is_expected.to_not contain_class('splunk::purge') }

        it { is_expected.to contain_class('splunk::type::lwf') }
        it { is_expected.to contain_class('splunk::type::base') }
        it { is_expected.to contain_class('splunk::install') }
        it { is_expected.to contain_class('splunk::service') }
        it { is_expected.to contain_class('splunk::config::mgmt_port') }
        it { is_expected.to contain_class('splunk::config::remove_uf') }

        # splunk::config::remove_uf tests
        describe 'splunk::config::remove_uf should contain' do
          it {
            is_expected.to contain_package('splunkforwarder').with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]',
            })
          }

          it {
            is_expected.to contain_file('/opt/splunkforwarder').with({
              :ensure  => 'absent',
              :force   => 'true',
              :recurse => 'true'
            })
          }
        end

        # splunk::config::lwf tests
        describe 'splunk::config::lwf should contain' do
          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local').with({
              :ensure  => 'directory',
              :owner   => 'splunk',
              :group   => 'splunk',
              :require => 'Class[Splunk::Install]'
            })
          }

          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
            })
          }

          it {
            is_expected.to contain_ini_setting('Enable Splunk LWF').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf',
              :section => 'install',
              :setting => 'state',
              :value   => 'enabled',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::config::mgmt_port tests
        describe 'splunk::config::mgmt_port should contain' do
          it {
            is_expected.to contain_ini_setting('Configure Management Port').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/system/local/server.conf',
              :section => 'httpServer',
              :value   => 'True',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::service tests
        describe 'splunk::service should contain' do
          it { is_expected.to contain_class('splunk::service') }

          it {
            is_expected.to contain_service('splunk').with({
              :ensure     => 'running',
              :hasrestart => 'true',
              :pattern    => 'splunkd',
            })
          }
        end

        # splunk::outputs tests
        describe 'splunk::outputs should contain' do
          it {
            is_expected.to_not contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :backup => 'true',
              :notify => 'Class[Splunk::Service]'
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]'
            })
          }
        end

        # splunk::install tests
        describe 'splunk::install module should contain' do
          it {
            is_expected.to contain_package('splunk').with({
              :ensure   => 'installed',
              :provider =>  nil,
              :source   => nil,
            })
          }

          it {
            is_expected.to contain_file('/etc/init.d/splunk').with({
              :ensure => 'present',
              :mode   => '0700',
              :owner  => 'root',
              :group  => 'root'
            })
          }

          it {
            is_expected.to contain_ini_setting('Server Name').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'general',
              :setting => 'serverName',
              :value   => facts[:fqdn]
            })
          }

          it {
            is_expected.to contain_ini_setting('SSL v3 only').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'sslConfig',
              :setting => 'supportSSLV3Only',
              :value   => 'True',
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/splunk.license").with({
              :ensure => 'present',
              :mode   => '0644',
              :owner  => 'splunk',
              :group  => 'splunk',
              :backup => 'true',
              :source => 'puppet:///modules/splunk/noarch/opt/splunk/etc/splunk-forwarder.license',
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/passwd").with({
              :ensure  => 'present',
              :replace => 'no',
              :mode    => '0600',
              :owner   => 'root',
              :group   => 'root',
              :backup  => 'true',
            })
          }
        end
      end

      context 'when type="hwf"' do
        let(:params) do
          {
            :type => 'hwf'
          }
        end

        it { is_expected.to compile.and_raise_error(/Server type: hwf feature has not yet been implemented/) }
      end

      context 'when type="search"' do
        let(:params) do
          {
            :type => 'search'
          }
        end

        it { is_expected.to_not contain_class('splunk::purge') }

        it { is_expected.to contain_class('splunk::type::search') }
        it { is_expected.to contain_class('splunk::type::base') }
        it { is_expected.to contain_class('splunk::install') }
        it { is_expected.to contain_class('splunk::service') }
        it { is_expected.to contain_class('splunk::outputs').with_tcpout_disabled(true) }
        it { is_expected.to contain_class('splunk::indexes') }
        it { is_expected.to contain_class('splunk::config::lwf').with_status('disabled') }
        it {
          is_expected.to contain_class('splunk::config::mgmt_port').with({
            :disable_default_port => 'False'
          })
        }
        it { is_expected.to contain_class('splunk::config::remove_uf') }

        # splunk::indexes tests
        describe 'splunk::indexes should contain' do
          it {
            is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :backup  => 'true',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
            })
          }
        end

        # splunk::config::remove_uf tests
        describe 'splunk::config::remove_uf should contain' do
          it {
            is_expected.to contain_package('splunkforwarder').with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]',
            })
          }

          it {
            is_expected.to contain_file('/opt/splunkforwarder').with({
              :ensure  => 'absent',
              :force   => 'true',
              :recurse => 'true'
            })
          }
        end

        # splunk::config::lwf tests
        describe 'splunk::config::lwf should contain' do
          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local').with({
              :ensure  => 'directory',
              :owner   => 'splunk',
              :group   => 'splunk',
              :require => 'Class[Splunk::Install]'
            })
          }

          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
            })
          }

          it {
            is_expected.to contain_ini_setting('Enable Splunk LWF').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf',
              :section => 'install',
              :setting => 'state',
              :value   => 'disabled',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::config::mgmt_port tests
        describe 'splunk::config::mgmt_port should contain' do
          it {
            is_expected.to contain_ini_setting('Configure Management Port').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/system/local/server.conf',
              :section => 'httpServer',
              :value   => 'False',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::service tests
        describe 'splunk::service should contain' do
          it { is_expected.to contain_class('splunk::service') }

          it {
            is_expected.to contain_service('splunk').with({
              :ensure     => 'running',
              :hasrestart => 'true',
              :pattern    => 'splunkd',
            })
          }
        end

        # splunk::outputs tests
        describe 'splunk::outputs should contain' do
          it {
            is_expected.to_not contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :backup => 'true',
              :notify => 'Class[Splunk::Service]'
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]'
            })
          }
        end

        # splunk::install tests
        describe 'splunk::install module should contain' do
          it {
            is_expected.to contain_package('splunk').with({
              :ensure   => 'installed',
              :provider =>  nil,
              :source   => nil,
            })
          }

          it {
            is_expected.to contain_exec('splunk-accept-license').with({
              :command => '/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt',
              :onlyif  => '/usr/bin/test -f /opt/splunk/ftr',
              :require => 'Package[splunk]',
              :notify  => 'Exec[splunk-enable-boot]',
            })
          }

          it {
            is_expected.to contain_exec('splunk-enable-boot').with({
              :command     => '/opt/splunk/bin/splunk enable boot-start',
              :refreshonly => 'true',
            })
          }

          it {
            is_expected.to contain_file('/etc/init.d/splunk').with({
              :ensure  => 'present',
              :mode    => '0700',
              :owner   => 'root',
              :group   => 'root',
              :require => 'Exec[splunk-enable-boot]',
            })
          }

          it {
            is_expected.to contain_ini_setting('Server Name').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'general',
              :setting => 'serverName',
              :value   => facts[:fqdn]
            })
          }

          it {
            is_expected.to contain_ini_setting('SSL v3 only').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'sslConfig',
              :setting => 'supportSSLV3Only',
              :value   => 'True',
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/splunk.license").with({
              :ensure => 'present',
              :mode   => '0644',
              :owner  => 'splunk',
              :group  => 'splunk',
              :backup => 'true',
              :source => nil,
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/passwd").with({
              :ensure  => 'present',
              :replace => 'no',
              :mode    => '0600',
              :owner   => 'root',
              :group   => 'root',
              :backup  => 'true',
            })
          }
        end
      end

      context 'when type="indexer"' do
        let(:params) do
          {
            :type   => 'indexer'
          }
        end

        it { is_expected.to_not contain_class('splunk::purge') }

        it { is_expected.to contain_class('splunk::type::indexer') }
        it { is_expected.to contain_class('splunk::type::base') }
        it { is_expected.to contain_class('splunk::install') }
        it { is_expected.to contain_class('splunk::service') }
        it { is_expected.to contain_class('splunk::outputs').with_tcpout_disabled(true) }
        it { is_expected.to contain_class('splunk::indexes') }
        it { is_expected.to contain_class('splunk::config::lwf').with_status('disabled') }
        it { is_expected.to contain_class('splunk::config::mgmt_port').with_disable_default_port('False') }
        it { is_expected.to contain_class('splunk::config::remove_uf') }
        it { is_expected.to contain_class('splunk::config::license').with_server(nil) }

        it { is_expected.to_not contain_ini_setting('Configure Splunk License') }

        # splunk::indexes tests
        describe 'splunk::indexes should contain' do
          it {
            is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :backup  => 'true',
              :require => 'Class[Splunk::Install]',
              :notify  => 'Class[Splunk::Service]',
            })
          }
        end

        # splunk::config::remove_uf tests
        describe 'splunk::config::remove_uf should contain' do
          it {
            is_expected.to contain_package('splunkforwarder').with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]',
            })
          }

          it {
            is_expected.to contain_file('/opt/splunkforwarder').with({
              :ensure  => 'absent',
              :force   => 'true',
              :recurse => 'true'
            })
          }
        end

        # splunk::config::lwf tests
        describe 'splunk::config::lwf should contain' do
          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local').with({
              :ensure  => 'directory',
              :owner   => 'splunk',
              :group   => 'splunk',
              :require => 'Class[Splunk::Install]'
            })
          }

          it {
            is_expected.to contain_file('/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf').with({
              :ensure  => 'file',
              :owner   => 'splunk',
              :group   => 'splunk',
              :mode    => '0644',
              :require => 'Class[Splunk::Install]',
            })
          }

          it {
            is_expected.to contain_ini_setting('Enable Splunk LWF').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/apps/SplunkLightForwarder/local/app.conf',
              :section => 'install',
              :setting => 'state',
              :value   => 'disabled',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::config::mgmt_port tests
        describe 'splunk::config::mgmt_port should contain' do
          it {
            is_expected.to contain_ini_setting('Configure Management Port').with({
              :ensure  => 'present',
              :path    => '/opt/splunk/etc/system/local/server.conf',
              :section => 'httpServer',
              :value   => 'False',
              :require => 'Class[Splunk::Install]'
            })
          }
        end

        # splunk::service tests
        describe 'splunk::service should contain' do
          it { is_expected.to contain_class('splunk::service') }

          it {
            is_expected.to contain_service('splunk').with({
              :ensure     => 'running',
              :hasrestart => 'true',
              :pattern    => 'splunkd',
            })
          }
        end

        # splunk::outputs tests
        describe 'splunk::outputs should contain' do
          it {
            is_expected.to_not contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'file',
              :owner  => 'splunk',
              :group  => 'splunk',
              :mode   => '0644',
              :backup => 'true',
              :notify => 'Class[Splunk::Service]'
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/system/local/outputs.conf").with({
              :ensure => 'absent',
              :notify => 'Class[Splunk::Service]'
            })
          }
        end

        # splunk::install tests
        describe 'splunk::install module should contain' do
          it {
            is_expected.to contain_package('splunk').with({
              :ensure   => 'installed',
              :provider =>  nil,
              :source   => nil,
            })
          }

          it {
            is_expected.to contain_exec('splunk-accept-license').with({
              :command => '/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt',
              :onlyif  => '/usr/bin/test -f /opt/splunk/ftr',
              :require => 'Package[splunk]',
              :notify  => 'Exec[splunk-enable-boot]',
            })
          }

          it {
            is_expected.to contain_exec('splunk-enable-boot').with({
              :command     => '/opt/splunk/bin/splunk enable boot-start',
              :refreshonly => 'true',
            })
          }

          it {
            is_expected.to contain_file('/etc/init.d/splunk').with({
              :ensure  => 'present',
              :mode    => '0700',
              :owner   => 'root',
              :group   => 'root',
              :require => 'Exec[splunk-enable-boot]',
            })
          }

          it {
            is_expected.to contain_ini_setting('Server Name').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'general',
              :setting => 'serverName',
              :value   => facts[:fqdn]
            })
          }

          it {
            is_expected.to contain_ini_setting('SSL v3 only').with({
              :ensure  => 'present',
              :path    => "/opt/splunk/etc/system/local/server.conf",
              :section => 'sslConfig',
              :setting => 'supportSSLV3Only',
              :value   => 'True',
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/splunk.license").with({
              :ensure => 'present',
              :mode   => '0644',
              :owner  => 'splunk',
              :group  => 'splunk',
              :backup => 'true',
              :source => nil,
            })
          }

          it {
            is_expected.to contain_file("/opt/splunk/etc/passwd").with({
              :ensure  => 'present',
              :replace => 'no',
              :mode    => '0600',
              :owner   => 'root',
              :group   => 'root',
              :backup  => 'true',
            })
          }
        end
      end

      context 'when type is not implemented' do
        let(:params) do
          {
            :type => 'foo'
          }
        end

        it { is_expected.to compile.and_raise_error(/Server type: foo is not a supported Splunk type\./) }
      end

    end
  end
end

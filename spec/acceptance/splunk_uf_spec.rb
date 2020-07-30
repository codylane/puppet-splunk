require 'spec_helper_acceptance'

def reset_environment
  pp = <<-EOS
    package { 'splunkforwarder':
      ensure => 'purged'
    } ->

    exec { 'remove_splunkforwarder_dir':
      command => '/bin/rm -rf /opt/splunkforwarder',
      onlyif  => '/usr/bin/test -d /opt/splunkforwarder',
    } ->

    file { '/etc/init.d/splunk':
      ensure => 'absent',
    } ->

    exec { 'kill_splunkd':
      command => '/usr/bin/killall -9 splunkd',
      onlyif  => '/usr/bin/pgrep -f "splunkd -p"',
    }
  EOS

  apply_manifest(pp, :catch_failures => true)
end

describe 'splunk' do
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

  describe 'when type="uf"' do
    reset_environment

    it 'should work with no errors' do
      pp = <<-EOS
        class { 'splunk':
          type             => 'uf',
          package_source   => "/opt/#{$pkg_name}",
          package_provider => 'rpm',
        }
      EOS

      # run it twice, to test idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe package('splunkforwarder') do
      it { is_expected.to be_installed }
    end

    describe file('/etc/init.d/splunk') do
      it { is_expected.to be_file }
      it { is_expected.to exist }
      it { is_expected.to be_mode '700' }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
    end

    describe service('splunk') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe file('/opt/splunkforwarder/etc/system/local/outputs.conf') do
      it { is_expected.to_not exist }
    end

    describe file('/opt/splunkforwarder/etc/system/local/server.conf') do
      fqdn = fact('fqdn')
      it { is_expected.to exist }
      it { is_expected.to be_file }
      it { is_expected.to be_mode '600' }

      its(:content) { is_expected.to match /\[general\].*serverName = #{fqdn}/m }
      its(:content) { is_expected.to match /\[sslConfig\].*supportSSLV3Only = True/m }
    end

    describe file('/opt/splunkforwarder/etc/splunk.license') do
      it { is_expected.to exist }
      it { is_expected.to be_owned_by 'splunk' }
      it { is_expected.to be_grouped_into 'splunk' }
      it { is_expected.to be_mode '644' }
      its(:size) { is_expected.to eq 0 }
    end

    describe file('/opt/splunkforwarder/etc/passwd') do
      it { is_expected.to exist }
      it { is_expected.to be_mode '600' }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      its(:content) {
        is_expected.to eq ":admin:$1$QfZoXMjP$jafmv2ASM45lllqaXHeXv/::Administrator:admin:changeme@example.com:\n"
      }
    end
  end

  context 'when configure_outputs=true' do
    reset_environment

    it 'should work with no errors' do
      pp = <<-EOS
        class { 'splunk':
          type              => 'uf',
          package_source    => "/opt/#{$pkg_name}",
          package_provider  => 'rpm',
          configure_outputs => true,
        }
      EOS

      # run it twice, to test idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe file('/opt/splunkforwarder/etc/system/local/outputs.conf') do
      let(:outputs_conf) do
        <<-EOS
#### THIS FILE MANAGED BY PUPPET ####
[tcpout]
defaultGroup = example1,example2
disabled = false

[tcpout:example1]
server = server1.example.com:9997

[tcpout:example2]
server = server2.example.com:9997



#### THIS FILE MANAGED BY PUPPET ####
        EOS
      end
      it { is_expected.to exist }
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by 'splunk' }
      it { is_expected.to be_grouped_into 'splunk' }
      it { is_expected.to be_mode '644' }
      its(:content) { is_expected.to eq outputs_conf }
    end
  end
end

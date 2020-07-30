require 'spec_helper'

describe 'splunk::ulimit' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with default params' do
        let(:title) do
          'foo'
        end

        it {
          is_expected.to contain_augeas("set splunk #{title} ulimit").with({
            :context => '/files/etc/security/limits.conf/',
            :changes => [
                          'set "domain[last()]" root',
                          'set "domain[.=\'root\']/type" -',
                          'set "domain[.=\'root\']/item" foo',
                          'set "domain[.=\'root\']/value" 40960'
                        ],
            :onlyif  => 'match domain[.=\'root\'][type=\'-\'][item=\'foo\'][value=\'40960\'] size == 0',
          })
        }
      end

      context 'with custom value param' do
        let(:title) do
          'foobar'
        end

        let(:params) do
          {
            :value => '123456'
          }
        end

        it {
          is_expected.to contain_augeas("set splunk #{title} ulimit").with({
            :context => '/files/etc/security/limits.conf/',
            :changes => [
                          'set "domain[last()]" root',
                          'set "domain[.=\'root\']/type" -',
                          'set "domain[.=\'root\']/item" foobar',
                          'set "domain[.=\'root\']/value" 123456'
                        ],
            :onlyif  => 'match domain[.=\'root\'][type=\'-\'][item=\'foobar\'][value=\'123456\'] size == 0',
          })
        }
      end

    end
  end
end

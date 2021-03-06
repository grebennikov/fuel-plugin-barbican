require 'spec_helper'

describe 'barbican::db' do

  shared_examples 'barbican::db' do

    context 'with default parameters' do

      it { is_expected.to contain_class('barbican::params') }
      it { is_expected.to contain_barbican_config('database/connection').with_value('sqlite:////var/lib/barbican/barbican.sqlite') }
      it { is_expected.to contain_barbican_config('database/idle_timeout').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_barbican_config('database/min_pool_size').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_barbican_config('database/max_retries').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_barbican_config('database/retry_interval').with_value('<SERVICE DEFAULT>') }

    end

    context 'with specific parameters' do
      let :params do
        { :database_connection     => 'mysql+pymysql://barbican:barbican@localhost/barbican',
          :database_idle_timeout   => '3601',
          :database_min_pool_size  => '2',
          :database_max_retries    => '11',
          :database_retry_interval => '11',
        }
      end

      it { is_expected.to contain_class('barbican::params') }
      it { is_expected.to contain_barbican_config('database/connection').with_value('mysql+pymysql://barbican:barbican@localhost/barbican').with_secret(true) }
      it { is_expected.to contain_barbican_config('database/idle_timeout').with_value('3601') }
      it { is_expected.to contain_barbican_config('database/min_pool_size').with_value('2') }
      it { is_expected.to contain_barbican_config('database/max_retries').with_value('11') }
      it { is_expected.to contain_barbican_config('database/retry_interval').with_value('11') }

    end

    context 'with postgresql backend' do
      let :params do
        { :database_connection     => 'postgresql://barbican:barbican@localhost/barbican', }
      end

      it 'install the proper backend package' do
        is_expected.to contain_package('python-psycopg2').with(:ensure => 'present')
      end
    end

    context 'with MySQL-python library as backend package' do
      let :params do
        { :database_connection     => 'mysql://barbican:barbican@localhost/barbican', }
      end

      it { is_expected.to contain_package('python-mysqldb').with(:ensure => 'present') }
    end

    context 'with incorrect database_connection string' do
      let :params do
        { :database_connection     => 'redis://barbican:barbican@localhost/barbican', }
      end

      it_raises 'a Puppet::Error', /validate_re/
    end

    context 'with incorrect pymysql database_connection string' do
      let :params do
        { :database_connection     => 'foo+pymysql://barbican:barbican@localhost/barbican', }
      end

      it_raises 'a Puppet::Error', /validate_re/
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :operatingsystemrelease => 'jessie',
      })
    end

    it_configures 'barbican::db'

    context 'with sqlite backend' do
      let :params do
        { :database_connection     => 'sqlite:///var/lib/barbican/barbican.sqlite', }
      end

      it 'install the proper backend package' do
        is_expected.to contain_package('barbican-backend-package').with(
          :ensure => 'present',
          :name   => 'python-pysqlite2',
          :tag    => 'openstack'
        )
      end

    end

    context 'using pymysql driver' do
      let :params do
        { :database_connection     => 'mysql+pymysql://barbican:barbican@localhost/barbican', }
      end

      it 'install the proper backend package' do
        is_expected.to contain_package('barbican-backend-package').with(
          :ensure => 'present',
          :name   => 'python-pymysql',
          :tag    => 'openstack'
        )
      end
    end
  end

  context 'on Redhat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat',
        :operatingsystemrelease => '7.1',
      })
    end

    it_configures 'barbican::db'

    context 'using pymysql driver' do
      let :params do
        { :database_connection     => 'mysql+pymysql://barbican:barbican@localhost/barbican', }
      end

      it { is_expected.not_to contain_package('barbican-backend-package') }
    end
  end

end


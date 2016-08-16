# == Class: barbican::db
#
#  Configure the barbican database
#
# === Parameters
#
# [*database_connection*]
#   Url used to connect to database.
#   (Optional) Defaults to "sqlite:////var/lib/barbican/barbican.sqlite".
#
# [*database_idle_timeout*]
#   Timeout when db connections should be reaped.
#   (Optional) Defaults to $::os_service_default
#
# [*database_max_retries*]
#   Maximum number of database connection retries during startup.
#   Setting -1 implies an infinite retry count.
#   (Optional) Defaults to $::os_service_default
#
# [*database_retry_interval*]
#   Interval between retries of opening a database connection.
#   (Optional) Defaults to $::os_service_default
#
# [*database_min_pool_size*]
#   Minimum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to $::os_service_default
#
# [*database_max_pool_size*]
#   Maximum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to $::os_service_default
#
# [*database_max_overflow*]
#   If set, use this value for max_overflow with sqlalchemy.
#   (Optional) Defaults to $::os_service_default
#
class barbican::db (
  $database_connection     = 'sqlite:////var/lib/barbican/barbican.sqlite',
  $database_idle_timeout   = $::os_service_default,
  $database_min_pool_size  = $::os_service_default,
  $database_max_pool_size  = $::os_service_default,
  $database_max_retries    = $::os_service_default,
  $database_retry_interval = $::os_service_default,
  $database_max_overflow   = $::os_service_default,
  $db_auto_create          = true,
) {

  include ::barbican::params

  $database_connection_real = pick($::barbican::database_connection, $database_connection)
  $database_idle_timeout_real = pick($::barbican::database_idle_timeout, $database_idle_timeout)
  $database_min_pool_size_real = pick($::barbican::database_min_pool_size, $database_min_pool_size)
  $database_max_pool_size_real = pick($::barbican::database_max_pool_size, $database_max_pool_size)
  $database_max_retries_real = pick($::barbican::database_max_retries, $database_max_retries)
  $database_retry_interval_real = pick($::barbican::database_retry_interval, $database_retry_interval)
  $database_max_overflow_real = pick($::barbican::database_max_overflow, $database_max_overflow)

  validate_re($database_connection_real,
    '^(sqlite|mysql(\+pymysql)?|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  case $database_connection_real {
    /^mysql(\+pymysql)?:\/\//: {
      require 'mysql::bindings'
      require 'mysql::bindings::python'
      if $database_connection_real =~ /^mysql\+pymysql/ {
        $backend_package = $::barbican::params::pymysql_package_name
      } else {
        $backend_package = false
      }
    }
    /^postgresql:\/\//: {
      $backend_package = false
      require 'postgresql::lib::python'
    }
    /^sqlite:\/\//: {
      $backend_package = $::barbican::params::sqlite_package_name
    }
    default: {
      fail('Unsupported backend configured')
    }
  }

  if $backend_package and !defined(Package[$backend_package]) {
    package {'barbican-backend-package':
      ensure => present,
      name   => $backend_package,
      tag    => 'openstack',
    }
  }

  barbican_config {
    'DEFAULT/db_auto_create':        value => $db_auto_create;
    'DEFAULT/sql_connection':        value => $database_connection_real, secret => true;
    'DEFAULT/sql_idle_timeout':      value => $database_idle_timeout_real;
    'DEFAULT/sql_pool_size':         value => $database_min_pool_size_real;
    'DEFAULT/sql_max_retries':       value => $database_max_retries_real;
    'DEFAULT/sql_retry_interval':    value => $database_retry_interval_real;
    'DEFAULT/sql_pool_max_overflow': value => $database_max_overflow_real;
  }

}

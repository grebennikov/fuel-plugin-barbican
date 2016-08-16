
class barbican::openstack_barbican (
  $db_host                        = 'localhost',
  $barbican_db_password           = false,
  $barbican_user                  = 'barbican',
  $barbican_user_password           = false,
  $barbican_tenant                  = 'services',
  $bind_host                      = '127.0.0.1',
  $registry_host                  = '127.0.0.1',
  $auth_uri                       = 'http://127.0.0.1:5000/',
  $identity_uri                   = 'http://127.0.0.1:35357/',
  $region                         = 'RegionOne',
  $barbican_protocol              = 'http',
  $db_type                        = 'mysql',
  $barbican_db_user               = 'barbican',
  $barbican_db_dbname             = 'barbican',
  $barbican_crypto_plugin         = 'simple_crypto',
  $host_href                      = 'http://localhost:9311',
  $primary_controller             = false,
  $verbose                        = false,
  $debug                          = false,
  $default_log_levels             = undef,
  $enabled                        = true,
  $use_syslog                     = false,
  $use_stderr                     = true,
  $pipeline                       = 'keystone',
  $syslog_log_facility            = 'LOG_LOCAL2',
  $idle_timeout                   = '3600',
  $max_pool_size                  = '10',
  $max_overflow                   = '30',
  $max_retries                    = '-1',
  $rabbit_password                = false,
  $rabbit_userid                  = 'guest',
  $rabbit_host                    = 'localhost',
  $rabbit_port                    = '5672',
  $rabbit_hosts                   = false,
  $rabbit_virtual_host            = '/',
  $rabbit_use_ssl                 = false,
  $rabbit_notification_exchange   = 'barbican',
  $rabbit_notification_topic      = 'notifications',
  $amqp_durable_queues            = false,
  $service_workers                = $::processorcount,
  $sync_db                        = true,
) {
  validate_string($barbican_user_password)
  validate_string($barbican_db_password)
  validate_string($rabbit_password)

  # Configure the db string
  case $db_type {
    'mysql': {
      $sql_connection = "mysql://${barbican_db_user}:${barbican_db_password}@${db_host}/${barbican_db_dbname}?read_timeout=60"
    }
    default: {
      fail("Wrong db_type: ${db_type}")
    }
  }

  # Install and configure barbican-api
  class { 'barbican::api':
    bind_host              => $bind_host,
#    auth_type              => 'keystone',
#    auth_uri               => $auth_uri,
#    identity_uri           => $identity_uri,
#    keystone_user          => $barbican_user,
#    keystone_password      => $barbican_user_password,
#    keystone_tenant        => $barbican_tenant,
    enabled                => $enabled,
    enabled_crypto_plugins => $barbican_crypto_plugin,
    host_href              => $host_href,
  }

  class {'barbican::api::logging':
    verbose                => $verbose,
    debug                  => $debug,
  }

  if $sync_db { $db_auto_create = false }
  else { $db_auto_create = true }

  class { 'barbican::db':
    db_auto_create          => $db_auto_create,
    database_connection     => $sql_connection,
    database_idle_timeout   => $idle_timeout,
    database_max_pool_size  => $max_pool_size,
    database_max_retries    => $max_retries,
    database_max_overflow   => $max_overflow,
  } 

  if $sync_db {
    include ::barbican::db::sync

  Class['barbican::db'] -> Class['barbican::db::sync'] -> Service['barbican-api']
  }

  barbican_config {
    'DEFAULT/auth_region':                 value => $region;
    'DEFAULT/os_region_name':              value => $region;
    'DEFAULT/workers':                     value => $service_workers;
  }


  if !is_array($rabbit_hosts) {
    $rabbit_hosts_real = split($rabbit_hosts, ',')
    barbican_config {
      'DEFAULT/kombu_reconnect_delay': value => 5.0;
    }
  } else {
    $rabbit_hosts_real = $rabbit_hosts
  }

  # Configure rabbitmq notifications
  if $ceilometer {
    $notification_driver = 'messaging'
  } else {
    $notification_driver = 'noop'
  }

  class { 'barbican::notify::rabbitmq':
    rabbit_password              => $rabbit_password,
    rabbit_userid                => $rabbit_userid,
    rabbit_hosts                 => $rabbit_hosts_real,
    rabbit_host                  => $rabbit_host,
    rabbit_port                  => $rabbit_port,
    rabbit_virtual_host          => $rabbit_virtual_host,
    rabbit_use_ssl               => $rabbit_use_ssl,
    rabbit_notification_exchange => $rabbit_notification_exchange,
    rabbit_notification_topic    => $rabbit_notification_topic,
    amqp_durable_queues          => $amqp_durable_queues,
    notification_driver          => $notification_driver,
  }

  # syslog additional settings default/use_syslog_rfc_format = true
  if $use_syslog {
    barbican_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }
}

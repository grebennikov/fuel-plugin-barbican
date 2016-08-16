notice('MODULAR: barbican.pp')

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

$barbican_hash         = hiera_hash('barbican', {})
$verbose               = pick($barbican_hash['verbose'], hiera('verbose', true))
$debug                 = pick($barbican_hash['debug'], hiera('debug', false))
$management_vip        = hiera('management_vip')
#$database_vip          = hiera('database_vip')
$database_vip          = hiera('management_vip')
$service_endpoint      = hiera('service_endpoint')
$storage_hash          = hiera('storage')
$use_syslog            = hiera('use_syslog', true)
$use_stderr            = hiera('use_stderr', false)
$syslog_log_facility   = hiera('syslog_log_facility_glance')
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$max_pool_size         = hiera('max_pool_size')
$max_overflow          = hiera('max_overflow')
$ceilometer_hash       = hiera_hash('ceilometer', {})
$region                = hiera('region','RegionOne')
$workers_max           = hiera('workers_max', 16)
$ironic_hash           = hiera_hash('ironic', {})
$primary_controller    = hiera('primary_controller')

$default_log_levels             = hiera_hash('default_log_levels')

$db_type                        = 'mysql'
$db_host                        = pick($barbican_hash['db_host'], $database_vip)
$api_bind_address               = get_network_role_property('barbican/api', 'ipaddr')
$enabled                        = true
$max_retries                    = '-1'
$idle_timeout                   = '3600'

$rabbit_password                = $rabbit_hash['password']
$rabbit_user                    = $rabbit_hash['user']
$rabbit_hosts                   = split(hiera('amqp_hosts',''), ',')
$rabbit_virtual_host            = '/'
$barbican_db_user               = pick($barbican_hash['db_user'], 'barbican')
$barbican_db_dbname             = pick($barbican_hash['db_name'], 'barbican')
$barbican_db_password           = $barbican_hash['db_password']
$barbican_user                  = pick($barbican_hash['user'],'barbican')
$barbican_user_password         = $barbican_hash['user_password']
$barbican_tenant                  = pick($barbican_hash['tenant'],'services')

$ssl_hash               = hiera_hash('use_ssl', {})
$public_vip             = hiera('public_vip')
$public_ssl_hash        = hiera('public_ssl')
$public_protocol        = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'protocol', 'http')
$public_address         = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'hostname', [$public_vip])
#$host_href              = "${public_protocol}://${public_address}:9311"
$host_href              = "http://${management_vip}:9311"

$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
$admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])
$glance_endpoint        = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [$management_vip])

$murano_hash    = hiera_hash('murano_hash', {})
$murano_plugins = pick($murano_hash['plugins'], {})

$auth_uri     = "${internal_auth_protocol}://${internal_auth_address}:5000/"
$identity_uri = "${admin_auth_protocol}://${admin_auth_address}:35357/"

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'glance-api':
    package_name => 'glance-api',
  }
  tweaks::ubuntu_service_override { 'glance-registry':
    package_name => 'glance-registry',
  }
}
##################################################
class { 'barbican::openstack_barbican':
  debug                          => $debug,
  verbose                        => $verbose,
  default_log_levels             => $default_log_levels,
  db_type                        => $db_type,
  db_host                        => $db_host,
  barbican_db_user               => $barbican_db_user,
  barbican_db_dbname             => $barbican_db_dbname,
  barbican_db_password           => $barbican_db_password,
  barbican_user                  => $barbican_user,
  barbican_user_password         => $barbican_user_password,
  barbican_tenant                => $barbican_tenant,
  auth_uri                       => $auth_uri,
  identity_uri                   => $identity_uri,
  barbican_protocol              => 'http',
  barbican_crypto_plugin         => 'simple_crypto',
  region                         => $region,
  bind_host                      => $api_bind_address,
  primary_controller             => $primary_controller,
  enabled                        => $enabled,
  use_syslog                     => $use_syslog,
  use_stderr                     => $use_stderr,
  syslog_log_facility            => $syslog_log_facility,
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
  rabbit_password                => $rabbit_password,
  rabbit_userid                  => $rabbit_user,
  rabbit_hosts                   => $rabbit_hosts,
  rabbit_virtual_host            => $rabbit_virtual_host,
  service_workers                => $service_workers,
  host_href                      => $host_href,
}

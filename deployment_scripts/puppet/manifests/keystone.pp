notice('MODULAR: barbican/keystone.pp')

$barbican_hash       = hiera_hash('barbican', {})
$public_vip          = hiera('public_vip')
$public_ssl_hash     = hiera('public_ssl')
$management_vip      = hiera('management_vip')
$region              = pick($barbican_hash['region'], hiera('region', 'RegionOne'))
$password            = $barbican_hash['user_password']
$auth_name           = pick($barbican_hash['auth_name'], 'barbican')
$configure_endpoint  = pick($barbican_hash['configure_endpoint'], true)
$configure_user      = pick($barbican_hash['configure_user'], true)
$configure_user_role = pick($barbican_hash['configure_user_role'], true)
$service_name        = pick($barbican_hash['service_name'], 'barbican')
$tenant              = pick($barbican_hash['tenant'], 'services')
$ssl_hash            = hiera_hash('use_ssl', {})

$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [$barbican_hash['auth_protocol'], 'http'])
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$keystone_auth_url     = "${internal_auth_protocol}://${internal_auth_address}:5000/"

Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::barbican::keystone::auth']

$public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'protocol', 'http')
$public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'hostname', [$public_vip])
$internal_protocol   = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'protocol', 'http')
$internal_address    = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'hostname', [$management_vip])
$admin_protocol      = get_ssl_property($ssl_hash, {}, 'barbican', 'admin', 'protocol', 'http')
$admin_address       = get_ssl_property($ssl_hash, {}, 'barbican', 'admin', 'hostname', [$management_vip])

$public_url = "${public_protocol}://${public_address}:9311"
$internal_url = "${internal_protocol}://${internal_address}:9311"
$admin_url  = "${admin_protocol}://${admin_address}:9311"

validate_string($public_address)
validate_string($password)

class {'::osnailyfacter::wait_for_keystone_backends':}

class { '::barbican::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  configure_user      => $configure_user,
  configure_user_role => $configure_user_role,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $internal_url,
  admin_url           => $admin_url,
  region              => $region,
  tenant              => $tenant,
  keystone_auth_url   => $keystone_auth_url,
}

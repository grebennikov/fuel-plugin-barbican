notice('MODULAR: barbican/barbican_keystone_hook.pp')

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

  include ::barbican::params
  barbican_api_paste_ini {
    'pipeline:barbican_api/pipeline': value => 'keystone_authtoken unauthenticated-context apiapp';
    'filter:keystone_authtoken/paste.filter_factory': value => 'keystonemiddleware.auth_token:filter_factory';
    'filter:keystone_authtoken/identity_uri': value => $keystone_auth_url;
    'filter:keystone_authtoken/admin_tenant_name': value => $tenant;
    'filter:keystone_authtoken/admin_user': value => $auth_name;
    'filter:keystone_authtoken/admin_password': value => $password;
    'filter:keystone_authtoken/auth_version': value => 'v3.0';
  } ~> service { "$::barbican::params::service_name":}

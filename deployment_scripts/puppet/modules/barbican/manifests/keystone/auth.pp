# == Class: barbican::keystone::auth
#
# Configures barbican user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   (required) Password for barbican user.
#
# [*auth_name*]
#   Username for barbican service. Defaults to 'barbican'.
#
# [*email*]
#   Email for barbican user. Defaults to 'barbican@localhost'.
#
# [*tenant*]
#   Tenant for barbican user. Defaults to 'services'.
#
# [*configure_endpoint*]
#   Should barbican endpoint be configured? Defaults to 'true'.
#
# [*configure_user*]
#   (Optional) Should the service user be configured?
#   Defaults to 'true'.
#
# [*configure_user_role*]
#   (Optional) Should the admin role be configured for the service user?
#   Defaults to 'true'.
#
# [*service_type*]
#   Type of service. Defaults to 'key-manager'.
#
# [*region*]
#   Region for endpoint. Defaults to 'RegionOne'.
#
# [*service_name*]
#   (optional) Name of the service.
#   Defaults to the value of auth_name.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:9311')
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:9311')
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:9311')
#   This url should *not* contain any trailing '/'.
#
class barbican::keystone::auth (
  $password,
  $auth_name           = 'barbican',
  $email               = 'barbican@localhost',
  $tenant              = 'services',
  $configure_endpoint  = true,
  $configure_user      = true,
  $configure_user_role = true,
  $service_name        = undef,
  $service_type        = 'key-manager',
  $region              = 'RegionOne',
  $public_url          = 'http://127.0.0.1:9311/v1',
  $internal_url        = 'http://127.0.0.1:9311/v1',
  $admin_url           = 'http://127.0.0.1:9311/v1',
  $keystone_auth_url   = 'http://127.0.0.1:5000/',
) {

  $real_service_name    = pick($service_name, $auth_name)

  keystone::resource::service_identity { 'barbican':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_name        => $real_service_name,
    service_type        => $service_type,
    service_description => 'Key management Service',
    region              => $region,
    auth_name           => $auth_name,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url,
    internal_url        => $internal_url,
    admin_url           => $admin_url,
  }

#  barbican_api_paste_ini {
#    'pipeline:barbican_api/pipeline': value => 'keystone_authtoken unauthenticated-context apiapp';
#    'filter:keystone_authtoken/paste.filter_factory': value => 'keystonemiddleware.auth_token:filter_factory';
#    'filter:keystone_authtoken/identity_uri': value => $keystone_auth_url,;
#    'filter:keystone_authtoken/admin_tenant_name': value => $tenant;
#    'filter:keystone_authtoken/admin_user': value => $auth_name;
#    'filter:keystone_authtoken/admin_password': value => $password;
#    'filter:keystone_authtoken/auth_version': value => 'v3.0';
#  } ~> Service <| name == 'barbican-server' |>
}

notice('MODULAR: barbican/vrouter.pp')

$barbican_hash       = hiera_hash('barbican', {})
$management_vip      = hiera('management_vip')
$password            = $barbican_hash['user_password']  
$auth_name           = pick($barbican_hash['auth_name'], 'barbican')
$tenant              = pick($barbican_hash['tenant'], 'services')
$ssl_hash            = hiera_hash('use_ssl', {})
$region              = hiera('region','RegionOne')

$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [$barbican_hash['auth_protocol'], 'http'])
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
$keystone_auth_url     = "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0"

$internal_protocol   = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'protocol', 'http')
$internal_address    = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'hostname', [$management_vip])

$internal_url = "${internal_protocol}://${internal_address}:9311"

validate_string($password)

file {'/etc/contrail':
  ensure => directory,
}

file { "/etc/contrail/contrail-lbaas-auth.conf":
  content => template("barbican/contrail-lbaas-auth.conf.erb"),
  owner => 'root',
  group => 'root',
  mode => 0644,
  require => File["/etc/contrail"],
}

exec {'supervisor-vrouter':
  command => '/usr/sbin/service supervisor-vrouter restart',
  onlyif => '/usr/sbin/service supervisor-vrouter status'
}

File<||> ~> Exec['supervisor-vrouter']

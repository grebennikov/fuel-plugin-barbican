notice('MODULAR: barbican/openstack-haproxy-barbican.pp')

$barbican_hash         = hiera_hash('barbican', {})
# enabled by default
$use_barbican          = pick($barbican_hash['enabled'], true)
$public_ssl_hash   = hiera('public_ssl')
$ssl_hash          = hiera('use_ssl', {})

$public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'usage', false)
$public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'barbican', 'public', 'path', [''])

$internal_ssl      = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'usage', false)
$internal_ssl_path = get_ssl_property($ssl_hash, {}, 'barbican', 'internal', 'path', [''])

$network_metadata  = hiera_hash('network_metadata')
$barbican_address_map  = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, hiera('heat_roles')), 'management')

$external_lb       = hiera('external_lb', false)

if ($use_barbican and !$external_lb) {
  $server_names        = hiera_array('barbican_names',keys($barbican_address_map))
  $ipaddresses         = hiera_array('barbican_ipaddresses', values($barbican_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

# configure barbican ha proxy
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip    => $internal_virtual_ip,
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    public_ssl             => $public_ssl,
    public_ssl_path        => $public_ssl_path,
    internal_ssl           => $internal_ssl,
    internal_ssl_path      => $internal_ssl_path,
    require_service        => 'barbican-api',
    haproxy_config_options => {
        'timeout server' => '660s',
        'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'barbican-api':
    order                  => '180',
    listen_port            => 9311,
    require_service        => 'barbican-api',
    haproxy_config_options => {
        'timeout server' => '660s',
        'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
    },
  }


}

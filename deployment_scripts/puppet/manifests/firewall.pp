notice('MODULAR: barbican/firewall.pp')

$network_scheme   = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata')
$roles            = hiera('roles')

$barbican_port              = 9311

# Ordering
if member($roles, 'primary-controller') or member($roles, 'controller') {

  firewall {'180 barbican':
    port   => $barbican_port,
    proto  => 'tcp',
    action => 'accept',
  }
}

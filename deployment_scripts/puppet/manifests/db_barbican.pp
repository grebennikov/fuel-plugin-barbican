notice('MODULAR: barbican/db.pp')

$barbican_hash    = hiera_hash('barbican', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip')
$database_vip   = hiera('database_vip')

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($barbican_hash['db_user'], 'barbican')
$db_name     = pick($barbican_hash['db_name'], 'barbican')
$db_password = pick($barbican_hash['db_password'], $mysql_root_password)

$db_host          = pick($barbican_hash['db_host'], $database_vip)
$db_create        = pick($barbican_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($barbican_hash['root_user'], $mysql_root_user)
$db_root_password = pick($barbican_hash['root_password'], $mysql_root_password)

$allowed_hosts = [ hiera('node_name'), 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)
validate_string($database_vip)


if $db_create {
  class { 'galera::client':
    custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
  }

  class { 'barbican::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  class { 'osnailyfacter::mysql_access':
    db_host     => $db_host,
    db_user     => $db_root_user,
    db_password => $db_root_password,
  }

  Class['galera::client'] ->
    Class['osnailyfacter::mysql_access'] ->
      Class['barbican::db::mysql']
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server

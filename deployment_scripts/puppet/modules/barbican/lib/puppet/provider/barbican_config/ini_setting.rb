Puppet::Type.type(:barbican_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:openstack_config).provider(:ini_setting)
) do

  def file_path
    '/etc/barbican/barbican.conf'
  end

end

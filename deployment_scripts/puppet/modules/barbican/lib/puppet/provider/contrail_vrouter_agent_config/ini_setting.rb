Puppet::Type.type(:contrail_vrouter_agent_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:openstack_config).provider(:ini_setting)
) do

  def file_path
    '/etc/contrail/contrail-vrouter-agent.conf'
  end

end

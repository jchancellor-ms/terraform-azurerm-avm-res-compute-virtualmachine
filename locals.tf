locals {
  #nic_subnets = [for subnet in jsondecode(data.azapi_resource.virtualmachine_virtual_network.output).properties.subnets : subnet if contains(var.subnet_names, subnet.name)]
  flattened_nics = flatten([for nic_key, nic in var.network_interfaces : [
    for ip_config_key, ip_config in nic.ip_configurations : {
      nic_key                  = nic_key
      ip_config_key            = ip_config_key
      nic_name                 = nic.name
      ip_config_name           = ip_config.name
      create_public_ip_address = ip_config.create_public_ip_address
    }
    ]
  ])
  #concat the ssh key values list
  admin_ssh_key = (((var.generate_admin_password_or_ssh_key == true) && (lower(var.virtualmachine_os_type) == "linux")) ?
    [{
      public_key = tls_private_key.this[0].public_key_openssh
      username   = var.admin_username
    }] :
  [])
  admin_ssh_keys = concat(var.admin_ssh_keys, local.admin_ssh_key)

  #concat the input variable with the simple list going forward
  source_image_reference = var.source_image_reference

}

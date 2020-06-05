locals {
  # General
  instance = "01"
 
  base_name = "${var.prefix}-${var.environment_name}-${var.app_name}-${var.app_id}-${local.instance}"

  rg_name   = "${local.base_name}-rg"
  
  nsg_name   = "${local.base_name}-default-nsg"
  
  lb_name = "${local.base_name}-lb"
  frontend_ip_configuration_name = "${local.base_name}-fip"
  backend_address_pool_name = "${local.base_name}-bap"
  
  outbound_pip_name = "${local.base_name}-outbound-pip"
  lb_name_outbound = "${local.base_name}-outbound-lb"
  frontend_ip_configuration_name_outbound = "${local.base_name}-outbound-fip"
  backend_address_pool_name_outbound = "${local.base_name}-outbound-bap"
  
  pls_load_balancer = "${local.base_name}-pls"

  blob_private_dns_link_name = "${local.base_name}-blob-dnslink"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
      created  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # VMSS locals

  vmss_name   = "${local.base_name}-pf-vmss" 
  
  vm_computer_name   = "${local.base_name}-pf"
  
  vm_os_name   = "${local.base_name}-pf-vm-os-disk"

  nic_name   = "${local.base_name}-pf-vm-nic"

}

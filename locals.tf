locals {
  # General
  rg_name   = "${var.prefix}-${var.environment_name}-rg"
  
  nsg_name   = "${var.prefix}-${var.environment_name}-default-nsg"
  
  lb_name = "${var.prefix}-${var.environment_name}-lb"
  frontend_ip_configuration_name = "${var.prefix}-${var.environment_name}-fip"
  backend_address_pool_name = "${var.prefix}-${var.environment_name}-bap"
  
  outbound_pip_name = "${var.prefix}-${var.environment_name}-outbound-pip"
  lb_name_outbound = "${var.prefix}-${var.environment_name}-outbound-lb"
  frontend_ip_configuration_name_outbound = "${var.prefix}-${var.environment_name}-outbound-fip"
  backend_address_pool_name_outbound = "${var.prefix}-${var.environment_name}-outbound-bap"
  
  pls_load_balancer = "${var.prefix}-${var.environment_name}-pls"

  blob_private_dns_link_name = "${var.prefix}-${var.environment_name}-blob-dnslink"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
      created  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # VMSS locals

  vmss_name   = "vmss-${var.prefix}-${var.environment_name}-pf-vmss" 
  
  vm_computer_name   = "${var.prefix}-${var.environment_name}-pf"
  
  vm_os_name   = "${var.prefix}-${var.environment_name}-pf-vm-os-disk"

  nic_name   = "${var.prefix}-${var.environment_name}-pf-vm-nic"

}

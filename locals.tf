locals {
  # General
  rg_name   = "rg-${var.prefix}-${var.environment_name}"
  
  nsg_name   = "nsg-${var.prefix}-${var.environment_name}-default"
  
  lb_name = "lb-${var.prefix}-${var.environment_name}"
  frontend_ip_configuration_name = "fip-${var.prefix}-${var.environment_name}"
  backend_address_pool_name = "bap-${var.prefix}-${var.environment_name}"
  pls_load_balancer = "pls-${var.prefix}-${var.environment_name}"

  blob_private_dns_link_name = "dnslink-${var.prefix}-${var.environment_name}-blob"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
      created  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # VMSS locals

  vmss_name   = "vmss-${var.prefix}-${var.environment_name}-pf" 
  
  vm_computer_name   = "${var.prefix}-${var.environment_name}-pf"
  
  vm_os_name   = "disk-${var.prefix}-${var.environment_name}-pf-vm-os"

  nic_name   = "nic-${var.prefix}-${var.environment_name}-pf-vm"

}

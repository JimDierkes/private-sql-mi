# CREATE: Resource Group
resource "azurerm_resource_group" "example" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "Resource Group"
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: DDOS Policy
resource "azurerm_network_ddos_protection_plan" "example" {
  name                = "ddospplan1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}


# GET: Virtual Network 
# data "azurerm_virtual_network" "example" {
#   resource_group_name = var.vnet_rg_name
#   name                = var.vnet_name
# }


# CREATE: Virtual Network 
resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.example.id
    enable = false
  }
}

resource "azurerm_subnet" "ForwarderSubnet" {
  name                                           = "ForwarderSubnet"
  resource_group_name                            = azurerm_resource_group.example.name
  virtual_network_name                           = azurerm_virtual_network.example.name
  address_prefix                                 = "10.0.0.0/24"
}

resource "azurerm_subnet" "PrivateLinkServiceSubnet" {
  name                                           = "PrivateLinkServiceSubnet"
  resource_group_name                            = azurerm_resource_group.example.name
  virtual_network_name                           = azurerm_virtual_network.example.name
  address_prefix                                 = "10.0.1.0/24"
  enforce_private_link_service_network_policies  = true
}

resource "azurerm_subnet" "PrivateEndpointSubnet" {
  name                                           = "PrivateEndpointSubnet"
  resource_group_name                            = azurerm_resource_group.example.name
  virtual_network_name                           = azurerm_virtual_network.example.name
  address_prefix                                 = "10.0.2.0/24"
  enforce_private_link_endpoint_network_policies = true
}


# UPDATE: Assign Network Security Groups to Subnets
 resource "azurerm_subnet_network_security_group_association" "ForwarderSubnet" {
   subnet_id                 = azurerm_subnet.ForwarderSubnet.id
   network_security_group_id = azurerm_network_security_group.example.id
 }
 resource "azurerm_subnet_network_security_group_association" "PrivateLinkServiceSubnet" {
   subnet_id                 = azurerm_subnet.PrivateLinkServiceSubnet.id
   network_security_group_id = azurerm_network_security_group.example.id
 }
 resource "azurerm_subnet_network_security_group_association" "PrivateEndpointSubnet" {
   subnet_id                 = azurerm_subnet.PrivateEndpointSubnet.id
   network_security_group_id = azurerm_network_security_group.example.id
 }


# CREATE: Network Security Group - Default rules.
resource "azurerm_network_security_group" "example" {
  name                = local.nsg_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = merge(
    local.common_tags, 
    {
        display_name = "Default Network Security Group"
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: Subnet
# IF: Subnet doesn't exists
# resource "azurerm_subnet" "example" {
#   count = contains(data.azurerm_virtual_network.example.subnets, var.subnet_name) ? 0 : 1

#   name                 = var.subnet_name
#   resource_group_name  = var.vnet_rg_name
#   virtual_network_name = var.vnet_name
#   address_prefixes     = [var.subnet_address_space]

#   enforce_private_link_endpoint_network_policies = true
#   enforce_private_link_service_network_policies = true
# }


# GET: Subnet 
# Subnet must have enabled:
#  - enforce_private_link_endpoint_network_policies
#  - enforce_private_link_service_network_policies
# data "azurerm_subnet" "example" {
#   name                 = var.subnet_name
#   resource_group_name  = var.vnet_rg_name
#   virtual_network_name = var.vnet_name

#   depends_on = [
#     azurerm_subnet.example
#   ]
# }

# CREATE: Internal Standard Load Balancer
resource "azurerm_lb" "example" {
  name                = local.lb_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name = local.frontend_ip_configuration_name
    subnet_id = azurerm_subnet.ForwarderSubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure Load Balancer"
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# UPDATE: Backend Address Pool for Internal Standard Load Balancer 
resource "azurerm_lb_backend_address_pool" "example" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = local.backend_address_pool_name
}

# UPDATE: NAT rules for Internal Standard Load Balancer 
resource "azurerm_lb_nat_rule" "example" {
  count               = length(var.remote_port)
  
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "Rule-${element(keys(var.remote_port), count.index)}-${count.index}"
  protocol            = "tcp"
  frontend_port       = "5000${count.index + 1}"
  backend_port = element(
    var.remote_port[element(keys(var.remote_port), count.index)],
    1,
  )

  frontend_ip_configuration_name = local.frontend_ip_configuration_name
}

# UPDATE: Health Probe for Internal Standard Load Balancer 
resource "azurerm_lb_probe" "example" {
  count               = length(var.lb_port)
  
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = element(keys(var.lb_port), count.index)
  protocol            = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  port                = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  interval_in_seconds = 5
  number_of_probes    = 2
}

# UPDATE: LB rules for Internal Standard Load Balancer 
resource "azurerm_lb_rule" "example" {
  count                          = length(var.lb_port)
  
  resource_group_name            = azurerm_resource_group.example.name
  loadbalancer_id                = azurerm_lb.example.id
  name                           = element(keys(var.lb_port), count.index)
  
  protocol                       = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  frontend_port                  = element(var.lb_port[element(keys(var.lb_port), count.index)], 0)
  backend_port                   = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
  idle_timeout_in_minutes        = 5
  probe_id                       = element(azurerm_lb_probe.example.*.id, count.index)
  
  depends_on                     = [
    azurerm_lb_probe.example
  ]
}



# CREATE: Public IP for LB
resource "azurerm_public_ip" "outbound" {
  count = var.outbound_internet_enabled ? 1 : 0

  name                = local.outbound_pip_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# CREATE: Public Standard Load Balancer
resource "azurerm_lb" "outbound" {
  count = var.outbound_internet_enabled ? 1 : 0

  name                = local.lb_name_outbound
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  frontend_ip_configuration {
      name = local.frontend_ip_configuration_name_outbound
      public_ip_address_id = azurerm_public_ip.outbound.0.id
  }
  
  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure Load Balancer for Internet Outbound"
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# UPDATE: Backend Address Pool for Public Standard Load Balancer 
resource "azurerm_lb_backend_address_pool" "outbound" {
  count = var.outbound_internet_enabled ? 1 : 0

  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.outbound.0.id
  name                = local.backend_address_pool_name_outbound
}

# UPDATE: LB Outbound rules for Public Standard Load Balancer 
resource "azurerm_lb_outbound_rule" "outbound" {
  count = var.outbound_internet_enabled ? 1 : 0

  resource_group_name     = azurerm_resource_group.example.name
  loadbalancer_id         = azurerm_lb.outbound.0.id
  name                    = "OutboundRule"
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.outbound.0.id

  frontend_ip_configuration {
    name = local.frontend_ip_configuration_name_outbound
  }
}

# CREATE: Private Link Service to Internal Load Balancer
resource "azurerm_private_link_service" "pls" {
  name                = local.pls_load_balancer
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  nat_ip_configuration {
    name               = "ipconfig"
    subnet_id          = azurerm_subnet.PrivateLinkServiceSubnet.id
    primary            = true
  }
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.example.frontend_ip_configuration.0.id]
}

# CREATE: Storage Account for Boot Diagnostics
resource "azurerm_storage_account" "diag" {
  name                     = "diag${substr(md5(azurerm_resource_group.example.id),0,15)}sa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(
      local.common_tags, 
      {
          display_name = "Diagnostics Storage Account"
      }
  )
    
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: Private Endpoint to Blob Storage for Diagnostics
resource "azurerm_private_endpoint" "diag" {
  name                = "${azurerm_storage_account.diag.name}-pe"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.PrivateEndpointSubnet.id

  private_service_connection {
    name                           = "${azurerm_storage_account.diag.name}-pecon"
    private_connection_resource_id = azurerm_storage_account.diag.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = merge(
      local.common_tags, 
      {
          display_name = "Private Endpoint to connect to Diagnostics Storage Account"
      }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: Private DNS zone to blob endpoint
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"  
  resource_group_name = azurerm_resource_group.example.name
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS zone to resolve storage private endpoint."
      }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: A record to Diagnostics Blob Storage.
resource "azurerm_private_dns_a_record" "diag" {
  name                = azurerm_storage_account.diag.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.diag.private_service_connection.0.private_ip_address]
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS record to Diagnostics Blob endpoint."
      }
  )

  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

# CREATE: Link Private DNS zone with Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = local.blob_private_dns_link_name
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.example.id
  registration_enabled  = false
  
  tags = merge(
      local.common_tags, 
      {
          display_name = "Private DNS zone Link to VNET."
      }
  )
    
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

##################################################
# CREATE: Linux VM or VMSS - for Port Forwarding #
##################################################

# GET: Configuration cloudinit file. This can be converted to use an image.
data "template_file" "cloudinit" {
  template = file("${path.module}/scripts/cloudinit.tpl")

  vars = {
    # Comma separated string if specifying a list
    fqdn_list = var.sql_mi_fqdn
    source_port_list = 1433
    destination_port_list = 1433
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = data.template_file.cloudinit.rendered
  }
}

# CREATE: Private/Public SSH Key for Linux Virtual Machine
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# CREATE: Azure Linux VMSS
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                  = local.vmss_name
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  sku                   = var.vm_size

  instances             = var.vmss_instances
  upgrade_mode          = "Manual"
  overprovision = false 

  zones = [1, 2, 3]

  computer_name_prefix  = local.vm_computer_name
  admin_username = var.vm_username
  disable_password_authentication = length(var.vm_password) > 0 ? false : true
  admin_password =  length(var.vm_password) > 0 ? var.vm_password : null

  dynamic "admin_ssh_key" {
    for_each = length(var.vm_password) > 0 ? [] : [var.vm_username]
    content {
      username   = var.vm_username
      public_key = tls_private_key.example["public_key_openssh"]
    }
  }

  # Cloud Init Config file
  custom_data = data.template_cloudinit_config.config.rendered

  # If vm_image_id is specified will use this instead of source_image_reference default settings
  source_image_id =  length(var.vm_image_id) > 0 ? var.vm_image_id : null

  dynamic "source_image_reference" {
    for_each = length(var.vm_image_id) > 0 ? [] : [var.vm_image_ref]
    content {
      publisher = lookup(var.vm_image_ref, "publisher", "Canonical")
      offer     = lookup(var.vm_image_ref, "offer", "UbuntuServer")
      sku       = lookup(var.vm_image_ref, "sku", "18.04-LTS")
      version   = lookup(var.vm_image_ref, "version", "latest")
    }
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  network_interface {
    name    = local.nic_name
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = azurerm_subnet.ForwarderSubnet.id
      load_balancer_backend_address_pool_ids = var.outbound_internet_enabled ? [ azurerm_lb_backend_address_pool.example.id, azurerm_lb_backend_address_pool.outbound.0.id ] : [ azurerm_lb_backend_address_pool.example.id]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure VMSS"
    }
  )
  
  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

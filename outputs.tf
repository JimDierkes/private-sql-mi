output "ForwarderSubnet_subnet_id" {
  value = azurerm_subnet.ForwarderSubnet.id
}

output "PrivateLinkServiceSubnet_subnet_id" {
  value = azurerm_subnet.PrivateLinkServiceSubnet.id
}

output "PrivateEndpointSubnet_subnet_id" {
  value = azurerm_subnet.PrivateEndpointSubnet.id
}

output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.example.id
}

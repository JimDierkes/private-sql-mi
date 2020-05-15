output "subnet_id" {
  value = azurerm_subnet.example.id
}

output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.example.id
}

output "resource_group_name" {
  value = azurerm_resource_group.health_fast_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.health_fast_vnet.name
}

output "subnets" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "network_security_groups" {
  value = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}

output "nsg_rules" {
  value = { for k, v in azurerm_network_security_rule.rules : k => v.name }
}
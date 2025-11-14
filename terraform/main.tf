terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

# ==========================
#  Resource Group
# ==========================
resource "azurerm_resource_group" "health_fast_rg" {
  name     = var.resource_group_name
  location = var.location
}

# ==========================
#  Virtual Network
# ==========================
resource "azurerm_virtual_network" "health_fast_vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.health_fast_rg.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name
}

# ==========================
#  Subnets
# ==========================
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.health_fast_rg.name
  virtual_network_name = azurerm_virtual_network.health_fast_vnet.name
  address_prefixes     = each.value.address_prefixes
}

# ==========================
#  Network Security Groups
# ==========================
resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.nsgs
  name                = each.key
  location            = azurerm_resource_group.health_fast_rg.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name
}

# ==========================
#  NSG Rules
# ==========================
locals {
  nsg_combined = flatten([
    for nsg_name, nsg in var.nsgs : [
      for rule in nsg.rules : {
        nsg_name = nsg_name
        rule     = rule
      }
    ]
  ])
}

resource "azurerm_network_security_rule" "rules" {
  for_each = {
    for combo in local.nsg_combined : "${combo.nsg_name}-${combo.rule.name}" => combo
  }

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
  resource_group_name         = azurerm_resource_group.health_fast_rg.name
  network_security_group_name = each.value.nsg_name

  # ✅ Lógica robusta para manejar uno o varios puertos
  destination_port_range = (
    try(length(each.value.rule.destination_port_ranges), 0) > 0 ?
    null :
    each.value.rule.destination_port_range
  )

  destination_port_ranges = (
    try(length(each.value.rule.destination_port_ranges), 0) > 0 ?
    each.value.rule.destination_port_ranges :
    null
  )
}

# ==========================
#  Asociación NSG <-> Subnet
# ==========================
resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.subnets[each.value.subnet].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg].id
}
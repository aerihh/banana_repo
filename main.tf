terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.44.0"
    }
  }
}

locals {
  combined_subnet = [
    for k, v in var.subnet_names : {
      sn_n = v
      sn_a = var.subnets[k]
    }
  ]
}

provider "azurerm" {
  # Configuration options
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
  features {
  }
}

resource "azurerm_resource_group" "health_fast_rg" {
  name = var.rg_name
  location = var.location
}

#Configuracion de la red virtual
resource "azurerm_virtual_network" "hf_vnet" {
  resource_group_name = azurerm_resource_group.health_fast_rg.name
  name = var.vnet_name
  location = var.location
  address_space = var.address_space
}

#3 subnets para cada end point api, db y web
resource "azurerm_subnet" "subnet_vnet" {
  for_each = { for idx, val in local.combined_subnet : idx => val }
  name = each.value.sn_n
  resource_group_name  = azurerm_resource_group.health_fast_rg.name
  virtual_network_name = azurerm_virtual_network.hf_vnet.name
  address_prefixes = each.value.sn_a
}


#FALTA DECLARAR UN NSG PARA LA SEGURIDAD DE LAS REDES


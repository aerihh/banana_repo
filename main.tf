terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.44.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
  features {
    
  }
}

resource "azurerm_resource_group" "hf_rg" {
  name = var.resource_group_name
  location = var.location
}

#Configuracion de la red virtual
resource "azurerm_virtual_network" "hf_vnet" {
  resource_group_name = azurerm_resource_group.hf_rg
  name = var.vnet_name
  location = var.location
  address_space = var.address_space
}

#3 subnets para cada end point api, db y web
resource "azurerm_subnet" "subnet_app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.hf_rg
  virtual_network_name = azurerm_virtual_network.hf_vnet
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.hf_rg
  virtual_network_name = azurerm_virtual_network.hf_vnet
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet_db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.hf_rg
  virtual_network_name = azurerm_virtual_network.hf_vnet
  address_prefixes     = ["10.0.3.0/24"]
}


#FALTA DECLARAR UN NSG PARA LA SEGURIDAD DE LAS REDES



output "hf_rg" {
  value = azurerm_resource_group.test_group.name
}

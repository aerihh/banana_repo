# banana_repo
This repository is in charge to help me upgrade my python, git and whatever else I want to learn.

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
  tenant_id = "17aa4ddc-a9ef-4a6c-9687-8572044513ac"
  subscription_id = "98f81224-226a-46f0-b9b7-34bded3c97d2"
  features {
    
  }
}

resource "azurerm_resource_group" "hf_rg" {
  name = "healthfast_group"
  location = "East US"
}


#Configuracion de la red virtual
resource "azurerm_virtual_network" "hf_vnet" {
  resource_group_name = "hf_rg"
  name = "healthfast-vnet"
  location = "eastus"
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
  address_prefixes     = ["10.0.11.0/24"]
}

resource "azurerm_subnet" "subnet_db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.hf_rg
  virtual_network_name = azurerm_virtual_network.hf_vnet
  address_prefixes     = ["10.0.21.0/24"]
}


#FALTA DECLARAR UN NSG PARA LA SEGURIDAD DE LAS REDES



output "hf_rg" {
  value = azurerm_resource_group.test_group.name
}

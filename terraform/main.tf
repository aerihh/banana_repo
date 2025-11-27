terraform {
  required_version = ">= 1.3.0"

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

# ==========================
#  NIC ---> app
# ==========================

resource "azurerm_network_interface" "app_nic" {
  name                = "app_nic"
  location            = azurerm_resource_group.health_fast_rg.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name

  ip_configuration {
    name                          = "internal_app"
    subnet_id                     = azurerm_subnet.subnets["app"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# ==========================
#  VM app
# ==========================

resource "azurerm_linux_virtual_machine" "vm_app" {
  name                = "vmapp"
  resource_group_name = azurerm_resource_group.health_fast_rg.name
  location            = azurerm_resource_group.health_fast_rg.location
  size                = "Standard_B1s"

  network_interface_ids = [
    azurerm_network_interface.app_nic.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"
  
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_admin_ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ==========================
#  Public IP
# ==========================

resource "azurerm_public_ip" "web_ip" {
  name                = "web-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}


# ==========================
#  NIC-WEB
# ==========================

resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets["web"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_ip.id
  }
}

# ==========================
#  VM_WEB
# ==========================

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init/web-nginx.yaml")
}

resource "azurerm_linux_virtual_machine" "vm_web" {
  name                = "vmweb"
  location            = var.location
  resource_group_name = azurerm_resource_group.health_fast_rg.name
  size                = "Standard_B1s"

  admin_username = var.vm_admin_username
  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_admin_ssh_key
  }

  custom_data = base64encode(data.template_file.cloud_init.rendered)

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

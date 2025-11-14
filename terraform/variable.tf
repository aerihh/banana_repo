variable "resource_group_name" {
  description = "Nombre del resource group"
  type        = string
  default     = "rg-healthfast"
}

variable "tenant_id"{
  default = "17aa4ddc-a9ef-4a6c-9687-8572044513ac"
}

variable "subscription_id"{
  default = "98f81224-226a-46f0-b9b7-34bded3c97d2"
}

variable "location" {
  description = "Ubicación de los recursos"
  type        = string
  default     = "eastus"
}

variable "vnet_name" {
  description = "Nombre de la red virtual"
  type        = string
  default     = "vnet-healthfast"
}

variable "subnets" {
  description = "Subnets de la red"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
    }
    db = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

variable "nsgs" {
  description = "NSGs y sus reglas"
  type = map(object({
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range           = string
      destination_port_range      = optional(string)
      destination_port_ranges     = optional(list(string))
      source_address_prefix       = string
      destination_address_prefix  = string
    }))
  }))
  default = {
    web = {
      rules = [
        {
          name                       = "Allow-HTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range           = "*"
          destination_port_range      = "80"
          source_address_prefix       = "*"
          destination_address_prefix  = "*"
        },
        {
          name                       = "Allow-HTTPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range           = "*"
          destination_port_range      = "443"
          source_address_prefix       = "*"
          destination_address_prefix  = "*"
        }
      ]
    }

    app = {
      rules = [
        {
          name                       = "Allow-AppPorts"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range           = "*"
          destination_port_ranges     = ["8080", "8443"]
          source_address_prefix       = "*"
          destination_address_prefix  = "*"
        }
      ]
    }

    db = {
      rules = [
        {
          name                       = "Allow-SQL"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range           = "*"
          destination_port_range      = "1433"
          source_address_prefix       = "*"
          destination_address_prefix  = "*"
        }
      ]
    }
  }
}

variable "subnet_nsg_associations" {
  description = "Asociaciones entre subnets y NSGs"
  type = map(object({
    subnet = string
    nsg    = string
  }))
  default = {
    web = {
      subnet = "web"
      nsg    = "web"
    }
    app = {
      subnet = "app"
      nsg    = "app"
    }
    db = {
      subnet = "db"
      nsg    = "db"
    }
  }
}
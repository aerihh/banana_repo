
variable "tenant_id"{
  default = "17aa4ddc-a9ef-4a6c-9687-8572044513ac"
}

variable "subscription_id"{
  default = "98f81224-226a-46f0-b9b7-34bded3c97d2"
}

variable "resource_group_name" {
  default = "rg-healthfast"
}

variable "location" {
  default = "eastus"
}

variable "vnet_name" {
  default = "healthfast-vnet"
}

variable "address_space" {
  default = ["10.0.0.0/16"]
}

variable "subnets" {
  default = {
    web = "10.0.1.0/24"
    app = "10.0.2.0/24"
    db  = "10.0.3.0/24"
  }
}

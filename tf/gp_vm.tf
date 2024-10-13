terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "3.8.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = ""
  tenant_id       = ""
  client_id       = ""
  client_secret   = ""
  features {}
}

locals {
  resource_group_name = "gp-vm-group"
  location            = "Australia East"
  virtual_network     = {
    name            = "gp-vm-vnet"
    address_space   = "10.0.0.0/16"
  }
  subnets             = [
    {
        name            = "subnetA"
        address_prefix  = "10.0.1.0/24"
    }
  ]
  nic_name            = "gp-vm-nic"
}

resource "azurerm_resource_group" "gp-vm-group" {
  name      = local.resource_group_name
  location  = local.location
}

resource "azurerm_virtual_network" "gp-vm-vnet" {
  name                = local.virtual_network.name
  location            = local.location
  address_space       = [local.virtual_network.address_space]
  resource_group_name = local.resource_group_name

  depends_on = [azurerm_resource_group.gp-vm-group]
}

resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]

  depends_on = [azurerm_virtual_network.gp-vm-vnet]
}

resource "azurerm_network_interface" "gp-vm-nic" {
  name                = local.nic_name
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gp-vm-public-ip.id
  }

  depends_on = [azurerm_subnet.subnetA]
}

resource "azurerm_public_ip" "gp-vm-public-ip" {
  name                = "gm-vm-public-ip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.gp-vm-group]
}
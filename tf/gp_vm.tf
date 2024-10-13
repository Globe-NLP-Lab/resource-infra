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

resource "azurerm_resource_group" "gp-vm-group" {
  name      = "gp-vm-group"
  location  = "Australia East"
}
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
  subscription_id = "FIXME:your_subscription_id"
  tenant_id       = "FIXME:your_tenant_id"
  client_id       = "FIXME:your_client_id"
  client_secret   = "FIXME:your_client_secret"
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

resource "azurerm_network_security_group" "gp-vm-nsg" {
  name                = "gp-vm-nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  depends_on = [azurerm_resource_group.gp-vm-group]
}

resource "azurerm_network_security_rule" "ssh_rule" {
  name                        = "allow_ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.gp-vm-nsg.name

  depends_on = [azurerm_network_security_group.gp-vm-nsg]
}

resource "azurerm_network_security_rule" "http_rule" {
  name                        = "allow_http"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.gp-vm-nsg.name
  
  depends_on = [azurerm_network_security_group.gp-vm-nsg]
}

resource "azurerm_network_security_rule" "https_rule" {
  name                        = "allow_https"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.gp-vm-nsg.name
  
  depends_on = [azurerm_network_security_group.gp-vm-nsg]
}

resource "azurerm_subnet_network_security_group_association" "gp_vm_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.gp-vm-nsg.id
}

resource "azurerm_linux_virtual_machine" "gp-research-linux-vm" {
  name                = "gp-research-linux-vm"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_D4s_v3"
  admin_username      = "FIXME:s3ty0urn4m3"
  admin_password      = "FIXME:s3ty0urp4ssw0rd"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.gp-vm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 1024
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.gp-vm-nic,
    azurerm_public_ip.gp-vm-public-ip,
  ]
}

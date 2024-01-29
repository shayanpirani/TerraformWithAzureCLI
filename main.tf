terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "shayan" {
  name     = "shayan"
  location = "East US"
  tags = {
    envirnoment = "Dev"
  }
}

resource "azurerm_virtual_network" "shayan_vn" {
  name                = "shayan_vn"
  resource_group_name = azurerm_resource_group.shayan.name
  location            = azurerm_resource_group.shayan.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    envirnoment = "Dev"
  }
}


resource "azurerm_subnet" "shayan_subnet" {
  name                 = "shayan_subnet"
  resource_group_name  = azurerm_resource_group.shayan.name
  virtual_network_name = azurerm_virtual_network.shayan_vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "shayan_security_group" {
  name                = "shayan_security_group"
  location            = azurerm_resource_group.shayan.location
  resource_group_name = azurerm_resource_group.shayan.name

  tags = {
    envirnoment = "Dev"
  }
}

resource "azurerm_network_security_rule" "shayan_dev_rule" {
  name                        = "shayan_dev_rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.shayan.name
  network_security_group_name = azurerm_network_security_group.shayan_security_group.name
}

resource "azurerm_subnet_network_security_group_association" "shayan_security_group_association" {
  subnet_id                 = azurerm_subnet.shayan_subnet.id
  network_security_group_id = azurerm_network_security_group.shayan_security_group.id
}

resource "azurerm_public_ip" "shayan_public_ip" {
  name                = "shayan_public_ip"
  resource_group_name = azurerm_resource_group.shayan.name
  location            = azurerm_resource_group.shayan.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_interface" "shayan_network_interface" {
  name                = "shayan_network_interface"
  location            = azurerm_resource_group.shayan.location
  resource_group_name = azurerm_resource_group.shayan.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.shayan_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.shayan_public_ip.id
  }

  tags = {
    envirnoment = "Dev"
  }
}

resource "azurerm_linux_virtual_machine" "shayan_virtual_machine" {
  name                = "shayan-VM"
  resource_group_name = azurerm_resource_group.shayan.name
  location            = azurerm_resource_group.shayan.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.shayan_network_interface.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/ShayanAzureKey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("windows-ssh-script.tpl",{
      hostname = self.public_ip_address,
      user = "adminuser",
      identityfile = "~/ssh/ShayanAzureKey"
     })    
     interpreter = [ "Powershell" , "-Command" ]
  }

  tags = {
    envirnoment = "Dev"
  }
}
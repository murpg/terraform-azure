variable "subscription_id" {
}

variable "client_id" {
}

variable "client_secret" {
}

variable "tenant_id" {
}

variable "web_server_location" {
}

variable "web_server_rg" {
}

variable "resource_prefix" {
}

variable "web_server_address_space" {
}

variable "web_server_address_prefix" {
}

variable "web_server_name" {
}

variable "environment" {
}

variable "admin_username" {
}

variable "admin_password" {
}

variable "allowed_ip" {
}

provider "azurerm" {
  version         = "~> 1.37.0"
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_address_prefix
}

resource "azurerm_network_interface" "web_server_nic" {
  name                      = "${var.web_server_name}-nic"
  location                  = var.web_server_location
  resource_group_name       = azurerm_resource_group.web_server_rg.name
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip.id
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                         = "${var.web_server_name}-public-ip"
  location                     = var.web_server_location
  resource_group_name          = azurerm_resource_group.web_server_rg.name
  allocation_method            = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22","80","443","3389"]
  source_address_prefix       = var.allowed_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_virtual_machine" "web_server" {
  name                  = var.web_server_name
  location              = var.web_server_location
  resource_group_name   = azurerm_resource_group.web_server_rg.name
  network_interface_ids = [azurerm_network_interface.web_server_nic.id]
  vm_size               = "Standard_E2s_v3"

  #storage_image_reference {
    #publisher = "MicrosoftWindowsServer"
    #offer     = "WindowsServer"
    #sku       = "2012-R2-Datacenter"
    #version   = "latest"
  #}

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web_server_name}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.web_server_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_virtual_machine_extension" "test" {
  name                 = "hostname"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_machine_name = var.web_server_name
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  depends_on           = [azurerm_virtual_machine.web_server]

  settings = <<SETTINGS
    {

      "fileUris": ["https://raw.githubusercontent.com/murpg/CountChocula/master/installChocoWin2019.ps1"],
       "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File installChocoWin2019.ps1"
    }
SETTINGS

}


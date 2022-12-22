variable "prefix" {}

variable "username" {}

variable "resource_group_name" {}

variable "subnet_id" {}

variable "network_security_group_id" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-public-ip"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "this" {
  name                = "${var.prefix}-interface"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "azurerm_windows_virtual_machine" "this" {
  name                = var.prefix
  computer_name       = "deco-vm"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  # Ddsv5-series virtual machines run on the 3rd Generation Intel® Xeon® Platinum 8370C (Ice Lake)
  # processor reaching an all core turbo clock speed of up to 3.5 GHz.
  #
  # Standard_D8ds_v5: 8 vCPUs, 32GB RAM, 300GB SSD, 12.5Gbps network.
  #
  size           = "Standard_D8ds_v5"
  admin_username = var.username
  admin_password = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Note from Pieter (Nov 2022):
  # I found the values for the fields below by first creating a VM manually
  # and using the Azure CLI to retrieve its JSON representation (`az vm list`).
  # That JSON includes the image reference.
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro-g2"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  location           = data.azurerm_resource_group.this.location
  enabled            = true

  # Shutdown VMs at midnight UTC in hopes to keep costs down.
  daily_recurrence_time = "0000"
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }
}

output "name" {
  value = azurerm_windows_virtual_machine.this.name
}

output "username" {
  value = azurerm_windows_virtual_machine.this.admin_username
}

output "password" {
  value     = azurerm_windows_virtual_machine.this.admin_password
  sensitive = true
}

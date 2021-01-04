variable "zone" {
  default = 1
}
variable "vm_size" {
  default = "Standard_D4s_v3"
}
variable "admin_username" {}
variable "prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "admin_password" {}
variable "subnet_id" {}
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "autoshutdown" {
  //count              = length(data.azurerm_resources.vms.resources)
  //virtual_machine_id = data.azurerm_resources.vms.resources[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.windows.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "0200"
  timezone              = "Tokyo Standard Time"

  notification_settings {
    enabled = false
  }
}

resource "azurerm_windows_virtual_machine" "windows" {
  name                = "vm-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  zone                = var.zone
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-with-Containers"
    version   = "latest"
  }
}

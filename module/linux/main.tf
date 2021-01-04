variable "admin_username" {}
variable "public_key_path" {}
variable "prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "zone" {
  default = 1
}
variable "vm_size" {
  default = "Standard_B2s"
}
variable "subnet_id" {}
variable "custom_data" {
 default =<<EOF
#!/bin/bash
curl -sL https://releases.rancher.com/install-docker/19.03.sh | sh
sudo usermod -aG docker tsunomur
EOF 
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "linux" {
  name                = "vm-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  zone                = var.zone
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(var.custom_data)
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
  virtual_machine_id = azurerm_linux_virtual_machine.linux.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "0200"
  timezone              = "Tokyo Standard Time"

  notification_settings {
    enabled = false
  }
}

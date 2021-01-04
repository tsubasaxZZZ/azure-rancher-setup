provider "azurerm" {
  version = "=2.40.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-rancher"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

// NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-rancher"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg-rule" {
  name                        = "remoteaccess"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefixes     = var.permit-access-source-ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
resource "azurerm_subnet_network_security_group_association" "nsg-assosiation" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

// VM
module "linux-rancher-server" {
  source = "./module/linux"

  prefix              = "rancher"
  admin_username      = var.admin_username
  public_key_path     = var.ssh_public_key_path
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = 1
  subnet_id           = azurerm_subnet.subnet.id

  custom_data = <<EOF
#!/bin/bash
curl -sL https://releases.rancher.com/install-docker/19.03.sh | sh
sudo usermod -aG docker tsunomur
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:latest
EOF
}

module "linux-controlplane" {
  count  = 3
  source = "./module/linux"

  prefix              = "control${count.index + 1}"
  admin_username      = var.admin_username
  public_key_path     = var.ssh_public_key_path
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = (count.index % 3) + 1
  subnet_id           = azurerm_subnet.subnet.id
}

module "linux-worker" {
  count  = var.linux-worker-count
  source = "./module/linux"

  prefix              = "worker${count.index + 1}"
  admin_username      = var.admin_username
  public_key_path     = var.ssh_public_key_path
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = (count.index % 3) + 1
  subnet_id           = azurerm_subnet.subnet.id
}

module "windows-worker" {
  count  = var.windows-worker-count
  source = "./module/windows"

  prefix              = "worker${count.index + 1 + var.linux-worker-count}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = (count.index % 3) + 1
  subnet_id           = azurerm_subnet.subnet.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}

module "windows-jumpbox" {
  source              = "./module/windows"
  prefix              = "jumpbox"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = 1
  subnet_id           = azurerm_subnet.subnet.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}


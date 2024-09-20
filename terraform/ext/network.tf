resource "azurerm_resource_group" "network" {
  name     = "${local.repository_name}-network"
  location = local.location
}

resource "azurerm_public_ip" "primary" {
  name                = "${local.repository_name}-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_virtual_network" "primary" {
  name                = "${local.repository_name}-vnet"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_network_security_group" "primary" {
  name                = "${local.repository_name}-nsg"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "backend" {
  name                 = "${local.repository_name}-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.primary.name

  address_prefixes  = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.primary.id
}

resource "azurerm_private_dns_zone" "database" {
  name                = "${local.repository_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = "LerpzDatabaseVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = azurerm_virtual_network.primary.id
  resource_group_name   = azurerm_resource_group.network.name
  depends_on            = [azurerm_subnet.backend]
}

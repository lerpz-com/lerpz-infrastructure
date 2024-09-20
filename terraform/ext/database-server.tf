resource "azurerm_resource_group" "database" {
  name     = "${local.repository_name}-database"
  location = local.location
}

resource "azurerm_postgresql_flexible_server" "primary" {
  name                = "${local.repository_name}-pgs"
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  zone                = 3

  administrator_login    = var.database_username
  administrator_password = var.database_password
  sku_name               = "B_Standard_B1ms"

  storage_mb            = 32768
  version               = "16"
  auto_grow_enabled     = false
  backup_retention_days = 7

  delegated_subnet_id           = azurerm_subnet.backend.id
  private_dns_zone_id           = azurerm_private_dns_zone.database.id
  public_network_access_enabled = false

  lifecycle {
    prevent_destroy = true
  }
}

# ======================================
# DATABASE MODULE with Private Endpoints
# ======================================

# SQL Servers
resource "azurerm_mssql_server" "sql" {
  for_each = toset([var.primary_region, var.secondary_region])

  name                          = "${var.project}-sql-${each.key}-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = each.key
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false  # Security: Disable public access

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, { "Region" = each.key })
}

# Application Database (Simplified - Basic tier for cost savings)
resource "azurerm_mssql_database" "app_db" {
  for_each = toset([var.primary_region, var.secondary_region])

  name           = "${var.project}-appdb-${each.key}"
  server_id      = azurerm_mssql_server.sql[each.key].id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  sku_name       = "Basic"
  zone_redundant = false

  tags = merge(var.tags, { "Region" = each.key })
}

# Failover Group for App Database
resource "azurerm_mssql_failover_group" "app_db_fg" {
  name      = "${var.project}-appdb-fg-${var.environment}"
  server_id = azurerm_mssql_server.sql[var.primary_region].id

  databases = [
    azurerm_mssql_database.app_db[var.primary_region].id
  ]

  partner_server {
    id = azurerm_mssql_server.sql[var.secondary_region].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = var.tags
}

# Private Endpoints for SQL Servers
resource "azurerm_private_endpoint" "sql" {
  for_each = toset([var.primary_region, var.secondary_region])

  name                = "${var.project}-pe-sql-${each.key}"
  location            = each.key
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_ids[each.key]

  private_service_connection {
    name                           = "${var.project}-psc-sql-${each.key}"
    private_connection_resource_id = azurerm_mssql_server.sql[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [var.sql_private_dns_zone_id]
  }

  tags = merge(var.tags, { "Region" = each.key })
}

data "azurerm_client_config" "current" {}

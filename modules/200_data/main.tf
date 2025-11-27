# ======================================
# 200_DATA LAYER - DATABASE RESOURCES
# ======================================
# This module creates:
# - Azure SQL Servers (multi-region)
# - Azure SQL Databases with failover groups
# - Private endpoints for SQL databases

data "azurerm_client_config" "current" {}

# ==================
# AZURE SQL SERVERS
# ==================
resource "azurerm_mssql_server" "regional" {
  for_each = toset(var.regions)

  name                         = "${var.project}-sql-${each.key}-${var.environment}"
  resource_group_name          = var.database_resource_group_name
  location                     = each.key
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  
  # Disable public network access for security
  public_network_access_enabled = false

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = var.tags
}

# ==================
# AZURE SQL DATABASES
# ==================
# Database 1: Application Database
resource "azurerm_mssql_database" "app_database" {
  for_each = toset(var.regions)

  name                        = "${var.project}-appdb-${each.key}"
  server_id                   = azurerm_mssql_server.regional[each.key].id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb                 = 50
  sku_name                    = "S2"
  zone_redundant              = false  # Changed: Subscription doesn't support zone redundancy
  
  tags = var.tags
}

# Database 2: Analytics Database
resource "azurerm_mssql_database" "analytics_database" {
  for_each = toset(var.regions)

  name                        = "${var.project}-analyticsdb-${each.key}"
  server_id                   = azurerm_mssql_server.regional[each.key].id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb                 = 100
  sku_name                    = "S3"
  zone_redundant              = false  # Changed: Subscription doesn't support zone redundancy
  
  tags = var.tags
}

# ==================
# FAILOVER GROUPS
# ==================
# Failover Group 1: Application Database
resource "azurerm_mssql_failover_group" "app_database_fg" {
  name      = "${var.project}-appdb-fg-${var.environment}"
  server_id = azurerm_mssql_server.regional[var.primary_region].id

  databases = [
    azurerm_mssql_database.app_database[var.primary_region].id
  ]

  partner_server {
    id = azurerm_mssql_server.regional[var.secondary_region].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = var.tags
}

# Failover Group 2: Analytics Database
resource "azurerm_mssql_failover_group" "analytics_database_fg" {
  name      = "${var.project}-analyticsdb-fg-${var.environment}"
  server_id = azurerm_mssql_server.regional[var.primary_region].id

  databases = [
    azurerm_mssql_database.analytics_database[var.primary_region].id
  ]

  partner_server {
    id = azurerm_mssql_server.regional[var.secondary_region].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = var.tags
}

# ==================
# FIREWALL RULES
# ==================
# NOTE: Firewall rules removed because public_network_access_enabled = false
# Private endpoints provide secure access without firewall rules
# Uncomment below ONLY if you enable public access on SQL servers

# resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
#   for_each = toset(var.regions)
#
#   name             = "AllowAzureServices"
#   server_id        = azurerm_mssql_server.regional[each.key].id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# ==================
# PRIVATE ENDPOINTS
# ==================
resource "azurerm_private_endpoint" "sql_server" {
  for_each = toset(var.regions)

  name                = "${var.project}-pe-sql-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = var.database_resource_group_name
  subnet_id           = var.private_endpoint_subnet_ids[each.key]

  private_service_connection {
    name                           = "psc-sql-${each.key}"
    private_connection_resource_id = azurerm_mssql_server.regional[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.sql_private_dns_zone_id]
  }

  tags = var.tags

  # Wait for SQL servers and databases to be fully provisioned
  depends_on = [
    azurerm_mssql_server.regional,
    azurerm_mssql_database.app_database,
    azurerm_mssql_database.analytics_database
  ]
}


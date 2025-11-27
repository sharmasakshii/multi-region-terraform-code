# ======================================
# STORAGE MODULE - MULTI-REGION STORAGE
# ======================================
# COST OPTIMIZED FOR DEMO
# This module creates:
# - 1 storage account per region (instead of 3)
# - Private endpoints for blob storage
# - Containers for application data

# ==================
# STORAGE ACCOUNTS
# ==================
# Storage Account 1: Application Data
resource "azurerm_storage_account" "app_storage" {
  for_each = toset(var.regions)

  name                     = "${var.project}appst${replace(each.key, "-", "")}${var.environment}"
  resource_group_name      = var.storage_resource_group_name
  location                 = each.key
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  
  # Enable public access during initial deployment
  # TODO: Lock down after containers are created by setting to false
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Allow"  # Temporary: Allow during creation
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

# COMMENTED OUT FOR COST OPTIMIZATION - Only using app_storage for demo
# Storage Account 2: Media Storage
# resource "azurerm_storage_account" "media_storage" {
#   for_each = toset(var.regions)
#   name     = "${var.project}mediast${replace(each.key, "-", "")}${var.environment}"
#   ...
# }

# Storage Account 3: Logs Storage
# resource "azurerm_storage_account" "logs_storage" {
#   for_each = toset(var.regions)
#   name     = "${var.project}logsst${replace(each.key, "-", "")}${var.environment}"
#   ...
# }

# ==================
# STORAGE CONTAINERS
# ==================
resource "azurerm_storage_container" "app_data" {
  for_each = toset(var.regions)

  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.app_storage[each.key].name
  container_access_type = "private"
}

# COMMENTED OUT FOR COST OPTIMIZATION
# resource "azurerm_storage_container" "media_files" {
#   for_each = toset(var.regions)
#   name     = "media-files"
#   storage_account_name  = azurerm_storage_account.media_storage[each.key].name
#   container_access_type = "private"
# }

# resource "azurerm_storage_container" "application_logs" {
#   for_each = toset(var.regions)
#   name     = "application-logs"
#   storage_account_name  = azurerm_storage_account.logs_storage[each.key].name
#   container_access_type = "private"
# }

# ==================
# PRIVATE ENDPOINTS - App Storage
# ==================
resource "azurerm_private_endpoint" "app_storage_blob" {
  for_each = toset(var.regions)

  name                = "${var.project}-pe-appst-blob-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = var.storage_resource_group_name
  subnet_id           = var.private_endpoint_subnet_ids[each.key]

  private_service_connection {
    name                           = "psc-appst-blob-${each.key}"
    private_connection_resource_id = azurerm_storage_account.app_storage[each.key].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.storage_blob_private_dns_zone_id]
  }

  tags = var.tags

  # Wait for storage accounts and containers to be fully provisioned
  depends_on = [
    azurerm_storage_account.app_storage,
    azurerm_storage_container.app_data
  ]
}

# COMMENTED OUT FOR COST OPTIMIZATION
# ==================
# PRIVATE ENDPOINTS - Media Storage
# ==================
# resource "azurerm_private_endpoint" "media_storage_blob" { ... }

# ==================
# PRIVATE ENDPOINTS - Logs Storage
# ==================
# resource "azurerm_private_endpoint" "logs_storage_blob" { ... }


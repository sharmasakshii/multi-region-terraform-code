# ======================================
# STORAGE MODULE with Private Endpoints
# ======================================

# Storage Accounts (GRS for geo-redundancy)
resource "azurerm_storage_account" "storage" {
  for_each = toset(var.regions)

  name                     = "${var.project}st${replace(each.key, "-", "")}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = each.key
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Enable public access for initial setup (can be disabled after deployment)
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(var.tags, { "Region" = each.key })
}

# Storage Containers
resource "azurerm_storage_container" "app_data" {
  for_each = toset(var.regions)

  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.storage[each.key].name
  container_access_type = "private"
}

# Private Endpoints for Storage Accounts
resource "azurerm_private_endpoint" "storage" {
  for_each = toset(var.regions)

  name                = "${var.project}-pe-storage-${each.key}"
  location            = each.key
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_ids[each.key]

  private_service_connection {
    name                           = "${var.project}-psc-storage-${each.key}"
    private_connection_resource_id = azurerm_storage_account.storage[each.key].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [var.storage_blob_private_dns_zone_id]
  }

  tags = merge(var.tags, { "Region" = each.key })
}

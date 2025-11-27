output "app_storage_accounts" {
  value = {
    for region, sa in azurerm_storage_account.app_storage :
    region => {
      id                   = sa.id
      name                 = sa.name
      primary_blob_endpoint = sa.primary_blob_endpoint
      private_endpoint_id   = azurerm_private_endpoint.app_storage_blob[region].id
    }
  }
  description = "Application storage accounts per region"
}

# COMMENTED OUT FOR COST OPTIMIZATION
# output "media_storage_accounts" { ... }
# output "logs_storage_accounts" { ... }

output "storage_connection_strings" {
  value = {
    for region in var.regions :
    region => {
      app_storage = azurerm_storage_account.app_storage[region].primary_connection_string
    }
  }
  sensitive   = true
  description = "Storage account connection strings (only app_storage)"
}




output "storage_account_ids" {
  value = { for k, v in azurerm_storage_account.storage : k => v.id }
}

output "storage_account_names" {
  value = { for k, v in azurerm_storage_account.storage : k => v.name }
}

output "primary_connection_string" {
  value     = azurerm_storage_account.storage[var.regions[0]].primary_connection_string
  sensitive = true
}

output "storage_account_endpoints" {
  value = { for k, v in azurerm_storage_account.storage : k => v.primary_blob_endpoint }
}

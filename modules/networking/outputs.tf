output "vnet_ids" {
  description = "Virtual Network IDs by region"
  value       = { for k, v in azurerm_virtual_network.vnet : k => v.id }
}

output "container_app_subnet_ids" {
  description = "Container App subnet IDs by region"
  value       = { for k, v in azurerm_subnet.container_apps : k => v.id }
}

output "private_endpoint_subnet_ids" {
  description = "Private Endpoint subnet IDs by region"
  value       = { for k, v in azurerm_subnet.private_endpoints : k => v.id }
}

output "database_subnet_ids" {
  description = "Database subnet IDs by region"
  value       = { for k, v in azurerm_subnet.database : k => v.id }
}

output "storage_subnet_ids" {
  description = "Storage subnet IDs by region"
  value       = { for k, v in azurerm_subnet.storage : k => v.id }
}

output "log_analytics_workspace_ids" {
  description = "Log Analytics Workspace IDs by region"
  value       = { for k, v in azurerm_log_analytics_workspace.workspace : k => v.id }
}

output "sql_private_dns_zone_id" {
  description = "SQL Private DNS Zone ID"
  value       = azurerm_private_dns_zone.sql.id
}

output "storage_private_dns_zone_id" {
  description = "Storage Blob Private DNS Zone ID"
  value       = azurerm_private_dns_zone.storage_blob.id
}

output "container_apps_private_dns_zone_id" {
  description = "Container Apps Private DNS Zone ID"
  value       = azurerm_private_dns_zone.container_apps.id
}

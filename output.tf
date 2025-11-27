# ======================================
# MODULAR INFRASTRUCTURE OUTPUTS
# ======================================

# Resource Groups
output "resource_groups" {
  description = "All resource group names"
  value = {
    networking = azurerm_resource_group.networking.name
    services   = { for k, v in azurerm_resource_group.services : k => v.name }
    database   = azurerm_resource_group.database.name
    storage    = azurerm_resource_group.storage.name
  }
}

# Networking
output "vnets" {
  description = "Virtual Network IDs"
  value       = module.networking.vnet_ids
}

# Container Apps
output "gateway_url" {
  description = "Public Gateway URL"
  value       = "https://${azurerm_container_app.gateway.ingress[0].fqdn}"
}

output "gateway_fqdn" {
  description = "Gateway FQDN"
  value       = azurerm_container_app.gateway.ingress[0].fqdn
}

output "container_apps" {
  description = "All container app names and regions"
  value = {
    gateway = {
      name   = azurerm_container_app.gateway.name
      fqdn   = azurerm_container_app.gateway.ingress[0].fqdn
      public = true
    }
    api = {
      for region in var.regions :
      region => {
        name   = azurerm_container_app.api[region].name
        fqdn   = try(azurerm_container_app.api[region].ingress[0].fqdn, "internal-only")
        public = false
      }
    }
    worker = {
      for region in var.regions :
      region => {
        name   = azurerm_container_app.worker[region].name
        fqdn   = try(azurerm_container_app.worker[region].ingress[0].fqdn, "internal-only")
        public = false
      }
    }
    processor = {
      for region in var.regions :
      region => {
        name   = azurerm_container_app.processor[region].name
        fqdn   = try(azurerm_container_app.processor[region].ingress[0].fqdn, "internal-only")
        public = false
      }
    }
    scheduler = {
      for region in var.regions :
      region => {
        name   = azurerm_container_app.scheduler[region].name
        fqdn   = try(azurerm_container_app.scheduler[region].ingress[0].fqdn, "internal-only")
        public = false
      }
    }
  }
}

# Database
output "sql_servers" {
  description = "SQL Server FQDNs"
  value       = module.database.sql_server_fqdns
}

output "sql_connection_string" {
  description = "SQL Failover Group Connection String"
  value       = module.database.connection_string
  sensitive   = false
}

# Storage
output "storage_accounts" {
  description = "Storage Account Names"
  value       = module.storage.storage_account_names
}

# Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project               = var.project
    environment           = var.environment
    regions               = var.regions
    primary_region        = var.primary_region
    resource_groups_count = 7
    gateway_url           = "https://${azurerm_container_app.gateway.ingress[0].fqdn}"
    architecture          = "Modular Multi-Region with Private Endpoints"
  }
}

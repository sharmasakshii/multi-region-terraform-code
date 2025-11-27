# ======================================
# ROOT OUTPUTS
# ======================================

# ==================
# RESOURCE GROUP
# ==================
output "resource_group" {
  value = {
    name     = module.base.resource_group.name
    location = module.base.resource_group.location
    id       = module.base.resource_group.id
  }
  description = "Main resource group containing all resources"
}

# ==================
# NETWORKING
# ==================
output "vnets" {
  value = {
    for region in var.regions :
    region => module.base.vnets[region].name
  }
  description = "Virtual networks per region"
}

output "subnets" {
  value = module.base.subnets
  description = "All subnets organized by type and region"
}

# ==================
# CONTAINER APPS
# ==================
output "primary_gateway_url" {
  value       = "https://${module.compute.primary_gateway.fqdn}"
  description = "Primary Gateway Container App URL (PUBLIC)"
}

output "primary_gateway_fqdn" {
  value       = module.compute.primary_gateway.fqdn
  description = "Primary Gateway FQDN"
}

output "container_app_environments" {
  value = {
    for region in var.regions :
    region => {
      name   = module.compute.container_app_environments[region].name
      domain = module.compute.container_app_environments[region].default_domain
      ip     = module.compute.container_app_environments[region].static_ip_address
    }
  }
  description = "Container App Environments details per region"
}

output "all_container_apps" {
  value       = module.compute.all_container_apps
  description = "All container apps FQDNs organized by service"
}

# ==================
# DATABASES
# ==================
output "sql_servers" {
  value = {
    for region in var.regions :
    region => {
      name = module.data.sql_servers[region].name
      fqdn = module.data.sql_servers[region].fqdn
    }
  }
  description = "SQL servers per region"
}

output "sql_failover_groups" {
  value = {
    app_database       = module.data.failover_groups.app_database.name
    analytics_database = module.data.failover_groups.analytics_database.name
  }
  description = "SQL failover group names"
}

output "sql_connection_strings" {
  value       = module.data.connection_strings
  sensitive   = true
  description = "SQL connection strings"
}

# ==================
# STORAGE
# ==================
output "storage_accounts" {
  value = {
    app_storage = {
      for region in var.regions :
      region => module.storage.app_storage_accounts[region].name
    }
  }
  description = "Storage account names (only app_storage for cost optimization)"
}

output "storage_connection_strings" {
  value       = module.storage.storage_connection_strings
  sensitive   = true
  description = "Storage account connection strings"
}

# ==================
# DEPLOYMENT SUMMARY
# ==================
output "deployment_summary" {
  value = {
    project             = var.project
    environment         = var.environment
    primary_region      = var.primary_region
    all_regions         = var.regions
    public_endpoint     = "https://${module.compute.primary_gateway.fqdn}"
    total_container_apps = 1 + (length(var.regions) * 2) # 1 public + 2 private per region (COST OPTIMIZED)
    total_sql_servers   = length(var.regions)
    total_sql_databases = length(var.regions) * 2 # 2 databases per region
    total_storage_accounts = length(var.regions) * 1 # 1 storage account per region (COST OPTIMIZED)
  }
  description = "High-level deployment summary (cost optimized for demo)"
}

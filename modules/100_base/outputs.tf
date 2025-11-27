output "resource_group" {
  value       = azurerm_resource_group.main
  description = "Main resource group for all resources"
}

output "vnets" {
  value = {
    for region, vnet in azurerm_virtual_network.regional_vnets :
    region => {
      id   = vnet.id
      name = vnet.name
    }
  }
  description = "Virtual networks per region"
}

output "subnets" {
  value = {
    container_apps = {
      for region, subnet in azurerm_subnet.container_apps :
      region => {
        id   = subnet.id
        name = subnet.name
      }
    }
    private_endpoints = {
      for region, subnet in azurerm_subnet.private_endpoints :
      region => {
        id   = subnet.id
        name = subnet.name
      }
    }
    database = {
      for region, subnet in azurerm_subnet.database :
      region => {
        id   = subnet.id
        name = subnet.name
      }
    }
    storage = {
      for region, subnet in azurerm_subnet.storage :
      region => {
        id   = subnet.id
        name = subnet.name
      }
    }
  }
  description = "Subnets per region"
}

output "log_analytics_workspaces" {
  value = {
    for region, law in azurerm_log_analytics_workspace.regional :
    region => {
      id   = law.id
      name = law.name
    }
  }
  description = "Log Analytics Workspaces per region"
}

output "private_dns_zones" {
  value = {
    storage_blob   = azurerm_private_dns_zone.storage_blob.id
    sql_database   = azurerm_private_dns_zone.sql_database.id
    container_apps = azurerm_private_dns_zone.container_apps.id
  }
  description = "Private DNS zones"
}




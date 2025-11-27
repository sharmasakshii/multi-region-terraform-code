output "sql_servers" {
  value = {
    for region, server in azurerm_mssql_server.regional :
    region => {
      id                 = server.id
      name               = server.name
      fqdn               = server.fully_qualified_domain_name
      private_endpoint_id = azurerm_private_endpoint.sql_server[region].id
    }
  }
  description = "SQL servers per region"
}

output "app_databases" {
  value = {
    for region, db in azurerm_mssql_database.app_database :
    region => {
      id   = db.id
      name = db.name
    }
  }
  description = "Application databases per region"
}

output "analytics_databases" {
  value = {
    for region, db in azurerm_mssql_database.analytics_database :
    region => {
      id   = db.id
      name = db.name
    }
  }
  description = "Analytics databases per region"
}

output "failover_groups" {
  value = {
    app_database = {
      id   = azurerm_mssql_failover_group.app_database_fg.id
      name = azurerm_mssql_failover_group.app_database_fg.name
    }
    analytics_database = {
      id   = azurerm_mssql_failover_group.analytics_database_fg.id
      name = azurerm_mssql_failover_group.analytics_database_fg.name
    }
  }
  description = "SQL failover groups"
}

output "connection_strings" {
  value = {
    app_database_primary = "Server=${azurerm_mssql_failover_group.app_database_fg.name}.database.windows.net;Database=${azurerm_mssql_database.app_database[var.primary_region].name};Authentication=Active Directory Default;"
    analytics_database_primary = "Server=${azurerm_mssql_failover_group.analytics_database_fg.name}.database.windows.net;Database=${azurerm_mssql_database.analytics_database[var.primary_region].name};Authentication=Active Directory Default;"
  }
  sensitive   = true
  description = "SQL connection strings"
}




output "sql_server_ids" {
  value = { for k, v in azurerm_mssql_server.sql : k => v.id }
}

output "sql_server_fqdns" {
  value = { for k, v in azurerm_mssql_server.sql : k => v.fully_qualified_domain_name }
}

output "connection_string" {
  value = "${azurerm_mssql_failover_group.app_db_fg.name}.database.windows.net"
  sensitive = false
}

output "failover_group_id" {
  value = azurerm_mssql_failover_group.app_db_fg.id
}

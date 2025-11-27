variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "primary_region" {
  type        = string
  description = "Primary Azure region"
}

variable "secondary_region" {
  type        = string
  description = "Secondary Azure region for failover"
}

variable "regions" {
  type        = list(string)
  description = "List of Azure regions"
}

variable "database_resource_group_name" {
  type        = string
  description = "Database resource group name"
}

variable "sql_admin_username" {
  type        = string
  description = "SQL Server admin username"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL Server admin password"
}

variable "private_endpoint_subnet_ids" {
  type        = map(string)
  description = "Private endpoint subnet IDs per region"
}

variable "sql_private_dns_zone_id" {
  type        = string
  description = "SQL private DNS zone ID"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}




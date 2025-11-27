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

variable "regions" {
  type        = list(string)
  description = "List of Azure regions"
}

variable "backend_resource_group_name" {
  type        = string
  description = "Backend resource group name"
}

variable "container_app_subnet_ids" {
  type        = map(string)
  description = "Container app subnet IDs per region"
}

variable "log_analytics_workspace_ids" {
  type        = map(string)
  description = "Log Analytics workspace IDs per region"
}

variable "container_apps" {
  type = map(object({
    name         = string
    cpu          = number
    memory       = string
    min_replicas = number
    max_replicas = number
  }))
  description = "Container apps configuration"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}




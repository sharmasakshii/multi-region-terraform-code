variable "project" {
  type        = string
  default     = "demo"
  description = "Project name prefix for all resources"
}

variable "primary_region" {
  type        = string
  default     = "eastus"
  description = "Primary Azure region"
}

variable "regions" {
  type = list(string)
  default = [
    "eastus",
    "centralus",
    "westus"
  ]
  description = "List of Azure regions for multi-region deployment"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name"
}

variable "container_apps" {
  type = map(object({
    name     = string
    cpu      = number
    memory   = string
    min_replicas = number
    max_replicas = number
  }))
  default = {
    "app1" = {
      name     = "api-service"
      cpu      = 0.5
      memory   = "1Gi"
      min_replicas = 1
      max_replicas = 3
    }
    "app2" = {
      name     = "worker-service"
      cpu      = 0.5
      memory   = "1Gi"
      min_replicas = 1
      max_replicas = 3
    }
    "app3" = {
      name     = "processor-service"
      cpu      = 0.75
      memory   = "1.5Gi"
      min_replicas = 1
      max_replicas = 5
    }
    "app4" = {
      name     = "scheduler-service"
      cpu      = 0.25
      memory   = "0.5Gi"
      min_replicas = 1
      max_replicas = 2
    }
    "app5" = {
      name     = "notification-service"
      cpu      = 0.5
      memory   = "1Gi"
      min_replicas = 1
      max_replicas = 3
    }
  }
  description = "Container apps configuration"
}

variable "vnet_address_spaces" {
  type = map(string)
  default = {
    "eastus"    = "10.10.0.0/16"
    "centralus" = "10.20.0.0/16"
    "westus"    = "10.30.0.0/16"
  }
  description = "VNet address spaces per region"
}

variable "sql_admin_username" {
  type        = string
  default     = "sqladmin"
  description = "SQL Server admin username"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!Complex"
  description = "SQL Server admin password"
}

variable "tags" {
  type = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "MultiRegion"
  }
  description = "Common tags for all resources"
}

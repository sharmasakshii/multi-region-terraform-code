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

variable "vnet_address_spaces" {
  type        = map(string)
  description = "VNet address spaces per region"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}




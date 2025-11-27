variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "regions" {
  type        = list(string)
  description = "List of Azure regions"
}

variable "vnet_address_spaces" {
  type        = map(string)
  description = "VNet address spaces per region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for networking resources"
}

variable "resource_group_location" {
  type        = string
  description = "Resource group location"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

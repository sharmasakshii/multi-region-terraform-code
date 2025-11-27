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

variable "storage_resource_group_name" {
  type        = string
  description = "Storage resource group name"
}

variable "private_endpoint_subnet_ids" {
  type        = map(string)
  description = "Private endpoint subnet IDs per region"
}

variable "storage_blob_private_dns_zone_id" {
  type        = string
  description = "Storage blob private DNS zone ID"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}




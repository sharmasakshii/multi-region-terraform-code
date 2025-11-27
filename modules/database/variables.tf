variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "primary_region" {
  type = string
}

variable "secondary_region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sql_admin_username" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "private_endpoint_subnet_ids" {
  type = map(string)
}

variable "sql_private_dns_zone_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

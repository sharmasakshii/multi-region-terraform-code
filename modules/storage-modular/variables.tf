variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "regions" {
  type = list(string)
}

variable "resource_group_name" {
  type = string
}

variable "private_endpoint_subnet_ids" {
  type = map(string)
}

variable "storage_blob_private_dns_zone_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

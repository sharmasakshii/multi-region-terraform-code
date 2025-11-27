# ======================================
# NETWORKING MODULE
# ======================================
# Creates:
# - Virtual Networks per region
# - Subnets (Container Apps, Private Endpoints, Database, Storage)
# - VNet Peering (mesh topology)
# - Private DNS Zones
# - Log Analytics Workspaces
# - NSGs

# ======================================
# VIRTUAL NETWORKS
# ======================================
resource "azurerm_virtual_network" "vnet" {
  for_each            = toset(var.regions)
  name                = "${var.project}-vnet-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_spaces[each.key]]
  tags                = merge(var.tags, { "Region" = each.key })
}

# ======================================
# SUBNETS
# ======================================

# Container Apps Subnet (512 IPs)
resource "azurerm_subnet" "container_apps" {
  for_each             = toset(var.regions)
  name                 = "${var.project}-subnet-containerApps-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 7, 0)] # /23
}

# Private Endpoints Subnet (256 IPs)
resource "azurerm_subnet" "private_endpoints" {
  for_each             = toset(var.regions)
  name                 = "${var.project}-subnet-privateEndpoints-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 4)] # /24
}

# Database Subnet (256 IPs) with service endpoints
resource "azurerm_subnet" "database" {
  for_each             = toset(var.regions)
  name                 = "${var.project}-subnet-database-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 5)] # /24
  service_endpoints    = ["Microsoft.Sql"]
}

# Storage Subnet (256 IPs) with service endpoints
resource "azurerm_subnet" "storage" {
  for_each             = toset(var.regions)
  name                 = "${var.project}-subnet-storage-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 6)] # /24
  service_endpoints    = ["Microsoft.Storage"]
}

# ======================================
# NETWORK SECURITY GROUPS
# ======================================
resource "azurerm_network_security_group" "container_apps" {
  for_each            = toset(var.regions)
  name                = "${var.project}-nsg-containerApps-${each.key}"
  location            = each.key
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { "Region" = each.key })

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "container_apps" {
  for_each                  = toset(var.regions)
  subnet_id                 = azurerm_subnet.container_apps[each.key].id
  network_security_group_id = azurerm_network_security_group.container_apps[each.key].id
}

# ======================================
# VNET PEERING (Mesh Topology)
# ======================================
locals {
  # Create all possible region pairs for peering
  region_pairs = flatten([
    for i, source in var.regions : [
      for j, dest in var.regions : {
        source = source
        dest   = dest
      } if i < j
    ]
  ])
}

# Peering: Source to Destination
resource "azurerm_virtual_network_peering" "source_to_dest" {
  for_each = {
    for pair in local.region_pairs :
    "${pair.source}-to-${pair.dest}" => pair
  }

  name                      = "${var.project}-peer-${each.value.source}-to-${each.value.dest}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet[each.value.source].name
  remote_virtual_network_id = azurerm_virtual_network.vnet[each.value.dest].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false

  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage
  ]
}

# Peering: Destination to Source
resource "azurerm_virtual_network_peering" "dest_to_source" {
  for_each = {
    for pair in local.region_pairs :
    "${pair.dest}-to-${pair.source}" => pair
  }

  name                      = "${var.project}-peer-${each.value.dest}-to-${each.value.source}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet[each.value.dest].name
  remote_virtual_network_id = azurerm_virtual_network.vnet[each.value.source].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false

  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage
  ]
}

# ======================================
# LOG ANALYTICS WORKSPACES
# ======================================
resource "azurerm_log_analytics_workspace" "workspace" {
  for_each            = toset(var.regions)
  name                = "${var.project}-law-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.tags, { "Region" = each.key })
}

# ======================================
# PRIVATE DNS ZONES
# ======================================

# SQL Database Private DNS Zone
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Storage Blob Private DNS Zone
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Container Apps Private DNS Zone
resource "azurerm_private_dns_zone" "container_apps" {
  name                = "privatelink.azurecontainerapps.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ======================================
# PRIVATE DNS ZONE VNET LINKS
# ======================================

# SQL DNS Zone Links
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  for_each              = toset(var.regions)
  name                  = "${var.project}-sql-dns-link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.vnet[each.key].id
  registration_enabled  = false
  tags                  = merge(var.tags, { "Region" = each.key })
}

# Storage Blob DNS Zone Links
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  for_each              = toset(var.regions)
  name                  = "${var.project}-storage-dns-link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet[each.key].id
  registration_enabled  = false
  tags                  = merge(var.tags, { "Region" = each.key })
}

# Container Apps DNS Zone Links
resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  for_each              = toset(var.regions)
  name                  = "${var.project}-containerapp-dns-link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps.name
  virtual_network_id    = azurerm_virtual_network.vnet[each.key].id
  registration_enabled  = false
  tags                  = merge(var.tags, { "Region" = each.key })
}

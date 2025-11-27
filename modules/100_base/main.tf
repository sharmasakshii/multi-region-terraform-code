# ======================================
# 100_BASE LAYER - FOUNDATIONAL RESOURCES
# ======================================
# This module creates the base infrastructure:
# - Resource Groups
# - Virtual Networks
# - Subnets
# - Network Security Groups
# - VNet Peering

# ==================
# RESOURCE GROUP (Single RG for all resources)
# ==================
resource "azurerm_resource_group" "main" {
  name     = "${var.project}-rg-${var.environment}-cb61e6"
  location = var.primary_region
  tags     = var.tags
}

# ==================
# VIRTUAL NETWORKS
# ==================
resource "azurerm_virtual_network" "regional_vnets" {
  for_each = toset(var.regions)

  name                = "${var.project}-vnet-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_spaces[each.key]]
  tags                = var.tags
}

# ==================
# SUBNETS
# ==================
# Container Apps Subnet (requires at least /23 = 512 IPs)
# NOTE: Do NOT delegate when using VNet integration - Azure manages it directly
resource "azurerm_subnet" "container_apps" {
  for_each = toset(var.regions)

  name                 = "snet-container-apps"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.regional_vnets[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 7, 0)]  # Creates /23 subnet

  # No delegation needed for VNet-integrated Container App Environments
  # Azure Container Apps manages the subnet directly
}

# Private Endpoints Subnet
resource "azurerm_subnet" "private_endpoints" {
  for_each = toset(var.regions)

  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.regional_vnets[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 4)]  # /24 subnet, avoiding overlap
}

# Database Subnet
resource "azurerm_subnet" "database" {
  for_each = toset(var.regions)

  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.regional_vnets[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 5)]  # /24 subnet, avoiding overlap
  
  service_endpoints = ["Microsoft.Sql"]
}

# Storage Subnet
resource "azurerm_subnet" "storage" {
  for_each = toset(var.regions)

  name                 = "snet-storage"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.regional_vnets[each.key].name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[each.key], 8, 6)]  # /24 subnet, avoiding overlap
  
  service_endpoints = ["Microsoft.Storage"]
}

# ==================
# NETWORK SECURITY GROUPS
# ==================
resource "azurerm_network_security_group" "container_apps" {
  for_each = toset(var.regions)

  name                = "${var.project}-nsg-container-apps-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  for_each = toset(var.regions)

  subnet_id                 = azurerm_subnet.container_apps[each.key].id
  network_security_group_id = azurerm_network_security_group.container_apps[each.key].id
}

# ==================
# VNET PEERING (Mesh topology)
# ==================
locals {
  # Create all possible peering combinations
  vnet_peering_pairs = flatten([
    for source_region in var.regions : [
      for dest_region in var.regions : {
        source = source_region
        dest   = dest_region
      } if source_region != dest_region
    ]
  ])
}

resource "azurerm_virtual_network_peering" "mesh" {
  for_each = {
    for pair in local.vnet_peering_pairs :
    "${pair.source}-to-${pair.dest}" => pair
  }

  name                      = "peer-${each.value.source}-to-${each.value.dest}"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.regional_vnets[each.value.source].name
  remote_virtual_network_id = azurerm_virtual_network.regional_vnets[each.value.dest].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false

  # Wait for all subnets to be created before peering
  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage,
    azurerm_subnet_network_security_group_association.container_apps
  ]
}

# ==================
# LOG ANALYTICS WORKSPACES
# ==================
resource "azurerm_log_analytics_workspace" "regional" {
  for_each = toset(var.regions)

  name                = "${var.project}-law-${each.key}-${var.environment}"
  location            = each.key
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ==================
# PRIVATE DNS ZONES
# ==================
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "sql_database" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "container_apps" {
  name                = "privatelink.azurecontainerapps.io"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Link DNS zones to all VNets
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  for_each = toset(var.regions)

  name                  = "link-storage-blob-${each.key}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.regional_vnets[each.key].id
  tags                  = var.tags

  # Wait for subnets to be fully created
  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_database" {
  for_each = toset(var.regions)

  name                  = "link-sql-database-${each.key}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database.name
  virtual_network_id    = azurerm_virtual_network.regional_vnets[each.key].id
  tags                  = var.tags

  # Wait for subnets to be fully created
  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  for_each = toset(var.regions)

  name                  = "link-container-apps-${each.key}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps.name
  virtual_network_id    = azurerm_virtual_network.regional_vnets[each.key].id
  tags                  = var.tags

  # Wait for subnets to be fully created
  depends_on = [
    azurerm_subnet.container_apps,
    azurerm_subnet.private_endpoints,
    azurerm_subnet.database,
    azurerm_subnet.storage
  ]
}


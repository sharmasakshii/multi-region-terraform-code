# ======================================
# MULTI-REGION AZURE INFRASTRUCTURE
# ======================================
# This is the root configuration that orchestrates all modules
# Module layers:
# - 100_base: Foundational resources (VNets, Subnets, Resource Groups)
# - 200_data: Database resources (Azure SQL)
# - 300_compute: Container Apps
# - storage: Multi-region storage accounts

data "azurerm_client_config" "current" {}

# ======================================
# LAYER 100: BASE INFRASTRUCTURE
# ======================================
module "base" {
  source = "./modules/100_base"

  project              = var.project
  environment          = var.environment
  primary_region       = var.primary_region
  regions              = var.regions
  vnet_address_spaces  = var.vnet_address_spaces
  tags                 = var.tags
}

# ======================================
# STORAGE MODULE
# ======================================
module "storage" {
  source = "./modules/storage"

  project                         = var.project
  environment                     = var.environment
  regions                         = var.regions
  storage_resource_group_name     = module.base.resource_group.name
  private_endpoint_subnet_ids     = {
    for region in var.regions :
    region => module.base.subnets.private_endpoints[region].id
  }
  storage_blob_private_dns_zone_id = module.base.private_dns_zones.storage_blob
  tags                             = var.tags

  depends_on = [module.base]
}

# ======================================
# LAYER 200: DATA / DATABASES
# ======================================
module "data" {
  source = "./modules/200_data"

  project                      = var.project
  environment                  = var.environment
  primary_region               = var.primary_region
  secondary_region             = var.regions[1] # centralus
  regions                      = var.regions
  database_resource_group_name = module.base.resource_group.name
  sql_admin_username           = var.sql_admin_username
  sql_admin_password           = var.sql_admin_password
  private_endpoint_subnet_ids  = {
    for region in var.regions :
    region => module.base.subnets.private_endpoints[region].id
  }
  sql_private_dns_zone_id      = module.base.private_dns_zones.sql_database
  tags                         = var.tags

  depends_on = [module.base]
}

# ======================================
# LAYER 300: COMPUTE / CONTAINER APPS
# ======================================
module "compute" {
  source = "./modules/300_compute"

  project                      = var.project
  environment                  = var.environment
  primary_region               = var.primary_region
  regions                      = var.regions
  backend_resource_group_name  = module.base.resource_group.name
  container_app_subnet_ids     = {
    for region in var.regions :
    region => module.base.subnets.container_apps[region].id
  }
  log_analytics_workspace_ids  = {
    for region in var.regions :
    region => module.base.log_analytics_workspaces[region].id
  }
  container_apps               = var.container_apps
  tags                         = var.tags

  depends_on = [module.base, module.data, module.storage]
}

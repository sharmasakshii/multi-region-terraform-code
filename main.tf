# ======================================
# MODULAR MULTI-REGION INFRASTRUCTURE
# ======================================
# Simplified version with separate RGs per service
# 1 Public Gateway + 4 Private Services
# All resources use Private Endpoints and Managed Identities

data "azurerm_client_config" "current" {}

# ======================================
# RESOURCE GROUPS
# ======================================

resource "azurerm_resource_group" "networking" {
  name     = "${var.project}-networking-rg-${var.environment}"
  location = var.primary_region
  tags     = var.tags
}

resource "azurerm_resource_group" "services" {
  for_each = toset(["gateway", "api", "worker", "processor", "scheduler"])
  name     = "${var.project}-${each.key}-rg-${var.environment}"
  location = var.primary_region
  tags     = merge(var.tags, { "Service" = each.key })
}

resource "azurerm_resource_group" "database" {
  name     = "${var.project}-database-rg-${var.environment}"
  location = var.primary_region
  tags     = var.tags
}

resource "azurerm_resource_group" "storage" {
  name     = "${var.project}-storage-rg-${var.environment}"
  location = var.primary_region
  tags     = var.tags
}

# ======================================
# NETWORKING MODULE
# ======================================
module "networking" {
  source = "./modules/networking"

  project                 = var.project
  environment             = var.environment
  regions                 = var.regions
  vnet_address_spaces     = var.vnet_address_spaces
  resource_group_name     = azurerm_resource_group.networking.name
  resource_group_location = azurerm_resource_group.networking.location
  tags                    = var.tags
}

# ======================================
# DATABASE MODULE
# ======================================
module "database" {
  source = "./modules/database"

  project                     = var.project
  environment                 = var.environment
  primary_region              = var.primary_region
  secondary_region            = var.regions[1]
  resource_group_name         = azurerm_resource_group.database.name
  sql_admin_username          = var.sql_admin_username
  sql_admin_password          = var.sql_admin_password
  private_endpoint_subnet_ids = module.networking.private_endpoint_subnet_ids
  sql_private_dns_zone_id     = module.networking.sql_private_dns_zone_id
  tags                        = var.tags

  depends_on = [module.networking]
}

# ======================================
# STORAGE MODULE
# ======================================
module "storage" {
  source = "./modules/storage-modular"

  project                          = var.project
  environment                      = var.environment
  regions                          = var.regions
  resource_group_name              = azurerm_resource_group.storage.name
  private_endpoint_subnet_ids      = module.networking.private_endpoint_subnet_ids
  storage_blob_private_dns_zone_id = module.networking.storage_private_dns_zone_id
  tags                             = var.tags

  depends_on = [module.networking]
}

# ======================================
# CONTAINER APP ENVIRONMENTS
# ======================================

resource "azurerm_container_app_environment" "env" {
  for_each = toset(var.regions)

  name                       = "${var.project}-cae-${each.key}-${var.environment}"
  location                   = each.key
  resource_group_name        = azurerm_resource_group.networking.name
  log_analytics_workspace_id = module.networking.log_analytics_workspace_ids[each.key]
  infrastructure_subnet_id   = module.networking.container_app_subnet_ids[each.key]

  tags = merge(var.tags, { "Region" = each.key })

  depends_on = [module.networking]
}

# ======================================
# GATEWAY SERVICE (Public)
# ======================================

resource "azurerm_container_app" "gateway" {
  name                         = "${var.project}-gateway-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env[var.primary_region].id
  resource_group_name          = azurerm_resource_group.services["gateway"].name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "gateway"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 1.0
      memory = "2Gi"

      env {
        name  = "AZURE_REGION"
        value = var.primary_region
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = merge(var.tags, { "Service" = "Gateway", "Visibility" = "Public" })
}

# ======================================
# API SERVICE (Private)
# ======================================

resource "azurerm_container_app" "api" {
  for_each = toset(var.regions)

  name                         = "${var.project}-api-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env[each.key].id
  resource_group_name          = azurerm_resource_group.services["api"].name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_REGION"
        value = each.key
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = false  # Private
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = merge(var.tags, { "Service" = "API", "Visibility" = "Private", "Region" = each.key })
}

# ======================================
# WORKER SERVICE (Private)
# ======================================

resource "azurerm_container_app" "worker" {
  for_each = toset(var.regions)

  name                         = "${var.project}-worker-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env[each.key].id
  resource_group_name          = azurerm_resource_group.services["worker"].name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "worker"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_REGION"
        value = each.key
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = false  # Private
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = merge(var.tags, { "Service" = "Worker", "Visibility" = "Private", "Region" = each.key })
}

# ======================================
# PROCESSOR SERVICE (Private)
# ======================================

resource "azurerm_container_app" "processor" {
  for_each = toset(var.regions)

  name                         = "${var.project}-processor-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env[each.key].id
  resource_group_name          = azurerm_resource_group.services["processor"].name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "processor"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.75
      memory = "1.5Gi"

      env {
        name  = "AZURE_REGION"
        value = each.key
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  ingress {
    external_enabled = false  # Private
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = merge(var.tags, { "Service" = "Processor", "Visibility" = "Private", "Region" = each.key })
}

# ======================================
# SCHEDULER SERVICE (Private)
# ======================================

resource "azurerm_container_app" "scheduler" {
  for_each = toset(var.regions)

  name                         = "${var.project}-scheduler-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env[each.key].id
  resource_group_name          = azurerm_resource_group.services["scheduler"].name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "scheduler"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AZURE_REGION"
        value = each.key
      }
    }

    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = false  # Private
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = merge(var.tags, { "Service" = "Scheduler", "Visibility" = "Private", "Region" = each.key })
}

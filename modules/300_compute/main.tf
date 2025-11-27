# ======================================
# 300_COMPUTE LAYER - CONTAINER APPS
# ======================================
# COST OPTIMIZED FOR DEMO
# This module creates:
# - Container App Environments (2 regions)
# - Primary Container App (public gateway)
# - 2 Regional Container Apps (private, multi-region)
# - Internal load balancing and networking

# ==================
# CONTAINER APP ENVIRONMENTS
# ==================
resource "azurerm_container_app_environment" "regional" {
  for_each = toset(var.regions)

  name                           = "${var.project}-cae-${each.key}-${var.environment}"
  location                       = each.key
  resource_group_name            = var.backend_resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_ids[each.key]
  infrastructure_subnet_id       = var.container_app_subnet_ids[each.key]
  internal_load_balancer_enabled = each.key != var.primary_region

  tags = var.tags
}

# ==================
# PRIMARY CONTAINER APP (PUBLIC)
# ==================
# This is the main gateway/API that is publicly accessible in East US
resource "azurerm_container_app" "primary_gateway" {
  name                         = "${var.project}-gateway-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.regional[var.primary_region].id
  resource_group_name          = var.backend_resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = 2
    max_replicas = 10

    container {
      name   = "gateway"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 1.0
      memory = "2Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PRIMARY_REGION"
        value = var.primary_region
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags
}

# ==================
# REGIONAL CONTAINER APPS (PRIVATE)
# ==================
# App 1: API Service (multi-region)
resource "azurerm_container_app" "api_service" {
  for_each = toset(var.regions)

  name                         = "${var.project}-api-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.regional[each.key].id
  resource_group_name          = var.backend_resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = var.container_apps["app1"].min_replicas
    max_replicas = var.container_apps["app1"].max_replicas

    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = var.container_apps["app1"].cpu
      memory = var.container_apps["app1"].memory

      env {
        name  = "SERVICE_NAME"
        value = "api-service"
      }

      env {
        name  = "REGION"
        value = each.key
      }

      env {
        name  = "PRIMARY_GATEWAY_URL"
        value = azurerm_container_app.primary_gateway.latest_revision_fqdn
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags
}

# App 2: Worker Service (multi-region)
resource "azurerm_container_app" "worker_service" {
  for_each = toset(var.regions)

  name                         = "${var.project}-worker-${each.key}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.regional[each.key].id
  resource_group_name          = var.backend_resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = var.container_apps["app2"].min_replicas
    max_replicas = var.container_apps["app2"].max_replicas

    container {
      name   = "worker"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = var.container_apps["app2"].cpu
      memory = var.container_apps["app2"].memory

      env {
        name  = "SERVICE_NAME"
        value = "worker-service"
      }

      env {
        name  = "REGION"
        value = each.key
      }

      env {
        name  = "PRIMARY_GATEWAY_URL"
        value = azurerm_container_app.primary_gateway.latest_revision_fqdn
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags
}

# COMMENTED OUT FOR COST OPTIMIZATION - Only using 2 microservices for demo
# App 3: Processor Service (multi-region)
# resource "azurerm_container_app" "processor_service" { ... }

# App 4: Scheduler Service (multi-region)
# resource "azurerm_container_app" "scheduler_service" { ... }

# App 5: Notification Service (multi-region)
# resource "azurerm_container_app" "notification_service" { ... }


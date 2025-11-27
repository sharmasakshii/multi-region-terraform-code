output "container_app_environments" {
  value = {
    for region, cae in azurerm_container_app_environment.regional :
    region => {
      id                       = cae.id
      name                     = cae.name
      default_domain           = cae.default_domain
      static_ip_address        = cae.static_ip_address
    }
  }
  description = "Container App Environments per region"
}

output "primary_gateway" {
  value = {
    id                      = azurerm_container_app.primary_gateway.id
    name                    = azurerm_container_app.primary_gateway.name
    fqdn                    = azurerm_container_app.primary_gateway.latest_revision_fqdn
    outbound_ip_addresses   = azurerm_container_app.primary_gateway.outbound_ip_addresses
  }
  description = "Primary gateway container app (public)"
}

output "api_services" {
  value = {
    for region, app in azurerm_container_app.api_service :
    region => {
      id   = app.id
      name = app.name
      fqdn = app.latest_revision_fqdn
    }
  }
  description = "API service container apps per region"
}

output "worker_services" {
  value = {
    for region, app in azurerm_container_app.worker_service :
    region => {
      id   = app.id
      name = app.name
      fqdn = app.latest_revision_fqdn
    }
  }
  description = "Worker service container apps per region"
}

# COMMENTED OUT FOR COST OPTIMIZATION
# output "processor_services" { ... }
# output "scheduler_services" { ... }
# output "notification_services" { ... }

output "all_container_apps" {
  value = {
    primary_gateway = azurerm_container_app.primary_gateway.latest_revision_fqdn
    api_services = {
      for region, app in azurerm_container_app.api_service :
      region => app.latest_revision_fqdn
    }
    worker_services = {
      for region, app in azurerm_container_app.worker_service :
      region => app.latest_revision_fqdn
    }
  }
  description = "All container apps FQDNs (cost optimized - only 2 microservices)"
}




# Modular Multi-Region Deployment Guide

## Architecture Overview

This deployment creates a **modular, multi-region Azure infrastructure** with:

### ✅ **Separate Resource Groups per Service**
- Networking RG (shared infrastructure)
- Gateway RG (public entry point)
- API, Worker, Processor, Scheduler RGs (private services)
- Database RG (SQL servers with private endpoints)
- Storage RG (blob storage with private endpoints)

### ✅ **Container Apps**
- **1 Public Gateway** (eastus) - Entry point for all external traffic
- **4 Private Services** (eastus + centralus each):
  - API Service
  - Worker Service
  - Processor Service
  - Scheduler Service

### ✅ **Security**
- All resources use **Managed Identities**
- **Private Endpoints** for SQL and Storage
- **Private ingress** for internal services (only Gateway is public)
- VNet integration for all container apps
- NSGs for network security

### ✅ **High Availability**
- **Multi-region deployment** (East US + Central US)
- **SQL Failover Groups** with automatic failover
- **GRS Storage** for geo-redundancy
- **VNet Peering** (mesh topology)

## Infrastructure Components

| Component | Count | Distribution | Access |
|-----------|-------|--------------|--------|
| Resource Groups | 7 | Separate per service | N/A |
| Virtual Networks | 2 | 1 per region | Private |
| Subnets | 8 | 4 per region | Private |
| Container App Environments | 2 | 1 per region | Private |
| Gateway Service | 1 | East US only | **PUBLIC** |
| API Service | 2 | 1 per region | Private |
| Worker Service | 2 | 1 per region | Private |
| Processor Service | 2 | 1 per region | Private |
| Scheduler Service | 2 | 1 per region | Private |
| SQL Servers | 2 | 1 per region | Private |
| SQL Databases | 2 | 1 per region | Private |
| SQL Failover Groups | 1 | Cross-region | Private |
| Storage Accounts | 2 | 1 per region | Private |
| Private Endpoints | 4 | 2 SQL + 2 Storage | Private |

**Total Container Apps:** 9 (1 public + 8 private)

## Python Microservices

### 1. **Gateway Service** (Public)
- **Location:** `microservices/gateway/`
- **Purpose:** Public entry point, routes to internal services
- **Endpoints:**
  - `/health` - Health check
  - `/api/*` - Routes to API service
  - `/worker/*` - Routes to Worker service
  - `/process/*` - Routes to Processor service
  - `/scheduler/*` - Routes to Scheduler service
  - `/system/status` - Overall system status

### 2. **API Service** (Private)
- **Location:** `microservices/api-service/`
- **Purpose:** REST API operations, CRUD, data queries
- **Endpoints:**
  - `/items` - CRUD operations
  - `/query` - Custom queries
  - `/stats` - Service statistics

### 3. **Worker Service** (Private)
- **Location:** `microservices/worker-service/`
- **Purpose:** Background job processing
- **Endpoints:**
  - `/job/submit` - Submit background jobs
  - `/job/{id}` - Get job status
  - `/jobs/active` - Active jobs
  - `/jobs/completed` - Completed jobs

### 4. **Processor Service** (Private)
- **Location:** `microservices/processor-service/`
- **Purpose:** Compute-intensive data processing
- **Endpoints:**
  - `/process/aggregate` - Data aggregation
  - `/process/transform` - Data transformation
  - `/process/analyze` - Data analysis
  - `/process/filter` - Data filtering

### 5. **Scheduler Service** (Private)
- **Location:** `microservices/scheduler-service/`
- **Purpose:** Task scheduling and cron jobs
- **Endpoints:**
  - `/schedule/create` - Create scheduled task
  - `/schedule/list` - List all schedules
  - `/schedule/{id}` - Get/delete schedule
  - `/status` - Scheduler status

## Deployment Steps

### Prerequisites
```bash
# 1. Azure CLI login
az login

# 2. Set subscription
az account set --subscription 1fc66efc-2ddc-4018-a0d6-a513dc7f219c

# 3. Verify Terraform installation
terraform version  # Should be >= 1.5.0
```

### Deploy Infrastructure

```bash
# Navigate to project directory
cd D:\projects\multi-region-terraform-code

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (20-30 minutes)
terraform apply -auto-approve

# Get outputs
terraform output
```

### Access Your Deployment

After deployment completes:

```bash
# Get public gateway URL
terraform output gateway_url

# Example: https://demo-gateway-prod.redforest-12345678.eastus.azurecontainerapps.io
```

## Testing the Deployment

### 1. Test Gateway (Public)
```bash
# Get gateway URL
GATEWAY_URL=$(terraform output -raw gateway_fqdn)

# Test health endpoint
curl https://$GATEWAY_URL/health

# Test system status
curl https://$GATEWAY_URL/system/status
```

### 2. Test Internal Services (via Gateway)
```bash
# API Service
curl https://$GATEWAY_URL/api/items

# Worker Service
curl -X POST https://$GATEWAY_URL/worker/submit \
  -H "Content-Type: application/json" \
  -d '{"job_type":"data_import","payload":{}}'

# Processor Service
curl -X POST https://$GATEWAY_URL/process/aggregate \
  -H "Content-Type: application/json" \
  -d '{"data":[{"value":10},{"value":20}],"operation":"sum"}'

# Scheduler Service
curl https://$GATEWAY_URL/scheduler/status
```

### 3. Test Database Connectivity
```bash
# Test SQL connection through gateway
curl https://$GATEWAY_URL/test/database
```

### 4. Test Storage Connectivity
```bash
# Test storage connection through gateway
curl https://$GATEWAY_URL/test/storage
```

## Architecture Diagram

```
Internet
    ↓
┌─────────────────────────────────────┐
│   Gateway Service (PUBLIC)          │
│   East US Only                      │
│   https://gateway.eastus.azurecontainerapps.io
└─────────────────────────────────────┘
    ↓
Internal VNet (Private Communication)
    ↓
┌──────────────────────────────────────────────────────────┐
│                     EAST US                              │
├──────────────────────────────────────────────────────────┤
│ Container Apps (Private):                               │
│ ├─ API Service         (internal only)                  │
│ ├─ Worker Service      (internal only)                  │
│ ├─ Processor Service   (internal only)                  │
│ └─ Scheduler Service   (internal only)                  │
│                                                          │
│ SQL Server:                                              │
│ ├─ Primary (Read/Write)                                 │
│ └─ Private Endpoint                                      │
│                                                          │
│ Storage Account:                                         │
│ ├─ GRS Replication                                       │
│ └─ Private Endpoint                                      │
└──────────────────────────────────────────────────────────┘
    ↕ VNet Peering + SQL Failover Group
┌──────────────────────────────────────────────────────────┐
│                   CENTRAL US                             │
├──────────────────────────────────────────────────────────┤
│ Container Apps (Private):                               │
│ ├─ API Service         (internal only)                  │
│ ├─ Worker Service      (internal only)                  │
│ ├─ Processor Service   (internal only)                  │
│ └─ Scheduler Service   (internal only)                  │
│                                                          │
│ SQL Server:                                              │
│ ├─ Secondary (Read-Only Replica)                        │
│ └─ Private Endpoint                                      │
│                                                          │
│ Storage Account:                                         │
│ ├─ GRS Replication                                       │
│ └─ Private Endpoint                                      │
└──────────────────────────────────────────────────────────┘
```

## Resource Groups Structure

```
demo-networking-rg-prod          # Shared networking infrastructure
├─ VNets (2)
├─ Subnets (8)
├─ NSGs (2)
├─ Private DNS Zones (3)
└─ Log Analytics Workspaces (2)

demo-gateway-rg-prod             # Public gateway service
└─ Gateway Container App (PUBLIC)

demo-api-rg-prod                 # API service
├─ API Container App (East US)
└─ API Container App (Central US)

demo-worker-rg-prod              # Worker service
├─ Worker Container App (East US)
└─ Worker Container App (Central US)

demo-processor-rg-prod           # Processor service
├─ Processor Container App (East US)
└─ Processor Container App (Central US)

demo-scheduler-rg-prod           # Scheduler service
├─ Scheduler Container App (East US)
└─ Scheduler Container App (Central US)

demo-database-rg-prod            # Database infrastructure
├─ SQL Servers (2)
├─ SQL Databases (2)
├─ SQL Failover Group (1)
└─ Private Endpoints (2)

demo-storage-rg-prod             # Storage infrastructure
├─ Storage Accounts (2)
└─ Private Endpoints (2)
```

## Cost Estimate

**Approximate Monthly Cost:** $200-300

- Container Apps: $50-80
- SQL Databases (S2): $150-180
- Storage (GRS): $10-20
- Networking: $10-20
- Log Analytics: $10-20

## Cleanup

To destroy all resources:

```bash
terraform destroy -auto-approve
```

## Next Steps

### 1. Build Custom Docker Images
```bash
cd microservices/gateway
docker build -t your-registry.azurecr.io/gateway:v1 .
docker push your-registry.azurecr.io/gateway:v1

# Repeat for each service
```

### 2. Update Terraform to Use Custom Images
Edit `main.tf` and replace:
```hcl
image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
```

With:
```hcl
image = "your-registry.azurecr.io/gateway:v1"
```

### 3. Add Azure Container Registry
Add ACR module to create a private container registry.

### 4. Configure CI/CD
Set up GitHub Actions or Azure DevOps pipelines for automated deployments.

## Troubleshooting

### Issue: Terraform errors during init
```bash
# Clear Terraform cache
rm -rf .terraform
rm .terraform.lock.hcl
terraform init
```

### Issue: Cannot access private services
- Private services are only accessible within the VNet
- Access them through the public gateway
- Or deploy a jump box / bastion host

### Issue: SQL connection failures
- Check that private endpoints are created
- Verify DNS resolution
- Check NSG rules
- Verify managed identity permissions

## Support

For issues or questions, review:
- `README.md` - Original project documentation
- Terraform documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure Container Apps docs: https://learn.microsoft.com/azure/container-apps/

# 🌍 Modular Multi-Region Azure Infrastructure with Microservices

**Production-grade, modular Azure multi-region infrastructure with private endpoints, managed identities, and microservices architecture**

![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production_Ready-green)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Infrastructure Components](#-infrastructure-components)
- [Microservices](#-microservices)
- [Quick Start](#-quick-start)
- [Deployment](#-deployment)
- [Testing](#-testing)
- [Cleanup](#-cleanup)
- [Cost Estimate](#-cost-estimate)
- [Project Structure](#-project-structure)

---

## 🎯 Overview

This project implements a **modular, multi-region Azure infrastructure** with a microservices architecture. It demonstrates enterprise-grade patterns including:

- **Modular Service Isolation**: Separate resource groups for each service type
- **Zero-Trust Security**: Private endpoints, managed identities, VNet integration
- **High Availability**: Multi-region deployment with SQL failover groups
- **Microservices Architecture**: 5 Python FastAPI services with proper isolation
- **Infrastructure as Code**: 100% Terraform managed with reusable modules

### **Key Highlights**

✅ **8 Separate Resource Groups** - Modular service isolation
✅ **1 Public Gateway + 8 Private Services** - Secure by default architecture
✅ **Managed Identities** - Passwordless authentication for all services
✅ **Private Endpoints** - Secure connectivity to PaaS services
✅ **SQL Failover Groups** - Automatic database replication and failover
✅ **GRS Storage** - Geo-redundant storage across regions
✅ **5 FastAPI Microservices** - Production-ready Python services
✅ **VNet Integration** - All services communicate over private network

---

## 🏗️ Architecture

### **High-Level Architecture**

```
                         INTERNET
                            │
                            ▼
                ┌──────────────────────┐
                │   Gateway Service    │ ◄─── PUBLIC (External Access)
                │   (West US 2)        │
                │   FastAPI + Routing  │
                └──────────┬───────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │      Private VNet (Internal)        │
        │      Mesh Topology + Peering        │
        └──────┬────────┬────────┬────────────┘
               │        │        │
    ┌──────────▼───┐  ┌▼────────▼───┐  ┌────▼──────┐
    │  WEST US 2   │  │ CENTRAL US   │  │ SHARED    │
    │  (Primary)   │  │ (Secondary)  │  │ RESOURCES │
    └──────────────┘  └──────────────┘  └───────────┘
    │                 │                  │
    │ • API Service   │ • API Service    │ • Private
    │ • Worker        │ • Worker         │   DNS Zones
    │ • Processor     │ • Processor      │ • VNet
    │ • Scheduler     │ • Scheduler      │   Peering
    │ • SQL Primary   │ • SQL Secondary  │ • NSGs
    │ • Storage GRS   │ • Storage GRS    │
    │ • Private       │ • Private        │
    │   Endpoints     │   Endpoints      │
    └─────────────────┴──────────────────┴───────────┘
               │                 │
               └─────────┬───────┘
                   SQL Failover Group
               (Automatic Replication)
```

### **Security Architecture**

```
External Request → Public Gateway (HTTPS)
                       │
                       ↓
            Internal VNet (Private)
                       │
         ┌─────────────┴─────────────┐
         │                           │
         ↓                           ↓
    Private Services          Private Endpoints
    (Internal Only)          (SQL + Storage)
         │                           │
         └──────────┬────────────────┘
                    ↓
           Managed Identity Auth
          (No passwords/secrets)
```

---

## ✨ Features

### **1. Modular Resource Groups**

Each service type has its own resource group for better isolation and management:

- `demo-networking-rg-prod` - Shared networking (VNets, DNS, NSGs)
- `demo-gateway-rg-prod` - Public gateway service
- `demo-api-rg-prod` - API services
- `demo-worker-rg-prod` - Worker services
- `demo-processor-rg-prod` - Processor services
- `demo-scheduler-rg-prod` - Scheduler services
- `demo-database-rg-prod` - SQL servers and databases
- `demo-storage-rg-prod` - Storage accounts

### **2. Security Features**

- **Managed Identities**: All 9 container apps use system-assigned managed identities
- **Private Endpoints**: SQL and Storage accessible only via private IPs
- **VNet Integration**: All services communicate over private network
- **Private DNS Zones**: Automatic DNS resolution for private endpoints
- **NSG Rules**: Network security groups protect container app subnets
- **TLS 1.2**: Minimum TLS version enforced on all services

### **3. High Availability**

- **Multi-Region**: Deployed across West US 2 and Central US
- **SQL Failover Groups**: Automatic database failover with 60-min grace period
- **Geo-Redundant Storage**: GRS replication across regions
- **Auto-Scaling**: Container apps scale based on load (1-5 replicas)
- **VNet Peering**: Mesh topology for cross-region communication

### **4. Microservices**

Five Python FastAPI microservices with proper separation of concerns:

1. **Gateway** - Public entry point and routing
2. **API Service** - REST API and CRUD operations
3. **Worker Service** - Background job processing
4. **Processor Service** - Data processing and transformations
5. **Scheduler Service** - Task scheduling and cron jobs

---

## 📦 Infrastructure Components

### **Resource Summary**

| Component | Count | Visibility | Regions |
|-----------|-------|------------|---------|
| **Resource Groups** | 8 | N/A | N/A |
| **Virtual Networks** | 2 | Private | Both |
| **Subnets** | 8 | Private | 4 per region |
| **VNet Peerings** | 2 | Private | Bidirectional |
| **Container App Environments** | 2 | Private | 1 per region |
| **Gateway Service** | 1 | **PUBLIC** | West US 2 |
| **API Services** | 2 | Private | Both regions |
| **Worker Services** | 2 | Private | Both regions |
| **Processor Services** | 2 | Private | Both regions |
| **Scheduler Services** | 2 | Private | Both regions |
| **SQL Servers** | 2 | Private | Both regions |
| **SQL Databases** | 2 | Private | Both regions |
| **SQL Failover Groups** | 1 | N/A | Cross-region |
| **Storage Accounts** | 2 | Private | Both regions |
| **Private Endpoints** | 4 | Private | 2 SQL + 2 Storage |
| **Private DNS Zones** | 3 | Private | SQL, Storage, Container Apps |
| **NSGs** | 2 | Private | 1 per region |
| **Log Analytics Workspaces** | 2 | Private | 1 per region |

**Total: ~73 Azure Resources**

### **Network Design**

| Region | VNet CIDR | Container Apps | Private Endpoints | Database | Storage |
|--------|-----------|----------------|-------------------|----------|---------|
| **West US 2** | 10.10.0.0/16 | 10.10.0.0/23 | 10.10.4.0/24 | 10.10.5.0/24 | 10.10.6.0/24 |
| **Central US** | 10.20.0.0/16 | 10.20.0.0/23 | 10.20.4.0/24 | 10.20.5.0/24 | 10.20.6.0/24 |

---

## 🐍 Microservices

All microservices are built with **Python FastAPI** and include:

- Health check endpoints
- Environment-based configuration
- Azure SDK integration
- Docker containerization
- Production-ready error handling

### **1. Gateway Service (Public)**

**Location**: `microservices/gateway/`
**Purpose**: Public entry point that routes external traffic to internal services

**Features**:
- FastAPI with async/await
- Routes to all internal services
- System status aggregation
- Health checks for all backend services

**Endpoints**:
- `GET /health` - Gateway health check
- `GET /api/*` - Proxy to API service
- `GET /worker/*` - Proxy to Worker service
- `GET /process/*` - Proxy to Processor service
- `GET /scheduler/*` - Proxy to Scheduler service
- `GET /system/status` - Overall system status

### **2. API Service (Private)**

**Location**: `microservices/api-service/`
**Purpose**: RESTful API for CRUD operations and data queries

**Features**:
- Pydantic models for validation
- In-memory storage (demo)
- SQL database integration ready
- Query and statistics endpoints

**Endpoints**:
- `GET /items` - List all items
- `POST /items` - Create new item
- `GET /items/{id}` - Get item by ID
- `PUT /items/{id}` - Update item
- `DELETE /items/{id}` - Delete item
- `GET /stats` - Service statistics

### **3. Worker Service (Private)**

**Location**: `microservices/worker-service/`
**Purpose**: Background job processing and async tasks

**Features**:
- Job queue management
- Job status tracking
- Async job processing
- Job history

**Endpoints**:
- `POST /job/submit` - Submit new job
- `GET /job/{id}` - Get job status
- `GET /jobs/active` - List active jobs
- `GET /jobs/completed` - List completed jobs

### **4. Processor Service (Private)**

**Location**: `microservices/processor-service/`
**Purpose**: Compute-intensive data processing and transformations

**Features**:
- Data aggregation
- Data transformation
- Analysis operations
- Filtering capabilities

**Endpoints**:
- `POST /process/aggregate` - Aggregate data
- `POST /process/transform` - Transform data
- `POST /process/analyze` - Analyze data
- `POST /process/filter` - Filter data

### **5. Scheduler Service (Private)**

**Location**: `microservices/scheduler-service/`
**Purpose**: Task scheduling and cron job management

**Features**:
- APScheduler integration
- Cron job scheduling
- Schedule management
- Task execution history

**Endpoints**:
- `POST /schedule/create` - Create scheduled task
- `GET /schedule/list` - List all schedules
- `GET /schedule/{id}` - Get schedule details
- `DELETE /schedule/{id}` - Delete schedule
- `GET /status` - Scheduler status

### **Python Dependencies**

All services share common dependencies:

```python
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
httpx==0.25.1
python-multipart==0.0.6
azure-identity==1.15.0
azure-storage-blob==12.19.0
pyodbc==5.0.1
apscheduler==3.10.4
```

---

## 🚀 Quick Start

### **Prerequisites**

- ✅ Azure CLI installed (`az --version`)
- ✅ Terraform 1.5.0+ installed (`terraform --version`)
- ✅ Azure subscription with Owner/Contributor access
- ✅ Git for version control

### **3-Step Deployment**

```bash
# 1. Login to Azure
az login
az account set --subscription <your-subscription-id>

# 2. Clone repository (if not already cloned)
git clone https://github.com/yourusername/multi-region-terraform-code
cd multi-region-terraform-code

# 3. Deploy infrastructure
terraform init
terraform apply -auto-approve
```

⏳ **Deployment time**: 20-30 minutes

---

## 📋 Deployment

### **Step 1: Configure Subscription**

Update `provider.tf` with your subscription ID:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "YOUR-SUBSCRIPTION-ID"
}
```

### **Step 2: Review Variables**

Check `variables.tf` for configuration:

```hcl
variable "project" {
  default = "demo"
}

variable "primary_region" {
  default = "westus2"
}

variable "regions" {
  default = ["westus2", "centralus"]
}

variable "environment" {
  default = "prod"
}

variable "sql_admin_username" {
  default = "sqladmin"
}

variable "sql_admin_password" {
  sensitive = true
  default   = "P@ssw0rd123!Complex"
}
```

⚠️ **Important**: Change SQL password for production!

### **Step 3: Initialize Terraform**

```bash
terraform init
```

### **Step 4: Plan Deployment**

```bash
terraform plan
```

Review what will be created (~73 resources).

### **Step 5: Deploy**

```bash
terraform apply -auto-approve
```

### **Step 6: Get Outputs**

```bash
# View all outputs
terraform output

# Get gateway URL
terraform output gateway_url
```

---

## ✅ Testing

### **1. Test Gateway (Public)**

```bash
# Get gateway URL
GATEWAY_URL=$(terraform output -raw gateway_fqdn)

# Test health endpoint
curl https://$GATEWAY_URL/health

# Test system status
curl https://$GATEWAY_URL/system/status
```

### **2. Test Internal Services (via Gateway)**

```bash
# API Service
curl https://$GATEWAY_URL/api/items

# Worker Service - Submit job
curl -X POST https://$GATEWAY_URL/worker/submit \
  -H "Content-Type: application/json" \
  -d '{"job_type":"data_import","payload":{}}'

# Processor Service - Aggregate data
curl -X POST https://$GATEWAY_URL/process/aggregate \
  -H "Content-Type: application/json" \
  -d '{"data":[{"value":10},{"value":20}],"operation":"sum"}'

# Scheduler Service
curl https://$GATEWAY_URL/scheduler/status
```

### **3. Test Database Connectivity**

```bash
# Check SQL servers
az sql server list --resource-group demo-database-rg-prod --output table

# Check failover groups
az sql failover-group list \
  --resource-group demo-database-rg-prod \
  --server demo-sql-westus2-prod \
  --output table
```

### **4. Test Storage Connectivity**

```bash
# List storage accounts
az storage account list --resource-group demo-storage-rg-prod --output table

# Check private endpoints
az network private-endpoint list --resource-group demo-storage-rg-prod --output table
```

---

## 🧹 Cleanup

### **Destroy All Resources**

```bash
terraform destroy -auto-approve
```

This will delete all 73 resources including:
- All 9 container apps
- All 8 resource groups
- SQL servers and databases
- Storage accounts
- Networking resources

⏳ **Takes**: 10-15 minutes

### **Verify Cleanup**

```bash
# Check resource groups
az group list --query "[?starts_with(name, 'demo-')]" --output table
```

---

## 💰 Cost Estimate

### **Monthly Cost Breakdown**

| Service | Quantity | Unit Cost | Monthly Cost |
|---------|----------|-----------|--------------|
| **VNets** | 2 | Free | $0 |
| **VNet Peering** | ~5 GB/day | $0.01/GB | ~$5 |
| **Container Apps** | 9 apps | $5-15/app | ~$50-100 |
| **SQL Databases** | 2 (Basic) | $5/db | ~$10 |
| **Storage Accounts** | 2 (GRS) | $5/account | ~$10 |
| **Private Endpoints** | 4 | $0.01/hr | ~$3 |
| **Log Analytics** | 2 | $2.50/GB | ~$25 |

**💵 Total: $100-150/month (~$3-5 per day)**

### **Cost Optimization Tips**

1. 💡 Use `terraform destroy` when not in use
2. 💡 Scale down container apps during off-hours
3. 💡 Reduce Log Analytics retention
4. 💡 Use spot/dev-test pricing where available
5. 💡 Monitor with Azure Cost Management

---

## 📁 Project Structure

```
multi-region-terraform-code/
│
├── 📄 README.md                          # This file
├── 📄 DEPLOYMENT-GUIDE.md                 # Detailed deployment guide
│
├── 🔧 main.tf                            # Root Terraform config
├── 🔧 variables.tf                       # Variable definitions
├── 🔧 provider.tf                        # Azure provider setup
├── 🔧 outputs.tf                         # Output definitions
│
├── 📂 modules/                           # Terraform modules
│   ├── 📂 networking/                    # VNets, subnets, DNS, NSGs
│   ├── 📂 database/                      # SQL servers, failover groups
│   └── 📂 storage-modular/               # Storage accounts, private endpoints
│
└── 📂 microservices/                     # Python FastAPI services
    ├── 📂 gateway/                       # Public gateway service
    │   ├── app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── 📂 api-service/                   # API service
    │   ├── app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── 📂 worker-service/                # Worker service
    │   ├── app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── 📂 processor-service/             # Processor service
    │   ├── app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    └── 📂 scheduler-service/             # Scheduler service
        ├── app.py
        ├── Dockerfile
        └── requirements.txt
```

---

## 🎓 Key Learnings

This project demonstrates:

1. **Modular Architecture**: Separate resource groups for each service type
2. **Zero-Trust Security**: Private endpoints, managed identities, no passwords
3. **High Availability**: Multi-region deployment with automatic failover
4. **Microservices Pattern**: Proper service isolation and communication
5. **Infrastructure as Code**: Complete Terraform automation
6. **Production Patterns**: NSGs, private DNS, VNet integration

---

## 🔧 Troubleshooting

### **Issue: Container Apps Not Starting**

```bash
# Check container app status
az containerapp show \
  --name demo-gateway-prod \
  --resource-group demo-gateway-rg-prod \
  --query "properties.runningStatus"

# Check logs
az containerapp logs show \
  --name demo-gateway-prod \
  --resource-group demo-gateway-rg-prod \
  --tail 50
```

### **Issue: Cannot Access Gateway**

```bash
# Get gateway URL
terraform output gateway_url

# Check ingress configuration
az containerapp ingress show \
  --name demo-gateway-prod \
  --resource-group demo-gateway-rg-prod
```

### **Issue: SQL Connection Failures**

```bash
# Check private endpoints
az network private-endpoint list \
  --resource-group demo-database-rg-prod \
  --output table

# Check DNS resolution
nslookup demo-sql-westus2-prod.database.windows.net
```

---

## 🎯 Next Steps

After deploying this infrastructure:

1. **Build Docker Images**: Build custom images from the microservices
2. **Push to ACR**: Deploy to Azure Container Registry
3. **Update Terraform**: Reference custom images instead of hello-world
4. **Add CI/CD**: Implement GitHub Actions or Azure DevOps
5. **Enable Monitoring**: Configure Application Insights
6. **Add Tests**: Implement integration and e2e tests

---

## 📊 Architecture Highlights

### **What Makes This Special**

✅ **Modular by Design**: Each service type has its own resource group
✅ **Security First**: Private endpoints, managed identities, zero passwords
✅ **Production Ready**: NSGs, private DNS, auto-scaling, failover groups
✅ **Cost Optimized**: Basic SQL tier, right-sized container apps
✅ **Fully Automated**: Deploy entire infrastructure with one command
✅ **Microservices**: 5 Python FastAPI services with proper isolation

### **Enterprise Patterns**

- 🏗️ Modular Terraform with reusable modules
- 🔒 Zero-trust networking with private endpoints
- 🔄 High availability with multi-region deployment
- 📊 Observability with Log Analytics integration
- 🎯 Separation of concerns with dedicated resource groups

---

## 🎉 Summary

**You now have a production-grade, modular, multi-region Azure infrastructure!**

### **Key Commands**

```bash
# Deploy
terraform apply -auto-approve

# Test gateway
curl https://$(terraform output -raw gateway_fqdn)/health

# Cleanup
terraform destroy -auto-approve
```

### **What You've Built**

✅ 8 separate resource groups for modular service isolation
✅ 1 public gateway + 8 private services across 2 regions
✅ SQL databases with automatic failover
✅ Geo-redundant storage with private endpoints
✅ 5 Python FastAPI microservices
✅ Complete zero-trust security with managed identities
✅ VNet integration and private DNS resolution

### **Cost**

💵 **$100-150/month** (~$3-5/day)

### **Deployment Time**

⏱️ **20-30 minutes** for complete infrastructure

---

**Questions? Check DEPLOYMENT-GUIDE.md for detailed instructions!**

🚀 **Ready to deploy? Run `terraform apply -auto-approve`!**

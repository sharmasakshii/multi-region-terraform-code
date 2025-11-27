# 🌍 Multi-Region Disaster Recovery (DR) Infrastructure

**Cost-optimized Azure multi-region infrastructure with automatic failover for team demos**

![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Status](https://img.shields.io/badge/Status-Demo_Ready-green)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [What's Included](#-whats-included)
- [Cost Information](#-cost-information)
- [Quick Start](#-quick-start)
- [Detailed Deployment](#-detailed-deployment)
- [Testing](#-testing)
- [DR Failover Demo](#-dr-failover-demo)
- [Cleanup](#-cleanup)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)

---

## 🎯 Overview

This project creates a **production-grade, multi-region infrastructure** on Azure designed to demonstrate **Disaster Recovery (DR)** capabilities. It's been **cost-optimized** specifically for team demos while maintaining all critical DR features.

### **Key Features**

✅ **Multi-Region Architecture**: 2 Azure regions (Central US + East US 2)  
✅ **Automatic SQL Failover**: Zero data loss with continuous replication  
✅ **Container Apps**: Auto-scaling microservices across regions  
✅ **Private Networking**: VNet peering + Private Endpoints  
✅ **Geo-Redundant Storage**: GRS replication  
✅ **Infrastructure as Code**: 100% Terraform managed  
✅ **Cost Optimized**: 60-70% cheaper than full production setup  

### **Use Cases**

- 🎭 Demonstrating DR capabilities to stakeholders
- 📚 Learning multi-region Azure architecture
- 🧪 Testing failover scenarios
- 🏗️ Foundation for production DR infrastructure

---

## 🏗️ Architecture

### **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Public Gateway     │
              │   (Central US)       │
              │   Container App      │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │       VNet Peering           │
         │   (Private Network Mesh)     │
         └───────────┬──────────┬───────┘
                     │          │
          ┌──────────▼─────┐  ┌▼──────────────┐
          │   Central US   │  │   East US 2   │
          │   (PRIMARY)    │  │  (SECONDARY)  │
          │                │  │               │
          │ • VNet         │  │ • VNet        │
          │ • SQL Primary  │◄─┤ • SQL Replica │
          │ • Storage GRS  │  │ • Storage GRS │
          │ • 2 Container  │  │ • 2 Container │
          │   Apps         │  │   Apps        │
          │ • Private      │  │ • Private     │
          │   Endpoints    │  │   Endpoints   │
          └────────────────┘  └───────────────┘
                     │          │
                     └──────────┘
                  SQL Failover Group
              (Continuous Replication)
```

### **Network Design**

| Region | VNet CIDR | Container Apps | Private Endpoints | Database | Storage |
|--------|-----------|----------------|-------------------|----------|---------|
| **Central US** | 10.10.0.0/16 | 10.10.0.0/23 | 10.10.4.0/24 | 10.10.5.0/24 | 10.10.6.0/24 |
| **East US 2** | 10.20.0.0/16 | 10.20.0.0/23 | 10.20.4.0/24 | 10.20.5.0/24 | 10.20.6.0/24 |

---

## 📦 What's Included

### **Infrastructure Resources**

| Resource Type | Count | Purpose |
|---------------|-------|---------|
| **Resource Group** | 1 | Container for all resources |
| **Virtual Networks** | 2 | Network isolation per region |
| **Subnets** | 8 | 4 per region (Container Apps, Private Endpoints, Database, Storage) |
| **VNet Peerings** | 2 | Bidirectional connectivity |
| **NSGs** | 2 | Security rules for Container Apps |
| **Log Analytics** | 2 | Monitoring per region |
| **Private DNS Zones** | 3 | Storage, SQL, Container Apps |
| **Storage Accounts** | 2 | GRS app storage (1 per region) |
| **Storage Containers** | 2 | Blob containers for app data |
| **SQL Servers** | 2 | One per region |
| **SQL Databases** | 4 | App DB + Analytics DB (2 per region) |
| **SQL Failover Groups** | 2 | Automatic DR for databases |
| **Container App Envs** | 2 | Runtime environments |
| **Container Apps** | 5 | 1 public gateway + 4 private microservices |
| **Private Endpoints** | 4 | Secure access to Storage (2) + SQL (2) |

**TOTAL: ~42 Azure Resources**

### **Container Apps**

1. **Gateway** (Public) - Central US
   - Entry point for all traffic
   - 1.0 CPU, 2GB RAM
   - Auto-scales: 2-10 replicas

2. **API Service** (Private) - Both regions
   - Internal API microservice
   - 0.25 CPU, 0.5GB RAM
   - Auto-scales: 1-2 replicas

3. **Worker Service** (Private) - Both regions
   - Background processing
   - 0.25 CPU, 0.5GB RAM
   - Auto-scales: 1-2 replicas

---

## 💰 Cost Information

### **Monthly Estimate (Optimized for Demo)**

| Service | Quantity | Unit Cost | Monthly Cost |
|---------|----------|-----------|--------------|
| **VNets** | 2 | Free | $0 |
| **VNet Peering** | ~2 GB/day | $0.01/GB | ~$5 |
| **SQL Databases** | 4 (S2/S3 tier) | $30-75/db | ~$180 |
| **Storage Accounts** | 2 (GRS) | $5/account | ~$10 |
| **Container Apps** | 5 apps | $5-10/app | ~$25-50 |
| **Log Analytics** | 2 (5GB/mo each) | $2.50/GB | ~$25 |
| **Private Endpoints** | 4 | $0.01/hr | ~$3 |

**💵 TOTAL: $150-250/month (~$5-8 per day)**

### **Cost Optimization vs Full Production**

| Metric | Full Production | Demo Optimized | Savings |
|--------|----------------|----------------|---------|
| Regions | 3 | 2 | -33% |
| Container Apps | 16 | 5 | -69% |
| Storage Accounts | 9 | 2 | -78% |
| Monthly Cost | $380-680 | $150-250 | **~60-70%** |

### **Cost-Saving Tips**

1. 💡 **Stop when not in use**: `terraform destroy` when done demoing
2. 💡 **Use Dev/Test pricing** for SQL databases (-40%)
3. 💡 **Reduce Log Analytics retention** to 7 days
4. 💡 **Lower SQL tier** to Basic for non-critical demos
5. 💡 **Scale down** container apps during off-hours

---

## 🚀 Quick Start

**3 Simple Steps to Deploy and Demo**

### **Prerequisites**

- ✅ Azure CLI installed (`az --version`)
- ✅ Terraform 1.5.0+ installed (`terraform --version`)
- ✅ Azure subscription with sufficient quota
- ✅ PowerShell 7+ (Windows) or Bash (Linux/Mac)

### **Step 1: Deploy Infrastructure** (30 minutes)

```powershell
# Navigate to project directory
cd d:\multi-region

# Login to Azure
az login

# Verify subscription
az account show

# Initialize Terraform
terraform init

# Deploy infrastructure
terraform apply -auto-approve
```

⏳ **Wait**: 20-30 minutes for deployment to complete

### **Step 2: Verify Deployment** (2 minutes)

```powershell
# Run quick validation test
.\quick-test.ps1
```

✅ **Expected**: All 7 tests should pass

### **Step 3: Demo Disaster Recovery** (10 minutes)

```powershell
# Run DR failover demonstration
.\dr-failover-test.ps1
```

🎭 **What happens**:
1. Shows current SQL replication status
2. Performs manual failover (Central US → East US 2)
3. Verifies failover completed successfully
4. Optionally fails back to original primary

---

## 📋 Detailed Deployment

### **1. Clone or Navigate to Project**

```powershell
cd d:\multi-region
```

### **2. Review Configuration**

Open `terraform.tfvars` to see the configuration:

```hcl
# Project settings
project     = "demo"
environment = "demo"

# Regions (cost optimized)
primary_region = "centralus"
regions = ["centralus", "eastus2"]

# SQL credentials
sql_admin_username = "sqladmin"
sql_admin_password = "YourSecurePassword123!"
```

⚠️ **Important**: Change the SQL password for production use!

### **3. Initialize Terraform**

```powershell
terraform init
```

This downloads the Azure provider and initializes the backend.

### **4. Preview Changes (Optional)**

```powershell
terraform plan
```

Review what will be created. You should see ~42 resources.

### **5. Deploy Infrastructure**

```powershell
terraform apply -auto-approve
```

Or without auto-approve to manually confirm:

```powershell
terraform apply
```

### **6. Monitor Deployment**

Terraform will show progress:

```
azurerm_resource_group.main: Creating...
azurerm_virtual_network.regional_vnets["centralus"]: Creating...
azurerm_virtual_network.regional_vnets["eastus2"]: Creating...
...
Apply complete! Resources: 42 added, 0 changed, 0 destroyed.
```

### **7. Get Outputs**

```powershell
# View all outputs
terraform output

# Get specific output
terraform output primary_gateway_url
```

---

## ✅ Testing

### **Quick Test Script**

The `quick-test.ps1` script validates your deployment:

```powershell
.\quick-test.ps1
```

**Tests Performed:**

1. ✅ **Resource Group** - Verifies RG exists
2. ✅ **Virtual Networks** - Checks for 2 VNets
3. ✅ **SQL Servers** - Validates 2 SQL servers
4. ✅ **SQL Failover Groups** - Confirms DR is configured
5. ✅ **Storage Accounts** - Checks 2 storage accounts
6. ✅ **Container Apps** - Validates 5 apps deployed
7. ✅ **Public Gateway** - Tests HTTP accessibility

**Expected Output:**

```
🧪 Multi-Region DR Quick Test (Cost Optimized)
================================================

✅ Test 1: Checking Resource Group...
  ✓ Resource Group exists: demo-rg-demo-cb61e6
    Location: centralus

✅ Test 2: Checking Virtual Networks...
  ✓ Found 2 VNets (expected: 2)
    - demo-vnet-centralus-demo in centralus
    - demo-vnet-eastus2-demo in eastus2

✅ Test 3: Checking SQL Servers...
  ✓ Found 2 SQL Servers (expected: 2)
    - demo-sql-centralus-demo in centralus
    - demo-sql-eastus2-demo in eastus2

✅ Test 4: Checking SQL Failover Groups (DR Critical)...
  ✓ App Database FG: Primary
  ✓ Analytics Database FG: Primary
    - Primary: centralus
    - Secondary: eastus2

✅ Test 5: Checking Storage Accounts...
  ✓ Found 2 Storage Accounts (expected: 2)

✅ Test 6: Checking Container Apps...
  ✓ Found 5 Container Apps (expected: 5)
    - Public apps: 1 (Gateway)
    - Private apps: 4 (API + Worker)

✅ Test 7: Testing Public Gateway...
  ✓ Gateway is accessible (HTTP 200)

================================================
📊 Test Summary (Cost Optimized Demo)
================================================
Passed: 7
Failed: 0
Success Rate: 100%

🎉 All tests passed! Your DR infrastructure is ready!
```

### **Manual Testing Commands**

```powershell
# List all resources
az resource list --resource-group demo-rg-demo-cb61e6 --output table

# Check SQL server status
az sql server list --resource-group demo-rg-demo-cb61e6 --output table

# Check failover groups
az sql failover-group list `
  --resource-group demo-rg-demo-cb61e6 `
  --server demo-sql-centralus-demo `
  --output table

# Test gateway
$url = terraform output -raw primary_gateway_url
Invoke-WebRequest -Uri $url -UseBasicParsing

# Open gateway in browser
Start-Process (terraform output -raw primary_gateway_url)
```

---

## 🔥 DR Failover Demo

### **What is a Failover?**

A **failover** is the process of switching from the primary region to the secondary region when a disaster occurs. This demonstrates:
- ✅ Business continuity during regional outages
- ✅ Zero data loss with continuous replication
- ✅ Automatic or manual failover capabilities
- ✅ Quick recovery time objectives (RTO)

### **Run the DR Test**

```powershell
.\dr-failover-test.ps1
```

### **Demo Flow**

#### **Step 1: Check Current Status**

The script shows:
- Current primary region (Central US)
- Current secondary region (East US 2)
- Replication status of both databases
- Current failover group roles

#### **Step 2: Confirm Failover**

You'll be prompted:

```
⚠️  STEP 2: Failover Confirmation
================================

You are about to initiate a MANUAL FAILOVER:
  Primary   (centralus)   → Becomes Secondary
  Secondary (eastus2) → Becomes Primary

Do you want to proceed with failover? (yes/no):
```

Type `yes` to continue.

#### **Step 3: Perform Failover**

The script executes:

```powershell
az sql failover-group set-primary `
  --name demo-appdb-fg-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --server demo-sql-eastus2-demo
```

⏳ Takes 30-60 seconds

#### **Step 4: Verify Failover**

Confirms:
- ✅ East US 2 is now PRIMARY
- ✅ Central US is now SECONDARY
- ✅ Replication is still active
- ✅ No data loss occurred

#### **Step 5: Failback (Optional)**

You can optionally fail back to the original primary:

```
🔙 STEP 5: Failback to Original Primary
=========================================

Would you like to fail back to the original primary (centralus)?

Failback now? (yes/no):
```

### **Key Points to Highlight**

During your team demo, emphasize:

1. **Zero Downtime**: Applications continue running during failover
2. **No Data Loss**: Continuous synchronous replication
3. **Automatic Capability**: Can be configured for automatic failover (60-min grace period)
4. **Manual Override**: Can manually trigger failover for planned maintenance
5. **Multi-Region Apps**: Container apps running in both regions for redundancy

---

## 🧹 Cleanup

### **Destroy All Resources**

When done with your demo:

```powershell
terraform destroy -auto-approve
```

Or with confirmation:

```powershell
terraform destroy
```

⏳ Takes 10-15 minutes

### **Verify Cleanup**

```powershell
# Check if resource group still exists
az group show --name demo-rg-demo-cb61e6
```

Should return an error if successfully deleted.

### **Cost Savings**

Destroying resources stops all charges. You can redeploy anytime using `terraform apply`.

---

## 🔧 Troubleshooting

### **Issue: Container Apps Not Starting**

**Symptom**: Container apps show "Provisioning" or "Failed" status

**Solution**:

```powershell
# Check container app logs
az containerapp logs show `
  --name demo-gateway-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --tail 50

# Check container app status
az containerapp show `
  --name demo-gateway-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --query "properties.runningStatus"
```

### **Issue: SQL Failover Takes Too Long**

**Symptom**: Failover doesn't complete within 60 seconds

**Solution**:

```powershell
# Check failover group status
az sql failover-group show `
  --name demo-appdb-fg-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --server demo-sql-centralus-demo `
  --query "{Name:name, Role:replicationRole, State:replicationState}"
```

Wait up to 5 minutes. If still stuck, check Azure Portal for errors.

### **Issue: Gateway Not Accessible**

**Symptom**: HTTP request to gateway times out

**Solution**:

```powershell
# Get the correct URL
terraform output primary_gateway_url

# Check if gateway is running
az containerapp show `
  --name demo-gateway-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --query "properties.{Status:runningStatus, FQDN:configuration.ingress.fqdn}"

# Check NSG rules
az network nsg show `
  --resource-group demo-rg-demo-cb61e6 `
  --name demo-nsg-container-apps-centralus-demo
```

### **Issue: Terraform State Lock**

**Symptom**: "Error acquiring the state lock"

**Solution**:

```powershell
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### **Issue: Insufficient Quota**

**Symptom**: "QuotaExceeded" error during deployment

**Solution**:

1. Check quotas:
   ```powershell
   az vm list-usage --location centralus -o table
   ```

2. Request quota increase via Azure Portal
3. Or change to different regions with available capacity

---

## 📁 Project Structure

```
d:\multi-region\
│
├── 📄 README.md                    # This file - complete documentation
├── 📄 QUICK-START.md               # Quick 3-step deployment guide
├── 📄 COST-OPTIMIZED-DEMO.md       # Detailed demo walkthrough
├── 📄 TESTING_GUIDE.md             # Comprehensive testing guide
├── 📄 QUICK_DEPLOY.md              # Fast deployment instructions
│
├── 🔧 main.tf                      # Root Terraform configuration
├── 🔧 variables.tf                 # Variable definitions
├── 🔧 terraform.tfvars             # Configuration values
├── 🔧 provider.tf                  # Azure provider setup
├── 🔧 output.tf                    # Output definitions
├── 📦 terraform.tfstate            # State file (auto-generated)
│
├── 🧪 quick-test.ps1               # Infrastructure validation script
├── 🔥 dr-failover-test.ps1         # DR failover demonstration script
├── 🧪 quick-test.sh                # Linux/Mac version of quick test
│
└── 📂 modules/                     # Terraform modules
    │
    ├── 📂 100_base/                # Layer 1: Networking foundation
    │   ├── main.tf                 # VNets, subnets, DNS zones
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── 📂 200_data/                # Layer 2: Databases
    │   ├── main.tf                 # SQL servers, databases, failover groups
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── 📂 300_compute/             # Layer 3: Container Apps
    │   ├── main.tf                 # Container app environments & apps
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── 📂 storage/                 # Storage layer
        ├── main.tf                 # Storage accounts & containers
        ├── variables.tf
        └── outputs.tf
```

---

## 🎓 Learning Resources

### **Terraform**
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Modules](https://www.terraform.io/language/modules)

### **Azure**
- [Azure SQL Failover Groups](https://docs.microsoft.com/azure/sql-database/sql-database-auto-failover-group)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [Azure VNet Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Azure Private Endpoints](https://docs.microsoft.com/azure/private-link/private-endpoint-overview)

### **Disaster Recovery**
- [Azure Business Continuity](https://docs.microsoft.com/azure/architecture/framework/resiliency/overview)
- [Multi-Region Architecture](https://docs.microsoft.com/azure/architecture/reference-architectures/app-service-web-app/multi-region)

---

## 🎯 Next Steps

After mastering this demo, consider:

1. **Scale Up**
   - Add West US 2 as third region
   - Include additional microservices
   - Implement Azure Traffic Manager

2. **Enhanced Security**
   - Add Azure Key Vault for secrets
   - Implement Azure WAF
   - Enable DDoS Protection

3. **Monitoring**
   - Set up Azure Monitor dashboards
   - Configure alerting rules
   - Implement Application Insights

4. **Automation**
   - CI/CD pipeline with GitHub Actions
   - Automated testing
   - Infrastructure validation

5. **Production Hardening**
   - Enable Azure Backup
   - Implement RBAC
   - Add compliance policies

---

## 📊 Demo Checklist

Use this during your team presentation:

- [ ] Infrastructure deployed successfully
- [ ] All 7 tests in `quick-test.ps1` pass
- [ ] Public gateway accessible via browser
- [ ] SQL failover groups show "Primary" role
- [ ] Container apps show "Running" status
- [ ] Explain architecture diagram
- [ ] Demonstrate manual SQL failover
- [ ] Show failover completion (30-60 sec)
- [ ] Verify new primary in East US 2
- [ ] Demonstrate failback to Central US
- [ ] Highlight zero data loss
- [ ] Discuss cost savings vs production
- [ ] Answer questions from team
- [ ] Run `terraform destroy` after demo

---

## 🤝 Contributing

This is a demo project. Feel free to:
- Fork and customize for your needs
- Add additional regions
- Include more services
- Enhance security features

---

## 📝 License

This project is provided as-is for demonstration purposes.

---

## 🎉 Summary

**You now have a complete, cost-optimized, multi-region DR infrastructure!**

### **Key Commands**

```powershell
# Deploy
terraform apply -auto-approve

# Test
.\quick-test.ps1

# Demo DR
.\dr-failover-test.ps1

# Cleanup
terraform destroy -auto-approve
```

### **What You've Built**

✅ 2 Azure regions with VNet peering  
✅ SQL databases with automatic failover  
✅ Container apps across regions  
✅ Geo-redundant storage  
✅ Private endpoints for security  
✅ Complete DR capabilities  

### **Cost**

💵 **$150-250/month** (~$5-8/day)

### **Demo Time**

⏱️ **15-20 minutes** to showcase full DR capabilities

---

**Questions? Issues? Check the troubleshooting section above or review the detailed guides!**

🚀 **Ready to deploy? Run `terraform apply -auto-approve` and start your demo!**


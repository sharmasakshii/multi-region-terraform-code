# 💰 Cost-Optimized Multi-Region DR Demo

This document describes the **cost-optimized infrastructure** designed specifically for demonstrating Disaster Recovery (DR) capabilities to your team.

---

## 🎯 Optimization Summary

### **Before (Full Production)**
- **3 Regions**: Central US, East US 2, West US 2
- **16 Container Apps**: 1 public + 15 private (5 per region)
- **9 Storage Accounts**: 3 types × 3 regions
- **Estimated Cost**: ~$380-680/month

### **After (Demo Optimized)** ✅
- **2 Regions**: Central US (primary), East US 2 (secondary)
- **5 Container Apps**: 1 public + 4 private (2 per region)
- **2 Storage Accounts**: 1 per region
- **Estimated Cost**: ~$150-250/month

### **Cost Savings**: ~60-70% reduction! 💸

---

## 📊 Resource Breakdown

| Resource Type | Count | Details |
|---------------|-------|---------|
| **Resource Group** | 1 | Single RG for all resources |
| **Virtual Networks** | 2 | Central US + East US 2 |
| **Subnets** | 8 | 4 per region (Container Apps, Private Endpoints, Database, Storage) |
| **VNet Peerings** | 2 | Bidirectional peering |
| **NSGs** | 2 | Security rules for Container Apps |
| **Log Analytics** | 2 | One per region |
| **Private DNS Zones** | 3 | Storage, SQL, Container Apps |
| **Storage Accounts** | 2 | App storage only (1 per region) |
| **Storage Containers** | 2 | One per storage account |
| **SQL Servers** | 2 | One per region |
| **SQL Databases** | 4 | 2 per region (App DB + Analytics DB) |
| **Failover Groups** | 2 | App DB + Analytics DB |
| **Container App Envs** | 2 | One per region |
| **Container Apps** | 5 | 1 public gateway + 2 API services + 2 worker services |
| **Private Endpoints** | 4 | Storage (2) + SQL (2) |

**TOTAL: ~42 Azure Resources** (down from ~95!)

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Public Gateway     │
              │   (Central US)       │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │       VNet Peering           │
         │      (Mesh Topology)         │
         └───────────┬──────────┬───────┘
                     │          │
          ┌──────────▼─────┐  ┌▼──────────────┐
          │   Central US   │  │   East US 2   │
          │   (PRIMARY)    │  │  (SECONDARY)  │
          │                │  │               │
          │ • VNet         │  │ • VNet        │
          │ • SQL Primary  │  │ • SQL Replica │
          │ • Storage      │  │ • Storage     │
          │ • 2 Container  │  │ • 2 Container │
          │   Apps         │  │   Apps        │
          └────────────────┘  └───────────────┘
                     │          │
                     └──────────┘
                  SQL Failover Group
              (Automatic replication)
```

---

## 🚀 Deployment Steps

### **1. Deploy Infrastructure**

```powershell
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (takes ~20-30 minutes)
terraform apply -auto-approve
```

### **2. Verify Deployment**

```powershell
# Run the quick test script
.\quick-test.ps1
```

**Expected Output:**
```
✅ Test 1: Resource Group .................... PASS
✅ Test 2: Virtual Networks (2) .............. PASS
✅ Test 3: SQL Servers (2) ................... PASS
✅ Test 4: SQL Failover Groups ............... PASS
✅ Test 5: Storage Accounts (2) .............. PASS
✅ Test 6: Container Apps (5) ................ PASS
✅ Test 7: Public Gateway .................... PASS

📊 Success Rate: 100%
🎉 All tests passed! Your DR infrastructure is ready!
```

### **3. Test Disaster Recovery**

```powershell
# Run the DR failover test
.\dr-failover-test.ps1
```

This script will:
1. ✅ Show current SQL replication status
2. ✅ Perform manual failover from Central US → East US 2
3. ✅ Verify failover completed successfully
4. ✅ Optionally fail back to original primary

---

## 🎭 Demo Script for Your Team

### **Phase 1: Show the Infrastructure (5 minutes)**

```powershell
# 1. Show all resources
az resource list --resource-group demo-rg-demo-cb61e6 --output table

# 2. Show SQL servers in both regions
az sql server list --resource-group demo-rg-demo-cb61e6 --output table

# 3. Show failover groups
az sql failover-group list --resource-group demo-rg-demo-cb61e6 --server demo-sql-centralus-demo --output table

# 4. Show container apps
az containerapp list --resource-group demo-rg-demo-cb61e6 --output table
```

### **Phase 2: Test the Gateway (2 minutes)**

```powershell
# Get gateway URL
$gatewayUrl = terraform output -raw primary_gateway_url

# Open in browser
Start-Process $gatewayUrl

# Or test with PowerShell
Invoke-WebRequest -Uri $gatewayUrl -UseBasicParsing
```

### **Phase 3: Demonstrate DR Failover (10 minutes)**

```powershell
# Run the DR test script
.\dr-failover-test.ps1

# Follow the prompts:
# 1. Review current status
# 2. Confirm failover
# 3. Watch it switch from Central US → East US 2
# 4. Verify new primary
# 5. Optionally fail back
```

**Key Points to Highlight:**
- ✅ **Zero Downtime**: SQL failover happens automatically
- ✅ **Data Protection**: Continuous replication ensures no data loss
- ✅ **Multi-Region**: Apps running in both regions for redundancy
- ✅ **Private Network**: All traffic secured via VNet peering
- ✅ **Cost Effective**: Optimized for demo purposes

---

## 💡 Key DR Features to Demonstrate

### **1. SQL Failover Groups**
- **Automatic Failover**: 60-minute grace period
- **Manual Failover**: Instant (as demonstrated)
- **Read-Write Endpoint**: Automatically updates
- **Continuous Replication**: Real-time sync between regions

### **2. Multi-Region Container Apps**
- **Active-Active**: Apps running in both regions
- **Internal Load Balancing**: Automatic traffic distribution
- **VNet Integration**: Private communication between regions

### **3. Geo-Redundant Storage**
- **GRS Replication**: Data automatically copied to paired region
- **Private Endpoints**: Secure access from Container Apps
- **99.99999999999999% durability** (16 nines!)

---

## 📝 Testing Checklist

Use this checklist during your demo:

- [ ] Infrastructure deployed successfully
- [ ] All 7 tests in `quick-test.ps1` pass
- [ ] Public gateway accessible via browser
- [ ] SQL failover groups show "Primary" role
- [ ] Container apps show "Running" status
- [ ] DR failover test completes successfully
- [ ] Failback to original primary works
- [ ] Team understands DR capabilities

---

## 🔧 Troubleshooting

### **Issue: Container Apps not starting**
```powershell
# Check container app logs
az containerapp logs show --name demo-gateway-demo --resource-group demo-rg-demo-cb61e6
```

### **Issue: SQL failover takes too long**
```powershell
# Check failover group status
az sql failover-group show --name demo-appdb-fg-demo --resource-group demo-rg-demo-cb61e6 --server demo-sql-centralus-demo
```

### **Issue: Gateway not accessible**
```powershell
# Get the latest gateway URL
terraform output primary_gateway_url

# Check if gateway is running
az containerapp show --name demo-gateway-demo --resource-group demo-rg-demo-cb61e6 --query "properties.runningStatus"
```

---

## 💰 Cost Breakdown

### **Monthly Estimate (US Regions)**

| Service | Count | Unit Cost | Monthly Cost |
|---------|-------|-----------|--------------|
| **VNets** | 2 | Free | $0 |
| **VNet Peering** | 2 GB/day | ~$0.01/GB | ~$5 |
| **SQL Databases** | 4 × S2/S3 | ~$30-75/db | ~$180 |
| **Storage Accounts** | 2 × GRS | ~$5/mo | ~$10 |
| **Container Apps** | 5 apps | ~$5-10/app | ~$25-50 |
| **Log Analytics** | 2 × 5GB/mo | ~$2.50/GB | ~$25 |
| **Private Endpoints** | 4 | ~$0.01/hr | ~$3 |

**TOTAL: ~$150-250/month**

### **Cost Optimization Tips**

1. **Use Dev/Test pricing** for SQL if available (-40%)
2. **Stop Container Apps** when not demoing
3. **Use Basic tier SQL** for non-critical demos (-60%)
4. **Reduce Log Analytics retention** to 7 days
5. **Delete when not in use**: `terraform destroy`

---

## 🎉 What's Next?

After your demo, you can:

1. **Scale Up**: Add the 3 additional microservices back
2. **Add More Regions**: Extend to West US 2 or other regions
3. **Enable Auto-Scaling**: Configure scaling rules
4. **Add Monitoring**: Set up alerts and dashboards
5. **Production Hardening**: Add Key Vault, WAF, DDoS protection

---

## 📚 Additional Resources

- **TESTING_GUIDE.md** - Comprehensive testing instructions
- **QUICK_DEPLOY.md** - Quick deployment guide
- **terraform.tfvars** - Configuration values

---

## 🏁 Quick Commands Reference

```powershell
# Deploy
terraform apply -auto-approve

# Test infrastructure
.\quick-test.ps1

# Test DR failover
.\dr-failover-test.ps1

# Get gateway URL
terraform output primary_gateway_url

# Destroy everything
terraform destroy -auto-approve
```

---

**Demo Duration**: ~15-20 minutes  
**Setup Time**: ~30 minutes  
**Cost**: ~$5-8 per day (if running 24/7)  

**Perfect for demonstrating enterprise-grade DR capabilities without breaking the bank!** 💪


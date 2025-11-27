# 🚀 Quick Start - Cost Optimized DR Demo

**3 Simple Steps to Deploy and Demo**

---

## ⚡ Step 1: Deploy Infrastructure (30 minutes)

```powershell
# Navigate to project directory
cd d:\multi-region

# Initialize Terraform
terraform init

# Deploy infrastructure
terraform apply -auto-approve
```

**Wait for completion**: ⏳ ~20-30 minutes

---

## ✅ Step 2: Verify Deployment (2 minutes)

```powershell
# Run quick test
.\quick-test.ps1
```

**Expected**: All 7 tests should pass ✅

---

## 🔥 Step 3: Demo Disaster Recovery (10 minutes)

```powershell
# Run DR failover test
.\dr-failover-test.ps1
```

**What happens**:
1. Shows current SQL replication status
2. Fails over from Central US → East US 2
3. Verifies failover completed
4. Optionally fails back to original primary

---

## 🎯 What You Get

- ✅ **2 Azure Regions** (Central US + East US 2)
- ✅ **5 Container Apps** (1 public gateway + 4 microservices)
- ✅ **SQL Failover Groups** (automatic DR)
- ✅ **Geo-Redundant Storage** (GRS)
- ✅ **Private Networking** (VNet peering + Private Endpoints)
- ✅ **~60% Cost Savings** vs full production setup

---

## 💰 Cost: ~$150-250/month

**Daily cost if running 24/7**: ~$5-8/day

**Cost-saving tip**: Run `terraform destroy` when not demoing!

---

## 📊 Resource Count

| Resource | Count |
|----------|-------|
| VNets | 2 |
| SQL Servers | 2 |
| SQL Databases | 4 |
| Storage Accounts | 2 |
| Container Apps | 5 |
| Private Endpoints | 4 |
| **Total Resources** | **~42** |

---

## 🔗 Useful Commands

```powershell
# Get gateway URL
terraform output primary_gateway_url

# Open gateway in browser
Start-Process (terraform output -raw primary_gateway_url)

# List all resources
az resource list --resource-group demo-rg-demo-cb61e6 --output table

# Check SQL failover status
az sql failover-group show `
  --name demo-appdb-fg-demo `
  --resource-group demo-rg-demo-cb61e6 `
  --server demo-sql-centralus-demo

# Delete everything
terraform destroy -auto-approve
```

---

## 📖 Full Documentation

- **COST-OPTIMIZED-DEMO.md** - Complete demo guide
- **TESTING_GUIDE.md** - Detailed testing instructions
- **terraform.tfvars** - Configuration settings

---

## ⚠️ Important Notes

1. **Azure Login**: Ensure `az login` is completed
2. **Terraform Version**: Requires Terraform 1.5.0+
3. **Subscription**: Verify sufficient quota for resources
4. **Region Availability**: Central US and East US 2 must support SQL

---

**Ready to demo? Run the 3 steps above!** 🎉


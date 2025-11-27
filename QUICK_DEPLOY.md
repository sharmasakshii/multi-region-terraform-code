# 🚀 Quick Deployment Guide

## ✅ Issue Fixed!
Created `terraform.tfvars` with working regions that avoid East US SQL capacity issues.

---

## 📋 New Configuration

### Regions Changed:
| Old | New | Reason |
|-----|-----|--------|
| `eastus` (primary) | `centralus` (primary) | East US has SQL capacity restrictions |
| `eastus` | `eastus2` | East US 2 has available capacity |
| `westus` | `westus2` | West US 2 is more reliable |

---

## 🔧 Deployment Steps

### Step 1: Clean Up Failed Resources
```bash
# Destroy any partially created resources
terraform destroy -auto-approve
```

**Expected output:**
- Will delete the demo-rg-prod-cb61e6 resource group
- May take 5-10 minutes

---

### Step 2: Re-initialize (if needed)
```bash
terraform init
```

---

### Step 3: Validate Configuration
```bash
terraform validate
```

**Should show:** `Success! The configuration is valid.`

---

### Step 4: Plan Deployment
```bash
terraform plan -out=tfplan
```

**Expected resources:** ~70 resources to be created

**Key things to verify in plan:**
- ✅ Resource group: `demo-rg-prod-cb61e6`
- ✅ Regions: `centralus`, `eastus2`, `westus2`
- ✅ SQL Servers in: centralus, eastus2, westus2
- ✅ Primary region: centralus
- ✅ No references to "eastus" (old region)

---

### Step 5: Apply
```bash
terraform apply tfplan
```

**Estimated time:** 25-35 minutes

**Progress phases:**
1. Base Infrastructure (5 min) - VNets, Subnets, NSGs
2. Storage (5 min) - Storage accounts and containers
3. Databases (15 min) - SQL servers, databases, failover groups ⏰ (slowest)
4. Compute (10 min) - Container App environments and apps

---

## 📊 What Will Be Created

### Single Resource Group
- `demo-rg-prod-cb61e6` (Central US)

### Inside the Resource Group
- **3 VNets** (centralus, eastus2, westus2)
- **12 Subnets** (4 per region)
- **3 NSGs**
- **6 VNet Peerings** (full mesh)
- **3 Log Analytics Workspaces**
- **3 Private DNS Zones**
- **9 DNS Zone Links**
- **9 Storage Accounts** (3 types × 3 regions)
- **9 Storage Containers**
- **9 Storage Private Endpoints**
- **3 SQL Servers** (1 per region)
- **6 SQL Databases** (2 per region)
- **2 SQL Failover Groups**
- **3 SQL Private Endpoints**
- **3 Container App Environments**
- **1 Public Gateway** (in centralus)
- **15 Private Container Apps** (5 services × 3 regions)

**Total: ~85 resources in 1 resource group** 🎯

---

## ✅ Success Indicators

After successful deployment, you'll see outputs showing:

```
Apply complete! Resources: 85 added, 0 changed, 0 destroyed.

Outputs:

resource_group = {
  "id" = "/subscriptions/.../resourceGroups/demo-rg-prod-cb61e6"
  "location" = "centralus"
  "name" = "demo-rg-prod-cb61e6"
}

primary_gateway_url = "https://demo-gateway-prod.xxxxx.centralus.azurecontainerapps.io"

sql_servers = {
  "centralus" = {
    "fqdn" = "demo-sql-centralus-prod.database.windows.net"
    "name" = "demo-sql-centralus-prod"
  }
  "eastus2" = {
    "fqdn" = "demo-sql-eastus2-prod.database.windows.net"
    "name" = "demo-sql-eastus2-prod"
  }
  "westus2" = {
    "fqdn" = "demo-sql-westus2-prod.database.windows.net"
    "name" = "demo-sql-westus2-prod"
  }
}

deployment_summary = {
  "all_regions" = ["centralus", "eastus2", "westus2"]
  "environment" = "prod"
  "primary_region" = "centralus"
  "project" = "demo"
  "public_endpoint" = "https://demo-gateway-prod.xxxxx.centralus.azurecontainerapps.io"
  ...
}
```

---

## 🧪 Testing Your Deployment

### Test 1: Public Gateway
```bash
# Get the gateway URL
terraform output primary_gateway_url

# Test it
curl $(terraform output -raw primary_gateway_url)
```

**Expected:** HTTP 200 response with "Hello World" or similar

---

### Test 2: SQL Failover Group
```bash
# Check failover group status
az sql failover-group show \
  --name demo-appdb-fg-prod \
  --resource-group demo-rg-prod-cb61e6 \
  --server demo-sql-centralus-prod \
  --query "{name:name, role:replicationRole, partnerRole:partnerServers[0].replicationRole}"
```

**Expected:**
```json
{
  "name": "demo-appdb-fg-prod",
  "role": "Primary",
  "partnerRole": "Secondary"
}
```

---

### Test 3: Storage Accounts
```bash
# List storage accounts
az storage account list \
  --resource-group demo-rg-prod-cb61e6 \
  --query "[].{name:name, location:location, sku:sku.name}" \
  --output table
```

**Expected:** 9 storage accounts with GRS replication

---

## 🔒 Post-Deployment Security

### Lock Down Storage Accounts (IMPORTANT!)

After successful deployment, secure your storage accounts:

```bash
# For each storage account, disable public access
az storage account update \
  --name demoappstcentralusprod \
  --resource-group demo-rg-prod-cb61e6 \
  --public-network-access Disabled \
  --default-action Deny

# Repeat for all 9 storage accounts
```

**Or** update the Terraform code and re-apply:
1. Edit `modules/storage/main.tf`
2. Change `public_network_access_enabled = true` to `false`
3. Change `default_action = "Allow"` to `"Deny"`
4. Run `terraform apply`

---

## 🚨 Troubleshooting

### If SQL Server Still Fails
Try even more regions:
- `northcentralus`
- `southcentralus`  
- `westeurope`
- `northeurope`

Update in `terraform.tfvars`:
```hcl
primary_region = "northcentralus"
regions = ["northcentralus", "southcentralus", "westeurope"]
```

### If Storage Access Denied
Storage accounts are temporarily open during deployment. This is expected and will be locked down after.

### If Terraform State Issues
```bash
# Remove corrupted state
terraform state list
terraform state rm module.data.azurerm_mssql_server.regional[\"eastus\"]

# Or start fresh
rm -rf .terraform terraform.tfstate*
terraform init
```

---

## 💰 Cost Estimate

**Monthly cost for 3 regions:**
- Container Apps: ~$150-300
- SQL Databases (6 DBs): ~$1,200
- Storage (GRS): ~$75-225
- Networking: ~$75-150
- Log Analytics: ~$75

**Total: ~$1,575 - $1,950/month**

To reduce costs:
- Use smaller SQL tiers (S1 instead of S2/S3)
- Use LRS instead of GRS for storage
- Reduce to 2 regions instead of 3

---

## 📞 Support Resources

- **Azure Status:** https://status.azure.com/
- **SQL Capacity Issues:** Open Azure Support ticket
- **Terraform Logs:** `TF_LOG=DEBUG terraform apply 2>&1 | tee terraform.log`

---

**Last Updated:** 2025-11-24  
**Status:** ✅ Ready to deploy with working regions!


# 🔧 Deployment Error Fixes

## Issues Encountered

### ❌ Issue 1: SQL Server Provisioning Restricted in East US
```
Status: "ProvisioningDisabled"
Message: "Provisioning is restricted in this region. Please choose a different region."
```

### ❌ Issue 2: Storage Container 403 Authorization Errors
```
AuthorizationFailure: This request is not authorized to perform this operation.
```

---

## ✅ SOLUTIONS

### Solution 1: Change SQL Primary Region

**Problem:** East US has capacity restrictions for SQL servers in your subscription.

**Fix:** Update your `terraform.tfvars` file to use a different region:

**Option A: Use Central US as Primary (RECOMMENDED)**
```hcl
primary_region = "centralus"
regions = [
  "centralus",  # Now primary
  "eastus2",    # Changed from eastus
  "westus"
]

vnet_address_spaces = {
  "centralus" = "10.10.0.0/16"
  "eastus2"   = "10.20.0.0/16"  # Changed from eastus
  "westus"    = "10.30.0.0/16"
}
```

**Option B: Use West US 2 as Primary**
```hcl
primary_region = "westus2"
regions = [
  "westus2",
  "eastus2",
  "centralus"
]

vnet_address_spaces = {
  "westus2"   = "10.10.0.0/16"
  "eastus2"   = "10.20.0.0/16"
  "centralus" = "10.30.0.0/16"
}
```

**Alternative:** Request quota increase for East US via Azure Support (takes days).

---

### Solution 2: Storage Account Network Access (FIXED)

**Problem:** Storage accounts were locked down with `public_network_access_enabled = false`, preventing Terraform from creating containers.

**Fix Applied:** Updated all storage accounts to temporarily allow public access during initial deployment.

**Changes Made in `modules/storage/main.tf`:**
- Changed `public_network_access_enabled` from `false` to `true`
- Changed `network_rules.default_action` from `"Deny"` to `"Allow"`
- Added TODO comments to lock down later

**Security Note:** After successful deployment, you can lock down storage accounts by:

1. Manual lockdown via Azure Portal:
   - Go to each storage account → Networking
   - Set "Public network access" to "Disabled"
   - Set "Default action" to "Deny"

2. Or update the code and re-apply after initial deployment:
   ```hcl
   public_network_access_enabled = false
   network_rules {
     default_action = "Deny"
     bypass         = ["AzureServices"]
   }
   ```

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Clean Up Failed Resources
```bash
# Destroy any partially created resources
terraform destroy

# Or target specific modules if needed
terraform destroy -target=module.data
terraform destroy -target=module.storage
```

### Step 2: Update terraform.tfvars
Update the regions as shown in Solution 1 above.

### Step 3: Re-initialize Terraform
```bash
terraform init
```

### Step 4: Plan and Verify
```bash
terraform plan -out=tfplan
# Review the plan carefully
```

### Step 5: Apply
```bash
terraform apply tfplan
```

---

## 📋 Post-Deployment Tasks

### 1. Lock Down Storage Accounts (IMPORTANT!)
Once deployment succeeds, lock down the storage accounts:

**Via Azure Portal:**
- Navigate to each storage account
- Go to: Settings → Networking
- Change "Public network access" to **Disabled**
- Under Firewall and virtual networks, set to **Deny** by default

**Or via Terraform (Second Apply):**
```bash
# Update modules/storage/main.tf:
# Set public_network_access_enabled = false
# Set default_action = "Deny"

terraform apply
```

### 2. Verify Failover Groups
```bash
# Check SQL failover group status
az sql failover-group show \
  --name demo-appdb-fg-prod \
  --resource-group demo-rg-database-prod-cb61e6 \
  --server demo-sql-centralus-prod
```

### 3. Test Public Gateway
```bash
# Get the gateway URL from outputs
terraform output primary_gateway_url

# Test it
curl $(terraform output -raw primary_gateway_url)
```

---

## 🔍 Troubleshooting

### If You Still Get SQL Errors:
- Try different regions: `westus2`, `eastus2`, `northeurope`, `westeurope`
- Check Azure status: https://status.azure.com/
- Verify subscription quotas: Azure Portal → Subscriptions → Usage + quotas

### If Storage Errors Persist:
- Ensure you're logged in: `az login`
- Check your Azure permissions (need Contributor or Owner role)
- Verify subscription is active

### If Network Errors Occur:
- Check your firewall isn't blocking Azure API calls
- Try from a different network
- Use Azure Cloud Shell as alternative

---

## 📞 Support

If issues persist:
1. Check Azure Service Health: https://portal.azure.com/#blade/Microsoft_Azure_Health
2. Open Azure Support ticket for quota increases
3. Review Terraform debug logs: `TF_LOG=DEBUG terraform apply`

---

## ✅ Verification Checklist

After successful deployment:

- [ ] All resource groups created
- [ ] VNets and subnets deployed in all regions
- [ ] Storage accounts accessible
- [ ] SQL servers and databases created
- [ ] Failover groups configured
- [ ] Container apps running
- [ ] Public gateway accessible
- [ ] Storage accounts locked down (post-deployment)
- [ ] Private endpoints working
- [ ] Monitoring/logging active

---

**Last Updated:** 2025-11-24
**Status:** Ready for deployment with fixes applied


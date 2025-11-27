# 🧪 Multi-Region DR Testing Guide

## 📋 Pre-Deployment Testing

### Step 1: Validate Terraform Configuration
```bash
# Validate syntax and configuration
terraform validate
```
**Expected:** ✅ `Success! The configuration is valid.`

---

### Step 2: Review the Plan
```bash
# Generate and review execution plan
terraform plan -out=tfplan

# Count resources to be created
terraform plan | grep "Plan:"
```
**Expected:** `Plan: ~85 to add, 0 to change, 0 to destroy`

---

### Step 3: Check for Correct Naming
```bash
# Search for environment in plan
terraform plan | grep -i "demo-rg-demo-cb61e6"
terraform plan | grep -i "demo-sql-centralus-demo"
```
**Expected:** Should see resources with `-demo-` naming

---

## 🚀 Deployment

```bash
# Deploy infrastructure
terraform apply tfplan

# Or with auto-approve (not recommended for production)
terraform apply -auto-approve
```

**Duration:** 25-35 minutes

Monitor for:
- ✅ No errors
- ✅ All resources created successfully
- ✅ Outputs displayed at the end

---

## ✅ Post-Deployment Testing

### Test 1: Verify Resource Group Created

```bash
# Check resource group exists
az group show --name demo-rg-demo-cb61e6 --query "{name:name, location:location, provisioningState:properties.provisioningState}"
```

**Expected Output:**
```json
{
  "name": "demo-rg-demo-cb61e6",
  "location": "centralus",
  "provisioningState": "Succeeded"
}
```

---

### Test 2: List All Resources

```bash
# Count all resources in the resource group
az resource list --resource-group demo-rg-demo-cb61e6 --query "length(@)"

# List all resources with their types
az resource list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, type:type, location:location}" --output table
```

**Expected:** ~85 resources

---

### Test 3: Test Public Gateway (Container App)

```bash
# Get the public gateway URL from Terraform outputs
terraform output primary_gateway_url

# Test the endpoint
curl $(terraform output -raw primary_gateway_url)

# Or with verbose output
curl -v $(terraform output -raw primary_gateway_url)
```

**Expected:**
```
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
...
```

**Alternative test in PowerShell:**
```powershell
$url = terraform output -raw primary_gateway_url
Invoke-WebRequest -Uri $url
```

---

### Test 4: Verify VNets and Peering

```bash
# List all VNets
az network vnet list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, addressSpace:addressSpace.addressPrefixes[0]}" --output table

# Check VNet peering status
az network vnet peering list --resource-group demo-rg-demo-cb61e6 --vnet-name demo-vnet-centralus-demo --query "[].{name:name, peeringState:peeringState, remoteVnet:remoteVirtualNetwork.id}" --output table
```

**Expected:**
- 3 VNets (centralus, eastus2, westus2)
- 6 peering connections
- All peering state: `Connected`

---

### Test 5: Verify SQL Servers and Databases

```bash
# List SQL servers
az sql server list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, state:state, version:version}" --output table

# List databases on primary server
az sql db list --resource-group demo-rg-demo-cb61e6 --server demo-sql-centralus-demo --query "[?name!='master'].{name:name, status:status, sku:sku.name, maxSizeBytes:maxSizeBytes}" --output table
```

**Expected:**
- 3 SQL servers (one per region)
- 2 databases per server (app database, analytics database)
- All status: `Online`

---

### Test 6: Test SQL Failover Groups

```bash
# Check app database failover group
az sql failover-group show \
  --name demo-appdb-fg-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --server demo-sql-centralus-demo \
  --query "{name:name, primaryServer:replicationRole, secondaryServer:partnerServers[0].replicationRole, replicationState:replicationState}" \
  --output json

# Check analytics database failover group
az sql failover-group show \
  --name demo-analyticsdb-fg-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --server demo-sql-centralus-demo \
  --query "{name:name, primaryServer:replicationRole, secondaryServer:partnerServers[0].replicationRole, replicationState:replicationState}" \
  --output json
```

**Expected:**
```json
{
  "name": "demo-appdb-fg-demo",
  "primaryServer": "Primary",
  "secondaryServer": "Secondary",
  "replicationState": "CATCH_UP" or "SEEDING"
}
```

---

### Test 7: Test SQL Connection String (from Terraform outputs)

```bash
# Get connection strings (marked as sensitive)
terraform output sql_connection_strings

# Test connection using SQL tools or Azure Data Studio
# Connection string format: 
# Server=demo-appdb-fg-demo.database.windows.net;Database=demo-appdb-centralus;User ID=sqladmin;Password=...
```

---

### Test 8: Verify Storage Accounts

```bash
# List storage accounts
az storage account list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, sku:sku.name, primaryEndpoints:primaryEndpoints.blob}" --output table

# Check a specific storage account status
az storage account show --name demoappstcentralusdemo --resource-group demo-rg-demo-cb61e6 --query "{name:name, provisioningState:provisioningState, statusOfPrimary:statusOfPrimary, allowBlobPublicAccess:allowBlobPublicAccess}"
```

**Expected:**
- 9 storage accounts (3 types × 3 regions)
- SKU: `Standard_GRS`
- `allowBlobPublicAccess`: false (after locking down)

---

### Test 9: List Storage Containers

```bash
# List containers in app storage account (need to use connection string or key)
az storage container list --account-name demoappstcentralusdemo --auth-mode login --query "[].{name:name, publicAccess:properties.publicAccess}" --output table
```

**Expected:**
- Container: `app-data` (private)
- Container: `media-files` (private)
- Container: `application-logs` (private)

---

### Test 10: Verify Container App Environments

```bash
# List Container App Environments
az containerapp env list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, provisioningState:properties.provisioningState}" --output table
```

**Expected:**
- 3 environments (one per region)
- All `provisioningState`: `Succeeded`

---

### Test 11: List All Container Apps

```bash
# List all container apps
az containerapp list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, fqdn:properties.configuration.ingress.fqdn, external:properties.configuration.ingress.external}" --output table
```

**Expected:**
- 16 container apps total:
  - 1 public gateway (external: true)
  - 15 private services (external: false, 5 services × 3 regions)

---

### Test 12: Test Container App Logs

```bash
# View logs from the public gateway
az containerapp logs show \
  --name demo-gateway-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --follow

# View logs from a specific private app
az containerapp logs show \
  --name demo-api-centralus-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --tail 50
```

---

### Test 13: Verify Private Endpoints

```bash
# List all private endpoints
az network private-endpoint list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, connectionState:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" --output table
```

**Expected:**
- 15 private endpoints (3 storage + 3 SQL per region)
- All `connectionState`: `Approved`

---

### Test 14: Verify Private DNS Zones

```bash
# List private DNS zones
az network private-dns zone list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, numberOfRecordSets:numberOfRecordSets}" --output table

# List DNS records in SQL DNS zone
az network private-dns record-set a list --resource-group demo-rg-demo-cb61e6 --zone-name privatelink.database.windows.net --output table
```

**Expected:**
- 3 private DNS zones
- Multiple A records for private endpoints

---

### Test 15: Verify Log Analytics Workspaces

```bash
# List Log Analytics workspaces
az monitor log-analytics workspace list --resource-group demo-rg-demo-cb61e6 --query "[].{name:name, location:location, retentionInDays:retentionInDays}" --output table

# Query logs from workspace (example)
az monitor log-analytics query \
  --workspace demo-law-centralus-demo \
  --analytics-query "ContainerAppConsoleLogs_CL | take 10" \
  --output table
```

---

## 🔥 Disaster Recovery Testing

### Test 16: Manual SQL Failover Test

⚠️ **Warning:** This will cause a brief outage!

```bash
# Initiate manual failover
az sql failover-group set-primary \
  --name demo-appdb-fg-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --server demo-sql-eastus2-demo

# Check new primary
az sql failover-group show \
  --name demo-appdb-fg-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --server demo-sql-eastus2-demo \
  --query "{name:name, primaryRole:replicationRole}"
```

**Expected:**
- Failover completes in 1-2 minutes
- Primary switches to eastus2
- Application can still connect using failover group endpoint

**Failback:**
```bash
# Fail back to original primary
az sql failover-group set-primary \
  --name demo-appdb-fg-demo \
  --resource-group demo-rg-demo-cb61e6 \
  --server demo-sql-centralus-demo
```

---

### Test 17: Simulate Regional Outage

**Scenario:** Central US region goes down

**Test:**
1. Container apps in eastus2 and westus2 should still be running
2. SQL fails over to eastus2 automatically (after 60 min grace period)
3. Storage is still accessible in other regions

**Verification:**
```bash
# Check container apps in other regions
az containerapp show --name demo-api-eastus2-demo --resource-group demo-rg-demo-cb61e6 --query "properties.runningStatus"
az containerapp show --name demo-api-westus2-demo --resource-group demo-rg-demo-cb61e6 --query "properties.runningStatus"
```

---

## 📊 Monitoring & Metrics

### Test 18: View Container App Metrics

```bash
# Get metrics for gateway app
az monitor metrics list \
  --resource "/subscriptions/.../resourceGroups/demo-rg-demo-cb61e6/providers/Microsoft.App/containerApps/demo-gateway-demo" \
  --metric "Requests" \
  --start-time 2025-11-24T00:00:00Z \
  --end-time 2025-11-24T23:59:59Z \
  --interval PT1H
```

---

### Test 19: View SQL Database Metrics

```bash
# Get DTU usage
az monitor metrics list \
  --resource "/subscriptions/.../resourceGroups/demo-rg-demo-cb61e6/providers/Microsoft.Sql/servers/demo-sql-centralus-demo/databases/demo-appdb-centralus" \
  --metric "dtu_consumption_percent" \
  --start-time 2025-11-24T00:00:00Z \
  --end-time 2025-11-24T23:59:59Z
```

---

## 🧹 Cleanup Testing

### Test 20: Destroy Infrastructure

```bash
# View what will be destroyed
terraform plan -destroy

# Destroy everything
terraform destroy

# Verify resource group is deleted
az group show --name demo-rg-demo-cb61e6
```

**Expected:**
- All resources deleted
- Resource group removed
- Takes ~15-20 minutes

---

## 📋 Quick Test Checklist

After deployment, run this quick validation:

```bash
#!/bin/bash
echo "🧪 Quick Multi-Region DR Test"
echo "=============================="

echo "✅ Testing Resource Group..."
az group show --name demo-rg-demo-cb61e6 --query name -o tsv && echo "  ✓ RG exists" || echo "  ✗ RG missing"

echo "✅ Testing VNets..."
VNET_COUNT=$(az network vnet list --resource-group demo-rg-demo-cb61e6 --query "length(@)")
echo "  Found $VNET_COUNT VNets (expected: 3)"

echo "✅ Testing SQL Servers..."
SQL_COUNT=$(az sql server list --resource-group demo-rg-demo-cb61e6 --query "length(@)")
echo "  Found $SQL_COUNT SQL Servers (expected: 3)"

echo "✅ Testing Storage Accounts..."
STORAGE_COUNT=$(az storage account list --resource-group demo-rg-demo-cb61e6 --query "length(@)")
echo "  Found $STORAGE_COUNT Storage Accounts (expected: 9)"

echo "✅ Testing Container Apps..."
APP_COUNT=$(az containerapp list --resource-group demo-rg-demo-cb61e6 --query "length(@)")
echo "  Found $APP_COUNT Container Apps (expected: 16)"

echo "✅ Testing Public Gateway..."
GATEWAY_URL=$(terraform output -raw primary_gateway_url)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $GATEWAY_URL)
echo "  Gateway HTTP Status: $HTTP_STATUS (expected: 200)"

echo ""
echo "=============================="
echo "✅ Quick test complete!"
```

Save as `test.sh`, make executable with `chmod +x test.sh`, and run: `./test.sh`

---

## 🎯 Success Criteria

Your deployment is successful if:

- ✅ All ~85 resources created
- ✅ Public gateway returns HTTP 200
- ✅ SQL failover groups show Primary/Secondary roles
- ✅ VNet peering status is `Connected`
- ✅ All container apps are `Running`
- ✅ Private endpoints are `Approved`
- ✅ Storage accounts accessible
- ✅ Logs visible in Log Analytics
- ✅ Manual failover works within 2 minutes
- ✅ Resources tagged correctly with `cb61e6`

---

## 📞 Troubleshooting

### Issue: Gateway returns 404
**Fix:** Wait 2-3 minutes for app to start, check logs

### Issue: SQL connection fails
**Fix:** Check firewall rules, verify private endpoint, use failover group endpoint

### Issue: Can't access storage
**Fix:** Check network rules, verify you have RBAC permissions

### Issue: Container app not running
**Fix:** Check logs with `az containerapp logs show`

---

**Happy Testing! 🚀**


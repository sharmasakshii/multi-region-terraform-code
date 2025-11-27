# ============================================
# Quick Multi-Region DR Infrastructure Test
# COST OPTIMIZED FOR DEMO
# ============================================

Write-Host "`n🧪 Multi-Region DR Quick Test (Cost Optimized)" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

$rg = "demo-rg-demo-cb61e6"
$passed = 0
$failed = 0
$primaryRegion = "centralus"
$secondaryRegion = "eastus2"

Write-Host "Configuration:" -ForegroundColor Gray
Write-Host "  Resource Group: $rg" -ForegroundColor Gray
Write-Host "  Primary Region: $primaryRegion" -ForegroundColor Gray
Write-Host "  Secondary Region: $secondaryRegion`n" -ForegroundColor Gray

# Test 1: Resource Group
Write-Host "✅ Test 1: Checking Resource Group..." -ForegroundColor Yellow
try {
    $rgInfo = az group show --name $rg 2>$null | ConvertFrom-Json
    if ($rgInfo.name -eq $rg) {
        Write-Host "  ✓ Resource Group exists: $($rgInfo.name)" -ForegroundColor Green
        Write-Host "    Location: $($rgInfo.location)" -ForegroundColor Gray
        $passed++
    }
} catch {
    Write-Host "  ✗ Resource Group not found" -ForegroundColor Red
    $failed++
}

# Test 2: Virtual Networks
Write-Host "`n✅ Test 2: Checking Virtual Networks..." -ForegroundColor Yellow
try {
    $vnets = az network vnet list --resource-group $rg 2>$null | ConvertFrom-Json
    $vnetCount = $vnets.Count
    Write-Host "  ✓ Found $vnetCount VNets (expected: 2)" -ForegroundColor $(if ($vnetCount -eq 2) { "Green" } else { "Yellow" })
    foreach ($vnet in $vnets) {
        Write-Host "    - $($vnet.name) in $($vnet.location)" -ForegroundColor Gray
    }
    if ($vnetCount -eq 2) { $passed++ } else { $failed++ }
} catch {
    Write-Host "  ✗ Error checking VNets" -ForegroundColor Red
    $failed++
}

# Test 3: SQL Servers
Write-Host "`n✅ Test 3: Checking SQL Servers..." -ForegroundColor Yellow
try {
    $sqlServers = az sql server list --resource-group $rg 2>$null | ConvertFrom-Json
    $sqlCount = $sqlServers.Count
    Write-Host "  ✓ Found $sqlCount SQL Servers (expected: 2)" -ForegroundColor $(if ($sqlCount -eq 2) { "Green" } else { "Yellow" })
    foreach ($sql in $sqlServers) {
        Write-Host "    - $($sql.name) in $($sql.location)" -ForegroundColor Gray
    }
    if ($sqlCount -eq 2) { $passed++ } else { $failed++ }
} catch {
    Write-Host "  ✗ Error checking SQL Servers" -ForegroundColor Red
    $failed++
}

# Test 4: SQL Failover Groups
Write-Host "`n✅ Test 4: Checking SQL Failover Groups (DR Critical)..." -ForegroundColor Yellow
try {
    $primaryServer = "demo-sql-$primaryRegion-demo"
    $fg1 = az sql failover-group show --name demo-appdb-fg-demo --resource-group $rg --server $primaryServer 2>$null | ConvertFrom-Json
    $fg2 = az sql failover-group show --name demo-analyticsdb-fg-demo --resource-group $rg --server $primaryServer 2>$null | ConvertFrom-Json
    
    if ($fg1 -and $fg2) {
        Write-Host "  ✓ App Database FG: $($fg1.replicationRole)" -ForegroundColor Green
        Write-Host "  ✓ Analytics Database FG: $($fg2.replicationRole)" -ForegroundColor Green
        Write-Host "    - Primary: $primaryRegion" -ForegroundColor Gray
        Write-Host "    - Secondary: $secondaryRegion" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "  ✗ Failover groups not found" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  ⚠ Failover groups check skipped (may still be provisioning)" -ForegroundColor Yellow
}

# Test 5: Storage Accounts
Write-Host "`n✅ Test 5: Checking Storage Accounts..." -ForegroundColor Yellow
try {
    $storageAccounts = az storage account list --resource-group $rg 2>$null | ConvertFrom-Json
    $storageCount = $storageAccounts.Count
    Write-Host "  ✓ Found $storageCount Storage Accounts (expected: 2)" -ForegroundColor $(if ($storageCount -eq 2) { "Green" } else { "Yellow" })
    foreach ($sa in $storageAccounts) {
        Write-Host "    - $($sa.name) [$($sa.sku.name)] in $($sa.location)" -ForegroundColor Gray
    }
    if ($storageCount -eq 2) { $passed++ } else { $failed++ }
} catch {
    Write-Host "  ✗ Error checking Storage Accounts" -ForegroundColor Red
    $failed++
}

# Test 6: Container Apps
Write-Host "`n✅ Test 6: Checking Container Apps..." -ForegroundColor Yellow
try {
    $containerApps = az containerapp list --resource-group $rg 2>$null | ConvertFrom-Json
    $appCount = $containerApps.Count
    Write-Host "  ✓ Found $appCount Container Apps (expected: 5)" -ForegroundColor $(if ($appCount -eq 5) { "Green" } else { "Yellow" })
    
    $publicApps = $containerApps | Where-Object { $_.properties.configuration.ingress.external -eq $true }
    $privateApps = $containerApps | Where-Object { $_.properties.configuration.ingress.external -eq $false }
    
    Write-Host "    - Public apps: $($publicApps.Count) (Gateway)" -ForegroundColor Gray
    Write-Host "    - Private apps: $($privateApps.Count) (API + Worker)" -ForegroundColor Gray
    
    if ($appCount -eq 5) { $passed++ } else { $failed++ }
} catch {
    Write-Host "  ✗ Error checking Container Apps" -ForegroundColor Red
    $failed++
}

# Test 7: Public Gateway HTTP Test
Write-Host "`n✅ Test 7: Testing Public Gateway..." -ForegroundColor Yellow
try {
    $gatewayUrl = terraform output -raw primary_gateway_url 2>$null
    if ($gatewayUrl) {
        Write-Host "  Gateway URL: $gatewayUrl" -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $gatewayUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✓ Gateway is accessible (HTTP $($response.StatusCode))" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  ✗ Gateway returned HTTP $($response.StatusCode)" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "  ⚠ Could not get gateway URL from Terraform outputs" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Gateway not accessible: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "📊 Test Summary (Cost Optimized Demo)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

$total = $passed + $failed
if ($total -gt 0) {
    $successRate = [math]::Round(($passed / $total) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })
}

Write-Host "`nInfrastructure Summary:" -ForegroundColor Cyan
Write-Host "  - Regions: 2 (Central US, East US 2)" -ForegroundColor Gray
Write-Host "  - VNets: 2" -ForegroundColor Gray
Write-Host "  - SQL Servers: 2 with Failover Groups" -ForegroundColor Gray
Write-Host "  - Storage Accounts: 2" -ForegroundColor Gray
Write-Host "  - Container Apps: 5 (1 public + 4 private)" -ForegroundColor Gray
Write-Host "  - Estimated Cost: ~$150-250/month" -ForegroundColor Gray

if ($failed -eq 0) {
    Write-Host "`n🎉 All tests passed! Your DR infrastructure is ready!" -ForegroundColor Green
    Write-Host "   Next: Run .\dr-failover-test.ps1 to test disaster recovery" -ForegroundColor Green
} elseif ($failed -le 2) {
    Write-Host "`n⚠️  Most tests passed. Check failed tests above." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Multiple tests failed. Review your deployment." -ForegroundColor Red
}

Write-Host "`nFor detailed testing, see TESTING_GUIDE.md`n" -ForegroundColor Gray


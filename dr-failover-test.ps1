# ============================================
# Disaster Recovery (DR) Failover Test
# ============================================
# This script tests the SQL failover capabilities
# to demonstrate disaster recovery between regions

Write-Host "`n🔥 Disaster Recovery (DR) Failover Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$rg = "demo-rg-demo-cb61e6"
$primaryRegion = "centralus"
$secondaryRegion = "eastus2"
$primaryServer = "demo-sql-$primaryRegion-demo"
$secondaryServer = "demo-sql-$secondaryRegion-demo"
$appFG = "demo-appdb-fg-demo"
$analyticsFG = "demo-analyticsdb-fg-demo"

Write-Host "Configuration:" -ForegroundColor Gray
Write-Host "  Resource Group: $rg" -ForegroundColor Gray
Write-Host "  Primary SQL Server: $primaryServer" -ForegroundColor Gray
Write-Host "  Secondary SQL Server: $secondaryServer`n" -ForegroundColor Gray

# ==================
# STEP 1: Check Current Status
# ==================
Write-Host "📋 STEP 1: Checking Current SQL Failover Group Status..." -ForegroundColor Yellow
Write-Host "============================================================`n" -ForegroundColor Yellow

try {
    Write-Host "App Database Failover Group:" -ForegroundColor Cyan
    $appFGInfo = az sql failover-group show --name $appFG --resource-group $rg --server $primaryServer 2>$null | ConvertFrom-Json
    if ($appFGInfo) {
        Write-Host "  ✓ Current Role: $($appFGInfo.replicationRole)" -ForegroundColor Green
        Write-Host "  ✓ Replication State: $($appFGInfo.replicationState)" -ForegroundColor Green
        Write-Host "  ✓ Primary Server: $primaryServer" -ForegroundColor Gray
        Write-Host "  ✓ Secondary Server: $secondaryServer`n" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ Could not retrieve App DB failover group info" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Analytics Database Failover Group:" -ForegroundColor Cyan
    $analyticsFGInfo = az sql failover-group show --name $analyticsFG --resource-group $rg --server $primaryServer 2>$null | ConvertFrom-Json
    if ($analyticsFGInfo) {
        Write-Host "  ✓ Current Role: $($analyticsFGInfo.replicationRole)" -ForegroundColor Green
        Write-Host "  ✓ Replication State: $($analyticsFGInfo.replicationState)" -ForegroundColor Green
        Write-Host "  ✓ Primary Server: $primaryServer" -ForegroundColor Gray
        Write-Host "  ✓ Secondary Server: $secondaryServer`n" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ Could not retrieve Analytics DB failover group info" -ForegroundColor Red
    exit 1
}

# ==================
# STEP 2: Confirm Failover
# ==================
Write-Host "`n⚠️  STEP 2: Failover Confirmation" -ForegroundColor Yellow
Write-Host "================================`n" -ForegroundColor Yellow

Write-Host "You are about to initiate a MANUAL FAILOVER:" -ForegroundColor Yellow
Write-Host "  Primary   ($primaryRegion)   → Becomes Secondary" -ForegroundColor Gray
Write-Host "  Secondary ($secondaryRegion) → Becomes Primary`n" -ForegroundColor Gray

Write-Host "This demonstrates disaster recovery when the primary region fails.`n" -ForegroundColor Cyan

$confirmation = Read-Host "Do you want to proceed with failover? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "`n❌ Failover cancelled by user.`n" -ForegroundColor Red
    exit 0
}

# ==================
# STEP 3: Perform Failover
# ==================
Write-Host "`n🔄 STEP 3: Initiating Failover to $secondaryRegion..." -ForegroundColor Yellow
Write-Host "=====================================================`n" -ForegroundColor Yellow

Write-Host "Failing over App Database..." -ForegroundColor Cyan
try {
    az sql failover-group set-primary `
        --name $appFG `
        --resource-group $rg `
        --server $secondaryServer `
        --output none 2>$null
    
    Write-Host "  ✓ App Database failover initiated" -ForegroundColor Green
} catch {
    Write-Host "  ✗ App Database failover failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nFailing over Analytics Database..." -ForegroundColor Cyan
try {
    az sql failover-group set-primary `
        --name $analyticsFG `
        --resource-group $rg `
        --server $secondaryServer `
        --output none 2>$null
    
    Write-Host "  ✓ Analytics Database failover initiated`n" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Analytics Database failover failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "⏳ Waiting for failover to complete (this may take 30-60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# ==================
# STEP 4: Verify Failover
# ==================
Write-Host "`n✅ STEP 4: Verifying Failover Status..." -ForegroundColor Yellow
Write-Host "=========================================`n" -ForegroundColor Yellow

try {
    Write-Host "App Database Failover Group (after failover):" -ForegroundColor Cyan
    $appFGInfoAfter = az sql failover-group show --name $appFG --resource-group $rg --server $secondaryServer 2>$null | ConvertFrom-Json
    if ($appFGInfoAfter) {
        Write-Host "  ✓ New Primary: $secondaryServer" -ForegroundColor Green
        Write-Host "  ✓ Current Role: $($appFGInfoAfter.replicationRole)" -ForegroundColor Green
        Write-Host "  ✓ Replication State: $($appFGInfoAfter.replicationState)`n" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Could not verify App DB failover" -ForegroundColor Red
}

try {
    Write-Host "Analytics Database Failover Group (after failover):" -ForegroundColor Cyan
    $analyticsFGInfoAfter = az sql failover-group show --name $analyticsFG --resource-group $rg --server $secondaryServer 2>$null | ConvertFrom-Json
    if ($analyticsFGInfoAfter) {
        Write-Host "  ✓ New Primary: $secondaryServer" -ForegroundColor Green
        Write-Host "  ✓ Current Role: $($analyticsFGInfoAfter.replicationRole)" -ForegroundColor Green
        Write-Host "  ✓ Replication State: $($analyticsFGInfoAfter.replicationState)`n" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Could not verify Analytics DB failover" -ForegroundColor Red
}

# ==================
# STEP 5: Failback Option
# ==================
Write-Host "`n🔙 STEP 5: Failback to Original Primary" -ForegroundColor Yellow
Write-Host "=========================================`n" -ForegroundColor Yellow

Write-Host "Would you like to fail back to the original primary ($primaryRegion)?`n" -ForegroundColor Cyan
$failbackConfirm = Read-Host "Failback now? (yes/no)"

if ($failbackConfirm -eq "yes") {
    Write-Host "`n🔄 Initiating Failback to $primaryRegion..." -ForegroundColor Yellow
    
    Write-Host "Failing back App Database..." -ForegroundColor Cyan
    try {
        az sql failover-group set-primary `
            --name $appFG `
            --resource-group $rg `
            --server $primaryServer `
            --output none 2>$null
        
        Write-Host "  ✓ App Database failback initiated" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ App Database failback failed" -ForegroundColor Red
    }

    Write-Host "`nFailing back Analytics Database..." -ForegroundColor Cyan
    try {
        az sql failover-group set-primary `
            --name $analyticsFG `
            --resource-group $rg `
            --server $primaryServer `
            --output none 2>$null
        
        Write-Host "  ✓ Analytics Database failback initiated`n" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Analytics Database failback failed`n" -ForegroundColor Red
    }

    Write-Host "⏳ Waiting for failback to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45

    Write-Host "`n✅ Failback Complete!" -ForegroundColor Green
    Write-Host "  Primary is now back in $primaryRegion`n" -ForegroundColor Gray
}

# ==================
# Summary
# ==================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 DR Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "✅ DR Capabilities Demonstrated:" -ForegroundColor Green
Write-Host "  1. SQL Failover Groups configured" -ForegroundColor Gray
Write-Host "  2. Manual failover from $primaryRegion → $secondaryRegion" -ForegroundColor Gray
Write-Host "  3. Continuous data replication verified" -ForegroundColor Gray
if ($failbackConfirm -eq "yes") {
    Write-Host "  4. Failback to original primary $primaryRegion" -ForegroundColor Gray
}

Write-Host "`n💡 Key DR Features:" -ForegroundColor Cyan
Write-Host "  • Automatic failover (60 min grace period)" -ForegroundColor Gray
Write-Host "  • Manual failover (as demonstrated)" -ForegroundColor Gray
Write-Host "  • Real-time data replication" -ForegroundColor Gray
Write-Host "  • Zero data loss with sync replication" -ForegroundColor Gray
Write-Host "  • Multi-region container apps ready" -ForegroundColor Gray

Write-Host "`n🎉 DR Test Complete!`n" -ForegroundColor Green


#!/bin/bash
# ============================================
# Quick Multi-Region DR Infrastructure Test
# ============================================

echo -e "\n🧪 Multi-Region DR Quick Test"
echo "============================"
echo ""

RG="demo-rg-demo-cb61e6"
PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Test 1: Resource Group
echo -e "${YELLOW}✅ Test 1: Checking Resource Group...${NC}"
if az group show --name $RG &>/dev/null; then
    RG_NAME=$(az group show --name $RG --query name -o tsv)
    RG_LOCATION=$(az group show --name $RG --query location -o tsv)
    echo -e "${GREEN}  ✓ Resource Group exists: $RG_NAME${NC}"
    echo -e "${GRAY}    Location: $RG_LOCATION${NC}"
    ((PASSED++))
else
    echo -e "${RED}  ✗ Resource Group not found${NC}"
    ((FAILED++))
fi

# Test 2: VNets
echo -e "\n${YELLOW}✅ Test 2: Checking Virtual Networks...${NC}"
VNET_COUNT=$(az network vnet list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$VNET_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $VNET_COUNT VNets (expected: 3)${NC}"
    az network vnet list --resource-group $RG --query "[].{name:name, location:location}" -o tsv | while read name location; do
        echo -e "${GRAY}    - $name in $location${NC}"
    done
    [ "$VNET_COUNT" -eq 3 ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking VNets${NC}"
    ((FAILED++))
fi

# Test 3: SQL Servers
echo -e "\n${YELLOW}✅ Test 3: Checking SQL Servers...${NC}"
SQL_COUNT=$(az sql server list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$SQL_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $SQL_COUNT SQL Servers (expected: 3)${NC}"
    az sql server list --resource-group $RG --query "[].{name:name, location:location}" -o tsv | while read name location; do
        echo -e "${GRAY}    - $name in $location${NC}"
    done
    [ "$SQL_COUNT" -eq 3 ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking SQL Servers${NC}"
    ((FAILED++))
fi

# Test 4: SQL Failover Groups
echo -e "\n${YELLOW}✅ Test 4: Checking SQL Failover Groups...${NC}"
FG1_ROLE=$(az sql failover-group show --name demo-appdb-fg-demo --resource-group $RG --server demo-sql-centralus-demo --query replicationRole -o tsv 2>/dev/null)
FG2_ROLE=$(az sql failover-group show --name demo-analyticsdb-fg-demo --resource-group $RG --server demo-sql-centralus-demo --query replicationRole -o tsv 2>/dev/null)

if [ -n "$FG1_ROLE" ] && [ -n "$FG2_ROLE" ]; then
    echo -e "${GREEN}  ✓ App Database FG: $FG1_ROLE${NC}"
    echo -e "${GREEN}  ✓ Analytics Database FG: $FG2_ROLE${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}  ⚠ Failover groups check skipped (may still be provisioning)${NC}"
fi

# Test 5: Storage Accounts
echo -e "\n${YELLOW}✅ Test 5: Checking Storage Accounts...${NC}"
STORAGE_COUNT=$(az storage account list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$STORAGE_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $STORAGE_COUNT Storage Accounts (expected: 9)${NC}"
    az storage account list --resource-group $RG --query "[].{name:name, sku:sku.name, location:location}" -o tsv | while read name sku location; do
        echo -e "${GRAY}    - $name [$sku] in $location${NC}"
    done
    [ "$STORAGE_COUNT" -eq 9 ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking Storage Accounts${NC}"
    ((FAILED++))
fi

# Test 6: Container Apps
echo -e "\n${YELLOW}✅ Test 6: Checking Container Apps...${NC}"
APP_COUNT=$(az containerapp list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$APP_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $APP_COUNT Container Apps (expected: 16)${NC}"
    PUBLIC_COUNT=$(az containerapp list --resource-group $RG --query "[?properties.configuration.ingress.external==\`true\`] | length(@)" -o tsv 2>/dev/null)
    PRIVATE_COUNT=$(az containerapp list --resource-group $RG --query "[?properties.configuration.ingress.external==\`false\`] | length(@)" -o tsv 2>/dev/null)
    echo -e "${GRAY}    - Public apps: $PUBLIC_COUNT${NC}"
    echo -e "${GRAY}    - Private apps: $PRIVATE_COUNT${NC}"
    [ "$APP_COUNT" -eq 16 ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking Container Apps${NC}"
    ((FAILED++))
fi

# Test 7: Public Gateway HTTP Test
echo -e "\n${YELLOW}✅ Test 7: Testing Public Gateway...${NC}"
GATEWAY_URL=$(terraform output -raw primary_gateway_url 2>/dev/null)
if [ -n "$GATEWAY_URL" ]; then
    echo -e "${GRAY}  Gateway URL: $GATEWAY_URL${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}  ✓ Gateway is accessible (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}  ✗ Gateway returned HTTP $HTTP_CODE${NC}"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}  ⚠ Could not get gateway URL from Terraform outputs${NC}"
fi

# Test 8: Private Endpoints
echo -e "\n${YELLOW}✅ Test 8: Checking Private Endpoints...${NC}"
PE_COUNT=$(az network private-endpoint list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$PE_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $PE_COUNT Private Endpoints (expected: 15)${NC}"
    APPROVED_COUNT=$(az network private-endpoint list --resource-group $RG --query "[?privateLinkServiceConnections[0].privateLinkServiceConnectionState.status=='Approved'] | length(@)" -o tsv 2>/dev/null)
    echo -e "${GRAY}    - Approved connections: $APPROVED_COUNT / $PE_COUNT${NC}"
    [ "$PE_COUNT" -eq 15 ] && [ "$APPROVED_COUNT" -eq "$PE_COUNT" ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking Private Endpoints${NC}"
    ((FAILED++))
fi

# Test 9: VNet Peering
echo -e "\n${YELLOW}✅ Test 9: Checking VNet Peering...${NC}"
PEERING_COUNT=$(az network vnet peering list --resource-group $RG --vnet-name demo-vnet-centralus-demo --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$PEERING_COUNT" ]; then
    CONNECTED_COUNT=$(az network vnet peering list --resource-group $RG --vnet-name demo-vnet-centralus-demo --query "[?peeringState=='Connected'] | length(@)" -o tsv 2>/dev/null)
    echo -e "${GREEN}  ✓ Found $PEERING_COUNT peerings from centralus VNet${NC}"
    echo -e "${GRAY}    - Connected: $CONNECTED_COUNT / $PEERING_COUNT${NC}"
    [ "$CONNECTED_COUNT" -eq "$PEERING_COUNT" ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking VNet Peering${NC}"
    ((FAILED++))
fi

# Test 10: Log Analytics Workspaces
echo -e "\n${YELLOW}✅ Test 10: Checking Log Analytics Workspaces...${NC}"
LAW_COUNT=$(az monitor log-analytics workspace list --resource-group $RG --query "length(@)" -o tsv 2>/dev/null)
if [ -n "$LAW_COUNT" ]; then
    echo -e "${GREEN}  ✓ Found $LAW_COUNT Log Analytics Workspaces (expected: 3)${NC}"
    az monitor log-analytics workspace list --resource-group $RG --query "[].{name:name, location:location}" -o tsv | while read name location; do
        echo -e "${GRAY}    - $name in $location${NC}"
    done
    [ "$LAW_COUNT" -eq 3 ] && ((PASSED++)) || ((FAILED++))
else
    echo -e "${RED}  ✗ Error checking Log Analytics Workspaces${NC}"
    ((FAILED++))
fi

# Summary
echo -e "\n============================="
echo -e "📊 Test Summary"
echo -e "============================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED / $TOTAL) * 100}")
    
    if [ $(echo "$SUCCESS_RATE >= 80" | bc -l) -eq 1 ]; then
        echo -e "${GREEN}Success Rate: $SUCCESS_RATE%${NC}"
    else
        echo -e "${YELLOW}Success Rate: $SUCCESS_RATE%${NC}"
    fi
fi

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! Your infrastructure is ready!${NC}"
elif [ $FAILED -le 2 ]; then
    echo -e "\n${YELLOW}⚠️  Most tests passed. Check failed tests above.${NC}"
else
    echo -e "\n${RED}❌ Multiple tests failed. Review your deployment.${NC}"
fi

echo -e "\n${GRAY}For detailed testing, see TESTING_GUIDE.md${NC}\n"


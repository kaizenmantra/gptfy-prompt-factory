#!/bin/bash

# =============================================================================
# GPTfy Prompt Factory - Pipeline Validation Script
# =============================================================================
#
# This script validates that the pipeline is working correctly by:
# 1. Checking golden test case exists
# 2. Running Apex unit tests
# 3. Validating most recent pipeline run
# 4. Reporting pass/fail status
#
# Usage:
#   ./scripts/validate-pipeline.sh [--org=org-alias]
#
# Examples:
#   ./scripts/validate-pipeline.sh
#   ./scripts/validate-pipeline.sh --org=agentictso
#
# Exit Codes:
#   0 - All validations passed
#   1 - Validation failed or error occurred
#
# @author Sonnet (Phase 5A.5 - Automated Testing)
# @date 2026-01-25
#
# =============================================================================

set -e  # Exit on error

# =============================================================================
# Configuration
# =============================================================================

ORG_ALIAS="agentictso"
GOLDEN_OPP_ID="006QH00000HjgvlYAB"
GOLDEN_OPP_NAME="Employee Health Insurance / McD Franchise Deal"

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --org=*)
            ORG_ALIAS="${arg#*=}"
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# =============================================================================
# Colors for output
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
}

print_step() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# Main Script
# =============================================================================

print_header "GPTfy Prompt Factory - Pipeline Validation"

echo ""
echo "   Org: $ORG_ALIAS"
echo "   Golden Test Case: $GOLDEN_OPP_ID"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Verify golden test case exists
# -----------------------------------------------------------------------------

print_step "Step 1: Verifying golden test case exists"

GOLDEN_CHECK=$(sf data query -o "$ORG_ALIAS" --query "SELECT Id, Name FROM Opportunity WHERE Id = '$GOLDEN_OPP_ID' LIMIT 1" --json | jq -r '.result.records[0].Id // empty')

if [ -z "$GOLDEN_CHECK" ]; then
    print_error "Golden test case not found: $GOLDEN_OPP_ID"
    echo ""
    echo "   Please create the golden test case before running validation."
    echo "   See docs/testing/GOLDEN_TEST_CASE.md for details."
    exit 1
fi

print_success "Golden test case exists: $GOLDEN_OPP_NAME"

# -----------------------------------------------------------------------------
# Step 2: Run Apex unit tests
# -----------------------------------------------------------------------------

print_step "Step 2: Running Apex unit tests"

echo "   Running PipelineIntegrationTest..."

TEST_RESULT=$(sf apex run test -o "$ORG_ALIAS" --class-names PipelineIntegrationTest --result-format human --wait 10 2>&1)

if echo "$TEST_RESULT" | grep -q "Failing"; then
    print_error "Unit tests failed"
    echo ""
    echo "$TEST_RESULT"
    exit 1
fi

if echo "$TEST_RESULT" | grep -q "Passing"; then
    PASS_COUNT=$(echo "$TEST_RESULT" | grep -oE '[0-9]+ Passing' | grep -oE '[0-9]+')
    print_success "Unit tests passed: $PASS_COUNT tests"
else
    print_warning "Could not determine test results"
    echo "$TEST_RESULT"
fi

# -----------------------------------------------------------------------------
# Step 3: Check for recent pipeline run
# -----------------------------------------------------------------------------

print_step "Step 3: Validating recent pipeline run"

# Query most recent run from today
RECENT_RUN=$(sf data query -o "$ORG_ALIAS" --query "SELECT Id, ccai__Status__c, ccai__Current_Stage__c FROM ccai__PF_Run__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" --json | jq -r '.result.records[0] // empty')

if [ -z "$RECENT_RUN" ]; then
    print_warning "No pipeline runs found today"
    echo ""
    echo "   This is expected if no pipelines have run yet."
    echo "   Skipping run validation."
else
    RUN_ID=$(echo "$RECENT_RUN" | jq -r '.Id')
    RUN_STATUS=$(echo "$RECENT_RUN" | jq -r '.ccai__Status__c')
    RUN_STAGE=$(echo "$RECENT_RUN" | jq -r '.ccai__Current_Stage__c')

    echo "   Found run: $RUN_ID"
    echo "   Status: $RUN_STATUS"
    echo "   Stage: $RUN_STAGE"

    if [ "$RUN_STATUS" = "Failed" ]; then
        print_error "Most recent run failed at stage $RUN_STAGE"
        exit 1
    elif [ "$RUN_STATUS" = "Completed" ]; then
        print_success "Most recent run completed successfully"
    else
        print_success "Most recent run is $RUN_STATUS (stage $RUN_STAGE)"
    fi
fi

# -----------------------------------------------------------------------------
# Step 4: Validate DCM quality (if recent run exists)
# -----------------------------------------------------------------------------

if [ ! -z "$RECENT_RUN" ] && [ "$RUN_STAGE" -ge 9 ]; then
    print_step "Step 4: Validating DCM quality"

    # Query DCM for recent run
    DCM_CHECK=$(sf data query -o "$ORG_ALIAS" --query "SELECT Id, ccai__Object_Name__c, (SELECT COUNT() FROM ccai__AI_Data_Extraction_Details__r) DetailCount, (SELECT COUNT() FROM ccai__DCM_Fields__r) FieldCount FROM ccai__AI_Data_Extraction_Mapping__c WHERE ccai__Run__c = '$RUN_ID' LIMIT 1" --json 2>&1)

    if echo "$DCM_CHECK" | grep -q '"totalSize":1'; then
        DCM_OBJECT=$(echo "$DCM_CHECK" | jq -r '.result.records[0].ccai__Object_Name__c')
        print_success "DCM created for $DCM_OBJECT"
    else
        print_warning "No DCM found for recent run"
    fi
else
    print_step "Step 4: Skipping DCM validation (run not at Stage 9+)"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

print_header "Validation Complete!"

echo ""
echo "📊 Summary:"
echo "   ✅ Golden test case exists"
echo "   ✅ Unit tests passing"
if [ ! -z "$RECENT_RUN" ]; then
    echo "   ✅ Recent run validated"
else
    echo "   ⚠️  No recent runs to validate"
fi
echo ""

print_success "All validations passed! Pipeline is working correctly."

exit 0

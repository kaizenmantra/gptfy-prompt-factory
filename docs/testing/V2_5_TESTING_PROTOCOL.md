# V2.5 End-to-End Testing Protocol

**Version:** 2.5.0
**Date:** 2026-01-26
**Purpose:** Comprehensive testing of V2.5 two-layer meta-prompt architecture with three golden test accounts

---

## Overview

This protocol tests the complete V2.5 pipeline:
1. **Stage 8**: Meta-prompt generates Handlebars template with merge fields
2. **Stage 9**: Merge Gate substitutes real data into template
3. **Stage 10**: Executes final prompt via GPTfy API
4. **Validation**: Verifies output quality against success criteria

---

## Test Accounts (Golden Test Cases)

Three accounts with rich data for comprehensive testing:

### Account 1: Pinnacle Wealth Partners
- **ID**: `001QH000024mdDnYAI`
- **Industry**: Financial Services
- **Revenue**: $15M
- **Business Context**: "Analyze this financial services account and provide executive insights for the Relationship Manager"
- **Target Persona**: Relationship Manager
- **Expected Focus**: Risk assessment, portfolio health, revenue opportunities

### Account 2: Vanguard Insurance Group
- **ID**: `001QH000024mdDoYAI`
- **Industry**: Insurance
- **Revenue**: $50M
- **Business Context**: "Analyze this insurance account and identify cross-sell opportunities for the Account Executive"
- **Target Persona**: Account Executive
- **Expected Focus**: Cross-sell analysis, coverage gaps, expansion opportunities

### Account 3: MediCare Solutions Inc.
- **ID**: `001QH000024mdDpYAI`
- **Industry**: Healthcare
- **Revenue**: $150M
- **Business Context**: "Analyze this healthcare account and assess renewal risk for the Customer Success Manager"
- **Target Persona**: Customer Success Manager
- **Expected Focus**: Renewal risk, engagement metrics, health score

---

## Phase 1: Create Test Scripts

Create three Apex test scripts in the `temp/` directory:

**File: `temp/test-v2.5-account1.apex`**

```apex
// Test V2.5 with Account 1: Pinnacle Wealth Partners
String accountId = '001QH000024mdDnYAI';
String objectName = 'Account';
String businessContext = 'Analyze this financial services account and provide executive insights for the Relationship Manager';
String targetPersona = 'Relationship Manager';
String outputFormat = 'Narrative';

// Start pipeline run
Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account1-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null, // businessObjectives
    'https://gptfy--agentictso.sandbox.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 1: Pinnacle Wealth Partners');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('Expected: V2.5 two-layer architecture');
System.debug('Stage 8: Generate template with merge fields');
System.debug('Stage 9: Substitute real data (Merge Gate)');
System.debug('Stage 10: Execute via GPTfy API');
System.debug('========================================');
```

**File: `temp/test-v2.5-account2.apex`**

```apex
// Test V2.5 with Account 2: Vanguard Insurance Group
String accountId = '001QH000024mdDoYAI';
String objectName = 'Account';
String businessContext = 'Analyze this insurance account and identify cross-sell opportunities for the Account Executive';
String targetPersona = 'Account Executive';
String outputFormat = 'Narrative';

Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account2-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null,
    'https://gptfy--agentictso.sandbox.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 2: Vanguard Insurance Group');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('========================================');
```

**File: `temp/test-v2.5-account3.apex`**

```apex
// Test V2.5 with Account 3: MediCare Solutions Inc.
String accountId = '001QH000024mdDpYAI';
String objectName = 'Account';
String businessContext = 'Analyze this healthcare account and assess renewal risk for the Customer Success Manager';
String targetPersona = 'Customer Success Manager';
String outputFormat = 'Narrative';

Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account3-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null,
    'https://gptfy--agentictso.sandbox.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 3: MediCare Solutions Inc.');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('========================================');
```

---

## Phase 2: Execute Tests & Capture Run IDs

Run each test script sequentially and capture Run IDs:

```bash
# Initialize results log
echo "=== V2.5 TESTING STARTED: $(date) ===" > temp/test-results.log

# Test Account 1
echo "=== TESTING ACCOUNT 1 ===" | tee -a temp/test-results.log
sf apex run --file temp/test-v2.5-account1.apex -o agentictso | tee -a temp/test-results.log

# Extract Run ID (format: a0gQH000005XXXXX)
# Look for: "Run ID: a0gQH000005GPh7YAG"
# CAPTURE THIS VALUE!

# Wait for pipeline completion (typical: 2-3 minutes)
echo "Waiting for Account 1 pipeline to complete..." | tee -a temp/test-results.log
sleep 180

# Test Account 2
echo "" | tee -a temp/test-results.log
echo "=== TESTING ACCOUNT 2 ===" | tee -a temp/test-results.log
sf apex run --file temp/test-v2.5-account2.apex -o agentictso | tee -a temp/test-results.log
sleep 180

# Test Account 3
echo "" | tee -a temp/test-results.log
echo "=== TESTING ACCOUNT 3 ===" | tee -a temp/test-results.log
sf apex run --file temp/test-v2.5-account3.apex -o agentictso | tee -a temp/test-results.log
sleep 180
```

**CRITICAL:** Extract the three Run IDs from the output. You'll need them for all subsequent phases.

Store them as variables:
```bash
# Replace with actual Run IDs from test output
RUN_ID_1="a0gQH000005GXXXXXX"
RUN_ID_2="a0gQH000005GXXXXXX"
RUN_ID_3="a0gQH000005GXXXXXX"
```

---

## Phase 3: Monitor Pipeline Completion

Check status for each Run ID:

```bash
check_status() {
    local run_id=$1
    local account_name=$2

    echo "" | tee -a temp/test-results.log
    echo "=== Checking $account_name (Run: $run_id) ===" | tee -a temp/test-results.log

    sf data query -o agentictso --query "SELECT Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = '$run_id'" --json | jq -r '.result.records[0] | "Status: \(.Status__c), Stage: \(.Current_Stage__c), Error: \(.Error_Message__c // "None")"' | tee -a temp/test-results.log
}

# Check all three
check_status "$RUN_ID_1" "Account 1 (Pinnacle)"
check_status "$RUN_ID_2" "Account 2 (Vanguard)"
check_status "$RUN_ID_3" "Account 3 (MediCare)"
```

**Expected Output:**
```
Status: Completed, Stage: 12, Error: None
```

**If Status = "Failed":**
- Note the `Current_Stage__c` where it failed
- Note the `Error_Message__c` for debugging
- Proceed to troubleshooting section

---

## Phase 4: Verify V2.5 Execution at Stage 8

Verify that Stage 8 used the V2.5 meta-prompt architecture:

```bash
verify_stage8() {
    local run_id=$1
    local account_name=$2

    echo "" | tee -a temp/test-results.log
    echo "=== Verifying Stage 8 V2.5 for $account_name ===" | tee -a temp/test-results.log

    # Get Stage 8 logs
    sf data query -o agentictso --query "SELECT Log_Message__c FROM PF_Run_Log__c WHERE Run__c = '$run_id' AND Stage_Number__c = 8 ORDER BY CreatedDate ASC" --json | jq -r '.result.records[] | .Log_Message__c' | grep -E "V2.5|meta-prompt|template" | tee -a temp/test-results.log
}

verify_stage8 "$RUN_ID_1" "Account 1"
verify_stage8 "$RUN_ID_2" "Account 2"
verify_stage8 "$RUN_ID_3" "Account 3"
```

**Expected Log Messages:**
```
V2.5 flag value: true
V2.5: Using two-layer meta-prompt architecture
V2.5: Loaded meta-prompt (8694 chars)
V2.5: Analyzed DCM structure: This DCM includes Account as root with X child relationships...
V2.5: Starting template generation...
V2.5: Generating prompt template (iteration 1)
V2.5: Template validation (iteration 1): Valid=true, Errors=0, Warnings=0
V2.5: Template generation successful after 1 iteration(s)
V2.5: Generated template (XXXX chars, 1 iteration)
V2.5: Prompt assembly complete (two-layer meta-prompt)
```

**CRITICAL CHECKS:**
1. ✅ "V2.5: Using two-layer meta-prompt architecture" present
2. ✅ "Template validation ... Valid=true" (not false)
3. ✅ Iterations = 1 (if >1, meta-prompt needs refinement)
4. ✅ Template size: 3,000-5,000 chars (reasonable template length)

---

## Phase 5: Verify Stage 9 Merge Gate

Verify that Stage 9 successfully merged template with real data:

```bash
verify_stage9() {
    local run_id=$1
    local account_name=$2

    echo "" | tee -a temp/test-results.log
    echo "=== Verifying Stage 9 Merge Gate for $account_name ===" | tee -a temp/test-results.log

    # Get Stage 9 logs
    sf data query -o agentictso --query "SELECT Log_Message__c FROM PF_Run_Log__c WHERE Run__c = '$run_id' AND Stage_Number__c = 9 ORDER BY CreatedDate ASC" --json | jq -r '.result.records[] | .Log_Message__c' | grep -E "V2.5|SOQL|Template|rendered|Merge Gate" | tee -a temp/test-results.log
}

verify_stage9 "$RUN_ID_1" "Account 1"
verify_stage9 "$RUN_ID_2" "Account 2"
verify_stage9 "$RUN_ID_3" "Account 3"
```

**Expected Log Messages:**
```
V2.5: Generated Dynamic SOQL for merge gate: SELECT Id, Name, Industry, AnnualRevenue, ...
V2.5: Successfully queried record data for merge.
V2.5: Template rendered successfully (XXXX chars)
```

**CRITICAL CHECKS:**
1. ✅ SOQL query generated (includes root fields + parent lookups + child subqueries)
2. ✅ Record data queried successfully
3. ✅ Template rendered successfully
4. ✅ Rendered prompt length: 3,000-8,000 chars (similar to template but with real data)

**If longer than template:** Good! Real data expanded iteration blocks.
**If much shorter:** Possible issue - iteration blocks may not have rendered.

---

## Phase 6: Extract Generated Prompts

Retrieve the final prompts created by the pipeline:

```bash
extract_prompt() {
    local run_id=$1
    local account_name=$2
    local output_file="temp/prompt-$account_name.txt"

    echo "" | tee -a temp/test-results.log
    echo "=== Extracting Final Prompt for $account_name ===" | tee -a temp/test-results.log

    # Get the AI Prompt record created by this run
    PROMPT_ID=$(sf data query -o agentictso --query "SELECT Created_Prompt_Id__c FROM PF_Run__c WHERE Id = '$run_id'" --json | jq -r '.result.records[0].Created_Prompt_Id__c')

    if [ "$PROMPT_ID" == "null" ] || [ -z "$PROMPT_ID" ]; then
        echo "ERROR: No prompt created for $account_name" | tee -a temp/test-results.log
        return 1
    fi

    echo "Prompt ID: $PROMPT_ID" | tee -a temp/test-results.log

    # Extract prompt command
    sf data query -o agentictso --query "SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id = '$PROMPT_ID'" --json | jq -r '.result.records[0].ccai__Prompt_Command__c' > "$output_file"

    # Show prompt stats
    PROMPT_LENGTH=$(wc -c < "$output_file")
    MERGE_FIELD_COUNT=$(grep -o '{{{' "$output_file" | wc -l)

    echo "Prompt saved to: $output_file" | tee -a temp/test-results.log
    echo "Length: $PROMPT_LENGTH chars" | tee -a temp/test-results.log
    echo "Merge fields remaining: $MERGE_FIELD_COUNT (should be 0!)" | tee -a temp/test-results.log

    # Preview first 500 chars
    echo "Preview:" | tee -a temp/test-results.log
    head -c 500 "$output_file" | tee -a temp/test-results.log
    echo "" | tee -a temp/test-results.log
    echo "..." | tee -a temp/test-results.log
}

extract_prompt "$RUN_ID_1" "account1"
extract_prompt "$RUN_ID_2" "account2"
extract_prompt "$RUN_ID_3" "account3"
```

**CRITICAL VALIDATIONS:**
1. ✅ **Merge fields remaining: 0** (no `{{{...}}}` placeholders in final prompt)
2. ✅ **Length: 3,000-8,000 chars** (reasonable prompt size)
3. ✅ **Preview contains real data** (actual account names, revenue figures, dates, etc.)

**Red Flags:**
- ❌ Merge fields > 0: Handlebars substitution failed
- ❌ Length < 1,000 chars: Template didn't render or data missing
- ❌ Preview shows generic text: Data not substituted

---

## Phase 7: Execute Prompts via GPTfy API

Test each prompt by calling the GPTfy API:

```bash
execute_prompt() {
    local run_id=$1
    local account_name=$2
    local account_id=$3

    echo "" | tee -a temp/test-results.log
    echo "=== Executing Prompt for $account_name via GPTfy ===" | tee -a temp/test-results.log

    # Get the prompt ID
    PROMPT_ID=$(sf data query -o agentictso --query "SELECT Created_Prompt_Id__c FROM PF_Run__c WHERE Id = '$run_id'" --json | jq -r '.result.records[0].Created_Prompt_Id__c')

    echo "Prompt ID: $PROMPT_ID" | tee -a temp/test-results.log

    # Get Salesforce session token
    SESSION_ID=$(sf org display -o agentictso --json | jq -r '.result.accessToken')
    INSTANCE_URL="https://gptfy--agentictso.sandbox.my.salesforce.com"

    # Execute prompt via GPTfy REST API
    curl -X POST "$INSTANCE_URL/services/apexrest/gptfy/v1/execute" \
         -H "Authorization: Bearer $SESSION_ID" \
         -H "Content-Type: application/json" \
         -d "{
             \"promptId\": \"$PROMPT_ID\",
             \"recordId\": \"$account_id\",
             \"async\": false
         }" \
         --silent | jq '.' > "temp/gptfy-response-$account_name.json"

    # Check response
    if [ -f "temp/gptfy-response-$account_name.json" ]; then
        ERROR=$(jq -r '.error // "None"' "temp/gptfy-response-$account_name.json")
        STATUS=$(jq -r '.status // "Unknown"' "temp/gptfy-response-$account_name.json")
        HTML_LENGTH=$(jq -r '.result.html // "" | length' "temp/gptfy-response-$account_name.json")

        echo "GPTfy Response saved to: temp/gptfy-response-$account_name.json" | tee -a temp/test-results.log
        echo "Status: $STATUS" | tee -a temp/test-results.log
        echo "Error: $ERROR" | tee -a temp/test-results.log
        echo "HTML Output Length: $HTML_LENGTH chars" | tee -a temp/test-results.log

        # Save HTML for manual review
        jq -r '.result.html // ""' "temp/gptfy-response-$account_name.json" > "temp/gptfy-output-$account_name.html"
        echo "HTML saved to: temp/gptfy-output-$account_name.html" | tee -a temp/test-results.log
    else
        echo "ERROR: No response file created" | tee -a temp/test-results.log
    fi
}

# Execute all three prompts
execute_prompt "$RUN_ID_1" "account1" "001QH000024mdDnYAI"
execute_prompt "$RUN_ID_2" "account2" "001QH000024mdDoYAI"
execute_prompt "$RUN_ID_3" "account3" "001QH000024mdDpYAI"
```

**Expected Output:**
- Status: success
- Error: None
- HTML Output Length: 2,000-10,000 chars
- HTML files created in `temp/` directory

**If Error:**
- Check prompt size (max 32,000 chars)
- Check for invalid HTML syntax
- Check for remaining merge fields in prompt

---

## Phase 8: Quality Analysis

Evaluate each HTML output against V2.5 success criteria:

```bash
analyze_quality() {
    local account_name=$1
    local html_file="temp/gptfy-output-$account_name.html"

    echo "" | tee -a temp/test-results.log
    echo "=== Quality Analysis: $account_name ===" | tee -a temp/test-results.log

    if [ ! -f "$html_file" ]; then
        echo "ERROR: HTML file not found: $html_file" | tee -a temp/test-results.log
        return 1
    fi

    # Check for required V2.5 components
    HAS_HEALTH_SCORE=$(grep -i -c "health.*score\|Health.*Score" "$html_file" || echo 0)
    HAS_RED_ALERT=$(grep -i -c "background.*red\|color.*red\|border.*red\|#ff\|#f00\|#dc3545\|rgb(220.*53.*69)" "$html_file" || echo 0)
    HAS_ORANGE_ALERT=$(grep -i -c "background.*orange\|color.*orange\|border.*orange\|#ffa500\|#fd7e14\|rgb(253.*126.*20)" "$html_file" || echo 0)
    HAS_BLUE_ALERT=$(grep -i -c "background.*blue\|color.*blue\|border.*blue\|#0d6efd\|#007bff\|rgb(0.*123.*255)" "$html_file" || echo 0)
    HAS_TABLE=$(grep -c "<table" "$html_file" || echo 0)
    HAS_STAT_CARD=$(grep -i -c "stat.*card\|kpi\|metric" "$html_file" || echo 0)

    # Check for data substitution (real values, not merge fields)
    HAS_MERGE_FIELDS=$(grep -c "{{{" "$html_file" || echo 0)
    HAS_ACCOUNT_NAME=$(grep -E -c "Pinnacle|Vanguard|MediCare" "$html_file" || echo 0)
    HAS_CURRENCY=$(grep -E -c "\$[0-9,]+" "$html_file" || echo 0)

    echo "Health Score: $HAS_HEALTH_SCORE (expected: 1+)" | tee -a temp/test-results.log
    echo "Red Alerts: $HAS_RED_ALERT" | tee -a temp/test-results.log
    echo "Orange Alerts: $HAS_ORANGE_ALERT" | tee -a temp/test-results.log
    echo "Blue Alerts: $HAS_BLUE_ALERT" | tee -a temp/test-results.log
    echo "Data Tables: $HAS_TABLE (expected: 1+)" | tee -a temp/test-results.log
    echo "Stat Cards/KPIs: $HAS_STAT_CARD (expected: 1+)" | tee -a temp/test-results.log
    echo "Merge Fields Remaining: $HAS_MERGE_FIELDS (expected: 0)" | tee -a temp/test-results.log
    echo "Real Account Name: $HAS_ACCOUNT_NAME (expected: 1+)" | tee -a temp/test-results.log
    echo "Currency Values: $HAS_CURRENCY (expected: 1+)" | tee -a temp/test-results.log

    # Calculate quality score (0-10)
    SCORE=0
    [ "$HAS_HEALTH_SCORE" -gt 0 ] && SCORE=$((SCORE + 2))
    [ "$HAS_RED_ALERT" -gt 0 ] && SCORE=$((SCORE + 1))
    [ "$HAS_ORANGE_ALERT" -gt 0 ] && SCORE=$((SCORE + 1))
    [ "$HAS_BLUE_ALERT" -gt 0 ] && SCORE=$((SCORE + 1))
    [ "$HAS_TABLE" -gt 0 ] && SCORE=$((SCORE + 1))
    [ "$HAS_STAT_CARD" -gt 0 ] && SCORE=$((SCORE + 1))
    [ "$HAS_MERGE_FIELDS" -eq 0 ] && SCORE=$((SCORE + 2))
    [ "$HAS_ACCOUNT_NAME" -gt 0 ] && SCORE=$((SCORE + 1))

    echo "Quality Score: $SCORE/10" | tee -a temp/test-results.log

    # Pass/Fail determination
    if [ "$SCORE" -ge 8 ]; then
        echo "Result: ✅ PASS" | tee -a temp/test-results.log
    elif [ "$SCORE" -ge 6 ]; then
        echo "Result: ⚠️  MARGINAL (needs improvement)" | tee -a temp/test-results.log
    else
        echo "Result: ❌ FAIL (quality below threshold)" | tee -a temp/test-results.log
    fi
    echo "" | tee -a temp/test-results.log
}

# Analyze all three outputs
analyze_quality "account1"
analyze_quality "account2"
analyze_quality "account3"
```

**Success Criteria:**
- Quality Score: **8+/10** ✅
- Merge Fields Remaining: **0** ✅
- Health Score: **Present** ✅
- 3-Color Alerts: **At least 2 colors used** ✅
- Data Tables: **At least 1** ✅
- Real Data: **Account names and currency values visible** ✅

---

## Phase 9: Generate Summary Report

```bash
echo "" | tee -a temp/test-results.log
echo "===========================================================" | tee -a temp/test-results.log
echo "V2.5 END-TO-END TEST SUMMARY" | tee -a temp/test-results.log
echo "===========================================================" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "Test Date: $(date)" | tee -a temp/test-results.log
echo "Org: agentictso@gptfy.com" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "-----------------------------------------------------------" | tee -a temp/test-results.log
echo "Account 1: Pinnacle Wealth Partners" | tee -a temp/test-results.log
echo "  ID: 001QH000024mdDnYAI" | tee -a temp/test-results.log
echo "  Run ID: $RUN_ID_1" | tee -a temp/test-results.log
echo "  Context: Financial Services / Relationship Manager" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "Account 2: Vanguard Insurance Group" | tee -a temp/test-results.log
echo "  ID: 001QH000024mdDoYAI" | tee -a temp/test-results.log
echo "  Run ID: $RUN_ID_2" | tee -a temp/test-results.log
echo "  Context: Insurance / Account Executive" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "Account 3: MediCare Solutions Inc." | tee -a temp/test-results.log
echo "  ID: 001QH000024mdDpYAI" | tee -a temp/test-results.log
echo "  Run ID: $RUN_ID_3" | tee -a temp/test-results.log
echo "  Context: Healthcare / Customer Success Manager" | tee -a temp/test-results.log
echo "-----------------------------------------------------------" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "Generated Files:" | tee -a temp/test-results.log
echo "  - temp/test-results.log (this file)" | tee -a temp/test-results.log
echo "  - temp/prompt-account1.txt" | tee -a temp/test-results.log
echo "  - temp/prompt-account2.txt" | tee -a temp/test-results.log
echo "  - temp/prompt-account3.txt" | tee -a temp/test-results.log
echo "  - temp/gptfy-output-account1.html" | tee -a temp/test-results.log
echo "  - temp/gptfy-output-account2.html" | tee -a temp/test-results.log
echo "  - temp/gptfy-output-account3.html" | tee -a temp/test-results.log
echo "  - temp/gptfy-response-account1.json" | tee -a temp/test-results.log
echo "  - temp/gptfy-response-account2.json" | tee -a temp/test-results.log
echo "  - temp/gptfy-response-account3.json" | tee -a temp/test-results.log
echo "" | tee -a temp/test-results.log
echo "===========================================================" | tee -a temp/test-results.log
echo "Review test-results.log and HTML outputs for analysis" | tee -a temp/test-results.log
echo "===========================================================" | tee -a temp/test-results.log
```

---

## Deliverables for Review

After completing all phases, the following files will be generated for analysis:

### Logs
1. **temp/test-results.log** - Complete execution log with all checks and validations

### Prompts (Generated Templates with Data)
2. **temp/prompt-account1.txt** - Final prompt for Pinnacle Wealth Partners
3. **temp/prompt-account2.txt** - Final prompt for Vanguard Insurance Group
4. **temp/prompt-account3.txt** - Final prompt for MediCare Solutions Inc.

### HTML Outputs (GPTfy Results)
5. **temp/gptfy-output-account1.html** - Dashboard for Pinnacle Wealth Partners
6. **temp/gptfy-output-account2.html** - Dashboard for Vanguard Insurance Group
7. **temp/gptfy-output-account3.html** - Dashboard for MediCare Solutions Inc.

### API Responses
8. **temp/gptfy-response-account1.json** - Full GPTfy API response for Account 1
9. **temp/gptfy-response-account2.json** - Full GPTfy API response for Account 2
10. **temp/gptfy-response-account3.json** - Full GPTfy API response for Account 3

---

## Troubleshooting Guide

### Issue: Pipeline fails at Stage 8

**Symptom:** Error at Stage 8, logs show V2.0 execution instead of V2.5

**Check 1:** Verify V2.5 flag is enabled
```bash
grep "USE_META_PROMPT_V2_5" force-app/main/default/classes/Stage08_PromptAssembly.cls
```
**Expected:** `private static final Boolean USE_META_PROMPT_V2_5 = true;`

**Fix:** If false, enable flag and redeploy:
```bash
# Edit the file to set flag to true
sf project deploy start -m ApexClass:Stage08_PromptAssembly -o agentictso
```

**Check 2:** Verify meta-prompt Builder exists
```bash
sf data query -o agentictso --query "SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name = 'GPTfy Prompt Generation Framework v2.5' AND ccai__Status__c = 'Active'" --json
```
**Expected:** 1 record with ID `a0DQH00000KaueT2AR`

---

### Issue: Pipeline fails at Stage 9 with "DCM config required"

**Symptom:** Stage 9 error: "Failed to create and deploy: DCM config and prompt config are required"

**Root Cause:** Stage 8 not passing metadata to Stage 9

**Check:** Verify Stage 8 outputs contain metadata
```bash
# Replace RUN_ID with your actual run ID
sf data query -o agentictso --query "SELECT Outputs__c FROM PF_Stage__c WHERE Run__c = 'RUN_ID' AND Stage_Number__c = 8" --json | jq '.result.records[0].Outputs__c | keys'
```

**Expected Keys:**
```json
["selectedFields", "selectedParentFields", "selectedGrandchildren", "dcmConfig", "promptConfig", "promptType"]
```

**Fix:** If missing, Stage 8 has regression. Check recent code changes:
```bash
git diff HEAD~1 force-app/main/default/classes/Stage08_PromptAssembly.cls
```

---

### Issue: Merge fields still present in final prompt

**Symptom:** `temp/prompt-accountX.txt` contains `{{{...}}}` placeholders

**Root Cause:** HandlebarsTemplateEngine not being called or failing

**Check 1:** Verify Stage 9 executed V2.5 flow
```bash
sf data query -o agentictso --query "SELECT Log_Message__c FROM PF_Run_Log__c WHERE Run__c = 'RUN_ID' AND Stage_Number__c = 9 AND Log_Message__c LIKE '%Template rendered%'" --json
```
**Expected:** Log showing "V2.5: Template rendered successfully (XXXX chars)"

**Check 2:** Verify HandlebarsTemplateEngine deployed
```bash
sf data query -o agentictso --query "SELECT Name FROM ApexClass WHERE Name = 'HandlebarsTemplateEngine'" --json
```
**Expected:** 1 record

**Fix:** If not found, deploy template engine:
```bash
sf project deploy start -m ApexClass:HandlebarsTemplateEngine -o agentictso
```

---

### Issue: GPTfy API returns error

**Symptom:** `temp/gptfy-response-accountX.json` contains error

**Possible Causes:**

1. **Prompt too large (>32,000 chars)**
   ```bash
   wc -c temp/prompt-account1.txt
   ```
   **Fix:** Refine meta-prompt to generate shorter templates

2. **Invalid HTML in prompt**
   ```bash
   tidy -q -e temp/prompt-account1.txt 2>&1 | head -20
   ```
   **Fix:** Check for unclosed tags, invalid syntax

3. **Merge fields not fully substituted**
   ```bash
   grep -o '{{{' temp/prompt-account1.txt | wc -l
   ```
   **Expected:** 0
   **Fix:** Debug HandlebarsTemplateEngine substitution logic

4. **GPTfy API credentials invalid**
   ```bash
   sf org display -o agentictso --json | jq '.result.accessToken'
   ```
   **Fix:** Re-authenticate if token expired

---

### Issue: Low quality score (<8/10)

**Symptom:** Quality analysis shows missing components

**Debug:**

1. **Missing Health Score:**
   - Check Stage 8 template includes health score calculation
   - Verify meta-prompt emphasizes health score requirement

2. **Missing 3-Color Alerts:**
   - Check template has conditional alert logic
   - Verify data contains values triggering different alert levels

3. **Missing Data Tables:**
   - Check template has iteration blocks for child records
   - Verify SOQL query returned child data

4. **Merge Fields Present:**
   - See "Merge fields still present" troubleshooting above

**Fix:** Iterate on meta-prompt content to emphasize missing components

---

## Success Criteria Checklist

Use this checklist to validate V2.5 is working correctly:

### Stage 8: Template Generation
- [ ] V2.5 flag enabled in code
- [ ] Meta-prompt Builder record exists and is active
- [ ] Stage 8 logs show "V2.5: Using two-layer meta-prompt architecture"
- [ ] Template generated on first iteration (iterations = 1)
- [ ] Template validation passes (Valid=true, Errors=0)
- [ ] Template contains merge fields ({{{...}}})
- [ ] Template size: 3,000-5,000 chars

### Stage 9: Merge Gate
- [ ] Stage 9 detects V2.5 template (promptType = 'V2.5_Meta_Generated')
- [ ] Dynamic SOQL generated successfully
- [ ] Record data queried successfully
- [ ] Template rendered successfully
- [ ] Rendered prompt size: 3,000-8,000 chars

### Final Prompt Quality
- [ ] No merge fields in final prompt ({{{...}}} count = 0)
- [ ] Real account names present (Pinnacle/Vanguard/MediCare)
- [ ] Currency values present ($X,XXX format)
- [ ] Dates present (YYYY-MM-DD or formatted dates)

### GPTfy Execution
- [ ] GPTfy API accepts prompt without error
- [ ] HTML output generated (2,000-10,000 chars)
- [ ] HTML contains health score
- [ ] HTML contains 3-color alerts (red/orange/blue)
- [ ] HTML contains data tables
- [ ] HTML contains stat cards or KPIs

### Overall Quality
- [ ] Quality score ≥ 8/10 for all three accounts
- [ ] Outputs are consistent in structure
- [ ] Outputs are personalized per business context
- [ ] No errors or warnings in logs

---

## Notes for Testers

1. **Timing:** Full pipeline takes 2-3 minutes per account. Budget 15-20 minutes total for all three tests.

2. **Org State:** Ensure accounts `001QH000024mdDnYAI`, `001QH000024mdDoYAI`, `001QH000024mdDpYAI` exist with related data (Contacts, Opportunities, Cases).

3. **Clean State:** Delete old test runs if needed:
   ```bash
   sf data query -o agentictso --query "SELECT Id FROM PF_Run__c WHERE Name LIKE 'V2.5-Test-%' ORDER BY CreatedDate DESC" --json
   ```

4. **Deployment Verification:** Before testing, verify latest code deployed:
   ```bash
   sf data query -o agentictso --query "SELECT Name, LastModifiedDate FROM ApexClass WHERE Name IN ('Stage08_PromptAssembly', 'Stage09_CreateAndDeploy', 'HandlebarsTemplateEngine') ORDER BY Name" --json
   ```

5. **Log Retention:** PF_Run_Log__c records may auto-delete after 7 days. Run tests and analyze results immediately.

---

**End of Testing Protocol**

#!/bin/bash
# Execute a single variant test
# Usage: ./run_variant_test.sh <variant_number> <variant_name>

set -e

VARIANT_NUM=$1
VARIANT_NAME=$2
PROMPT_ID="a0DQH00000KYLsv2AH"
OPP_ID="006QH00000HjgvlYAB"
ORG_ALIAS="agentictso"
TEST_DIR="tests/phase0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 VARIANT ${VARIANT_NUM}: ${VARIANT_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Step 1: Read variant file
VARIANT_FILE="${TEST_DIR}/variants/variant_${VARIANT_NUM}_${VARIANT_NAME}.txt"
echo "📖 Reading variant file: ${VARIANT_FILE}"

if [ ! -f "$VARIANT_FILE" ]; then
    echo "❌ ERROR: Variant file not found: $VARIANT_FILE"
    exit 1
fi

VARIANT_SIZE=$(wc -c < "$VARIANT_FILE")
echo "   Size: ${VARIANT_SIZE} bytes"
echo ""

# Step 2: Update prompt with this variant
echo "📝 Updating prompt ${PROMPT_ID} with Variant ${VARIANT_NUM}..."

# Create temp apex file with variant content
# Due to size, we'll update directly via Apex
cat > "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex" << 'APEX_EOF'
String promptText = '';
APEX_EOF

# Read file in chunks and build Apex string
# For simplicity, we'll use a different approach - save to file and read in Apex
echo "ccai__AI_Prompt__c prompt = [SELECT Id FROM ccai__AI_Prompt__c WHERE Id = 'a0DQH00000KYLsv2AH'];" >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"
echo "prompt.ccai__Prompt_Command__c = " >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"

# Convert file to Apex string literal (escape quotes, add newlines)
awk '{
    gsub(/'\''/, "'\''\\'\'''\'");  # Escape single quotes
    gsub(/\\/, "\\\\");             # Escape backslashes
    printf "'\''%s\\n'\'' +\n", $0;
}' "$VARIANT_FILE" >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"

echo "'';" >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"
echo "update prompt;" >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"
echo "System.debug('✅ Prompt updated with Variant ${VARIANT_NUM}');" >> "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"

# Execute update
echo "   Executing Apex update..."
sf apex run -f "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex" -o ${ORG_ALIAS} > "${TEST_DIR}/update_${VARIANT_NUM}.log" 2>&1

if grep -q "Compiled successfully" "${TEST_DIR}/update_${VARIANT_NUM}.log"; then
    echo "   ✅ Prompt updated successfully"
else
    echo "   ❌ ERROR: Prompt update failed"
    cat "${TEST_DIR}/update_${VARIANT_NUM}.log"
    exit 1
fi

rm -f "${TEST_DIR}/temp_update_${VARIANT_NUM}.apex"
echo ""

# Step 3: Execute prompt via Prompt Factory  
echo "🚀 Executing prompt via API..."
echo "   Prompt ID: ${PROMPT_ID}"
echo "   Opportunity ID: ${OPP_ID}"
echo ""

# Create Apex script to call executePrompt
cat > "${TEST_DIR}/temp_execute_${VARIANT_NUM}.apex" << APEX_EXECUTE
// Execute prompt for Variant ${VARIANT_NUM}
String promptReqId = 'e6e00b0d8e81c6b1976ac4e458a131ed4e951';
String opportunityId = '${OPP_ID}';

System.debug('Executing prompt: ' + promptReqId + ' for Opportunity: ' + opportunityId);

// Call the execute prompt API via HTTP
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/ccai/v1/executePrompt');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(120000); // 2 minutes

Map<String, Object> body = new Map<String, Object>{
    'promptRequestId' => promptReqId,
    'recordId' => opportunityId,
    'customPromptCommand' => ''
};

req.setBody(JSON.serialize(body));

Http http = new Http();
HTTPResponse res = http.send(req);

System.debug('HTTP Status: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());

if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
    System.debug('✅ Prompt executed successfully');
} else {
    System.debug('❌ ERROR: Prompt execution failed');
}
APEX_EXECUTE

echo "   Calling executePrompt API..."
sf apex run -f "${TEST_DIR}/temp_execute_${VARIANT_NUM}.apex" -o ${ORG_ALIAS} > "${TEST_DIR}/execute_${VARIANT_NUM}.log" 2>&1

if grep -q "✅ Prompt executed successfully" "${TEST_DIR}/execute_${VARIANT_NUM}.log"; then
    echo "   ✅ API call successful"
else
    echo "   ⚠️  Check execution log for status"
fi

rm -f "${TEST_DIR}/temp_execute_${VARIANT_NUM}.apex"
echo ""

# Step 4: Wait for processing
echo "⏳ Waiting for AI processing (30 seconds)..."
sleep 30
echo ""

# Step 5: Query response
echo "📊 Querying AI Response..."
RESPONSE_QUERY="SELECT Id, Name, ccai__Status__c, ccai__Response__c, ccai__Token_Count__c, CreatedDate FROM ccai__AI_Response__c WHERE ccai__AI_Prompt__c = '${PROMPT_ID}' ORDER BY CreatedDate DESC LIMIT 1"

sf data query -q "$RESPONSE_QUERY" -o ${ORG_ALIAS} --json > "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.json"

# Extract response details
RESPONSE_ID=$(jq -r '.result.records[0].Id // "NONE"' "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.json")
RESPONSE_STATUS=$(jq -r '.result.records[0].ccai__Status__c // "NONE"' "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.json")
RESPONSE_TOKENS=$(jq -r '.result.records[0].ccai__Token_Count__c // "0"' "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.json")

echo "   Response ID: ${RESPONSE_ID}"
echo "   Status: ${RESPONSE_STATUS}"
echo "   Tokens: ${RESPONSE_TOKENS}"
echo ""

if [ "$RESPONSE_STATUS" = "Completed" ]; then
    echo "   ✅ AI processing completed successfully"
    
    # Extract HTML output
    jq -r '.result.records[0].ccai__Response__c // ""' "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.json" > "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.html"
    
    HTML_SIZE=$(wc -c < "${TEST_DIR}/outputs/output_${VARIANT_NUM}_${VARIANT_NAME}.html")
    echo "   HTML output size: ${HTML_SIZE} bytes"
else
    echo "   ⚠️  Status: ${RESPONSE_STATUS}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VARIANT ${VARIANT_NUM} COMPLETE"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

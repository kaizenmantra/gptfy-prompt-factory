#!/bin/bash
# Simple prompt update using sf data update
# Usage: ./update_prompt_simple.sh <variant_file>

VARIANT_FILE=$1
PROMPT_ID="a0DQH00000KYLsv2AH"
ORG_ALIAS="agentictso"

if [ ! -f "$VARIANT_FILE" ]; then
    echo "Error: File not found: $VARIANT_FILE"
    exit 1
fi

echo "Reading variant: $VARIANT_FILE"
PROMPT_TEXT=$(cat "$VARIANT_FILE")

echo "Updating prompt $PROMPT_ID..."

# Create JSON payload
cat > /tmp/prompt_update.json << EOF
{
  "ccai__Prompt_Command__c": $(echo "$PROMPT_TEXT" | jq -Rs .)
}
EOF

# Update via REST API using sf
sf data update record -s ccai__AI_Prompt__c -i "$PROMPT_ID" --json-file /tmp/prompt_update.json -o "$ORG_ALIAS"

rm /tmp/prompt_update.json

echo "Update complete!"

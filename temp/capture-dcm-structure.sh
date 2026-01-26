#!/bin/bash
DCM_ID="a05QH000008RggHYAS"
ORG="agentictso"
OUTPUT_DIR="/Users/sgupta/projects-sfdc/gptfy-prompt-factory/temp"

echo "=== Capturing DCM Structure for $DCM_ID ==="
echo ""

# Get DCM Header
echo "1. DCM Header..."
sf data query --query "SELECT Id, Name, ccai__Object_Name__c FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = '$DCM_ID'" --target-org $ORG --json > $OUTPUT_DIR/dcm-header.json

# Get DCM Details (child objects)
echo "2. DCM Details (child/grandchild objects)..."
sf data query --query "SELECT Id, ccai__Object_Name__c, ccai__RelationshipName__c, ccai__Type__c, ccai__Order__c FROM ccai__AI_Data_Extraction_Detail__c WHERE ccai__AI_Data_Extraction_Mapping__c = '$DCM_ID' ORDER BY ccai__Order__c" --target-org $ORG --json > $OUTPUT_DIR/dcm-details.json

# Get DCM Fields
echo "3. DCM Fields..."
sf data query --query "SELECT Id, ccai__Object_Name__c, ccai__Field_Name__c, ccai__Type__c FROM ccai__AI_Data_Extraction_Field__c WHERE ccai__AI_Data_Extraction_Mapping__c = '$DCM_ID' ORDER BY ccai__Object_Name__c, ccai__Field_Name__c" --target-org $ORG --json > $OUTPUT_DIR/dcm-fields.json

echo ""
echo "✅ DCM data captured to $OUTPUT_DIR/"
echo ""

# Summary counts
DETAIL_COUNT=$(cat $OUTPUT_DIR/dcm-details.json | jq '.result.totalSize')
FIELD_COUNT=$(cat $OUTPUT_DIR/dcm-fields.json | jq '.result.totalSize')

echo "Summary:"
echo "  - Detail records (child/grandchild objects): $DETAIL_COUNT"
echo "  - Field records: $FIELD_COUNT"

#!/usr/bin/env python3
"""
Update prompt via Salesforce REST API
"""

import subprocess
import json
import sys
from pathlib import Path

PROMPT_ID = "a0DQH00000KYLsv2AH"
ORG_ALIAS = "agentictso"

def get_access_token():
    """Get Salesforce access token"""
    cmd = f"sf org display --target-org {ORG_ALIAS} --json"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error getting access token: {result.stderr}")
        return None, None
    
    data = json.loads(result.stdout)
    access_token = data['result']['accessToken']
    instance_url = data['result']['instanceUrl']
    
    return access_token, instance_url

def update_prompt_via_rest(variant_file, access_token, instance_url):
    """Update prompt using REST API"""
    # Read variant
    with open(variant_file, 'r') as f:
        prompt_text = f.read()
    
    print(f"Updating prompt with {len(prompt_text)} characters...")
    
    # Create JSON payload
    payload = {
        "ccai__Prompt_Command__c": prompt_text
    }
    
    # Write payload to temp file
    payload_file = "/tmp/prompt_payload.json"
    with open(payload_file, 'w') as f:
        json.dump(payload, f)
    
    # Use curl to update via REST API
    url = f"{instance_url}/services/data/v65.0/sobjects/ccai__AI_Prompt__c/{PROMPT_ID}"
    
    cmd = f"""curl -X PATCH "{url}" \
-H "Authorization: Bearer {access_token}" \
-H "Content-Type: application/json" \
-d @{payload_file}"""
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Prompt updated successfully via REST API")
        return True
    else:
        print(f"❌ Error updating prompt: {result.stderr}")
        print(f"Response: {result.stdout}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 update_via_rest.py <variant_file>")
        sys.exit(1)
    
    variant_file = sys.argv[1]
    
    if not Path(variant_file).exists():
        print(f"Error: File not found: {variant_file}")
        sys.exit(1)
    
    print(f"Getting access token for {ORG_ALIAS}...")
    access_token, instance_url = get_access_token()
    
    if not access_token:
        print("Failed to get access token")
        sys.exit(1)
    
    print(f"Instance URL: {instance_url}")
    print(f"Updating prompt: {PROMPT_ID}")
    print(f"Variant file: {variant_file}")
    print()
    
    success = update_prompt_via_rest(variant_file, access_token, instance_url)
    
    if success:
        print()
        print("🎯 Prompt is ready for execution!")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()

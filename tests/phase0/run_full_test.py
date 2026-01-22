#!/usr/bin/env python3
"""
Phase 0 Full Test - Execute all 5 variants
Uses REST API for prompt updates
"""

import subprocess
import json
import time
import sys
from pathlib import Path

# Configuration
PROMPT_ID = "a0DQH00000KYLsv2AH"
OPP_ID = "006QH00000HjgvlYAB"
PROMPT_REQUEST_ID = "e6e00b0d8e81c6b1976ac4e458a131ed4e951"
ORG_ALIAS = "agentictso"
TEST_DIR = Path("tests/phase0")

VARIANTS = [
    (0, "baseline"),
    (1, "evidence"),
    (2, "diagnostic"),
    (3, "context"),
    (4, "all")
]

def run_command(cmd, timeout=300):
    """Run shell command"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"

def get_access_token():
    """Get Salesforce access token"""
    cmd = f"sf org display --target-org {ORG_ALIAS} --json"
    success, stdout, stderr = run_command(cmd)
    
    if not success:
        return None, None
    
    data = json.loads(stdout)
    return data['result']['accessToken'], data['result']['instanceUrl']

def update_prompt_rest(variant_num, variant_name, access_token, instance_url):
    """Update prompt via REST API"""
    variant_file = TEST_DIR / "variants" / f"variant_{variant_num}_{variant_name}.txt"
    
    with open(variant_file, 'r') as f:
        prompt_text = f.read()
    
    print(f"   Variant size: {len(prompt_text)} characters")
    
    # Create payload
    payload = {"ccai__Prompt_Command__c": prompt_text}
    payload_file = "/tmp/prompt_payload.json"
    with open(payload_file, 'w') as f:
        json.dump(payload, f)
    
    # REST API update
    url = f"{instance_url}/services/data/v65.0/sobjects/ccai__AI_Prompt__c/{PROMPT_ID}"
    cmd = f'curl -s -X PATCH "{url}" -H "Authorization: Bearer {access_token}" -H "Content-Type: application/json" -d @{payload_file}'
    
    success, stdout, stderr = run_command(cmd, timeout=60)
    
    if success and (not stdout or stdout == ""):
        # Empty response means success in PATCH
        print("   ✅ Prompt updated via REST API")
        return True
    else:
        print(f"   ❌ Update failed: {stdout[:200]}")
        return False

def execute_prompt_api(variant_num, access_token, instance_url):
    """Execute prompt via API"""
    url = f"{instance_url}/services/apexrest/ccai/v1/executePrompt"
    
    payload = {
        "promptRequestId": PROMPT_REQUEST_ID,
        "recordId": OPP_ID,
        "customPromptCommand": ""
    }
    
    payload_file = "/tmp/execute_payload.json"
    with open(payload_file, 'w') as f:
        json.dump(payload, f)
    
    cmd = f'curl -s -X POST "{url}" -H "Authorization: Bearer {access_token}" -H "Content-Type: application/json" -d @{payload_file}'
    
    success, stdout, stderr = run_command(cmd, timeout=120)
    
    if success:
        print("   ✅ API called successfully")
        return True
    else:
        print(f"   ⚠️  API call status unknown")
        return False

def query_response(variant_num, variant_name):
    """Query AI response"""
    query = f"SELECT Id, Name, ccai__Status__c, ccai__Response__c, ccai__Token_Count__c, CreatedDate FROM ccai__AI_Response__c WHERE ccai__AI_Prompt__c = '{PROMPT_ID}' ORDER BY CreatedDate DESC LIMIT 1"
    
    cmd = f'sf data query -q "{query}" -o {ORG_ALIAS} --json'
    success, stdout, stderr = run_command(cmd)
    
    if not success:
        return None
    
    try:
        result = json.loads(stdout)
        if result.get('result', {}).get('records'):
            record = result['result']['records'][0]
            
            # Save outputs
            output_file = TEST_DIR / "outputs" / f"output_{variant_num}_{variant_name}.json"
            with open(output_file, 'w') as f:
                json.dump(record, f, indent=2)
            
            html_output = record.get('ccai__Response__c', '')
            html_file = TEST_DIR / "outputs" / f"output_{variant_num}_{variant_name}.html"
            with open(html_file, 'w') as f:
                f.write(html_output)
            
            print(f"   Response ID: {record.get('Id')}")
            print(f"   Status: {record.get('ccai__Status__c')}")
            print(f"   Tokens: {record.get('ccai__Token_Count__c')}")
            print(f"   HTML size: {len(html_output)} chars")
            
            return record
        else:
            print("   ⚠️  No response found")
            return None
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None

def run_variant(variant_num, variant_name, access_token, instance_url):
    """Execute full test for one variant"""
    print()
    print("━" * 70)
    print(f"🧪 VARIANT {variant_num}: {variant_name.upper()}")
    print("━" * 70)
    print(f"Started: {time.strftime('%H:%M:%S')}")
    print()
    
    # Step 1: Update prompt
    print("📝 Updating prompt...")
    if not update_prompt_rest(variant_num, variant_name, access_token, instance_url):
        print(f"❌ Variant {variant_num} FAILED")
        return False
    
    print()
    
    # Step 2: Execute via API
    print("🚀 Executing prompt...")
    execute_prompt_api(variant_num, access_token, instance_url)
    
    print()
    
    # Step 3: Wait for processing
    print("⏳ Waiting for AI processing (90 seconds)...")
    for i in range(9):
        time.sleep(10)
        print(f"   {(i+1)*10}s...", end=" ", flush=True)
    print()
    print()
    
    # Step 4: Query response (with retries)
    print("📊 Querying response...")
    for attempt in range(3):
        response = query_response(variant_num, variant_name)
        if response and response.get('ccai__Status__c') == 'Completed':
            print()
            print(f"✅ VARIANT {variant_num} COMPLETE - {time.strftime('%H:%M:%S')}")
            print("━" * 70)
            return True
        
        if attempt < 2:
            print(f"   Retry {attempt + 2}/3 in 20s...")
            time.sleep(20)
    
    print()
    print(f"⚠️  VARIANT {variant_num} STATUS UNKNOWN - {time.strftime('%H:%M:%S')}")
    print("━" * 70)
    return False

def main():
    print()
    print("=" * 70)
    print("🚀 PHASE 0 QUALITY TEST - FULL EXECUTION")
    print("=" * 70)
    print(f"Test Opportunity: {OPP_ID}")
    print(f"Test Prompt: {PROMPT_ID}")
    print(f"Total Variants: {len(VARIANTS)}")
    print(f"Estimated Time: ~{len(VARIANTS) * 2} minutes")
    print("=" * 70)
    
    # Get access token once
    print("\n🔑 Getting access token...")
    access_token, instance_url = get_access_token()
    
    if not access_token:
        print("❌ Failed to get access token")
        sys.exit(1)
    
    print(f"✅ Connected to: {instance_url}\n")
    
    # Run all variants
    results = []
    for variant_num, variant_name in VARIANTS:
        success = run_variant(variant_num, variant_name, access_token, instance_url)
        results.append((variant_num, variant_name, success))
        
        if variant_num < VARIANTS[-1][0]:
            print(f"\n⏸️  Brief pause before next variant...\n")
            time.sleep(5)
    
    # Summary
    print()
    print("=" * 70)
    print("📊 TEST EXECUTION SUMMARY")
    print("=" * 70)
    passed = 0
    for variant_num, variant_name, success in results:
        status = "✅ PASS" if success else "⚠️  CHECK"
        print(f"  Variant {variant_num} ({variant_name:12s}): {status}")
        if success:
            passed += 1
    print("=" * 70)
    print(f"Completed: {passed}/{len(VARIANTS)} variants")
    print()
    
    print("🎯 Next: Run scoring analysis")
    print("   Command: python3 tests/phase0/score_outputs.py")
    print()

if __name__ == "__main__":
    main()

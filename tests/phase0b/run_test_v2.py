#!/usr/bin/env python3
"""
Phase 0B Test Execution - Using REST API (working approach from Phase 0)
"""

import json
import subprocess
import time
from pathlib import Path
from datetime import datetime

# Configuration
PROMPT_ID = "a0DQH00000KYLsv2AH"
OPP_ID = "006QH00000HjgvlYAB"
PROMPT_REQUEST_ID = "e6e00b0d8e81c6b1976ac4e458a131ed4e951"
ORG_ALIAS = "agentictso"
TEST_DIR = Path("tests/phase0b")

VARIANTS = [
    (15, "risk_visual"),
    (16, "action_cards"),
    (18, "timeline_visual"),
    (19, "multi_pattern_architecture"),
    (20, "account360_enhanced")
]

def run_command(cmd, timeout=60):
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
        return False, "", "Timeout"

def get_credentials():
    """Get Salesforce credentials"""
    cmd = f"sf org display -o {ORG_ALIAS} --json"
    success, stdout, stderr = run_command(cmd)
    if not success:
        raise Exception("Failed to get credentials")
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
    
    if success and (not stdout or stdout.strip() == ""):
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
        print("   ✅ API called")
        return True
    else:
        print(f"   ⚠️  API call failed")
        return False

def query_response(variant_num, variant_name):
    """Query AI response"""
    # Wait for processing
    print("   ⏳ Waiting 20 seconds for AI processing...")
    time.sleep(20)
    
    query = f"SELECT Id, ccai__Status__c, ccai__AI_Processed_Data_No_PII__c FROM ccai__AI_Response__c WHERE ccai__AI_Prompt__c = '{PROMPT_ID}' AND ccai__Record_Id__c = '{OPP_ID}' ORDER BY CreatedDate DESC LIMIT 1"
    
    cmd = f'sf data query -q "{query}" -o {ORG_ALIAS} --json'
    success, stdout, stderr = run_command(cmd, timeout=60)
    
    if not success:
        print(f"   ❌ Query failed")
        return None
    
    try:
        result = json.loads(stdout)
        if not result.get('result', {}).get('records'):
            print("   ❌ No response record found")
            return None
        
        record = result['result']['records'][0]
        response_id = record['Id']
        status = record['ccai__Status__c']
        
        print(f"   ✅ Found response: {response_id} (Status: {status})")
        
        # Save full record
        output_dir = TEST_DIR / "outputs"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        output_file = output_dir / f"output_{variant_num}_{variant_name}.json"
        with open(output_file, 'w') as f:
            json.dump(record, f, indent=2)
        
        # Extract HTML
        processed_data_str = record.get('ccai__AI_Processed_Data_No_PII__c')
        if not processed_data_str:
            print("   ⚠️ No processed data found")
            return None
        
        processed_data = json.loads(processed_data_str)
        html_content = processed_data['data']['value']['choices'][0]['message']['content']
        
        # Save HTML
        html_file = output_dir / f"output_{variant_num}_{variant_name}.html"
        with open(html_file, 'w') as f:
            f.write(html_content)
        
        html_size = len(html_content)
        print(f"   ✅ Saved output ({html_size:,} bytes)")
        
        return {
            "response_id": response_id,
            "status": status,
            "html_size": html_size
        }
    
    except Exception as e:
        print(f"   ❌ Error processing response: {e}")
        return None

def main():
    """Main execution"""
    print("=" * 70)
    print("PHASE 0B: PATTERN TESTING - v2 (REST API)")
    print("=" * 70)
    print(f"\nStarted: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Get credentials
    print("🔑 Getting credentials...")
    try:
        access_token, instance_url = get_credentials()
        print(f"✅ Connected to: {instance_url}\n")
    except Exception as e:
        print(f"❌ Failed: {e}")
        return
    
    results = []
    
    for variant_num, variant_name in VARIANTS:
        print(f"{'=' * 70}")
        print(f"VARIANT {variant_num}: {variant_name}")
        print(f"{'=' * 70}")
        
        # Update prompt
        print(f"📝 Updating prompt...")
        if not update_prompt_rest(variant_num, variant_name, access_token, instance_url):
            print(f"⚠️ Skipping Variant {variant_num}\n")
            continue
        
        time.sleep(3)
        
        # Execute
        print(f"🚀 Executing prompt...")
        if not execute_prompt_api(variant_num, access_token, instance_url):
            print(f"⚠️ Skipping Variant {variant_num}\n")
            continue
        
        # Query response
        print(f"📊 Querying response...")
        response_data = query_response(variant_num, variant_name)
        
        if response_data:
            results.append({
                "variant_num": variant_num,
                "variant_name": variant_name,
                **response_data
            })
            print(f"\n✅ Variant {variant_num} COMPLETE!\n")
        
        time.sleep(10)
    
    # Summary
    print(f"{'=' * 70}")
    print(f"SUMMARY")
    print(f"{'=' * 70}")
    print(f"Successful: {len(results)}/{len(VARIANTS)}")
    
    for r in results:
        print(f"  V{r['variant_num']}: {r['status']} | {r['html_size']:,} bytes")
    
    # Save
    summary_file = TEST_DIR / "outputs" / "execution_summary.json"
    with open(summary_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n✅ Saved to: {summary_file}")
    print(f"📊 Next: Run score_phase0b_outputs.py")

if __name__ == "__main__":
    main()

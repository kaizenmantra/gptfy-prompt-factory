#!/usr/bin/env python3
"""
Phase 0 Test Execution Script
Executes all 5 prompt variants and captures responses
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

def run_sf_command(cmd):
    """Run Salesforce CLI command and return result"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=300
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"

def update_prompt(variant_num, variant_name):
    """Update prompt with variant content"""
    print(f"📝 Updating prompt with Variant {variant_num} ({variant_name})...")
    
    # Read variant file
    variant_file = TEST_DIR / "variants" / f"variant_{variant_num}_{variant_name}.txt"
    with open(variant_file, 'r') as f:
        prompt_text = f.read()
    
    print(f"   Variant size: {len(prompt_text)} characters")
    
    # Create Apex script to update
    apex_script = f"""
ccai__AI_Prompt__c prompt = [SELECT Id FROM ccai__AI_Prompt__c WHERE Id = '{PROMPT_ID}'];
prompt.ccai__Prompt_Command__c = {json.dumps(prompt_text)};
update prompt;
System.debug('✅ Prompt updated with Variant {variant_num}');
"""
    
    # Write to temp file
    temp_apex = TEST_DIR / f"temp_update_{variant_num}.apex"
    with open(temp_apex, 'w') as f:
        f.write(apex_script)
    
    # Execute
    cmd = f"sf apex run -f {temp_apex} -o {ORG_ALIAS}"
    success, stdout, stderr = run_sf_command(cmd)
    
    # Cleanup
    temp_apex.unlink()
    
    if success and ("Compiled successfully" in stdout or "Executed successfully" in stdout):
        print("   ✅ Prompt updated successfully")
        return True
    else:
        print(f"   ❌ ERROR: Prompt update failed")
        print(f"   STDOUT: {stdout[:500]}")
        print(f"   STDERR: {stderr[:500]}")
        return False

def execute_prompt(variant_num):
    """Execute prompt via API"""
    print(f"🚀 Executing prompt via API...")
    
    # Create Apex script to call API
    apex_script = f"""
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/ccai/v1/executePrompt');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setTimeout(120000);

Map<String, Object> body = new Map<String, Object>{{
    'promptRequestId' => '{PROMPT_REQUEST_ID}',
    'recordId' => '{OPP_ID}',
    'customPromptCommand' => ''
}};

req.setBody(JSON.serialize(body));

Http http = new Http();
HTTPResponse res = http.send(req);

System.debug('HTTP Status: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());

if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {{
    System.debug('✅ API call successful');
}} else {{
    System.debug('❌ API call failed');
}}
"""
    
    # Write to temp file
    temp_apex = TEST_DIR / f"temp_execute_{variant_num}.apex"
    with open(temp_apex, 'w') as f:
        f.write(apex_script)
    
    # Execute
    cmd = f"sf apex run -f {temp_apex} -o {ORG_ALIAS}"
    success, stdout, stderr = run_sf_command(cmd)
    
    # Cleanup
    temp_apex.unlink()
    
    if success:
        print("   ✅ API called successfully")
        return True
    else:
        print(f"   ⚠️  Check logs for API status")
        print(f"   STDOUT: {stdout[:500]}")
        return False

def query_response(variant_num, variant_name):
    """Query AI response"""
    print(f"📊 Querying AI Response...")
    
    query = f"SELECT Id, Name, ccai__Status__c, ccai__Response__c, ccai__Token_Count__c, CreatedDate FROM ccai__AI_Response__c WHERE ccai__AI_Prompt__c = '{PROMPT_ID}' ORDER BY CreatedDate DESC LIMIT 1"
    
    cmd = f'sf data query -q "{query}" -o {ORG_ALIAS} --json'
    success, stdout, stderr = run_sf_command(cmd)
    
    if not success:
        print(f"   ❌ Query failed")
        return None
    
    try:
        result = json.loads(stdout)
        if result.get('result', {}).get('records'):
            record = result['result']['records'][0]
            
            # Save full response
            output_file = TEST_DIR / "outputs" / f"output_{variant_num}_{variant_name}.json"
            with open(output_file, 'w') as f:
                json.dump(record, f, indent=2)
            
            # Save HTML separately
            html_output = record.get('ccai__Response__c', '')
            html_file = TEST_DIR / "outputs" / f"output_{variant_num}_{variant_name}.html"
            with open(html_file, 'w') as f:
                f.write(html_output)
            
            print(f"   Response ID: {record.get('Id')}")
            print(f"   Status: {record.get('ccai__Status__c')}")
            print(f"   Tokens: {record.get('ccai__Token_Count__c')}")
            print(f"   HTML size: {len(html_output)} characters")
            
            return record
        else:
            print("   ⚠️  No response found yet")
            return None
    except json.JSONDecodeError as e:
        print(f"   ❌ Failed to parse response: {e}")
        return None

def run_variant(variant_num, variant_name):
    """Run complete test for one variant"""
    print()
    print("━" * 60)
    print(f"🧪 VARIANT {variant_num}: {variant_name.upper()}")
    print("━" * 60)
    print(f"Started: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Step 1: Update prompt
    if not update_prompt(variant_num, variant_name):
        print(f"❌ Variant {variant_num} FAILED at update step")
        return False
    
    print()
    
    # Step 2: Execute prompt
    if not execute_prompt(variant_num):
        print(f"⚠️  Variant {variant_num} API call may have issues")
    
    print()
    
    # Step 3: Wait for processing
    print("⏳ Waiting for AI processing (60 seconds)...")
    time.sleep(60)
    print()
    
    # Step 4: Query response (with retries)
    max_retries = 3
    response = None
    for attempt in range(max_retries):
        response = query_response(variant_num, variant_name)
        if response and response.get('ccai__Status__c') == 'Completed':
            break
        if attempt < max_retries - 1:
            print(f"   Retrying in 30 seconds... (attempt {attempt + 2}/{max_retries})")
            time.sleep(30)
    
    print()
    print("━" * 60)
    if response and response.get('ccai__Status__c') == 'Completed':
        print(f"✅ VARIANT {variant_num} COMPLETE")
    else:
        print(f"⚠️  VARIANT {variant_num} COMPLETED WITH WARNINGS")
    print(f"Finished: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("━" * 60)
    print()
    
    return True

def main():
    """Main execution"""
    print()
    print("=" * 60)
    print("🚀 PHASE 0 QUALITY TEST - FULL EXECUTION")
    print("=" * 60)
    print(f"Test Opportunity: {OPP_ID}")
    print(f"Test Prompt: {PROMPT_ID}")
    print(f"Org: {ORG_ALIAS}")
    print()
    print(f"Total Variants: {len(VARIANTS)}")
    print(f"Estimated Time: ~{len(VARIANTS) * 2} minutes")
    print("=" * 60)
    
    results = []
    for variant_num, variant_name in VARIANTS:
        success = run_variant(variant_num, variant_name)
        results.append((variant_num, variant_name, success))
        
        # Brief pause between variants
        if variant_num < VARIANTS[-1][0]:
            print(f"⏸️  Pausing 10 seconds before next variant...\n")
            time.sleep(10)
    
    # Summary
    print()
    print("=" * 60)
    print("📊 TEST EXECUTION SUMMARY")
    print("=" * 60)
    for variant_num, variant_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"  Variant {variant_num} ({variant_name}): {status}")
    print("=" * 60)
    print()
    
    print("🎯 Next step: Run scoring script to analyze results")
    print("   Command: python3 tests/phase0/score_outputs.py")
    print()

if __name__ == "__main__":
    main()

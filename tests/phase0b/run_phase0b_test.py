#!/usr/bin/env python3
"""
Phase 0B Pattern Testing Script
Tests different analytical patterns and UI components
Uses same framework as Phase 0 but with enhanced scoring
"""

import json
import subprocess
import time
from pathlib import Path
from datetime import datetime

# Configuration
PROMPT_ID = "a0DQH00000KYLsv2AH"
OPPORTUNITY_ID = "006QH00000HjgvlYAB"
ORG_ALIAS = "agentictso"

# Test variants
VARIANTS = [
    {"num": 15, "name": "Risk Visual", "file": "variant_15_risk_visual.txt"},
    {"num": 16, "name": "Action Cards", "file": "variant_16_action_cards.txt"},
    {"num": 18, "name": "Timeline Visual", "file": "variant_18_timeline_visual.txt"},
    {"num": 19, "name": "Multi-Pattern Architecture", "file": "variant_19_multi_pattern_architecture.txt"},
    {"num": 20, "name": "Account360 Enhanced", "file": "variant_20_account360_enhanced.txt"},
]

def get_org_credentials():
    """Get Salesforce org credentials"""
    print("🔑 Getting Salesforce org credentials...")
    result = subprocess.run(
        ["sf", "org", "display", "--target-org", ORG_ALIAS, "--json"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        raise Exception(f"Failed to get org credentials: {result.stderr}")
    
    data = json.loads(result.stdout)
    return {
        "access_token": data["result"]["accessToken"],
        "instance_url": data["result"]["instanceUrl"]
    }

def update_prompt_apex(variant_num, variant_name):
    """Update AI_Prompt__c record via Apex Anonymous"""
    print(f"\n📝 Updating prompt with Variant {variant_num}: {variant_name}...")
    
    # Read variant file
    variant_files = list(Path("tests/phase0b/variants").glob(f"variant_{variant_num}_*.txt"))
    
    if not variant_files:
        print(f"❌ Variant file not found for variant {variant_num}")
        return False
    
    with open(variant_files[0], 'r') as f:
        prompt_content = f.read()
    
    print(f"   Variant size: {len(prompt_content)} characters")
    
    # Create Apex script to update
    apex_script = f"""
ccai__AI_Prompt__c prompt = [SELECT Id FROM ccai__AI_Prompt__c WHERE Id = '{PROMPT_ID}'];
prompt.ccai__Prompt_Command__c = {json.dumps(prompt_content)};
update prompt;
System.debug('✅ Prompt updated with Variant {variant_num}');
"""
    
    # Write to temp file
    temp_apex = Path(f"tests/phase0b/temp_update_{variant_num}.apex")
    with open(temp_apex, 'w') as f:
        f.write(apex_script)
    
    # Execute
    result = subprocess.run(
        ["sf", "apex", "run", "-f", str(temp_apex), "-o", ORG_ALIAS],
        capture_output=True,
        text=True,
        timeout=60
    )
    
    # Cleanup
    if temp_apex.exists():
        temp_apex.unlink()
    
    # Check for success
    if result.returncode == 0:
        if ("Compiled successfully" in result.stdout and "Executed successfully" in result.stdout):
            print("   ✅ Prompt updated successfully")
            return True
        elif result.returncode == 0:
            # If return code is 0, consider it success even if message is different
            print("   ✅ Prompt updated (return code 0)")
            return True
    
    print(f"   ❌ ERROR: Prompt update failed (return code: {result.returncode})")
    print(f"   STDOUT: {result.stdout[:300]}")
    print(f"   STDERR: {result.stderr[:300]}")
    return False

def execute_prompt_api(variant_num, variant_name, access_token, instance_url):
    """Execute prompt via /services/apexrest/ccai/v1/executePrompt API"""
    print(f"\n🚀 Executing Variant {variant_num}: {variant_name}...")
    
    url = f"{instance_url}/services/apexrest/ccai/v1/executePrompt"
    
    payload = {
        "recordId": OPPORTUNITY_ID,
        "promptId": PROMPT_ID
    }
    
    payload_file = Path("/tmp/execute_prompt_payload.json")
    with open(payload_file, 'w') as f:
        json.dump(payload, f)
    
    curl_cmd = [
        "curl", "-X", "POST",
        url,
        "-H", f"Authorization: Bearer {access_token}",
        "-H", "Content-Type: application/json",
        "-d", f"@{payload_file}",
        "--silent"
    ]
    
    result = subprocess.run(curl_cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ Failed to execute prompt: {result.stderr}")
        return None
    
    response = json.loads(result.stdout) if result.stdout else {}
    
    if response.get("success"):
        print(f"✅ Execution successful: {response.get('message')}")
        return response
    else:
        print(f"❌ Execution failed: {response.get('message')}")
        return None

def query_response(variant_num, variant_name):
    """Query AI_Response__c record to get output"""
    print(f"\n📊 Querying response for Variant {variant_num}...")
    
    # Wait for AI processing
    print("⏳ Waiting 15 seconds for AI processing...")
    time.sleep(15)
    
    # Query for the response
    query = f"""
    SELECT Id, ccai__Status__c, ccai__AI_Processed_Data_No_PII__c 
    FROM ccai__AI_Response__c 
    WHERE ccai__AI_Prompt__c = '{PROMPT_ID}' 
    AND ccai__Record_Id__c = '{OPPORTUNITY_ID}'
    ORDER BY CreatedDate DESC 
    LIMIT 1
    """
    
    result = subprocess.run(
        ["sf", "data", "query", "--query", query, "--target-org", ORG_ALIAS, "--json"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"❌ Query failed: {result.stderr}")
        return None
    
    data = json.loads(result.stdout)
    
    if not data["result"]["records"]:
        print("❌ No response record found")
        return None
    
    record = data["result"]["records"][0]
    response_id = record["Id"]
    status = record["ccai__Status__c"]
    
    print(f"✅ Found response: {response_id} (Status: {status})")
    
    # Save full record
    output_dir = Path("tests/phase0b/outputs")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    with open(output_dir / f"output_{variant_num}_{variant_name.lower().replace(' ', '_')}.json", 'w') as f:
        json.dump(record, f, indent=2)
    
    # Extract HTML from nested JSON
    try:
        processed_data_str = record["ccai__AI_Processed_Data_No_PII__c"]
        processed_data = json.loads(processed_data_str)
        html_content = processed_data["data"]["value"]["choices"][0]["message"]["content"]
        
        # Save HTML
        with open(output_dir / f"output_{variant_num}_{variant_name.lower().replace(' ', '_')}.html", 'w') as f:
            f.write(html_content)
        
        html_size = len(html_content)
        print(f"✅ Saved output ({html_size:,} bytes)")
        
        return {
            "response_id": response_id,
            "status": status,
            "html_content": html_content,
            "html_size": html_size
        }
    
    except Exception as e:
        print(f"❌ Failed to extract HTML: {e}")
        return None

def main():
    """Main test execution"""
    print("=" * 70)
    print("PHASE 0B: PATTERN & UI COMPONENT TESTING")
    print("=" * 70)
    print(f"\nTest Configuration:")
    print(f"  Prompt ID: {PROMPT_ID}")
    print(f"  Opportunity ID: {OPPORTUNITY_ID}")
    print(f"  Total Variants: {len(VARIANTS)}")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Get credentials
    try:
        creds = get_org_credentials()
        print(f"✅ Connected to org: {creds['instance_url']}")
    except Exception as e:
        print(f"❌ Failed to get credentials: {e}")
        return
    
    # Execute each variant
    results = []
    
    for variant in VARIANTS:
        print(f"\n{'=' * 70}")
        print(f"TESTING VARIANT {variant['num']}: {variant['name']}")
        print(f"{'=' * 70}")
        
        # Update prompt using Apex Anonymous
        if not update_prompt_apex(variant["num"], variant["name"]):
            print(f"⚠️ Skipping execution for Variant {variant['num']}")
            continue
        
        # Wait a moment
        time.sleep(3)
        
        # Execute prompt
        exec_result = execute_prompt_api(variant["num"], variant["name"], creds["access_token"], creds["instance_url"])
        
        if not exec_result:
            print(f"⚠️ Skipping query for Variant {variant['num']}")
            continue
        
        # Query response
        response_data = query_response(variant["num"], variant["name"])
        
        if response_data:
            results.append({
                "variant_num": variant["num"],
                "variant_name": variant["name"],
                **response_data
            })
        
        print(f"\n✅ Variant {variant['num']} complete!")
        print(f"⏸️ Waiting 10 seconds before next variant...")
        time.sleep(10)
    
    # Summary
    print(f"\n{'=' * 70}")
    print("TEST EXECUTION SUMMARY")
    print(f"{'=' * 70}")
    print(f"\nCompleted: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Successful executions: {len(results)}/{len(VARIANTS)}")
    
    if results:
        print(f"\nResults Summary:")
        for r in results:
            print(f"  Variant {r['variant_num']} ({r['variant_name']}): {r['status']} | {r['html_size']:,} bytes")
    
    # Save results summary
    with open("tests/phase0b/outputs/execution_summary.json", 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n✅ All tests complete! Results saved to tests/phase0b/outputs/")
    print(f"📊 Next: Run score_phase0b_outputs.py to analyze quality")

if __name__ == "__main__":
    main()

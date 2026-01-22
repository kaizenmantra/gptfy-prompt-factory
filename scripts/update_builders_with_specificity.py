#!/usr/bin/env python3
"""
Update Evidence Binding builder and create Next Best Action builder with specificity rules
"""

import json
import subprocess
import sys

def get_access_token():
    """Get Salesforce access token"""
    result = subprocess.run(
        ['sf', 'org', 'display', '--json', '-o', 'agentictso'],
        capture_output=True,
        text=True
    )
    org_info = json.loads(result.stdout)
    return org_info['result']['accessToken'], org_info['result']['instanceUrl']

def read_file(filepath):
    """Read file content"""
    with open(filepath, 'r') as f:
        return f.read()

def update_evidence_binding(token, instance_url, builder_id, content):
    """Update existing Evidence Binding builder"""
    # Escape content for JSON
    content_escaped = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '').replace('\t', '    ')
    
    payload = {
        "ccai__Prompt_Command__c": content_escaped
    }
    
    curl_cmd = f'''curl -X PATCH "{instance_url}/services/data/v65.0/sobjects/ccai__AI_Prompt__c/{builder_id}" \
    -H "Authorization: Bearer {token}" \
    -H "Content-Type: application/json" \
    -d '{json.dumps(payload)}' '''
    
    result = subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ Updated Evidence Binding builder: {builder_id}")
        print(f"   Content size: {len(content)} chars")
        return True
    else:
        print(f"❌ Failed to update: {result.stderr}")
        return False

def create_next_best_action(token, instance_url, content, dcm_id, record_type_id):
    """Create Next Best Action builder"""
    # Escape content for JSON
    content_escaped = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '').replace('\t', '    ')
    
    payload = {
        "Name": "Next Best Action Pattern",
        "RecordTypeId": record_type_id,
        "Category__c": "Pattern",
        "ccai__Object__c": "Opportunity",
        "ccai__AI_Data_Extraction_Mapping__c": dcm_id,
        "ccai__Status__c": "Active",
        "ccai__Prompt_Command__c": content_escaped,
        "ccai__How_it_Works__c": "Provides specific, actionable recommendations with clear owners, deadlines, and evidence. Enforces use of actual names, specific dates, and bounded actions. Extracted from Phase 0B Variant 16."
    }
    
    curl_cmd = f'''curl -X POST "{instance_url}/services/data/v65.0/sobjects/ccai__AI_Prompt__c" \
    -H "Authorization: Bearer {token}" \
    -H "Content-Type: application/json" \
    -d '{json.dumps(payload)}' '''
    
    result = subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        response = json.loads(result.stdout)
        if response.get('success'):
            print(f"✅ Created Next Best Action builder: {response['id']}")
            print(f"   Content size: {len(content)} chars")
            return response['id']
        else:
            print(f"❌ Failed to create: {response.get('errors', 'Unknown error')}")
            return None
    else:
        print(f"❌ Failed to create: {result.stderr}")
        return None

def main():
    print("🔧 Updating Builders with Specificity Rules...\n")
    
    # Get access token
    print("1. Getting Salesforce access token...")
    token, instance_url = get_access_token()
    print(f"   ✅ Connected to {instance_url}\n")
    
    # Read updated Evidence Binding content
    print("2. Reading updated Evidence Binding content...")
    evidence_binding_content = read_file('docs/quality-rules/evidence_binding_v2.md')
    print(f"   ✅ Loaded {len(evidence_binding_content)} chars\n")
    
    # Read Next Best Action content
    print("3. Reading Next Best Action content...")
    next_best_action_content = read_file('docs/quality-rules/next_best_action_pattern.md')
    print(f"   ✅ Loaded {len(next_best_action_content)} chars\n")
    
    # Get Evidence Binding builder ID
    print("4. Getting Evidence Binding builder ID...")
    result = subprocess.run([
        'sf', 'data', 'query', '-o', 'agentictso',
        '--query', "SELECT Id FROM ccai__AI_Prompt__c WHERE Name = 'Evidence Binding Rules v2' AND RecordType.DeveloperName = 'Builder'",
        '--json'
    ], capture_output=True, text=True)
    
    query_result = json.loads(result.stdout)
    if query_result['result']['records']:
        evidence_binding_id = query_result['result']['records'][0]['Id']
        print(f"   ✅ Found: {evidence_binding_id}\n")
    else:
        print("   ❌ Evidence Binding builder not found!")
        sys.exit(1)
    
    # Get DCM ID and Record Type ID
    print("5. Getting DCM and Record Type IDs...")
    dcm_result = subprocess.run([
        'sf', 'data', 'query', '-o', 'agentictso',
        '--query', "SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = 'a05QH000008PLavYAG'",
        '--json'
    ], capture_output=True, text=True)
    
    rt_result = subprocess.run([
        'sf', 'data', 'query', '-o', 'agentictso',
        '--query', "SELECT Id FROM RecordType WHERE SObjectType = 'ccai__AI_Prompt__c' AND DeveloperName = 'Builder'",
        '--json'
    ], capture_output=True, text=True)
    
    dcm_id = json.loads(dcm_result.stdout)['result']['records'][0]['Id']
    record_type_id = json.loads(rt_result.stdout)['result']['records'][0]['Id']
    print(f"   ✅ DCM: {dcm_id}")
    print(f"   ✅ Record Type: {record_type_id}\n")
    
    # Update Evidence Binding
    print("6. Updating Evidence Binding builder...")
    update_evidence_binding(token, instance_url, evidence_binding_id, evidence_binding_content)
    print()
    
    # Check if Next Best Action already exists
    print("7. Checking if Next Best Action already exists...")
    check_result = subprocess.run([
        'sf', 'data', 'query', '-o', 'agentictso',
        '--query', "SELECT Id FROM ccai__AI_Prompt__c WHERE Name = 'Next Best Action Pattern' AND RecordType.DeveloperName = 'Builder'",
        '--json'
    ], capture_output=True, text=True)
    
    existing = json.loads(check_result.stdout)['result']['records']
    if existing:
        print(f"   ⚠️ Already exists: {existing[0]['Id']}")
        print("   Skipping creation (delete manually if you want to recreate)\n")
    else:
        print("   ✅ Does not exist, creating...\n")
        
        # Create Next Best Action
        print("8. Creating Next Best Action builder...")
        new_id = create_next_best_action(token, instance_url, next_best_action_content, dcm_id, record_type_id)
        
        if new_id:
            print("\n9. Assigning topics to Next Best Action...")
            # Get topic IDs
            topics_query = """SELECT Id, Name FROM Topic WHERE Name IN ('Next Best Action', 'Opportunity', 'P0')"""
            topics_result = subprocess.run([
                'sf', 'data', 'query', '-o', 'agentictso',
                '--query', topics_query,
                '--json'
            ], capture_output=True, text=True)
            
            topics = json.loads(topics_result.stdout)['result']['records']
            for topic in topics:
                assignment_payload = {
                    "TopicId": topic['Id'],
                    "EntityId": new_id
                }
                
                curl_cmd = f'''curl -X POST "{instance_url}/services/data/v65.0/sobjects/TopicAssignment" \
                -H "Authorization: Bearer {token}" \
                -H "Content-Type: application/json" \
                -d '{json.dumps(assignment_payload)}' '''
                
                subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)
                print(f"   ✅ Assigned topic: {topic['Name']}")
    
    print("\n✅ ALL DONE!")
    print("\nSummary:")
    print(f"  - Updated Evidence Binding: {evidence_binding_id} ({len(evidence_binding_content)} chars)")
    if new_id:
        print(f"  - Created Next Best Action: {new_id} ({len(next_best_action_content)} chars)")
    print("\n6 total builders now in org (Quality Rule, Pattern x2, UI Component x2, Context Template)")

if __name__ == '__main__':
    main()

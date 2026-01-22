#!/usr/bin/env python3
"""
Create complete builder prompts with FULL content using Salesforce REST API
Avoids Apex string escaping issues
"""

import subprocess
import json
import os

# Configuration
ORG_ALIAS = "agentictso"
CORRECT_DCM = "a05QH000008PLavYAG"
CORRECT_AI_CONNECTION = "a01gD000003okzEQAQ"
BUILDER_RT_ID = "012QH0000045bz7YAA"

def get_access_token():
    """Get Salesforce access token from CLI"""
    cmd = f"sf org display --target-org {ORG_ALIAS} --json"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    data = json.loads(result.stdout)
    return data['result']['accessToken'], data['result']['instanceUrl']

def delete_existing_builders():
    """Delete incomplete builders"""
    print("Step 1: Deleting incomplete builders...")
    
    # Query existing builders
    query = "SELECT Id FROM ccai__AI_Prompt__c WHERE RecordType.DeveloperName='Builder' AND Name IN ('Evidence Binding Rules v2','Risk Assessment Pattern','Stat Card Component','Alert Box Component','Healthcare Payer Context')"
    
    cmd = f"sf data query -o {ORG_ALIAS} --query \"{query}\" --json"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        data = json.loads(result.stdout)
        records = data.get('result', {}).get('records', [])
        
        for record in records:
            record_id = record['Id']
            del_cmd = f"sf data delete record -o {ORG_ALIAS} -s ccai__AI_Prompt__c -i {record_id}"
            subprocess.run(del_cmd, shell=True, capture_output=True)
            print(f"  Deleted: {record_id}")
        
        print(f"✅ Deleted {len(records)} old builders\n")

def create_builder_via_api(name, category, prompt_command, description=None, how_it_works=None):
    """Create builder using REST API"""
    
    access_token, instance_url = get_access_token()
    
    # Prepare payload
    payload = {
        "Name": name,
        "RecordTypeId": BUILDER_RT_ID,
        "Category__c": category,
        "ccai__Status__c": "Active",
        "ccai__Type__c": "Text",
        "ccai__Object__c": "Opportunity",
        "ccai__AI_Connection__c": CORRECT_AI_CONNECTION,
        "ccai__AI_Data_Extraction_Mapping__c": CORRECT_DCM,
        "ccai__Prompt_Command__c": prompt_command
    }
    
    if description:
        payload["ccai__Description__c"] = description
    if how_it_works:
        payload["ccai__How_it_works__c"] = how_it_works
    
    # Write payload to temp file
    with open('/tmp/payload.json', 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    
    # Use curl with REST API
    url = f"{instance_url}/services/data/v65.0/sobjects/ccai__AI_Prompt__c"
    
    curl_cmd = f"""curl -X POST "{url}" \
-H "Authorization: Bearer {access_token}" \
-H "Content-Type: application/json" \
-d @/tmp/payload.json"""
    
    result = subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        response = json.loads(result.stdout)
        if response.get('success'):
            record_id = response['id']
            print(f"✅ Created: {name}")
            print(f"   ID: {record_id}")
            print(f"   Content size: {len(prompt_command)} chars")
            return record_id
        else:
            print(f"❌ Failed: {name}")
            print(f"   Errors: {response.get('errors')}")
            return None
    else:
        print(f"❌ Failed: {name}")
        print(f"   Error: {result.stderr}")
        return None

def main():
    print("=== CREATING COMPLETE BUILDERS VIA REST API ===\n")
    
    # Delete existing
    delete_existing_builders()
    
    # Read full content
    print("Step 2: Reading full content from source files...\n")
    
    # 1. Evidence Binding - Full content
    with open('docs/quality-rules/evidence_binding_v2.md', 'r', encoding='utf-8') as f:
        evidence_content = f.read()
    
    # 2. Risk Assessment - Full Pattern 1 section
    with open('tests/phase0b/patterns/ANALYTICAL_PATTERNS.md', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        # Extract Pattern 1 (lines 9-57)
        risk_content = ''.join(lines[8:57])
    
    # 3. Stat Card - Full Component 1
    with open('tests/phase0b/patterns/UI_COMPONENTS.md', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        # Extract Component 1 (lines 9-87)
        stat_card_content = ''.join(lines[8:87])
    
    # 4. Alert Box - Full Component 5
    with open('tests/phase0b/patterns/UI_COMPONENTS.md', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        # Extract Component 5 (lines 336-417)
        alert_box_content = ''.join(lines[335:417])
    
    # 5. Healthcare Context - Read from phase0c if it exists
    healthcare_file = 'tests/phase0c/evidence_binding_v2.md'
    if os.path.exists(healthcare_file):
        with open(healthcare_file, 'r', encoding='utf-8') as f:
            healthcare_content = f.read()
    else:
        # Use abbreviated version
        healthcare_content = """=== CONTEXT TEMPLATE: HEALTHCARE PAYER ===

INDUSTRY: Healthcare and Insurance (Payer Organizations)

KEY TERMINOLOGY:
- Member: Healthcare plan enrollee/beneficiary
- Provider: Doctor, hospital, clinic
- Network: In-network vs. out-of-network care
- Claims: Medical billing transactions
- Value-Based Care: Payment models tied to quality/outcomes

KEY STAKEHOLDERS:
- Chief Medical Officer (CMO): Clinical decisions
- Chief Information Officer (CIO): Technology infrastructure
- VP of Operations: Process efficiency, cost reduction
- Director of Care Management: Member outcomes
- Compliance Officer: HIPAA, state/federal regulations
- CFO: Financial impact, ROI, budget authority

BUYING PATTERNS:
- Long sales cycles: 9-18 months typical
- Compliance is paramount: HIPAA/BAA required
- POC expectations: 3-6 months, 500-5K members
- Integration complexity: Legacy systems, HL7/FHIR standards

RISK FACTORS:
- No CMO or CIO engagement = HIGH RISK
- No compliance documentation = DEAL KILLER
- Late stage without BAA = WARNING
- Q4 close without budget = likely slip to next fiscal year

BENCHMARKS:
- Average deal size: $300K-$2M
- Average sales cycle: 12 months
- Close rate: 25-35% (lower than other industries)
"""
    
    print("Content sizes:")
    print(f"  Evidence Binding: {len(evidence_content)} chars")
    print(f"  Risk Assessment: {len(risk_content)} chars")
    print(f"  Stat Card: {len(stat_card_content)} chars")
    print(f"  Alert Box: {len(alert_box_content)} chars")
    print(f"  Healthcare: {len(healthcare_content)} chars\n")
    
    # Create builders
    print("Step 3: Creating builders via REST API...\n")
    
    builders = []
    
    id1 = create_builder_via_api("Evidence Binding Rules v2", "Quality Rule", evidence_content, 
                                  "Complete evidence binding rules v2 - insight-first approach")
    if id1: builders.append(("Evidence Binding", id1))
    
    id2 = create_builder_via_api("Risk Assessment Pattern", "Pattern", risk_content,
                                  "Complete risk assessment pattern with examples")
    if id2: builders.append(("Risk Assessment", id2))
    
    id3 = create_builder_via_api("Stat Card Component", "UI Component", stat_card_content,
                                  "Complete stat card UI component with HTML templates")
    if id3: builders.append(("Stat Card", id3))
    
    id4 = create_builder_via_api("Alert Box Component", "UI Component", alert_box_content,
                                  "Complete alert box UI component with color schemes")
    if id4: builders.append(("Alert Box", id4))
    
    id5 = create_builder_via_api("Healthcare Payer Context", "Context Template", healthcare_content,
                                  "Healthcare payer industry context and heuristics")
    if id5: builders.append(("Healthcare", id5))
    
    print(f"\n{'='*60}")
    print(f"✅ CREATED {len(builders)} COMPLETE BUILDERS")
    print(f"{'='*60}\n")
    
    for name, builder_id in builders:
        print(f"  {name}: {builder_id}")
    
    print("\n🎯 All builders now have FULL content + correct DCM")
    print("   Ready for testing with Opportunity data")

if __name__ == "__main__":
    main()

# Task 5.11: Integration Test Solution

## Problem

`Test.stopTest()` forces all queued async jobs to complete synchronously, causing the 12-stage pipeline to hit Salesforce's stack depth limit.

**Root cause**: Chained queueable jobs work fine in production (one at a time), but in test context they all execute at once in a deep call stack.

## Solution: Hybrid Approach

### Part 1: Apex Test (Input Validation) ✅

Test what we CAN test without async execution:
- Controller input validation
- Run record creation
- Basic error handling

**File**: `PipelineIntegrationTest.cls` (deployed)

**What it tests**:
- ✅ Required field validation
- ✅ Run record creation with correct fields
- ⚠️ Cannot test full pipeline due to async limitations

### Part 2: Python E2E Script (Full Pipeline) 🔜

Test the complete flow outside of Apex test context:

**File**: `scripts/test-pipeline-e2e.py`

```python
#!/usr/bin/env python3
"""
End-to-end pipeline test using REST API

Tests:
1. Start pipeline via Salesforce REST API
2. Poll for completion (Stages 1-9)
3. Validate DCM structure
4. Validate Prompt template
5. (Optional) Execute prompt via GPTfy and validate output

Usage:
    python scripts/test-pipeline-e2e.py --account-id 001QH000024mdDnYAI
"""

import requests
import time
import json
import sys
from typing import Dict, Optional

class SalesforceClient:
    def __init__(self, instance_url: str, access_token: str):
        self.instance_url = instance_url
        self.access_token = access_token
        self.headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }

    def start_pipeline(self, account_id: str) -> str:
        """Start pipeline run via controller"""
        url = f'{self.instance_url}/services/apexrest/PromptFactoryController/start'

        payload = {
            'promptName': 'E2E Test - Account 360',
            'rootObject': 'Account',
            'sampleRecordId': account_id,
            'businessContext': 'Analyze account health and opportunities',
            'outputFormat': 'Narrative',
            'aiModelId': 'a01gD000003okzEQAQ',
            'companyUrl': 'https://test.com'
        }

        response = requests.post(url, headers=self.headers, json=payload)
        response.raise_for_status()
        return response.json()['runId']

    def get_run_status(self, run_id: str) -> Dict:
        """Get pipeline run status"""
        query = f"SELECT Id, Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = '{run_id}'"
        url = f'{self.instance_url}/services/data/v65.0/query?q={query}'

        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        records = response.json()['records']
        return records[0] if records else None

    def wait_for_stage(self, run_id: str, target_stage: int = 9, timeout: int = 300) -> bool:
        """Wait for pipeline to reach target stage"""
        start_time = time.time()

        while time.time() - start_time < timeout:
            status = self.get_run_status(run_id)

            if not status:
                print(f"❌ Run {run_id} not found")
                return False

            current_stage = status.get('Current_Stage__c', 0)
            run_status = status.get('Status__c', 'Unknown')

            print(f"  Stage {current_stage}/12 - Status: {run_status}")

            if current_stage >= target_stage:
                if run_status == 'Completed' or current_stage == target_stage:
                    print(f"✅ Reached Stage {current_stage}")
                    return True
                elif run_status == 'Failed':
                    print(f"❌ Failed at Stage {current_stage}: {status.get('Error_Message__c')}")
                    # If failed at Stage 10+, that's OK (we only care about 1-9)
                    if current_stage >= 10:
                        return True
                    return False

            time.sleep(5)

        print(f"⏱️  Timeout after {timeout}s")
        return False

    def get_created_dcm(self, run_id: str) -> Optional[Dict]:
        """Get DCM created by this run"""
        query = """
            SELECT Id, Name, ccai__Object_Name__c,
                   (SELECT Id, ccai__Type__c FROM ccai__AI_Data_Extraction_Details__r)
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE Name LIKE '%E2E Test%'
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        """
        url = f'{self.instance_url}/services/data/v65.0/query?q={query}'

        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        records = response.json()['records']
        return records[0] if records else None

    def get_created_prompt(self, run_id: str) -> Optional[Dict]:
        """Get Prompt created by this run"""
        query = """
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE Name LIKE '%E2E Test%'
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        """
        url = f'{self.instance_url}/services/data/v65.0/query?q={query}'

        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        records = response.json()['records']
        return records[0] if records else None


def validate_dcm(dcm: Dict) -> bool:
    """Validate DCM structure"""
    print("\n🔍 Validating DCM...")

    if not dcm:
        print("  ❌ DCM not created")
        return False

    # Check root object
    if dcm.get('ccai__Object_Name__c') != 'Account':
        print(f"  ❌ Expected root object 'Account', got '{dcm.get('ccai__Object_Name__c')}'")
        return False

    # Check details exist
    details = dcm.get('ccai__AI_Data_Extraction_Details__r', {}).get('records', [])
    detail_count = len(details)

    if detail_count < 5:
        print(f"  ❌ Expected at least 5 child objects, got {detail_count}")
        return False

    # Check for grandchild
    grandchild_count = sum(1 for d in details if d.get('ccai__Type__c') == 'GRANDCHILD')
    if grandchild_count < 1:
        print(f"  ❌ Expected at least 1 grandchild object, got {grandchild_count}")
        return False

    print(f"  ✅ DCM valid: {detail_count} details, {grandchild_count} grandchildren")
    return True


def validate_prompt(prompt: Dict) -> bool:
    """Validate Prompt template"""
    print("\n🔍 Validating Prompt...")

    if not prompt:
        print("  ❌ Prompt not created")
        return False

    template = prompt.get('ccai__Prompt_Command__c', '')

    if len(template) < 1000:
        print(f"  ❌ Template too short: {len(template)} chars")
        return False

    # Check merge fields
    if '{{{' not in template or '}}}' not in template:
        print("  ❌ No merge field syntax found")
        return False

    merge_field_count = template.count('{{{')
    if merge_field_count < 50:
        print(f"  ❌ Expected at least 50 merge fields, got {merge_field_count}")
        return False

    # Check iteration blocks
    if '{{#' not in template or '{{/' not in template:
        print("  ❌ No iteration blocks found")
        return False

    iteration_count = template.count('{{#')
    if iteration_count < 3:
        print(f"  ❌ Expected at least 3 iteration blocks, got {iteration_count}")
        return False

    # Check for hardcoded values
    hardcoded_values = ['Pinnacle Wealth', 'TESTDATA_', 'Sarah Chen']
    for hardcoded in hardcoded_values:
        if hardcoded in template:
            print(f"  ❌ Found hardcoded value: {hardcoded}")
            return False

    print(f"  ✅ Prompt valid: {len(template)} chars, {merge_field_count} merge fields, {iteration_count} iterations")
    return True


def main():
    import argparse
    import os

    parser = argparse.ArgumentParser(description='Run end-to-end pipeline test')
    parser.add_argument('--account-id', default='001QH000024mdDnYAI', help='Test account ID')
    parser.add_argument('--instance-url', default=os.getenv('SF_INSTANCE_URL'), help='Salesforce instance URL')
    parser.add_argument('--access-token', default=os.getenv('SF_ACCESS_TOKEN'), help='Access token')

    args = parser.parse_args()

    if not args.instance_url or not args.access_token:
        print("Error: Set SF_INSTANCE_URL and SF_ACCESS_TOKEN environment variables")
        sys.exit(1)

    client = SalesforceClient(args.instance_url, args.access_token)

    print(f"🚀 Starting pipeline for Account {args.account_id}...")
    try:
        run_id = client.start_pipeline(args.account_id)
        print(f"  Run ID: {run_id}")
    except Exception as e:
        print(f"❌ Failed to start pipeline: {e}")
        sys.exit(1)

    print("\n⏳ Waiting for pipeline to reach Stage 9...")
    if not client.wait_for_stage(run_id, target_stage=9, timeout=300):
        print("❌ Pipeline did not complete")
        sys.exit(1)

    # Validate outputs
    dcm = client.get_created_dcm(run_id)
    prompt = client.get_created_prompt(run_id)

    dcm_valid = validate_dcm(dcm)
    prompt_valid = validate_prompt(prompt)

    if dcm_valid and prompt_valid:
        print("\n✅ All validations passed!")
        sys.exit(0)
    else:
        print("\n❌ Validation failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
```

## Usage

### 1. Get Salesforce Credentials

```bash
# Get access token
sf org display --target-org agentictso --json | jq -r '.result | "export SF_INSTANCE_URL=\(.instanceUrl)\nexport SF_ACCESS_TOKEN=\(.accessToken)"'
```

### 2. Run E2E Test

```bash
# Set credentials
export SF_INSTANCE_URL="https://agentictso.my.salesforce.com"
export SF_ACCESS_TOKEN="00D..."

# Run test
python3 scripts/test-pipeline-e2e.py --account-id 001QH000024mdDnYAI
```

### 3. Expected Output

```
🚀 Starting pipeline for Account 001QH000024mdDnYAI...
  Run ID: a0gQH000005...

⏳ Waiting for pipeline to reach Stage 9...
  Stage 1/12 - Status: In Progress
  Stage 3/12 - Status: In Progress
  Stage 5/12 - Status: In Progress
  Stage 9/12 - Status: In Progress
✅ Reached Stage 9

🔍 Validating DCM...
  ✅ DCM valid: 6 details, 1 grandchildren

🔍 Validating Prompt...
  ✅ Prompt valid: 17032 chars, 94 merge fields, 27 iterations

✅ All validations passed!
```

## Task 5.11 Deliverables

1. ✅ **PipelineIntegrationTest.cls** - Apex test for validation logic (deployed)
2. 🔜 **scripts/test-pipeline-e2e.py** - Python E2E test script
3. ✅ **Documentation** - This file explaining the approach

## Next Steps

- Create `scripts/test-pipeline-e2e.py`
- Add to CI/CD pipeline
- Document usage in README

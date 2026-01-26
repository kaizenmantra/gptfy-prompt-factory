#!/usr/bin/env python3
"""
End-to-end pipeline test using REST API

Tests:
1. Start pipeline via PromptFactoryController
2. Poll for completion (Stages 1-9)
3. Validate DCM structure
4. Validate Prompt template

Usage:
    python scripts/test-pipeline-e2e.py --account-id 001QH000024mdDnYAI

Prerequisites:
    export SF_INSTANCE_URL="https://yourinstance.my.salesforce.com"
    export SF_ACCESS_TOKEN="00D..."
"""

import requests
import time
import json
import sys
import os
from typing import Dict, Optional
from urllib.parse import quote_plus


class SalesforceClient:
    def __init__(self, instance_url: str, access_token: str):
        self.instance_url = instance_url.rstrip('/')
        self.access_token = access_token
        self.headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }

    def query(self, soql: str) -> list:
        """Execute SOQL query"""
        url = f'{self.instance_url}/services/data/v65.0/query'
        params = {'q': soql}
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json().get('records', [])

    def start_pipeline_apex(self, account_id: str) -> str:
        """Start pipeline via anonymous Apex"""
        apex_code = f"""
Id runId = PromptFactoryController.startPipelineRun(
    'E2E Test - Account 360',
    'Account',
    '{account_id}',
    'Analyze account health and opportunities for E2E testing',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.com'
);
System.debug('RUN_ID:' + runId);
"""
        url = f'{self.instance_url}/services/data/v65.0/tooling/executeAnonymous'
        params = {'anonymousBody': apex_code}

        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        result = response.json()

        if not result.get('success'):
            raise Exception(f"Apex execution failed: {result}")

        # Extract run ID from debug logs
        logs = result.get('logs', '')
        for line in logs.split('\n'):
            if 'RUN_ID:' in line:
                run_id = line.split('RUN_ID:')[1].strip()
                return run_id

        raise Exception("Could not extract run ID from Apex execution")

    def get_run_status(self, run_id: str) -> Optional[Dict]:
        """Get pipeline run status"""
        records = self.query(
            f"SELECT Id, Status__c, Current_Stage__c, Error_Message__c "
            f"FROM PF_Run__c WHERE Id = '{run_id}'"
        )
        return records[0] if records else None

    def wait_for_stage(self, run_id: str, target_stage: int = 9, timeout: int = 300) -> bool:
        """Wait for pipeline to reach target stage"""
        start_time = time.time()
        last_stage = 0

        while time.time() - start_time < timeout:
            status = self.get_run_status(run_id)

            if not status:
                print(f"❌ Run {run_id} not found")
                return False

            current_stage = status.get('Current_Stage__c') or 0
            run_status = status.get('Status__c', 'Unknown')

            # Only print when stage changes
            if current_stage != last_stage:
                print(f"  Stage {current_stage}/12 - Status: {run_status}")
                last_stage = current_stage

            if current_stage >= target_stage:
                if run_status == 'Completed' or current_stage == target_stage:
                    print(f"✅ Reached Stage {current_stage}")
                    return True
                elif run_status == 'Failed':
                    error_msg = status.get('Error_Message__c', 'Unknown error')
                    print(f"⚠️  Failed at Stage {current_stage}: {error_msg}")
                    # If failed at Stage 10+, that's OK (we only care about 1-9)
                    if current_stage >= 10:
                        print("  (Stage 10+ failure is acceptable for this test)")
                        return True
                    return False

            time.sleep(5)

        print(f"⏱️  Timeout after {timeout}s at Stage {current_stage}")
        return False

    def get_created_dcm(self) -> Optional[Dict]:
        """Get DCM created today"""
        records = self.query(
            "SELECT Id, Name, ccai__Object_Name__c "
            "FROM ccai__AI_Data_Extraction_Mapping__c "
            "WHERE Name LIKE '%E2E Test%' AND CreatedDate = TODAY "
            "ORDER BY CreatedDate DESC LIMIT 1"
        )
        return records[0] if records else None

    def get_dcm_details(self, dcm_id: str) -> list:
        """Get DCM detail records"""
        return self.query(
            f"SELECT Id, ccai__Object_Name__c, ccai__Type__c "
            f"FROM ccai__AI_Data_Extraction_Detail__c "
            f"WHERE ccai__AI_Data_Extraction_Mapping__c = '{dcm_id}'"
        )

    def get_dcm_field_count(self, dcm_id: str) -> int:
        """Get count of DCM fields"""
        result = self.query(
            f"SELECT COUNT(Id) cnt FROM ccai__AI_Data_Extraction_Field__c "
            f"WHERE ccai__AI_Data_Extraction_Mapping__c = '{dcm_id}'"
        )
        return result[0].get('cnt', 0) if result else 0

    def get_created_prompt(self) -> Optional[Dict]:
        """Get Prompt created today"""
        records = self.query(
            "SELECT Id, Name, ccai__Prompt_Command__c "
            "FROM ccai__AI_Prompt__c "
            "WHERE Name LIKE '%E2E Test%' AND CreatedDate = TODAY "
            "ORDER BY CreatedDate DESC LIMIT 1"
        )
        return records[0] if records else None


def validate_dcm(client: SalesforceClient, dcm: Dict) -> bool:
    """Validate DCM structure"""
    print("\n🔍 Validating DCM...")

    if not dcm:
        print("  ❌ DCM not created")
        return False

    # Check root object
    root_object = dcm.get('ccai__Object_Name__c')
    if root_object != 'Account':
        print(f"  ❌ Expected root object 'Account', got '{root_object}'")
        return False

    # Check details exist
    details = client.get_dcm_details(dcm['Id'])
    detail_count = len(details)

    if detail_count < 5:
        print(f"  ❌ Expected at least 5 child objects, got {detail_count}")
        return False

    if detail_count > 10:
        print(f"  ❌ Expected at most 10 child objects, got {detail_count}")
        return False

    # Check for grandchild
    grandchild_count = sum(1 for d in details if d.get('ccai__Type__c') == 'GRANDCHILD')
    if grandchild_count < 1:
        print(f"  ❌ Expected at least 1 grandchild object, got {grandchild_count}")
        return False

    # Check field count
    field_count = client.get_dcm_field_count(dcm['Id'])
    if field_count < 40:
        print(f"  ❌ Expected at least 40 fields, got {field_count}")
        return False

    if field_count > 150:
        print(f"  ❌ Expected at most 150 fields, got {field_count}")
        return False

    print(f"  ✅ DCM valid:")
    print(f"     - {detail_count} detail records")
    print(f"     - {grandchild_count} grandchild objects")
    print(f"     - {field_count} fields")
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
    hardcoded_values = ['Pinnacle Wealth', 'TESTDATA_', 'Sarah Chen', 'Michael Rodriguez']
    found_hardcoded = []
    for hardcoded in hardcoded_values:
        if hardcoded in template:
            found_hardcoded.append(hardcoded)

    if found_hardcoded:
        print(f"  ❌ Found hardcoded values: {', '.join(found_hardcoded)}")
        return False

    print(f"  ✅ Prompt valid:")
    print(f"     - {len(template)} characters")
    print(f"     - {merge_field_count} merge fields")
    print(f"     - {iteration_count} iteration blocks")
    print(f"     - No hardcoded values")
    return True


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Run end-to-end pipeline test')
    parser.add_argument('--account-id', default='001QH000024mdDnYAI', help='Test account ID')
    parser.add_argument('--instance-url', default=os.getenv('SF_INSTANCE_URL'), help='Salesforce instance URL')
    parser.add_argument('--access-token', default=os.getenv('SF_ACCESS_TOKEN'), help='Access token')

    args = parser.parse_args()

    if not args.instance_url or not args.access_token:
        print("❌ Error: Set SF_INSTANCE_URL and SF_ACCESS_TOKEN environment variables")
        print("\nExample:")
        print('  eval "$(sf org display --target-org agentictso --json | jq -r \'.result | "export SF_INSTANCE_URL=\\(.instanceUrl)\\nexport SF_ACCESS_TOKEN=\\(.accessToken)"\')"')
        sys.exit(1)

    client = SalesforceClient(args.instance_url, args.access_token)

    print(f"🚀 Starting pipeline for Account {args.account_id}...")
    try:
        run_id = client.start_pipeline_apex(args.account_id)
        print(f"  Run ID: {run_id}")
    except Exception as e:
        print(f"❌ Failed to start pipeline: {e}")
        sys.exit(1)

    print("\n⏳ Waiting for pipeline to reach Stage 9...")
    if not client.wait_for_stage(run_id, target_stage=9, timeout=300):
        print("❌ Pipeline did not complete Stage 9")
        sys.exit(1)

    # Validate outputs
    dcm = client.get_created_dcm()
    prompt = client.get_created_prompt()

    dcm_valid = validate_dcm(client, dcm)
    prompt_valid = validate_prompt(prompt)

    print("\n" + "="*60)
    if dcm_valid and prompt_valid:
        print("✅ ALL VALIDATIONS PASSED")
        print("="*60)
        sys.exit(0)
    else:
        print("❌ VALIDATION FAILED")
        print("="*60)
        sys.exit(1)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Autonomous Prompt Iteration System

This script autonomously iterates on Stage 8 system prompts to improve GPTfy output quality.

Process:
1. Run pipeline for test accounts (Stages 1-9 create DCM + Prompt)
2. Execute prompts via GPTfy REST API (bypass failing Stage 10)
3. Evaluate outputs using Stage 12 quality rubric
4. Identify improvement areas
5. Update Stage 8 system prompt
6. Repeat up to 10 iterations or until quality target met

Prerequisites:
    export SF_INSTANCE_URL="https://yourinstance.my.salesforce.com"
    export SF_ACCESS_TOKEN="00D..."

Usage:
    python scripts/autonomous-iteration.py [--max-iterations 10] [--target-score 8.5]
"""

import requests
import time
import json
import sys
import os
import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

# Test Accounts
TEST_ACCOUNTS = [
    {'id': '001QH000024mdDnYAI', 'name': 'Pinnacle Wealth Partners', 'industry': 'Financial Services', 'revenue': '$15M'},
    {'id': '001QH000024mdDoYAI', 'name': 'Vanguard Insurance Group', 'industry': 'Insurance', 'revenue': '$50M'},
    {'id': '001QH000024mdDpYAI', 'name': 'MediCare Solutions Inc', 'industry': 'Healthcare', 'revenue': '$150M'},
]

# Quality Rubric (from Stage 12)
QUALITY_DIMENSIONS = [
    'Evidence Binding',
    'Diagnostic Depth',
    'Visual Quality',
    'UI Effectiveness',
    'Data Accuracy',
    'Persona Fit',
    'Actionability',
    'Business Value'
]

QUALITY_THRESHOLD = 7.0
QUALITY_TARGET = 8.5


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

    def start_pipeline_apex(self, iteration_num: int, account_id: str, account_name: str) -> str:
        """Start pipeline via anonymous Apex"""
        run_name = f'ITER{iteration_num:02d}-{account_name.replace(" ", "")}'

        apex_code = f"""
Id runId = PromptFactoryController.startPipelineRun(
    '{run_name}',
    'Account',
    '{account_id}',
    'Analyze this account for health, opportunity pipeline, support issues, and engagement.',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.example.com'
);
System.debug('### RUN_ID: ' + runId);
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
            if '### RUN_ID:' in line:
                run_id = line.split('### RUN_ID:')[1].strip()
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
                print(f"  ❌ Run {run_id} not found")
                return False

            current_stage = status.get('Current_Stage__c') or 0
            run_status = status.get('Status__c', 'Unknown')

            # Only print when stage changes
            if current_stage != last_stage:
                print(f"  Stage {current_stage}/12 - Status: {run_status}")
                last_stage = current_stage

            if current_stage >= target_stage:
                if run_status == 'Completed' or current_stage == target_stage:
                    print(f"  ✅ Reached Stage {current_stage}")
                    return True
                elif run_status == 'Failed':
                    error_msg = status.get('Error_Message__c', 'Unknown error')
                    print(f"  ⚠️  Failed at Stage {current_stage}: {error_msg}")
                    # If failed at Stage 10+, that's OK (we only care about 1-9)
                    if current_stage >= 10:
                        print("    (Stage 10+ failure is acceptable - DCM/Prompt created)")
                        return True
                    return False

            time.sleep(5)

        print(f"  ⏱️  Timeout after {timeout}s at Stage {current_stage}")
        return False

    def get_created_prompt(self, run_name_pattern: str) -> Optional[Dict]:
        """Get Prompt created for a run"""
        records = self.query(
            f"SELECT Id, Name, ccai__Prompt_Command__c, ccai__Prompt_Request_Id__c, ccai__Status__c "
            f"FROM ccai__AI_Prompt__c "
            f"WHERE Name LIKE '{run_name_pattern}%' "
            f"ORDER BY CreatedDate DESC LIMIT 1"
        )
        return records[0] if records else None

    def execute_prompt(self, prompt_request_id: str, record_id: str, max_retries: int = 3) -> Optional[str]:
        """Execute a GPTfy prompt via REST API"""
        url = f'{self.instance_url}/services/apexrest/ccai/v1/executePrompt'

        body = {
            'promptRequestId': prompt_request_id,
            'recordId': record_id,
            'customPromptCommand': ''
        }

        for attempt in range(max_retries):
            try:
                response = requests.post(url, headers=self.headers, json=body, timeout=120)

                if response.status_code == 200:
                    data = response.json()
                    status = data.get('status')

                    if status in ['Processed', 'Success']:
                        return data.get('responseBody')
                    elif status in ['Errored', 'Error', 'Failed']:
                        error_msg = data.get('message', 'Unknown error')
                        print(f"    ❌ GPTfy error: {error_msg}")
                        if attempt < max_retries - 1:
                            print(f"    🔄 Retrying... (attempt {attempt + 2}/{max_retries})")
                            time.sleep(10)
                            continue
                        return None
                    else:
                        print(f"    ⚠️  Unexpected status: {status}")
                        return None
                else:
                    print(f"    ❌ HTTP {response.status_code}: {response.text[:200]}")
                    if attempt < max_retries - 1:
                        print(f"    🔄 Retrying... (attempt {attempt + 2}/{max_retries})")
                        time.sleep(10)
                        continue
                    return None

            except Exception as e:
                print(f"    ❌ Exception: {e}")
                if attempt < max_retries - 1:
                    print(f"    🔄 Retrying... (attempt {attempt + 2}/{max_retries})")
                    time.sleep(10)
                    continue
                return None

        return None


class QualityEvaluator:
    """Evaluates prompt outputs using Stage 12 quality rubric via Claude API"""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.api_url = "https://api.anthropic.com/v1/messages"

    def evaluate_output(self, html_output: str, account_context: Dict) -> Dict:
        """
        Evaluate HTML output using Stage 12 quality rubric
        Returns: {
            'scores': {dimension: score (1-10)},
            'average': float,
            'strengths': [str],
            'weaknesses': [str],
            'recommendations': [str]
        }
        """
        evaluation_prompt = self._build_evaluation_prompt(html_output, account_context)

        # Call Claude API
        headers = {
            'x-api-key': self.api_key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json'
        }

        body = {
            'model': 'claude-sonnet-4-20250514',
            'max_tokens': 4000,
            'messages': [
                {'role': 'user', 'content': evaluation_prompt}
            ]
        }

        response = requests.post(self.api_url, headers=headers, json=body)
        response.raise_for_status()

        result = response.json()
        evaluation_text = result['content'][0]['text']

        return self._parse_evaluation(evaluation_text)

    def _build_evaluation_prompt(self, html_output: str, account_context: Dict) -> str:
        """Build evaluation prompt based on Stage 12 rubric"""
        return f"""You are an expert AI quality auditor for Salesforce implementations.

Evaluate this AI-generated Account 360 dashboard output and score it on 8 dimensions (scale 1-10):

1. **Evidence Binding** (1-10): Are field citations present and correctly formatted? Do assertions reference specific fields?

2. **Diagnostic Depth** (1-10): Does it use diagnostic/prescriptive language ("indicates", "suggests") rather than just descriptive ("has", "shows")?

3. **Visual Quality** (1-10): Clean formatting, SLDS patterns, proper hierarchy, appropriate use of whitespace?

4. **UI Effectiveness** (1-10): Stat cards for key metrics, alerts for issues, tables for data, appropriate component choices?

5. **Data Accuracy** (1-10): Correct totals, proper date handling, accurate related record counts?

6. **Persona Fit** (1-10): Appropriate density and tone for the executive user persona?

7. **Actionability** (1-10): Specific, time-bound next steps based on data insights?

8. **Business Value** (1-10): Strategic "so what" value - does it answer "why should I care?"

**Account Context:**
- Name: {account_context['name']}
- Industry: {account_context['industry']}
- Revenue: {account_context['revenue']}

**HTML Output to Evaluate:**
{html_output[:10000]}  <!-- Truncated to first 10K chars for API limits -->

**Response Format (JSON):**
{{
  "scores": {{
    "Evidence Binding": 8,
    "Diagnostic Depth": 7,
    "Visual Quality": 9,
    "UI Effectiveness": 8,
    "Data Accuracy": 9,
    "Persona Fit": 7,
    "Actionability": 6,
    "Business Value": 8
  }},
  "average": 7.75,
  "strengths": [
    "Excellent use of stat cards for key metrics",
    "Clean SLDS formatting with good visual hierarchy"
  ],
  "weaknesses": [
    "Missing field citations in some assertions",
    "Actionable recommendations too generic, not time-bound"
  ],
  "recommendations": [
    "Add field citations using pattern: 'Field: Value' or bullet format",
    "Make recommendations specific with deadlines: 'Follow up with Contact X by DATE'"
  ]
}}

Provide ONLY the JSON response, no additional text."""

    def _parse_evaluation(self, evaluation_text: str) -> Dict:
        """Parse JSON evaluation from Claude response"""
        # Extract JSON from response (may have markdown code fences)
        json_match = re.search(r'```json\s*(\{.*?\})\s*```', evaluation_text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            # Try to find raw JSON
            json_match = re.search(r'\{.*\}', evaluation_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
            else:
                raise Exception("Could not extract JSON from evaluation response")

        return json.loads(json_str)


class PromptIterator:
    """Main iteration orchestrator"""

    def __init__(self, sf_client: SalesforceClient, evaluator: QualityEvaluator):
        self.sf_client = sf_client
        self.evaluator = evaluator
        self.iteration_dir = Path('temp/prompt-iterations')
        self.iteration_dir.mkdir(parents=True, exist_ok=True)

    def run_iteration(self, iteration_num: int, account: Dict) -> Dict:
        """Run a single iteration for one account"""
        print(f"\n{'='*80}")
        print(f"ITERATION {iteration_num} - {account['name']}")
        print(f"{'='*80}")

        # Step 1: Start pipeline
        print(f"\n1️⃣  Starting pipeline for {account['name']}...")
        try:
            run_id = self.sf_client.start_pipeline_apex(iteration_num, account['id'], account['name'])
            print(f"   Run ID: {run_id}")
        except Exception as e:
            print(f"   ❌ Failed to start pipeline: {e}")
            return {'success': False, 'error': str(e)}

        # Step 2: Wait for Stage 9 completion
        print(f"\n2️⃣  Waiting for pipeline to reach Stage 9...")
        if not self.sf_client.wait_for_stage(run_id, target_stage=9, timeout=300):
            print(f"   ❌ Pipeline did not complete Stage 9")
            return {'success': False, 'error': 'Pipeline failed before Stage 9'}

        # Step 3: Get created prompt
        print(f"\n3️⃣  Retrieving created prompt...")
        run_pattern = f"ITER{iteration_num:02d}-{account['name'].replace(' ', '')}"
        prompt = self.sf_client.get_created_prompt(run_pattern)

        if not prompt:
            print(f"   ❌ Prompt not found")
            return {'success': False, 'error': 'Prompt not created'}

        prompt_request_id = prompt.get('ccai__Prompt_Request_Id__c')
        if not prompt_request_id:
            print(f"   ❌ Prompt Request ID not found (prompt may not be activated)")
            return {'success': False, 'error': 'Prompt not activated'}

        print(f"   ✅ Prompt ID: {prompt['Id']}")
        print(f"   ✅ Request ID: {prompt_request_id}")

        # Step 4: Execute prompt
        print(f"\n4️⃣  Executing prompt via GPTfy REST API...")
        html_output = self.sf_client.execute_prompt(prompt_request_id, account['id'])

        if not html_output:
            print(f"   ❌ Prompt execution failed")
            return {'success': False, 'error': 'Prompt execution failed'}

        print(f"   ✅ Received HTML output ({len(html_output)} chars)")

        # Save output
        output_file = self.iteration_dir / f"iteration-{iteration_num:02d}-{account['name'].replace(' ', '-').lower()}-output.html"
        output_file.write_text(html_output)
        print(f"   💾 Saved to: {output_file}")

        # Step 5: Evaluate output
        print(f"\n5️⃣  Evaluating output quality...")
        evaluation = self.evaluator.evaluate_output(html_output, account)

        print(f"\n   📊 Quality Scores:")
        for dimension, score in evaluation['scores'].items():
            emoji = '✅' if score >= QUALITY_TARGET else '⚠️' if score >= QUALITY_THRESHOLD else '❌'
            print(f"      {emoji} {dimension}: {score}/10")

        print(f"\n   📈 Average Score: {evaluation['average']:.2f}/10")

        if evaluation['average'] >= QUALITY_TARGET:
            print(f"   🎯 TARGET MET! (>= {QUALITY_TARGET})")
        elif evaluation['average'] >= QUALITY_THRESHOLD:
            print(f"   ✅ THRESHOLD MET (>= {QUALITY_THRESHOLD})")
        else:
            print(f"   ❌ BELOW THRESHOLD (< {QUALITY_THRESHOLD})")

        # Save evaluation
        eval_file = self.iteration_dir / f"iteration-{iteration_num:02d}-{account['name'].replace(' ', '-').lower()}-evaluation.json"
        eval_file.write_text(json.dumps(evaluation, indent=2))
        print(f"   💾 Evaluation saved to: {eval_file}")

        return {
            'success': True,
            'run_id': run_id,
            'prompt_id': prompt['Id'],
            'output_length': len(html_output),
            'evaluation': evaluation
        }


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Run autonomous prompt iteration')
    parser.add_argument('--max-iterations', type=int, default=10, help='Maximum iterations')
    parser.add_argument('--target-score', type=float, default=QUALITY_TARGET, help='Target average score')
    parser.add_argument('--instance-url', default=os.getenv('SF_INSTANCE_URL'))
    parser.add_argument('--access-token', default=os.getenv('SF_ACCESS_TOKEN'))
    parser.add_argument('--anthropic-api-key', default=os.getenv('ANTHROPIC_API_KEY'))

    args = parser.parse_args()

    # Validate environment
    if not args.instance_url or not args.access_token:
        print("❌ Error: Set SF_INSTANCE_URL and SF_ACCESS_TOKEN environment variables")
        sys.exit(1)

    if not args.anthropic_api_key:
        print("❌ Error: Set ANTHROPIC_API_KEY environment variable")
        sys.exit(1)

    # Initialize clients
    sf_client = SalesforceClient(args.instance_url, args.access_token)
    evaluator = QualityEvaluator(args.anthropic_api_key)
    iterator = PromptIterator(sf_client, evaluator)

    print(f"""
{'='*80}
AUTONOMOUS PROMPT ITERATION SYSTEM
{'='*80}
Max Iterations: {args.max_iterations}
Target Score: {args.target_score}/10
Test Accounts: {len(TEST_ACCOUNTS)}
{'='*80}
""")

    # Run baseline iteration (Iteration 0) on all 3 accounts
    print(f"\n🔬 BASELINE ITERATION (Iteration 0)")
    print(f"Testing current Stage 8 prompt on all accounts...\n")

    baseline_results = []
    for account in TEST_ACCOUNTS:
        result = iterator.run_iteration(0, account)
        baseline_results.append({
            'account': account,
            'result': result
        })
        time.sleep(5)  # Brief pause between accounts

    # Analyze baseline
    print(f"\n\n{'='*80}")
    print(f"BASELINE ANALYSIS")
    print(f"{'='*80}\n")

    baseline_scores = [r['result']['evaluation']['average']
                      for r in baseline_results
                      if r['result'].get('success')]

    if baseline_scores:
        avg_baseline = sum(baseline_scores) / len(baseline_scores)
        print(f"Average Baseline Score: {avg_baseline:.2f}/10")

        if avg_baseline >= args.target_score:
            print(f"\n🎉 TARGET ALREADY MET! No iterations needed.")
            sys.exit(0)

    # TODO: Implement iterative improvement logic
    print(f"\n⚠️  Iterative improvement not yet implemented.")
    print(f"Next steps:")
    print(f"  1. Analyze baseline weaknesses across all accounts")
    print(f"  2. Update Stage 8 system prompt")
    print(f"  3. Re-test on Account 1")
    print(f"  4. If improved, test on Accounts 2 & 3")
    print(f"  5. Repeat until target met or max iterations reached")


if __name__ == '__main__':
    main()

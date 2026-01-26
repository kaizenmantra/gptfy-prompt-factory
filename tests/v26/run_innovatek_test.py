#!/usr/bin/env python3
"""
V2.6 End-to-End Test - Innovatek Account
Fully automated: pipeline -> GPTfy API -> score -> iterate

Flow:
1. Start pipeline via TestHarnessController REST API
2. Poll until Stage 9 completes (get promptId)
3. Get promptRequestId from prompt record
4. Call GPTfy executePrompt API directly (bypasses Stage 10 Apex)
5. Score the HTML response
6. Iterate if score < 90
"""

import subprocess
import json
import time
import sys
import re
from pathlib import Path
from datetime import datetime

# Configuration
ORG_ALIAS = "agentictso"
INNOVATEK_ACCOUNT_ID = "001QH000024pY3ZYAU"
ROOT_OBJECT = "Account"
BUSINESS_CONTEXT = "Account 360 dashboard for Sales Reps, Account Executives, and Customer Success Managers in a renewal-heavy business. Focus on account health, related opportunities, cases, activities, and key contacts. Highlight any overdue deals or stale engagement."
OUTPUT_FORMAT = "Dashboard"
TEMPLATE_NAME = "Account 360 - Innovatek Test"

# Quality thresholds
TARGET_SCORE = 90
MAX_ITERATIONS = 3

# Test output directory
TEST_DIR = Path("tests/v26")

# Quality scoring constants
FORBIDDEN_PHRASES = [
    'ensure alignment', 'consider scheduling', 'maintain momentum',
    'engage stakeholders', 'reinforce value proposition', 'address concerns',
    'follow up with', 'reach out to', 'touch base', 'circle back',
    'there is', 'there are', 'consider following', 'ensure proper'
]

EVIDENCE_PATTERNS = [
    r'\d+\s*(days?|months?|weeks?)\s*(overdue|past|ago|stale|behind|late)',
    r'\$[\d,]+[KMB]?',
    r'\d+%',
]

DATE_ANALYSIS_PATTERNS = [
    r'overdue',
    r'past\s*(due|close)',
    r'days?\s+(late|overdue|past|behind)',
    r'months?\s+(late|overdue|past|behind)',
    r'stale|no\s+activity',
    r'behind\s+schedule',
]


def run_command(cmd, timeout=300):
    """Run shell command and return (success, stdout, stderr)"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"


def parse_apex_rest_response(stdout):
    """Parse Apex REST response (handles double-encoded JSON from JSON.serialize)"""
    try:
        first_parse = json.loads(stdout)
        if isinstance(first_parse, str):
            return json.loads(first_parse)
        return first_parse
    except json.JSONDecodeError:
        return None


def get_credentials():
    """Get Salesforce access token and instance URL"""
    cmd = f"sf org display -o {ORG_ALIAS} --json 2>/dev/null"
    success, stdout, _ = run_command(cmd)
    if not success:
        raise Exception("Failed to get credentials")
    data = json.loads(stdout)
    return data['result']['accessToken'], data['result']['instanceUrl']


def start_pipeline(access_token, instance_url):
    """Start pipeline via TestHarnessController REST API, return run_id"""
    url = f"{instance_url}/services/apexrest/test-harness/start-pipeline"
    payload = {
        "rootObject": ROOT_OBJECT,
        "sampleRecordId": INNOVATEK_ACCOUNT_ID,
        "templateName": TEMPLATE_NAME,
        "businessContext": BUSINESS_CONTEXT,
        "outputFormat": OUTPUT_FORMAT
    }

    with open("/tmp/pipeline_payload.json", 'w') as f:
        json.dump(payload, f)

    cmd = f'curl -s -X POST "{url}" -H "Authorization: Bearer {access_token}" -H "Content-Type: application/json" -d @/tmp/pipeline_payload.json'
    success, stdout, stderr = run_command(cmd, timeout=60)

    if not success:
        raise Exception(f"Pipeline start failed: {stderr}")

    response = parse_apex_rest_response(stdout)
    if not response or not response.get('success'):
        raise Exception(f"Pipeline start failed: {response}")

    return response.get('runId')


def poll_until_stage9(run_id, access_token, instance_url, max_wait=600):
    """Poll run status until Stage 9 completes, return prompt_id"""
    url = f"{instance_url}/services/apexrest/test-harness/run-status/{run_id}"
    start_time = time.time()

    while time.time() - start_time < max_wait:
        cmd = f'curl -s "{url}" -H "Authorization: Bearer {access_token}"'
        success, stdout, _ = run_command(cmd, timeout=30)

        if success:
            response = parse_apex_rest_response(stdout)
            if response:
                stage = response.get('currentStage', 0)
                status = response.get('status', 'Unknown')
                prompt_id = response.get('createdPromptId')

                print(f"   Stage {stage}: {status}")

                if status == 'Failed':
                    raise Exception(f"Pipeline failed at stage {stage}")

                if stage >= 9 and prompt_id:
                    return prompt_id

        time.sleep(10)

    raise Exception("Timeout waiting for Stage 9")


def get_prompt_request_id(prompt_id):
    """Get ccai__Prompt_Request_Id__c from the prompt record"""
    query = f"SELECT ccai__Prompt_Request_Id__c FROM ccai__AI_Prompt__c WHERE Id = '{prompt_id}'"
    cmd = f'sf data query -o {ORG_ALIAS} -q "{query}" --json 2>/dev/null'
    success, stdout, _ = run_command(cmd, timeout=30)

    if success:
        try:
            result = json.loads(stdout)
            records = result.get('result', {}).get('records', [])
            if records:
                return records[0].get('ccai__Prompt_Request_Id__c')
        except:
            pass
    return None


def execute_gptfy_and_get_html(prompt_request_id, record_id, access_token, instance_url):
    """Call GPTfy executePrompt API and return HTML from responseBody"""
    url = f"{instance_url}/services/apexrest/ccai/v1/executePrompt"
    payload = {
        "promptRequestId": prompt_request_id,
        "recordId": record_id,
        "customPromptCommand": ""
    }

    with open("/tmp/gptfy_payload.json", 'w') as f:
        json.dump(payload, f)

    cmd = f'curl -s -X POST "{url}" -H "Authorization: Bearer {access_token}" -H "Content-Type: application/json" -d @/tmp/gptfy_payload.json'
    success, stdout, _ = run_command(cmd, timeout=180)

    if not success:
        return None, "API call failed"

    try:
        response = json.loads(stdout)
        status = response.get('status')
        html = response.get('responseBody', '')
        response_id = response.get('responseId')

        if status == 'Processed' and html:
            return html, response_id
        else:
            return None, f"Status: {status}"
    except json.JSONDecodeError:
        return None, "Invalid JSON response"


def score_output(html):
    """Score HTML output, return metrics dict with compositeScore"""
    if not html:
        return {'compositeScore': 0, 'error': 'No HTML'}

    metrics = {'outputLength': len(html)}

    # Evidence: dollar amounts, percentages
    evidence_count = 0
    for pattern in EVIDENCE_PATTERNS:
        evidence_count += len(re.findall(pattern, html, re.IGNORECASE))
    metrics['evidenceCitations'] = evidence_count

    # Date analysis: overdue, past due, stale, etc.
    date_count = 0
    for pattern in DATE_ANALYSIS_PATTERNS:
        date_count += len(re.findall(pattern, html, re.IGNORECASE))
    metrics['dateAnalysis'] = date_count

    # Forbidden phrases
    forbidden_count = 0
    forbidden_found = []
    for phrase in FORBIDDEN_PHRASES:
        matches = re.findall(re.escape(phrase), html, re.IGNORECASE)
        if matches:
            forbidden_count += len(matches)
            forbidden_found.append(phrase)
    metrics['forbiddenPhrases'] = forbidden_count
    metrics['forbiddenFound'] = forbidden_found

    # Color diversity
    has_red = 'BA0517' in html or 'ba0517' in html.lower()
    has_orange = 'DD7A01' in html or 'dd7a01' in html.lower()
    has_blue = '0176D3' in html or '0176d3' in html.lower()
    metrics['colorDiversity'] = sum([has_red, has_orange, has_blue])

    # Customer references
    customer_count = len(re.findall(r'Innovatek', html, re.IGNORECASE))
    customer_count += len(re.findall(r'\$[\d,]+', html))
    customer_count += len(re.findall(r'[A-Z][a-z]+\s+[A-Z][a-z]+', html))  # Names
    metrics['customerReferences'] = min(customer_count, 20)

    # Composite score (0-100)
    evidence_score = min(metrics['evidenceCitations'] * 3, 25)
    date_score = min(metrics['dateAnalysis'] * 5, 25)
    forbidden_penalty = max(20 - metrics['forbiddenPhrases'] * 5, 0)
    color_score = metrics['colorDiversity'] * 5
    customer_score = min(metrics['customerReferences'] * 1.5, 15)

    metrics['compositeScore'] = round(evidence_score + date_score + forbidden_penalty + color_score + customer_score, 1)
    metrics['scores'] = {
        'evidence': evidence_score, 'dateAnalysis': date_score,
        'forbidden': forbidden_penalty, 'colors': color_score, 'customer': customer_score
    }

    return metrics


def save_output(iteration, html, metrics, prompt_id):
    """Save HTML and metrics to files"""
    output_dir = TEST_DIR / "outputs"
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    html_file = output_dir / f"innovatek_iter{iteration}_{timestamp}.html"
    with open(html_file, 'w') as f:
        f.write(html or "")

    metrics_file = output_dir / f"innovatek_iter{iteration}_{timestamp}_metrics.json"
    with open(metrics_file, 'w') as f:
        json.dump({'iteration': iteration, 'timestamp': timestamp, 'promptId': prompt_id, 'metrics': metrics}, f, indent=2)

    return html_file, metrics_file


def print_summary(metrics):
    """Print score summary"""
    print(f"\n{'=' * 50}")
    print(f"SCORE: {metrics.get('compositeScore', 0)}/100")
    print(f"{'=' * 50}")
    scores = metrics.get('scores', {})
    print(f"  Evidence:     {metrics.get('evidenceCitations', 0):3d} items  ({scores.get('evidence', 0)}/25)")
    print(f"  Date Analysis:{metrics.get('dateAnalysis', 0):3d} items  ({scores.get('dateAnalysis', 0)}/25)")
    print(f"  Forbidden:    {metrics.get('forbiddenPhrases', 0):3d} found  ({scores.get('forbidden', 0)}/20)")
    print(f"  Colors:       {metrics.get('colorDiversity', 0)}/3        ({scores.get('colors', 0)}/15)")
    print(f"  Customer Ref: {metrics.get('customerReferences', 0):3d} items  ({scores.get('customer', 0)}/15)")
    if metrics.get('forbiddenFound'):
        print(f"  Forbidden: {metrics['forbiddenFound'][:3]}")
    print(f"{'=' * 50}")


def main():
    print(f"\n{'=' * 70}")
    print("V2.6 INNOVATEK ACCOUNT 360 TEST")
    print(f"{'=' * 70}")
    print(f"Target: {TARGET_SCORE}/100 | Max Iterations: {MAX_ITERATIONS}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Get credentials once
    print("\n[1] Getting credentials...")
    access_token, instance_url = get_credentials()
    print(f"    Connected: {instance_url}")

    best_score = 0

    for iteration in range(1, MAX_ITERATIONS + 1):
        print(f"\n{'=' * 70}")
        print(f"ITERATION {iteration}/{MAX_ITERATIONS}")
        print(f"{'=' * 70}")

        # Start pipeline
        print("\n[2] Starting pipeline...")
        try:
            run_id = start_pipeline(access_token, instance_url)
            print(f"    Run ID: {run_id}")
        except Exception as e:
            print(f"    FAILED: {e}")
            continue

        # Poll for Stage 9
        print("\n[3] Waiting for Stage 9...")
        try:
            prompt_id = poll_until_stage9(run_id, access_token, instance_url)
            print(f"    Prompt ID: {prompt_id}")
        except Exception as e:
            print(f"    FAILED: {e}")
            continue

        # Get prompt request ID
        print("\n[4] Getting prompt request ID...")
        prompt_request_id = get_prompt_request_id(prompt_id)
        if not prompt_request_id:
            print("    FAILED: No prompt request ID")
            continue
        print(f"    Request ID: {prompt_request_id}")

        # Execute GPTfy
        print("\n[5] Calling GPTfy API...")
        html, response_info = execute_gptfy_and_get_html(prompt_request_id, INNOVATEK_ACCOUNT_ID, access_token, instance_url)
        if not html:
            print(f"    FAILED: {response_info}")
            continue
        print(f"    Response: {response_info} | HTML: {len(html)} chars")

        # Score
        print("\n[6] Scoring output...")
        metrics = score_output(html)
        print_summary(metrics)

        # Save
        html_file, metrics_file = save_output(iteration, html, metrics, prompt_id)
        print(f"\n[7] Saved: {html_file.name}")

        score = metrics.get('compositeScore', 0)
        best_score = max(best_score, score)

        if score >= TARGET_SCORE:
            print(f"\n{'=' * 70}")
            print(f"SUCCESS! Score {score} >= {TARGET_SCORE}")
            print(f"{'=' * 70}")
            break
        else:
            print(f"\n    Score {score} < {TARGET_SCORE} - {'iterating...' if iteration < MAX_ITERATIONS else 'max iterations reached'}")

    # Final
    print(f"\n{'=' * 70}")
    print(f"RESULT: {'PASS' if best_score >= TARGET_SCORE else 'NEEDS IMPROVEMENT'}")
    print(f"Best Score: {best_score}/100 | Target: {TARGET_SCORE}/100")
    print(f"Finished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'=' * 70}\n")


if __name__ == "__main__":
    main()

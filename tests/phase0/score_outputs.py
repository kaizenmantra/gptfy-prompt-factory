#!/usr/bin/env python3
"""
Phase 0 Output Scoring Script
Analyzes and compares all 5 variant outputs
"""

import re
import json
from pathlib import Path
from datetime import datetime

TEST_DIR = Path("tests/phase0")

VARIANTS = [
    (0, "baseline", "Baseline (no enhancements)"),
    (1, "evidence", "+Evidence Binding"),
    (2, "diagnostic", "+Diagnostic Language"),
    (3, "context", "+Context Application"),
    (4, "all", "+All Three Combined")
]

# Forbidden phrases that indicate generic sales advice
FORBIDDEN_PHRASES = [
    'ensure alignment', 'consider scheduling', 'maintain momentum',
    'engage stakeholders', 'reinforce value proposition', 'address concerns',
    'follow up with', 'reach out to', 'touch base', 'circle back',
    'there is', 'there are', 'consider following'
]

# Customer-specific terms that should appear in enhanced variants
CUSTOMER_TERMS = [
    'McDonald', 'franchise', 'healthcare payer', 'health insurance',
    'CFO', 'Sarah Johnson', 'Lisa Martinez', 'Michael Chen', 'Robert Taylor',
    'TCO', 'HIPAA', 'compliance', 'Aetna', 'competitor', 'wellness',
    'benefits', 'ROI Analysis', 'overdue', 'budget'
]

# Diagnostic language indicators
DIAGNOSTIC_INDICATORS = [
    'CRITICAL', 'HIGH RISK', 'WARNING', 'GAP', 'MISSING',
    'OPPORTUNITY', 'Evidence:', 'immediately', 'must', 'requires'
]

# Descriptive language (should be minimized)
DESCRIPTIVE_INDICATORS = [
    'shows', 'displays', 'contains', 'includes', 'has'
]

def load_html(variant_num, variant_name):
    """Load HTML output for a variant"""
    html_file = TEST_DIR / "outputs" / f"output_{variant_num}_{variant_name}.html"
    with open(html_file, 'r') as f:
        return f.read()

def count_pattern(text, patterns):
    """Count occurrences of patterns in text"""
    count = 0
    found = []
    for pattern in patterns:
        matches = re.findall(re.escape(pattern), text, re.IGNORECASE)
        if matches:
            count += len(matches)
            found.append((pattern, len(matches)))
    return count, found

def count_evidence_citations(text):
    """Count explicit evidence citations"""
    # Look for patterns like "(Evidence: Field = Value)" or "Evidence: Field ="
    pattern = r'\(Evidence:.*?\)|Evidence:.*?[=:]'
    matches = re.findall(pattern, text, re.IGNORECASE)
    
    # Also count field references like "Contact.Name = 'X'"
    field_refs = re.findall(r'\w+\.\w+\s*=\s*[\'"]', text)
    
    return len(matches) + len(field_refs), matches[:5]  # Return first 5 examples

def assess_diagnostic_quality(text):
    """Assess diagnostic vs descriptive language (0-5 scale)"""
    diag_count, _ = count_pattern(text, DIAGNOSTIC_INDICATORS)
    desc_count, _ = count_pattern(text, DESCRIPTIVE_INDICATORS)
    
    # Score based on ratio
    if desc_count == 0:
        ratio = diag_count
    else:
        ratio = diag_count / desc_count
    
    score = min(5.0, max(1.0, 1 + (ratio * 0.8)))
    return round(score, 1), diag_count, desc_count

def calculate_composite_score(metrics):
    """Calculate composite quality score (0-100)"""
    evidence_points = min(metrics['evidenceCitations'] * 5, 50)  # Max 50
    forbidden_penalty = max(50 - (metrics['forbiddenPhrases'] * 10), 0)  # -10 per phrase
    customer_points = min(metrics['customerReferences'] * 2, 20)  # Max 20
    diagnostic_points = metrics['diagnosticScore'] * 4  # Max 20
    structure_bonus = 10 if metrics['hasStructuredFormat'] else 0
    
    composite = (evidence_points + forbidden_penalty + customer_points + 
                 diagnostic_points + structure_bonus) / 1.5
    
    return round(composite, 1)

def score_variant(variant_num, variant_name):
    """Score a single variant"""
    html = load_html(variant_num, variant_name)
    
    # Count evidence citations
    evidence_count, evidence_examples = count_evidence_citations(html)
    
    # Count forbidden phrases
    forbidden_count, forbidden_found = count_pattern(html, FORBIDDEN_PHRASES)
    
    # Count customer references
    customer_count, customer_found = count_pattern(html, CUSTOMER_TERMS)
    
    # Assess diagnostic quality
    diag_score, diag_count, desc_count = assess_diagnostic_quality(html)
    
    # Check for structured format
    has_structure = ('Key Risks' in html or 'Signal Assessment' in html or 
                    'Recommended Actions' in html or 'CRITICAL' in html)
    
    metrics = {
        'evidenceCitations': evidence_count,
        'forbiddenPhrases': forbidden_count,
        'customerReferences': customer_count,
        'diagnosticScore': diag_score,
        'diagnosticCount': diag_count,
        'descriptiveCount': desc_count,
        'outputLength': len(html),
        'hasStructuredFormat': has_structure,
        'evidenceExamples': evidence_examples,
        'forbiddenFound': forbidden_found[:3],  # Top 3
        'customerFound': customer_found[:5]  # Top 5
    }
    
    metrics['compositeScore'] = calculate_composite_score(metrics)
    
    return metrics

def generate_markdown_report(results):
    """Generate markdown comparison report"""
    baseline_metrics = [r for r in results if r[0] == 0][0][3]
    winner = max(results, key=lambda x: x[3]['compositeScore'])
    
    md = f"""# Phase 0 Quality Test Results

**Test Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Test Opportunity**: McDonald's Franchise Healthcare Insurance ($1.5M)  
**Test Prompt**: Deal Coach 05-05PM

---

## 📊 Results Summary

| Variant | Evidence | Forbidden | Customer | Diagnostic | Composite | Winner |
|---------|----------|-----------|----------|------------|-----------|--------|
"""
    
    for variant_num, variant_name, variant_desc, metrics in results:
        winner_icon = "🏆" if metrics['compositeScore'] == winner[3]['compositeScore'] else ""
        md += f"| **{variant_num}** ({variant_desc}) | {metrics['evidenceCitations']} | {metrics['forbiddenPhrases']} | {metrics['customerReferences']} | {metrics['diagnosticScore']}/5 | **{metrics['compositeScore']}/100** | {winner_icon} |\n"
    
    winner_metrics = winner[3]
    md += f"""
---

## 🏆 Winner: Variant {winner[0]} - {winner[2]}

**Composite Score**: {winner_metrics['compositeScore']}/100

### Key Improvements Over Baseline

| Metric | Baseline | Winner | Delta | % Change |
|--------|----------|--------|-------|----------|
| Evidence Citations | {baseline_metrics['evidenceCitations']} | {winner_metrics['evidenceCitations']} | +{winner_metrics['evidenceCitations'] - baseline_metrics['evidenceCitations']} | +{round((winner_metrics['evidenceCitations'] - baseline_metrics['evidenceCitations']) / max(baseline_metrics['evidenceCitations'], 1) * 100, 1)}% |
| Forbidden Phrases | {baseline_metrics['forbiddenPhrases']} | {winner_metrics['forbiddenPhrases']} | {winner_metrics['forbiddenPhrases'] - baseline_metrics['forbiddenPhrases']} | {round((winner_metrics['forbiddenPhrases'] - baseline_metrics['forbiddenPhrases']) / max(baseline_metrics['forbiddenPhrases'], 1) * 100, 1)}% |
| Customer References | {baseline_metrics['customerReferences']} | {winner_metrics['customerReferences']} | +{winner_metrics['customerReferences'] - baseline_metrics['customerReferences']} | +{round((winner_metrics['customerReferences'] - baseline_metrics['customerReferences']) / max(baseline_metrics['customerReferences'], 1) * 100, 1)}% |
| Diagnostic Score | {baseline_metrics['diagnosticScore']}/5 | {winner_metrics['diagnosticScore']}/5 | +{round(winner_metrics['diagnosticScore'] - baseline_metrics['diagnosticScore'], 1)} | +{round((winner_metrics['diagnosticScore'] - baseline_metrics['diagnosticScore']) / max(baseline_metrics['diagnosticScore'], 0.1) * 100, 1)}% |
| Composite Score | {baseline_metrics['compositeScore']}/100 | {winner_metrics['compositeScore']}/100 | +{round(winner_metrics['compositeScore'] - baseline_metrics['compositeScore'], 1)} | +{round((winner_metrics['compositeScore'] - baseline_metrics['compositeScore']) / max(baseline_metrics['compositeScore'], 1) * 100, 1)}% |

---

## ✅ Success Criteria Check

| Criterion | Target | Winner Result | Status |
|-----------|--------|---------------|--------|
| Evidence Citations | ≥ 8 | {winner_metrics['evidenceCitations']} | {"✅ PASS" if winner_metrics['evidenceCitations'] >= 8 else "❌ FAIL"} |
| Forbidden Phrases | ≤ 3 | {winner_metrics['forbiddenPhrases']} | {"✅ PASS" if winner_metrics['forbiddenPhrases'] <= 3 else "❌ FAIL"} |
| Customer References | ≥ 5 | {winner_metrics['customerReferences']} | {"✅ PASS" if winner_metrics['customerReferences'] >= 5 else "❌ FAIL"} |
| Diagnostic Score | ≥ 4.0/5 | {winner_metrics['diagnosticScore']}/5 | {"✅ PASS" if winner_metrics['diagnosticScore'] >= 4.0 else "❌ FAIL"} |
| Composite Score | ≥ 75/100 | {winner_metrics['compositeScore']}/100 | {"✅ PASS" if winner_metrics['compositeScore'] >= 75 else "❌ FAIL"} |

**Passed**: {sum([
    winner_metrics['evidenceCitations'] >= 8,
    winner_metrics['forbiddenPhrases'] <= 3,
    winner_metrics['customerReferences'] >= 5,
    winner_metrics['diagnosticScore'] >= 4.0,
    winner_metrics['compositeScore'] >= 75
])}/5 criteria

---

## 📋 Detailed Metrics by Variant

"""
    
    for variant_num, variant_name, variant_desc, metrics in results:
        md += f"""### Variant {variant_num}: {variant_desc}

**Composite Score**: {metrics['compositeScore']}/100

**Metrics**:
- Evidence Citations: {metrics['evidenceCitations']}
- Forbidden Phrases: {metrics['forbiddenPhrases']}
- Customer References: {metrics['customerReferences']}
- Diagnostic Score: {metrics['diagnosticScore']}/5 (Diagnostic: {metrics['diagnosticCount']}, Descriptive: {metrics['descriptiveCount']})
- Output Length: {metrics['outputLength']} characters
- Structured Format: {"Yes" if metrics['hasStructuredFormat'] else "No"}

**Sample Evidence Citations**:
{chr(10).join(f"- {ex}" for ex in metrics['evidenceExamples'][:3]) if metrics['evidenceExamples'] else "- None found"}

**Forbidden Phrases Found**:
{chr(10).join(f"- '{phrase}' ({count}x)" for phrase, count in metrics['forbiddenFound']) if metrics['forbiddenFound'] else "- None found ✅"}

**Top Customer Terms**:
{chr(10).join(f"- '{term}' ({count}x)" for term, count in metrics['customerFound'][:5]) if metrics['customerFound'] else "- None found"}

---

"""
    
    # Decision
    passes = sum([
        winner_metrics['evidenceCitations'] >= 8,
        winner_metrics['forbiddenPhrases'] <= 3,
        winner_metrics['customerReferences'] >= 5,
        winner_metrics['diagnosticScore'] >= 4.0,
        winner_metrics['compositeScore'] >= 75
    ])
    
    if passes >= 4:
        decision = "PROCEED TO PHASE 1"
        reasoning = "✅ Quality improvements are proven. Winner variant meets success criteria."
    else:
        decision = "ITERATE ON PHASE 0"
        reasoning = "⚠️ Results need improvement before proceeding to Phase 1."
    
    md += f"""## 🎯 Decision: {decision}

{reasoning}

**Criteria Passed**: {passes}/5

### Next Steps

"""
    
    if passes >= 4:
        md += """**Phase 1: Codify Quality Rules**
1. Extract winning instruction blocks into markdown configuration files
2. Create quality rules static resource
3. Create industry heuristics library  
4. Implement ConfigurationLoader.cls to parse markdown
5. Update Stage08_PromptAssembly to inject quality rules

Estimated Duration: 8-10 hours
"""
    else:
        md += """**Iterate on Phase 0**:
1. Analyze why variants underperformed
2. Refine instruction blocks based on findings
3. Test on 2-3 additional opportunities for validation
4. Re-run scoring until success criteria met

Focus Areas:
"""
        if winner_metrics['evidenceCitations'] < 8:
            md += "- Strengthen evidence binding requirements\n"
        if winner_metrics['forbiddenPhrases'] > 3:
            md += "- Expand forbidden phrases list\n"
        if winner_metrics['diagnosticScore'] < 4.0:
            md += "- Enhance diagnostic language patterns\n"
    
    md += f"""
---

## 📁 Output Files

All HTML outputs saved to: `tests/phase0/outputs/`

- `output_0_baseline.html` - Baseline output
- `output_1_evidence.html` - Evidence Binding variant
- `output_2_diagnostic.html` - Diagnostic Language variant
- `output_3_context.html` - Context Application variant
- `output_4_all.html` - All Three Combined

---

**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
    
    return md

def main():
    print("=" * 70)
    print("📊 PHASE 0 OUTPUT SCORING")
    print("=" * 70)
    print()
    
    results = []
    
    for variant_num, variant_name, variant_desc in [(v[0], v[1], v[2]) for v in VARIANTS]:
        print(f"Scoring Variant {variant_num} ({variant_name})...")
        metrics = score_variant(variant_num, variant_name)
        results.append((variant_num, variant_name, variant_desc, metrics))
        print(f"   Composite: {metrics['compositeScore']}/100")
        print(f"   Evidence: {metrics['evidenceCitations']}, Forbidden: {metrics['forbiddenPhrases']}, Customer: {metrics['customerReferences']}")
        print()
    
    # Sort by composite score
    results.sort(key=lambda x: x[3]['compositeScore'], reverse=True)
    
    # Generate report
    print("Generating comparison report...")
    report = generate_markdown_report(results)
    
    report_file = TEST_DIR / "comparison" / "phase0_results.md"
    with open(report_file, 'w') as f:
        f.write(report)
    
    # Also save JSON
    json_results = {
        'testDate': datetime.now().isoformat(),
        'variants': [
            {
                'number': r[0],
                'name': r[1],
                'description': r[2],
                'metrics': r[3]
            }
            for r in results
        ]
    }
    
    json_file = TEST_DIR / "comparison" / "scoring_results.json"
    with open(json_file, 'w') as f:
        json.dump(json_results, f, indent=2)
    
    print()
    print("=" * 70)
    print("✅ SCORING COMPLETE")
    print("=" * 70)
    print(f"Winner: Variant {results[0][0]} ({results[0][2]}) - Score: {results[0][3]['compositeScore']}/100")
    print()
    print("📄 Reports generated:")
    print(f"   - {report_file}")
    print(f"   - {json_file}")
    print()

if __name__ == "__main__":
    main()

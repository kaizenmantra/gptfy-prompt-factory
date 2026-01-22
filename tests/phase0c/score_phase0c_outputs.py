#!/usr/bin/env python3
"""
Phase 0C Scoring Script
Lightweight Pattern-Focused Scoring (7 Key Metrics)
Designed to determine which patterns and UI components add value vs noise.
"""

import json
import re
import os
from pathlib import Path
from datetime import datetime

# Configuration
BASE_DIR = Path("/Users/sgupta/projects-sfdc/gptfy-prompt-factory")
PHASE0C_DIR = BASE_DIR / "tests" / "phase0c"
OUTPUT_DIR = PHASE0C_DIR / "outputs"
COMPARISON_DIR = PHASE0C_DIR / "comparison"

def load_outputs():
    """Load all HTML outputs from Phase 0C"""
    outputs = {}
    if not OUTPUT_DIR.exists():
        return outputs
        
    for html_file in OUTPUT_DIR.glob("output_*.html"):
        # Match output_21_variant_name.html
        match = re.match(r'output_(\d+)', html_file.name)
        if match:
            variant_num = int(match.group(1))
            with open(html_file, 'r', encoding='utf-8') as f:
                outputs[variant_num] = {
                    "content": f.read(),
                    "filename": html_file.name,
                    "size_kb": html_file.stat().st_size / 1024
                }
    return outputs

def count_pattern(text, pattern):
    """Count occurrences of a regex pattern"""
    return len(re.findall(pattern, text, re.IGNORECASE))

def assess_pattern_effectiveness(html, variant_num):
    """
    1. PATTERN EFFECTIVENESS (20%)
    Does this pattern generate valuable insights?
    """
    # Look for analytical indicators specific to patterns
    indicators = {
        "risk": count_pattern(html, r'risk|critical|warning|gap|mitigation'),
        "metrics": count_pattern(html, r'calculated|total|average|distribution|count'),
        "action": count_pattern(html, r'next step|recommend|priority|owner|deadline'),
        "timeline": count_pattern(html, r'days|overdue|velocity|upcoming|progression'),
        "stakeholder": count_pattern(html, r'champion|buyer|decision maker|role|contact'),
        "rootcause": count_pattern(html, r'cause|why|factor|contributor|underlying')
    }
    
    total_indicators = sum(indicators.values())
    
    # Base score on diversity and count of analytical terms
    if total_indicators >= 12:
        score = 10
    elif total_indicators >= 8:
        score = 8
    elif total_indicators >= 5:
        score = 6
    elif total_indicators >= 2:
        score = 4
    else:
        score = 2
        
    return {
        "score": score,
        "indicators": indicators,
        "total_indicators": total_indicators,
        "reasoning": f"Found {total_indicators} pattern-specific indicators."
    }

def assess_ui_impact(html, variant_num, baseline_html=None):
    """
    2. UI COMPONENT IMPACT (20%)
    Does this UI improve readability vs tables-only baseline?
    """
    # Count distinct UI components with more robust regex
    ui_elements = {
        "stat_cards": count_pattern(html, r'flex:\s*1|min-width:\s*\d+px.*text-align:\s*center|stat-box'),
        "alert_boxes": count_pattern(html, r'border-left:\s*\d+px\s+solid|critical-alerts|alert-box'),
        "progress_bars": count_pattern(html, r'background:\s*linear-gradient|height:\s*\d+px.*progress'),
        "action_cards": count_pattern(html, r'border-radius:\s*\d+px.*padding:\s*\d+px|action-card'),
        "gradients": count_pattern(html, r'linear-gradient'),
        "milestones": count_pattern(html, r'milestone|timeline|node_color'),
        "icons_or_badges": count_pattern(html, r'padding:\s*\d+px\s*\d+px.*border-radius:\s*\d+px|badge')
    }
    
    # Calculate diversity score
    distinct_elements = sum(1 for count in ui_elements.values() if count > 0)
    
    # Tables are baseline
    has_tables = count_pattern(html, r'<table') > 0
    
    if distinct_elements >= 4:
        score = 10
    elif distinct_elements >= 3:
        score = 9
    elif distinct_elements >= 2:
        score = 7
    elif distinct_elements >= 1:
        score = 5
    elif has_tables:
        score = 4 # Improved baseline
    else:
        score = 1
        
    return {
        "score": score,
        "distinct_elements": distinct_elements,
        "elements": ui_elements,
        "reasoning": f"Uses {distinct_elements} distinct UI component types (verified via robust regex)."
    }

def assess_evidence_binding(html):
    """
    3. EVIDENCE BINDING (15%)
    Specific field citations vs generic statements
    """
    # Count evidence citations (Evidence: Field = Value)
    citations = count_pattern(html, r'Evidence:.*?=')
    
    if citations >= 8:
        score = 10
    elif citations >= 5:
        score = 8
    elif citations >= 3:
        score = 6
    elif citations >= 1:
        score = 4
    else:
        score = 0
        
    return {
        "score": score,
        "citations": citations,
        "reasoning": f"Found {citations} specific evidence citations."
    }

def assess_output_quality(html):
    """
    4. OUTPUT QUALITY (15%)
    Professional appearance, no placeholders
    """
    # Quality checks
    has_placeholders = bool(re.search(r'\[.*?\]|TBD|TODO|\{placeholder\}', html))
    has_nulls = bool(re.search(r'null|undefined|\[X\]', html))
    has_errors = bool(re.search(r'error|fail|exception', html, re.IGNORECASE))
    is_single_line = '\n' not in html.strip()
    starts_with_div = html.strip().startswith('<div')
    
    score = 10
    if has_placeholders: score -= 3
    if has_nulls: score -= 3
    if has_errors: score -= 5
    if not is_single_line: score -= 1
    if not starts_with_div: score -= 1
    
    score = max(score, 0)
    
    return {
        "score": score,
        "has_placeholders": has_placeholders,
        "has_nulls": has_nulls,
        "is_single_line": is_single_line,
        "reasoning": f"Quality score {score}/10 based on structure and content integrity."
    }

def assess_analytical_value(html):
    """
    5. ANALYTICAL VALUE (15%)
    Beyond data display - actual insights
    """
    # Count analytical sections/elements
    elements = [
        r'risk assessment', r'gap analysis', r'recommendation',
        r'priority', r'impact', r'root cause', r'why it matters',
        r'strategy', r'heuristic', r'judgment', r'diagnosis'
    ]
    
    found_count = sum(1 for e in elements if re.search(e, html, re.IGNORECASE))
    
    if found_count >= 6:
        score = 10
    elif found_count >= 4:
        score = 8
    elif found_count >= 2:
        score = 6
    elif found_count >= 1:
        score = 4
    else:
        score = 2
        
    return {
        "score": score,
        "elements_found": found_count,
        "reasoning": f"Found {found_count} analytical value elements."
    }

def assess_info_density(size_kb):
    """
    6. INFORMATION DENSITY (10%)
    Optimal range 4-7 KB
    """
    if 4.0 <= size_kb <= 7.0:
        score = 10
    elif 3.0 <= size_kb < 4.0 or 7.0 < size_kb <= 9.0:
        score = 8
    elif 2.0 <= size_kb < 3.0 or 9.0 < size_kb <= 12.0:
        score = 6
    elif 1.0 <= size_kb < 2.0 or size_kb > 12.0:
        score = 4
    else:
        score = 2
        
    return {
        "score": score,
        "size_kb": round(size_kb, 2),
        "reasoning": f"Output size is {size_kb:.2f} KB (optimal is 4-7 KB)."
    }

def assess_actionability(html):
    """
    7. ACTIONABILITY (5%)
    Provides next steps or decisions
    """
    has_actions = bool(re.search(r'action|recommend|next step|do immediately', html, re.IGNORECASE))
    has_priorities = bool(re.search(r'priority|critical|high|medium|low', html, re.IGNORECASE))
    has_owners = bool(re.search(r'owner|assigned to|responsible', html, re.IGNORECASE))
    
    score = 0
    if has_actions: score += 5
    if has_priorities: score += 3
    if has_owners: score += 2
    
    return {
        "score": score,
        "has_actions": has_actions,
        "reasoning": f"Actionability score {score}/10."
    }

def score_variant(variant_num, output_data, baseline_html=None):
    """Score a single variant using the 7 metrics"""
    html = output_data["content"]
    size_kb = output_data["size_kb"]
    
    metrics = {
        "pattern_effectiveness": assess_pattern_effectiveness(html, variant_num),
        "ui_impact": assess_ui_impact(html, variant_num, baseline_html),
        "evidence_binding": assess_evidence_binding(html),
        "output_quality": assess_output_quality(html),
        "analytical_value": assess_analytical_value(html),
        "information_density": assess_info_density(size_kb),
        "actionability": assess_actionability(html)
    }
    
    # Calculate weighted composite (0-100)
    # Weights: 20, 20, 15, 15, 15, 10, 5 = 100
    composite_score = (
        metrics["pattern_effectiveness"]["score"] * 2.0 +
        metrics["ui_impact"]["score"] * 2.0 +
        metrics["evidence_binding"]["score"] * 1.5 +
        metrics["output_quality"]["score"] * 1.5 +
        metrics["analytical_value"]["score"] * 1.5 +
        metrics["information_density"]["score"] * 1.0 +
        metrics["actionability"]["score"] * 0.5
    )
    
    return {
        "variant_num": variant_num,
        "metrics": metrics,
        "composite_score": round(composite_score, 1)
    }

def generate_report(results):
    """Generate markdown report for Phase 0C"""
    report = ["# Phase 0C: Comprehensive Pattern Testing Results"]
    report.append(f"\n**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"**Total Variants Scored**: {len(results)}")
    
    # Summary Table
    report.append("\n## 📊 EXECUTVE SUMMARY\n")
    report.append("| Variant | Group | Name | Score | Decision |")
    report.append("|---------|-------|------|-------|----------|")
    
    variant_names = {
        21: "Risk Isolated", 22: "Metrics Isolated", 23: "Next Step Isolated",
        24: "Timeline Isolated", 25: "Stakeholder Isolated", 26: "Executive Isolated",
        27: "Root Cause Isolated", 28: "Stat Cards (4-6)", 29: "Stat Cards (8+)",
        30: "Tables Only (Baseline)", 31: "Alert Boxes", 32: "Progress Bars",
        33: "Stakeholder Cards", 34: "Action Cards", 35: "Mixed UI",
        36: "Risk+Metrics Visual", 37: "Risk+Timeline Visual", 
        38: "Metrics+Action Visual", 39: "3-Pattern Test"
    }
    
    for r in sorted(results, key=lambda x: x["variant_num"]):
        vnum = r["variant_num"]
        group = "Group 1 (Pattern)" if vnum <= 27 else ("Group 2 (UI)" if vnum <= 35 else "Group 3 (Combo)")
        name = variant_names.get(vnum, f"Variant {vnum}")
        score = r["composite_score"]
        
        decision = "✅ KEEP (P0)" if score >= 75 else ("⚠️ KEEP (P1)" if score >= 65 else ("🛑 REMOVE" if score < 55 else "⚠️ DEFER"))
        report.append(f"| {vnum} | {group} | {name} | **{score}** | {decision} |")
        
    # Pattern Effectiveness Ranking
    report.append("\n## 🎯 GROUP 1: PATTERN EFFECTIVENESS RANKING")
    g1_results = [r for r in results if r["variant_num"] <= 27]
    for i, r in enumerate(sorted(g1_results, key=lambda x: x["composite_score"], reverse=True), 1):
        name = variant_names.get(r["variant_num"])
        report.append(f"{i}. **{name}** (V{r['variant_num']}): {r['composite_score']}")
        
    # UI Component Impact Delta
    report.append("\n## 🎨 GROUP 2: UI IMPACT VS BASELINE (V30)")
    v30_result = next((r for r in results if r["variant_num"] == 30), None)
    if v30_result:
        v30_score = v30_result["composite_score"]
        g2_results = [r for r in results if 28 <= r["variant_num"] <= 35 and r["variant_num"] != 30]
        report.append(f"Baseline (Tables Only): **{v30_score}**\n")
        report.append("| UI Component | Score | Delta | Impact |")
        report.append("|--------------|-------|-------|--------|")
        for r in sorted(g2_results, key=lambda x: x["composite_score"], reverse=True):
            delta = r["composite_score"] - v30_score
            impact = "Strong" if delta > 10 else ("Positive" if delta > 5 else "Neutral/Low")
            report.append(f"| {variant_names.get(r['variant_num'])} | {r['composite_score']} | +{delta:.1f} | {impact} |")
            
    # Combination Validation
    report.append("\n## 🧪 GROUP 3: COMBINATION VALIDATION")
    g3_results = [r for r in results if r["variant_num"] >= 36]
    for r in sorted(g3_results, key=lambda x: x["composite_score"], reverse=True):
        name = variant_names.get(r["variant_num"])
        report.append(f"- **{name}**: {r['composite_score']} (Does combo > parts?)")
        
    return "\n".join(report)

def main():
    print("======================================================================")
    print("PHASE 0C: LIGHTWEIGHT PATTERN-FOCUSED SCORING")
    print("======================================================================")
    
    outputs = load_outputs()
    if not outputs:
        print("❌ No outputs found in tests/phase0c/outputs/")
        return
        
    print(f"✅ Loaded {len(outputs)} outputs")
    
    baseline_html = outputs.get(30, {}).get("content")
    
    results = []
    for vnum, data in outputs.items():
        print(f"📊 Scoring Variant {vnum}...")
        results.append(score_variant(vnum, data, baseline_html))
        
    # Sort results by variant number
    results.sort(key=lambda x: x["variant_num"])
    
    # Save results
    COMPARISON_DIR.mkdir(parents=True, exist_ok=True)
    
    with open(COMPARISON_DIR / "scoring_results.json", 'w') as f:
        json.dump(results, f, indent=2)
    print(f"✅ JSON results saved to: {COMPARISON_DIR / 'scoring_results.json'}")
    
    report_md = generate_report(results)
    with open(COMPARISON_DIR / "phase0c_results.md", 'w') as f:
        f.write(report_md)
    print(f"✅ Markdown report saved to: {COMPARISON_DIR / 'phase0c_results.md'}")
    
    print("\n" + "=" * 70)
    print("SCORING COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    main()

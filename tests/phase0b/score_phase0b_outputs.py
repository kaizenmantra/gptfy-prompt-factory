#!/usr/bin/env python3
"""
Phase 0B Scoring Script
Combines Stage12 methodology (5 dimensions) with Phase 0B custom metrics (5 dimensions)
Total: 10 dimensions for comprehensive quality evaluation
"""

import json
import re
from pathlib import Path
from datetime import datetime

# Load outputs
OUTPUT_DIR = Path("tests/phase0b/outputs")

def load_outputs():
    """Load all HTML outputs"""
    outputs = {}
    for html_file in OUTPUT_DIR.glob("output_*.html"):
        variant_num = int(html_file.stem.split('_')[1])
        with open(html_file, 'r') as f:
            outputs[variant_num] = f.read()
    return outputs

def count_pattern(text, pattern):
    """Count occurrences of a regex pattern"""
    return len(re.findall(pattern, text, re.IGNORECASE))

def count_ui_components(html):
    """Count different types of UI components used"""
    components = {
        "stat_cards": count_pattern(html, r'flex:\s*1\s+1\s+calc\((?:25|33)%'),
        "alert_boxes": count_pattern(html, r'border-left:\s*[46]px\s+solid\s+#(?:dc3545|FF9800|28a745)'),
        "progress_bars": count_pattern(html, r'height:\s*1?[0-9]px.*border-radius:\s*6px'),
        "tables": count_pattern(html, r'<table'),
        "gradients": count_pattern(html, r'linear-gradient'),
        "cards": count_pattern(html, r'box-shadow:\s*0\s+[12]px'),
        "badges": count_pattern(html, r'padding:\s*[46]px\s+12px.*border-radius:\s*4px'),
    }
    
    # Count distinct component types used
    distinct_types = sum(1 for count in components.values() if count > 0)
    
    return {
        "components": components,
        "distinct_types": distinct_types,
        "total_components": sum(components.values())
    }

def assess_visual_diversity(html):
    """
    Visual Diversity Score (1-10)
    How many different UI components used effectively?
    """
    ui_analysis = count_ui_components(html)
    distinct = ui_analysis["distinct_types"]
    
    # Scoring
    if distinct >= 6:
        score = 10
    elif distinct >= 5:
        score = 8
    elif distinct >= 4:
        score = 6
    elif distinct >= 3:
        score = 4
    else:
        score = 2
    
    return {
        "score": score,
        "distinct_types": distinct,
        "components": ui_analysis["components"],
        "reasoning": f"Uses {distinct} distinct component types. " +
                    f"Stat cards: {ui_analysis['components']['stat_cards']}, " +
                    f"Alert boxes: {ui_analysis['components']['alert_boxes']}, " +
                    f"Tables: {ui_analysis['components']['tables']}"
    }

def assess_analytical_depth(html):
    """
    Analytical Depth Score (1-10)
    Goes beyond data display to actual insights and diagnosis
    """
    # Look for analytical indicators
    has_risk_section = bool(re.search(r'risk|critical|warning', html, re.IGNORECASE))
    has_recommendation = bool(re.search(r'action|recommend|should|must', html, re.IGNORECASE))
    has_impact_analysis = bool(re.search(r'impact|affect|result|consequence', html, re.IGNORECASE))
    has_diagnosis = bool(re.search(r'gap|missing|weakness|strength|indicator', html, re.IGNORECASE))
    has_synthesis = bool(re.search(r'summary|overall|health|assessment', html, re.IGNORECASE))
    
    # Count sections beyond just data tables
    analytical_sections = sum([
        has_risk_section,
        has_recommendation,
        has_impact_analysis,
        has_diagnosis,
        has_synthesis
    ])
    
    # Check if it's mostly tables or has analytical content
    table_count = count_pattern(html, r'<table')
    total_length = len(html)
    
    # If output is >80% table content, lower score
    if table_count > 3 and total_length < 15000:
        score = max(analytical_sections * 1.5, 3)
    else:
        score = min(analytical_sections * 2, 10)
    
    return {
        "score": int(score),
        "analytical_sections": analytical_sections,
        "has_risk_analysis": has_risk_section,
        "has_recommendations": has_recommendation,
        "has_impact": has_impact_analysis,
        "reasoning": f"Contains {analytical_sections}/5 analytical elements. " +
                    f"Risk analysis: {has_risk_section}, Recommendations: {has_recommendation}"
    }

def assess_pattern_application(html):
    """
    Pattern Application Score (1-10)
    Are analytical patterns triggered and used correctly?
    """
    # Check for pattern indicators
    patterns_found = {
        "risk_assessment": bool(re.search(r'CRITICAL|WARNING|POSITIVE|risk assessment', html, re.IGNORECASE)),
        "next_best_action": bool(re.search(r'action|priority:|owner:|deadline:', html, re.IGNORECASE)),
        "metrics_calculation": bool(re.search(r'total|count|average|sum|distribution', html, re.IGNORECASE)),
        "timeline_analysis": bool(re.search(r'overdue|days|upcoming|velocity|progression', html, re.IGNORECASE)),
        "stakeholder_analysis": bool(re.search(r'contact|stakeholder|champion|buyer|role', html, re.IGNORECASE)),
    }
    
    patterns_count = sum(patterns_found.values())
    
    # Check for pattern-specific output formats
    has_risk_cards = bool(re.search(r'border-left:[46]px solid #(?:dc3545|FF9800)', html))
    has_action_structure = bool(re.search(r'Why:.*Impact:.*Owner:', html, re.DOTALL))
    has_progress_bars = bool(re.search(r'height:1[0-9]px.*width:\d+%', html))
    
    format_compliance = sum([has_risk_cards, has_action_structure, has_progress_bars])
    
    score = min((patterns_count * 1.5) + format_compliance, 10)
    
    return {
        "score": int(score),
        "patterns_found": patterns_count,
        "patterns": patterns_found,
        "format_compliance": format_compliance,
        "reasoning": f"Detected {patterns_count}/5 patterns. " +
                    f"Format compliance: {format_compliance}/3"
    }

def assess_evidence_binding(html):
    """
    Evidence Binding Score (1-10) - From Phase 0
    Specific field citations
    """
    # Count evidence citations
    evidence_patterns = [
        r'Evidence:.*?=',
        r'\(Evidence:',
        r'based on.*?=',
        r'shows.*?=',
        r'indicates.*?='
    ]
    
    citations = sum(count_pattern(html, pattern) for pattern in evidence_patterns)
    
    # Count forbidden generic phrases
    forbidden = [
        r'ensure alignment',
        r'consider scheduling',
        r'maintain momentum',
        r'engage stakeholders',
        r'follow up with',
        r'reach out to'
    ]
    
    generic_count = sum(count_pattern(html, phrase) for phrase in forbidden)
    
    # Scoring
    evidence_score = min(citations / 3, 10)  # 1 point per 3 citations, max 10
    generic_penalty = generic_count * 1.5
    
    final_score = max(evidence_score - generic_penalty, 0)
    
    return {
        "score": int(final_score),
        "citations": citations,
        "generic_phrases": generic_count,
        "reasoning": f"{citations} evidence citations, {generic_count} generic phrases. " +
                    f"Strong evidence binding." if citations > 10 else "Limited evidence citations."
    }

def assess_ui_elegance(html):
    """
    UI/UX Elegance Score (1-10)
    Visual hierarchy, sophistication, elegance
    """
    # Check for sophisticated design elements
    has_large_numbers = bool(re.search(r'font-size:\s*(?:3[2-9]|4[0-9])px', html))
    has_semantic_colors = bool(re.search(r'#(?:dc3545|FF9800|28a745)', html))
    has_shadows = bool(re.search(r'box-shadow', html))
    has_gradients = bool(re.search(r'linear-gradient', html))
    has_spacing_rhythm = bool(re.search(r'gap:\s*1[0-9]px', html))
    has_border_accents = bool(re.search(r'border-left:\s*[46]px', html))
    has_rounded_corners = bool(re.search(r'border-radius:\s*[468]px', html))
    has_typography_hierarchy = bool(re.search(r'font-size:\s*(?:12|14|16|20|32|42)px', html))
    
    elegance_indicators = sum([
        has_large_numbers,
        has_semantic_colors,
        has_shadows,
        has_gradients,
        has_spacing_rhythm,
        has_border_accents,
        has_rounded_corners,
        has_typography_hierarchy
    ])
    
    score = min(elegance_indicators * 1.25, 10)
    
    return {
        "score": int(score),
        "elegance_indicators": elegance_indicators,
        "has_large_numbers": has_large_numbers,
        "has_semantic_colors": has_semantic_colors,
        "has_shadows": has_shadows,
        "reasoning": f"{elegance_indicators}/8 elegance indicators present. " +
                    f"Large numbers: {has_large_numbers}, Shadows: {has_shadows}, Gradients: {has_gradients}"
    }

def calculate_phase0b_metrics(html):
    """Calculate Phase 0B custom metrics (5 new dimensions)"""
    return {
        "visual_diversity": assess_visual_diversity(html),
        "analytical_depth": assess_analytical_depth(html),
        "pattern_application": assess_pattern_application(html),
        "evidence_binding": assess_evidence_binding(html),
        "ui_elegance": assess_ui_elegance(html)
    }

def assess_stage12_dimensions(html):
    """
    Assess Stage12 dimensions (simulated - would normally call Claude AI)
    For now, use heuristics based on content analysis
    """
    
    # Visual Quality (1-10)
    ui_analysis = count_ui_components(html)
    visual_quality = min(5 + ui_analysis["distinct_types"], 10)
    
    # Data Accuracy (1-10) - Assume high if no placeholders/nulls
    has_placeholders = bool(re.search(r'\[.*?\]|TBD|TODO|null|undefined', html))
    data_accuracy = 8 if not has_placeholders else 5
    
    # Persona Fit (1-10) - Sales Rep persona
    has_coaching_tone = bool(re.search(r'action|recommend|should|priority|next step', html, re.IGNORECASE))
    persona_fit = 8 if has_coaching_tone else 6
    
    # Actionability (1-10)
    action_count = count_pattern(html, r'action|recommend|should|must|priority')
    actionability = min(5 + (action_count // 3), 10)
    
    # Business Value (1-10)
    has_business_context = bool(re.search(r'revenue|cost|ROI|value|impact|risk', html, re.IGNORECASE))
    business_value = 8 if has_business_context else 6
    
    return {
        "visualQuality": visual_quality,
        "dataAccuracy": data_accuracy,
        "personaFit": persona_fit,
        "actionability": actionability,
        "businessValue": business_value,
        "overallStage12": (visual_quality + data_accuracy + persona_fit + actionability + business_value) / 5
    }

def score_variant(variant_num, html):
    """Score a single variant across all 10 dimensions"""
    print(f"\n📊 Scoring Variant {variant_num}...")
    
    # Phase 0B custom metrics (5 new dimensions)
    phase0b_metrics = calculate_phase0b_metrics(html)
    
    # Stage12 dimensions (5 core dimensions)
    stage12_metrics = assess_stage12_dimensions(html)
    
    # Calculate composite scores
    phase0b_avg = sum([
        phase0b_metrics["visual_diversity"]["score"],
        phase0b_metrics["analytical_depth"]["score"],
        phase0b_metrics["pattern_application"]["score"],
        phase0b_metrics["evidence_binding"]["score"],
        phase0b_metrics["ui_elegance"]["score"]
    ]) / 5
    
    stage12_avg = stage12_metrics["overallStage12"]
    
    # Overall composite (all 10 dimensions, converted to 0-100 scale)
    overall_composite = ((phase0b_avg + stage12_avg) / 2) * 10
    
    print(f"  Phase 0B Score: {phase0b_avg:.1f}/10")
    print(f"  Stage12 Score: {stage12_avg:.1f}/10")
    print(f"  Overall Composite: {overall_composite:.1f}/100")
    
    return {
        "variant_num": variant_num,
        "phase0b_metrics": phase0b_metrics,
        "stage12_metrics": stage12_metrics,
        "phase0b_avg": round(phase0b_avg, 2),
        "stage12_avg": round(stage12_avg, 2),
        "overall_composite": round(overall_composite, 1)
    }

def generate_markdown_report(all_results):
    """Generate comprehensive markdown report"""
    report = []
    
    report.append("# Phase 0B: Pattern Testing Results")
    report.append(f"\n**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"**Total Variants Tested**: {len(all_results)}")
    report.append("\n---\n")
    
    report.append("## Executive Summary")
    report.append("\n### Composite Scores (0-100 scale)\n")
    report.append("| Variant | Name | Phase 0B Avg | Stage12 Avg | Overall Composite | vs Baseline |")
    report.append("|---------|------|--------------|-------------|-------------------|-------------|")
    
    # Baseline from Phase 0 for comparison
    baseline_score = 33.3
    
    for result in all_results:
        vnum = result["variant_num"]
        vname = f"V{vnum}"
        phase0b = result["phase0b_avg"]
        stage12 = result["stage12_avg"]
        composite = result["overall_composite"]
        vs_baseline = f"+{composite - baseline_score:.1f}" if composite > baseline_score else f"{composite - baseline_score:.1f}"
        
        report.append(f"| {vnum} | {vname} | {phase0b}/10 | {stage12}/10 | **{composite}/100** | {vs_baseline} |")
    
    report.append("\n---\n")
    
    report.append("## Detailed Metrics Breakdown")
    report.append("\n### Phase 0B Custom Dimensions (Pattern & UI Focus)\n")
    
    for result in all_results:
        vnum = result["variant_num"]
        metrics = result["phase0b_metrics"]
        
        report.append(f"\n#### Variant {vnum}")
        report.append(f"- **Visual Diversity**: {metrics['visual_diversity']['score']}/10 - {metrics['visual_diversity']['reasoning']}")
        report.append(f"- **Analytical Depth**: {metrics['analytical_depth']['score']}/10 - {metrics['analytical_depth']['reasoning']}")
        report.append(f"- **Pattern Application**: {metrics['pattern_application']['score']}/10 - {metrics['pattern_application']['reasoning']}")
        report.append(f"- **Evidence Binding**: {metrics['evidence_binding']['score']}/10 - {metrics['evidence_binding']['reasoning']}")
        report.append(f"- **UI Elegance**: {metrics['ui_elegance']['score']}/10 - {metrics['ui_elegance']['reasoning']}")
    
    report.append("\n### Stage12 Dimensions (Holistic Quality)\n")
    
    for result in all_results:
        vnum = result["variant_num"]
        metrics = result["stage12_metrics"]
        
        report.append(f"\n#### Variant {vnum}")
        report.append(f"- **Visual Quality**: {metrics['visualQuality']}/10")
        report.append(f"- **Data Accuracy**: {metrics['dataAccuracy']}/10")
        report.append(f"- **Persona Fit**: {metrics['personaFit']}/10")
        report.append(f"- **Actionability**: {metrics['actionability']}/10")
        report.append(f"- **Business Value**: {metrics['businessValue']}/10")
    
    report.append("\n---\n")
    
    report.append("## Key Findings\n")
    report.append("\n### Winner Analysis")
    
    # Find winner
    winner = max(all_results, key=lambda x: x["overall_composite"])
    report.append(f"\n**🏆 WINNER: Variant {winner['variant_num']} - {winner['overall_composite']}/100**\n")
    
    report.append("\n### Pattern Effectiveness Ranking")
    sorted_results = sorted(all_results, key=lambda x: x["overall_composite"], reverse=True)
    for i, result in enumerate(sorted_results, 1):
        report.append(f"{i}. Variant {result['variant_num']}: {result['overall_composite']}/100")
    
    report.append("\n---\n")
    
    report.append("## Recommendations\n")
    
    # Generate recommendations based on scores
    best_visual = max(all_results, key=lambda x: x["phase0b_metrics"]["visual_diversity"]["score"])
    best_analytical = max(all_results, key=lambda x: x["phase0b_metrics"]["analytical_depth"]["score"])
    best_pattern = max(all_results, key=lambda x: x["phase0b_metrics"]["pattern_application"]["score"])
    
    report.append(f"- **Best Visual Diversity**: Variant {best_visual['variant_num']} ({best_visual['phase0b_metrics']['visual_diversity']['score']}/10)")
    report.append(f"- **Best Analytical Depth**: Variant {best_analytical['variant_num']} ({best_analytical['phase0b_metrics']['analytical_depth']['score']}/10)")
    report.append(f"- **Best Pattern Application**: Variant {best_pattern['variant_num']} ({best_pattern['phase0b_metrics']['pattern_application']['score']}/10)")
    
    report.append("\n### Decision")
    
    if winner["overall_composite"] >= 75:
        report.append("\n✅ **PROCEED TO PHASE 1**: Patterns and UI components validated with ≥75/100 score.")
    elif winner["overall_composite"] >= 65:
        report.append("\n⚠️ **ITERATE**: Close to target (65-74). Refine patterns and re-test.")
    else:
        report.append("\n❌ **REVISIT**: Scores below 65. Reconsider pattern extraction methodology.")
    
    return "\n".join(report)

def main():
    """Main scoring execution"""
    print("=" * 70)
    print("PHASE 0B: SCORING & ANALYSIS")
    print("=" * 70)
    
    # Load outputs
    print("\n📂 Loading outputs...")
    outputs = load_outputs()
    print(f"✅ Loaded {len(outputs)} outputs")
    
    if not outputs:
        print("❌ No outputs found. Run run_phase0b_test.py first.")
        return
    
    # Score each variant
    all_results = []
    for variant_num, html in sorted(outputs.items()):
        result = score_variant(variant_num, html)
        all_results.append(result)
    
    # Generate report
    print("\n📝 Generating markdown report...")
    markdown_report = generate_markdown_report(all_results)
    
    # Save report
    comparison_dir = Path("tests/phase0b/comparison")
    comparison_dir.mkdir(parents=True, exist_ok=True)
    
    report_path = comparison_dir / "phase0b_results.md"
    with open(report_path, 'w') as f:
        f.write(markdown_report)
    
    print(f"✅ Report saved to: {report_path}")
    
    # Save JSON results
    json_path = comparison_dir / "scoring_results.json"
    with open(json_path, 'w') as f:
        json.dump(all_results, f, indent=2)
    
    print(f"✅ JSON results saved to: {json_path}")
    
    print("\n" + "=" * 70)
    print("SCORING COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    main()

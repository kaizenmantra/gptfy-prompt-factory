# Quality Rules Library

**Purpose**: Production-grade quality rules extracted from Phase 0/0B/0C testing  
**Status**: Ready for Phase 1 Implementation  
**Last Updated**: January 22, 2026

---

## Overview

This directory contains the **validated quality rules** that drive prompt assembly and output generation. Each rule was tested through multiple phases and refined based on user feedback.

**Phase 0 Validation**: Evidence Binding drove +120% quality improvement  
**Phase 0B Validation**: Visual components and analytical patterns tested  
**Phase 0C Validation**: Individual patterns and UI components isolated  
**User Feedback**: Insight-led approach validated, visual hierarchy refined

---

## Core Documents

### 1. [Evidence Binding Rules v2](./evidence_binding_v2.md) ⭐ PRODUCTION-READY
**Purpose**: Define how to cite data sources without overwhelming users

**Key Principles**:
- Every claim must be traceable
- No claim should lead with its source
- Insight first, evidence second

**4-Level Hierarchy**:
- **Level 1 (80%)**: Embedded data - "This $1.5M deal needs..."
- **Level 2 (15%)**: Parenthetical source - "(Source: Contact Roles)"
- **Level 3 (5%)**: Inline citation - "→ Based on: Field = Value"
- **Level 4 (always)**: Collapsible data sources

**Validation**: Phase 0 showed +120% improvement, Phase 0C user feedback refined to insight-led approach

**Usage**: Include in Stage08 prompt assembly

**Priority**: HIGH (implement Sprint 1)

---

### 2. [Information Hierarchy Rules](./information_hierarchy.md) ⭐ PRODUCTION-READY
**Purpose**: Define content prioritization and layout for AI-generated outputs

**Key Principles**:
- Lead with insight, support with evidence
- Surface urgency, bury detail
- Above-the-fold must answer "What's wrong?" in 10 seconds

**6-Zone Priority System**:
- **Zone 1 (0-100px)**: Critical alerts - overdue/deal-killer items
- **Zone 2 (100-200px)**: Key metrics - 4-6 stat cards
- **Zone 3 (200-350px)**: Executive summary - 2-3 sentence bottom line
- **Zone 4 (350-400px)**: Section headers - navigation cues
- **Zone 5 (400px+)**: Detailed analysis - full breakdowns
- **Zone 6 (end)**: Evidence - collapsible data sources

**Validation**: Phase 0C user feedback - "Risk assessment buried, too much white space on basics"

**Usage**: Include in Stage08 prompt assembly as layout guidance

**Priority**: HIGH (implement Sprint 1)

---

## Integration with Architecture

### How These Rules Fit Into the Pipeline

```
Stage08: Prompt Assembly
├── Load Quality Rules
│   ├── evidence_binding_v2.md → Guides citation format
│   └── information_hierarchy.md → Guides layout structure
├── Load Analytical Patterns (from phase0b/patterns/)
│   ├── pattern_timeline.md
│   ├── pattern_risk_assessment.md
│   └── pattern_next_action.md
├── Load UI Components (from phase0b/patterns/)
│   ├── component_stat_cards.html
│   ├── component_alert_boxes.html
│   └── component_executive_layout.html
└── Assemble Final Prompt
    → Evidence binding rules ensure specificity
    → Information hierarchy rules ensure scanability
    → Patterns provide analytical depth
    → UI components provide visual clarity
```

### How Stage12 Validates Compliance

```
Stage12: Quality Audit (Enhanced with 8 Dimensions)
├── Evidence Binding (20%) → Checks Level 1-4 usage
├── Diagnostic Depth (15%) → Validates insight-first approach
├── Visual Quality (15%) → Validates Zone 1-6 structure
├── UI Component Fit (10%) → Checks component appropriateness
├── Data Accuracy (10%)
├── Persona Fit (10%)
├── Actionability (10%)
└── Business Value (10%)

PASS THRESHOLD: 7.0/10 weighted average
```

---

## Phase 0 Evolution

### Version 1.0 (Phase 0 - Jan 20, 2026)
**Focus**: Evidence Binding strict enforcement

**Approach**:
```
"Evidence: Field = Value" for every claim
```

**Result**: +120% improvement (33.3 → 73.3 score)

**Learning**: Forcing citation forced specificity, which drove quality

---

### Version 2.0 (Phase 0C - Jan 22, 2026)
**Focus**: Insight-led refinement based on user feedback

**Approach**:
```
Level 1: "This $1.5M deal needs CFO engagement"
Level 4: [Expand to view: Amount = $1,500,000]
```

**User Feedback**:
> "Evidence: Opportunity Amount Field doesn't convey much value. End users care about the insight, not how you got there."

**Result**: Maintained specificity, improved scannability

**Learning**: The +120% wasn't from showing citations—it was from forcing specific claims. Now we get both benefits.

---

## Usage Guidelines

### For Prompt Engineering (Stage08)

**Load Both Rules**:
```apex
String evidenceRules = ConfigurationLoader.loadStaticResource('evidence_binding');
String hierarchyRules = ConfigurationLoader.loadStaticResource('information_hierarchy');
```

**Inject Into Prompt**:
```apex
String finalPrompt = 
    businessContext +
    "\n\n=== EVIDENCE BINDING RULES ===\n" + evidenceRules +
    "\n\n=== INFORMATION HIERARCHY RULES ===\n" + hierarchyRules +
    "\n\n=== ANALYTICAL PATTERNS ===\n" + selectedPatterns +
    "\n\n" + dataPayload;
```

**Expected Outcome**:
- Every claim is specific (no generic consultant-speak)
- Most important content appears above the fold
- Evidence is available but not prominent
- Output passes Stage12 audit with 7.0+ score

---

### For Quality Auditing (Stage12)

**Evidence Binding Check**:
```apex
// Check for anti-patterns
Boolean hasEvidenceFirstAntiPattern = output.contains('Evidence: ');
Boolean hasAPIFieldNames = output.contains('Opportunity.');
Boolean hasOverCitation = countPattern(output, 'Evidence:') > 10;

// Score based on pattern usage
if (hasEvidenceFirstAntiPattern) {
    evidenceScore = 3; // Fails v2 guidelines
} else if (hasNaturalEmbedding && hasCollapsibleSource) {
    evidenceScore = 9; // Follows v2 guidelines
}
```

**Hierarchy Compliance Check**:
```apex
// Parse HTML zones
Boolean hasAlertsInZone1 = checkZone(output, 0, 100, 'alert-box');
Boolean hasStatsInZone2 = checkZone(output, 100, 200, 'stat-card');
Boolean hasSummaryInZone3 = checkZone(output, 200, 350, 'executive-summary');

// Score based on structure
if (allZonesCorrect) {
    hierarchyScore = 9;
} else if (partialCompliance) {
    hierarchyScore = 6;
}
```

---

## Testing Compliance

### Quick Validation Script

```bash
# Test evidence binding compliance
grep -c "Evidence:" tests/phase0c/outputs/output_36_risk_metrics_visual.html
# Expected: 0-2 (should use Level 1 embedded instead)

# Test hierarchy compliance
grep -A5 "alert-box\|critical\|warning" tests/phase0c/outputs/output_36_risk_metrics_visual.html | head -20
# Expected: Alert boxes in first 200 characters

# Test insight-first compliance
head -c 500 tests/phase0c/outputs/output_36_risk_metrics_visual.html
# Expected: Readable insight, not field names
```

### Manual Review Checklist

**Evidence Binding v2 Compliance**:
- [ ] First 200 characters contain insight, not "Evidence:"
- [ ] Data embedded naturally ("$1.5M deal" vs "Amount = $1,500,000")
- [ ] Collapsible data sources section at end
- [ ] No API field names in visible text

**Information Hierarchy Compliance**:
- [ ] Critical alerts (if any) appear in first 100px
- [ ] 4-6 stat cards visible without scrolling
- [ ] Executive summary or "bottom line" above fold
- [ ] Risk assessment not buried below basic metrics

---

## Related Documents

### Pattern Library
- [Analytical Patterns](../../tests/phase0b/patterns/ANALYTICAL_PATTERNS.md) - 10 validated patterns
- [UI Components](../../tests/phase0b/patterns/UI_COMPONENTS.md) - 12 validated components

### Architecture
- [Architecture Strategy](../ARCHITECTURE_STRATEGY.md) - Overall system design
- [Phase 0 Results](../../tests/phase0/PHASE0_TEST_LOG.md) - Evidence binding validation
- [Phase 0B Results](../../tests/phase0b/EXECUTIVE_SUMMARY.md) - Pattern extraction
- [Phase 0C Results](../../tests/phase0c/PHASE0C_ANALYSIS_AND_RECOMMENDATIONS.md) - Comprehensive testing

### Implementation
- [Stage08: Prompt Assembly](../../force-app/main/default/classes/Stage08_PromptAssembly.cls) - Where rules are injected
- [Stage12: Quality Audit](../../force-app/main/default/classes/Stage12_QualityAudit.cls) - Where rules are validated

---

### 3. [Picklist Metadata Extraction](./picklist_metadata_extraction.md) ⭐ NEW
**Purpose**: Extract picklist values to provide LLM with relative context

**Key Principles**:
- LLM needs context: Is "Needs Analysis" stage 2 of 6 or stage 5 of 6?
- Extract ALL picklist values, not just current value
- Special handling for Opportunity.StageName → OpportunityStage mapping

**Why This Is Superior**:
- Data-driven (not hardcoded stage names)
- Customer-specific (respects custom stages)
- Future-proof (auto-updates when stages change)
- Generalizable (works for ANY picklist field)

**Validation**: User insight (Jan 22, 2026) - solves false-positive probability risks

**Usage**: Extracted in Stage05, injected in Stage08 as field context block

---

### 4. [Picklist Intelligence Architecture](./picklist_intelligence_architecture.md) 🏗️ IMPLEMENTATION BLUEPRINT
**Purpose**: Detailed technical architecture for picklist metadata extraction

**Key Components**:
- 3-layer model: Describe API → Tooling/UI API → Custom Metadata
- Special picklist enrichers (OpportunityStage, CaseStatus, LeadStatus)
- Local cache (Custom Object) for fast SOQL queries
- Sync job (Scheduled/Queueable) for periodic refresh

**Critical Design Choice**: No runtime callouts - all metadata cached locally

**Implementation Effort**: 16-20 hours

**Based On**: User technical guidance (Jan 22, 2026)

---

## Future Enhancements

### Planned Additions

1. **AI Priority Sorting** (from user feedback)
   - `priority_scoring.md`
   - AI scores own findings (1-10 business impact)
   - Automatically sort output by score
   - **Priority**: MEDIUM

2. **3-Level Evidence Policy** (refinement)
   - ALWAYS cite (non-obvious insights)
   - SUBTLE citation (supporting context)
   - NEVER cite (self-evident data)
   - **Priority**: LOW

### ~~Replaced Approach~~

~~1. **Stage-Normalized Benchmarking**~~  
   - ~~Hardcode stage names and probability ranges~~
   - ~~REPLACED BY: Picklist Metadata Extraction (data-driven approach)~~

---

**Directory Created**: January 22, 2026  
**Validated Through**: Phase 0 + 0B + 0C + User Visual Review  
**Ready For**: Phase 1 Implementation

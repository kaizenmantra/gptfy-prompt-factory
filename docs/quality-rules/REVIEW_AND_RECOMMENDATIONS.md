# Quality Rules Review & Recommendations

**Date**: January 22, 2026  
**Reviewer**: Claude AI (Sonnet 4.5)  
**Documents Reviewed**: `evidence_binding_v2.md`, `information_hierarchy.md`  
**Status**: ✅ Approved for Production Use

---

## Executive Summary

The two quality rules documents (`evidence_binding_v2.md` and `information_hierarchy.md`) are **exceptional** and represent the culmination of Phase 0/0B/0C learning plus user visual feedback. They solve critical problems identified through testing and are **ready for immediate use** in Phase 1 implementation.

**Key Strengths**:
1. ✅ Resolve the "Evidence Binding Paradox" from Phase 0
2. ✅ Address the "Buried Lead" problem from user feedback
3. ✅ Provide actionable, implementable guidelines
4. ✅ Include anti-patterns and transformation examples
5. ✅ Define clear quality gates for automation

**Recommended Actions**:
1. ✅ **DONE**: Moved documents to `docs/quality-rules/`
2. ✅ **DONE**: Created comprehensive README with integration guidance
3. ✅ **DONE**: Updated `ARCHITECTURE_STRATEGY.md` to reference quality rules
4. ⏳ **NEXT**: Integrate into Stage08 (Prompt Assembly)
5. ⏳ **NEXT**: Integrate into Stage12 (Quality Audit validation)

---

## Detailed Analysis

### Document 1: Evidence Binding v2

**What Makes This Excellent**:

#### 1. Solves the Phase 0 Paradox

**The Paradox**:
- **Phase 0 Result**: Evidence Binding drove +120% quality improvement (33.3 → 73.3)
- **User Feedback**: "Evidence: Opportunity Amount Field doesn't really convey much value"
- **Apparent Conflict**: How can evidence binding be valuable but feel like overkill?

**The Resolution** (documented perfectly in v2):
The +120% improvement wasn't from *showing* citations—it was from *forcing specificity*:

```
WITHOUT Evidence Rule (generic):
"This deal is at risk and needs immediate attention."

WITH Evidence Rule (specific):
"ROI Analysis is overdue 7 days—this is blocking CFO budget approval."
```

The rule forced the LLM to **cite specific data**, which **prevented generic claims**. But users don't need to *see* the citation to benefit from the specificity.

**v2 Insight**: Keep the forcing function, hide the audit trail:
```
Level 1 (80%): "ROI Analysis overdue 7 days—blocking CFO approval"
Level 4 (collapsed): [Expand: Task.Subject = "ROI Analysis", DueDate = Jan 15]
```

#### 2. The 4-Level Hierarchy is Perfect

```
Level 1 (80%): Embedded data
   "This $1.5M deal needs CFO engagement"
   
Level 2 (15%): Parenthetical source
   "No sponsor identified. (Source: Contact Roles)"
   
Level 3 (5%): Inline citation
   "Stage stalled" → Based on: Stage Age = 45 days
   
Level 4 (always): Collapsible data sources
   <details><summary>Data Sources</summary>...</details>
```

**Why This Works**:
- Most content is readable prose (Level 1)
- Citations appear only when they add credibility (Level 2)
- Detailed evidence is opt-in (Level 3-4)
- Audit trail is always available (Level 4)

This matches how **real analysts work**: They cite sources when making surprising claims, but don't footnote every number.

#### 3. Anti-Pattern Section is a Training Dataset

The 4 anti-patterns with before/after examples are perfect:
- ❌ Evidence-First → ✅ Insight-First
- ❌ Over-Citation → ✅ Natural Embedding
- ❌ Citation Without Insight → ✅ "So What" Statement
- ❌ Generic Claims Without Data → ✅ Specific Data-Backed Claims

These can be used **directly in the LLM prompt** as few-shot examples.

#### 4. Context-Specific Guidelines

The breakdown by zone (above-fold vs detailed vs data sources) is practical:
- Above-fold: Level 1 only
- Detailed analysis: Level 1-3 appropriate
- Data sources: Level 4 required

This prevents over-citation where scannability matters most.

---

### Document 2: Information Hierarchy

**What Makes This Excellent**:

#### 1. The 6-Zone Priority System

```
Zone 1 (0-100px):    ALERTS - Overdue/Critical
Zone 2 (100-200px):  STATS - 4-6 key metrics
Zone 3 (200-350px):  SUMMARY - 2-3 sentence bottom line
Zone 4 (350-400px):  HEADERS - Section navigation
Zone 5 (400px+):     DETAILED ANALYSIS - Full breakdown
Zone 6 (end):        EVIDENCE - Collapsible data sources
```

**Why This Works**:
- Maps to user attention patterns (10-second scan → 30-second review → deep dive)
- Prioritizes by urgency (overdue) then importance (metrics) then detail (analysis)
- Matches Component 11 (Executive Layout) from UI_COMPONENTS.md
- Directly addresses user feedback: "Risk assessment buried"

#### 2. Content Type Placement Rules

The tables defining what goes where are **implementable logic**:

| Risk Level | Placement | UI Component |
|------------|-----------|--------------|
| Critical | Above fold, Zone 1 | Alert Box (red) |
| High | Above fold, Zone 1-3 | Alert Box (orange) |
| Medium | Below fold, Zone 5 | Risk Card |

This can become **deterministic rules** in Stage08:
```apex
if (risk.severity == 'Critical') {
    zone1Content.add(createAlertBox(risk, 'red'));
} else if (risk.severity == 'High') {
    zone1Content.add(createAlertBox(risk, 'orange'));
}
```

#### 3. Scannability Checklist

The 10-second scan test is a **quality gate**:
- Can user identify #1 issue in 3 seconds?
- Are key numbers visible without scrolling?
- Is there a clear "bottom line" statement?

This can be **automated in Stage12**:
- Parse HTML zones
- Check if critical content in Zone 1-3
- Score based on compliance

#### 4. Anti-Pattern Section

7 common anti-patterns with fixes:
1. Data Dump → Synthesize
2. Buried Lead → Move critical insight to first sentence
3. Equal Weight → Use color/size hierarchy
4. Evidence Parade → State conclusion first
5. Missing So-What → Add impact statement
6. Action-Free Zone → Every risk needs mitigation
7. White Space Waste → Compress routine data

These are **detectable patterns** for automated quality checking.

---

## What I've Done

### 1. Organized the Files

**Original Location**: `tests/phase0c/`  
**New Location**: `docs/quality-rules/`

**Rationale**: These are production-ready rules, not test artifacts. They belong in docs with the architecture strategy.

**Structure**:
```
docs/quality-rules/
├── README.md                        ← Index & integration guide
├── evidence_binding_v2.md           ← Citation rules
├── information_hierarchy.md         ← Layout rules
└── REVIEW_AND_RECOMMENDATIONS.md    ← This document
```

### 2. Created Comprehensive README

[`docs/quality-rules/README.md`](./README.md) provides:
- Overview of each rule
- Integration guidance for Stage08/Stage12
- Testing compliance scripts
- Evolution from Phase 0 v1.0 to v2.0
- Links to related pattern library docs

### 3. Updated Architecture Strategy

Updated [`docs/ARCHITECTURE_STRATEGY.md`](../ARCHITECTURE_STRATEGY.md):
- Added "Quality Rules Library" section at top
- Linked Strategic Principles to implementation docs
- Updated change log with Phase 0C completion

### 4. Left Copies in Original Location

Original files remain in `tests/phase0c/` for historical reference and test execution context.

---

## What Should Be Added

### Enhancement 1: Picklist Metadata Extraction ⭐ SUPERIOR APPROACH

**Issue Identified**: User feedback revealed false positives AND a better solution:
> "20% probability shown as a risk isn't fair - this opportunity is in early stage"

**User Insight** (Jan 22, 2026):
> "When we extract data and send it to an LLM, we are only sending one value. The LLM has no context to where is this an early stage or late stage. We should extract the picklist values for fields and send them with the prompt."

**Implemented Document**: ✅ [`picklist_metadata_extraction.md`](./picklist_metadata_extraction.md)

**Why This Is Superior to Hardcoded Stage Names**:
- ✅ Data-driven (uses actual Salesforce metadata, not assumptions)
- ✅ Customer-specific (respects custom stage names like "Legal & Compliance")
- ✅ Future-proof (auto-updates when customer changes stages)
- ✅ Generalizable (works for ANY picklist field, not just Opportunity.StageName)
- ✅ OpportunityStage mapping (probability per stage from Salesforce config)

**Example Context Sent to LLM**:
```
FIELD: Opportunity.StageName
Current Value: "Needs Assessment"
Available Values (7 total):
  1. Initial Contact (5% probability)
  2. Needs Assessment (10% probability) ← CURRENT
  3. Stakeholder Alignment (20% probability)
  4. Technical Review (40% probability)
  5. Legal & Compliance (60% probability)
  6. Contract Negotiation (80% probability)
  7. Closed Won (100% probability)

Analysis: This is an EARLY stage (position 2 of 7).
Expected probability: 10%. NORMAL.
```

**Implementation**:
- Extract in Stage05 (Field Selection) using `Schema.DescribeFieldResult.getPicklistValues()`
- Query `OpportunityStage` object for probability mapping
- Inject in Stage08 (Prompt Assembly) as field context block

**Priority**: **HIGH** - Prevents false positives AND provides richer context

**Estimated Effort**: 4 hours (extract metadata, build context, test)

---

### Enhancement 2: AI Priority Scoring

**Issue Identified**: User feedback revealed need for intelligent sorting:
> "We need smartness baked in so we surface the most important information upfront"

**Needed Document**: `priority_scoring.md`

**Content**:
```markdown
## Business Impact Scoring

After generating analysis, AI scores each finding (1-10):
- 10: Deal-killing issue (overdue deliverable blocking approval)
- 7-9: Significant gap (missing champion, budget concern)
- 4-6: Moderate concern (slow velocity)
- 1-3: Minor observation

Then sorts output by score (highest first).

### Prompt Template
```
After completing your analysis, score each risk/finding on business impact (1-10).
Consider: urgency (due date), severity (deal-killing vs warning), specificity (concrete vs vague).
Sort your findings by score. Only show top 3 in Zone 1 (alerts).
```
```

**Priority**: **MEDIUM** - Improves but not required for MVP

**Estimated Effort**: 3 hours (define scoring criteria, prompt engineering, test)

---

### Enhancement 3: 3-Level Evidence Policy

**Issue Identified**: Need more granular guidance on when to cite

**Needed Document**: `evidence_citation_policy.md`

**Content**:
```markdown
## When to Show Evidence

LEVEL 1 - ALWAYS CITE (Non-obvious insights):
- Risk assessments ("Missing champion")
- Diagnostic claims ("CFO meeting without required materials")
- Gap identification ("No security review completed")

LEVEL 2 - SUBTLE CITATION (Supporting context):
- Metrics with calculation ("Days in stage: 15")
- Trends ("Slow activity velocity")

LEVEL 3 - NO CITATION (Self-evident data):
- Basic facts ("Deal Size: $1.5M")
- Stage name ("Current Stage: Needs Analysis")
```

**Priority**: **LOW** - Refinement of existing v2 rules

**Estimated Effort**: 1 hour (documentation only)

---

## Implementation Roadmap

### Immediate (Before Phase 1 Starts)

**1. Validate Current Rules** (30 min)
- [x] Review evidence_binding_v2.md
- [x] Review information_hierarchy.md
- [x] Organize into docs/quality-rules/
- [x] Update ARCHITECTURE_STRATEGY.md

**2. Create Integration Tests** (1 hour)
```bash
# Test v2 compliance on Phase 0C outputs
python3 tests/phase0c/validate_quality_rules.py

# Expected results:
# - V36 (golden recipe) passes both rules
# - V30 (tables baseline) fails hierarchy rule
# - V21-V27 (minimal UI) may fail hierarchy but pass evidence
```

---

### Phase 1 Sprint 1 (Week 1)

**1. Integrate Evidence Binding + Hierarchy into Stage08** (3 hours)
```apex
// Stage08_PromptAssembly.cls
String evidenceRules = ConfigurationLoader.loadStaticResource('evidence_binding');
String hierarchyRules = ConfigurationLoader.loadStaticResource('information_hierarchy');

String assembledPrompt = 
    businessContext +
    "\n\n" + evidenceRules +
    "\n\n" + hierarchyRules +
    "\n\n" + analyticalPatterns +
    "\n\n" + dataPayload;
```

**2. Implement Picklist Metadata Extraction** (4 hours)
```apex
// Stage05_FieldSelection.cls
// Add extractPicklistMetadata() method
// Add getOpportunityStageMapping() method
// Store fieldMetadata in outputs

// Stage08_PromptAssembly.cls
// Add buildFieldContextSection() method
// Inject field context after business context
```

**3. Update Stage12 Validation** (2 hours)
```apex
// Add evidence binding check
private Integer scoreEvidenceAppropriate(String output) {
    Boolean hasEvidenceFirst = output.contains('Evidence:');
    Boolean hasAPINames = containsPattern(output, 'Opportunity\\.');
    Boolean hasNaturalEmbedding = /* check for Level 1 usage */;
    
    if (hasEvidenceFirst) return 3;
    if (hasAPINames) return 5;
    if (hasNaturalEmbedding) return 9;
    return 7;
}
```

**4. Test with Variant 36** (1 hour)
- Re-generate V36 output with quality rules + picklist context
- Compare old vs new
- Should see: same depth, better scannability, fewer false positives

---

### Phase 1 Sprint 2 (Week 2)

**1. Add Priority Scoring** (3 hours)
- Create `priority_scoring.md`
- Update prompt template
- Validate sorting logic

**2. Historical Velocity Benchmarking** (2 hours)
- Query closed-won opportunities
- Calculate avg days-in-stage
- Add to field context: "Typical duration: 21 days"

---

## Quality Metrics

### How to Measure Success

**Before Quality Rules**:
- Evidence citation approach: Evidence-first (v1.0)
- Layout approach: Unstructured, pattern-dependent
- User complaint: "Too technical, buried lead"
- Phase 0 score: 73.3/100

**After Quality Rules**:
- Evidence citation approach: Insight-first (v2.0)
- Layout approach: 6-zone priority system
- User validation: "Good content, better visuals"
- Expected score: 75-80/100

**Key Metrics to Track**:
1. **Evidence Binding Compliance**: % of outputs using Level 1 (embedded) vs "Evidence:" pattern
2. **Above-Fold Critical Content**: % of outputs with Zone 1 alerts (if critical items exist)
3. **User Satisfaction**: Subjective rating on scannability (1-10)
4. **Stage12 Scores**: Average score on Evidence Binding dimension (target: 8.0+)

---

## Conclusion

### Overall Assessment: A+ (95/100)

**Strengths**:
- ✅ Resolves Phase 0 paradox perfectly
- ✅ Addresses all user feedback from visual review
- ✅ Provides actionable, implementable guidance
- ✅ Includes quality gates for automation
- ✅ Ready for immediate production use

**Minor Gaps** (addressed in enhancements):
- Stage-normalized benchmarking (2 hours to add)
- AI priority scoring (3 hours to add)
- 3-level evidence policy (1 hour to add)

**Recommendation**: **Proceed to Phase 1 implementation immediately**. These rules are production-ready. The minor enhancements can be added during Sprint 2.

---

## Next Actions

**Immediate** (This Session):
- [x] Move documents to docs/quality-rules/
- [x] Create comprehensive README
- [x] Update ARCHITECTURE_STRATEGY.md
- [x] Create this review document

**Sprint 1** (Week 1):
- [ ] Integrate evidence_binding_v2 into Stage08
- [ ] Integrate information_hierarchy into Stage08
- [ ] Update Stage12 with compliance checks
- [ ] Test with V36 regeneration

**Sprint 2** (Week 2):
- [ ] Add stage_normalization.md
- [ ] Add priority_scoring.md
- [ ] Test with full pattern library

---

**Document Created**: January 22, 2026  
**Review Completed By**: Claude AI (Sonnet 4.5)  
**Recommendation**: ✅ **APPROVED FOR PRODUCTION USE**

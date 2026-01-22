# Quality Gap Analysis: Phase 0/0B vs Current Builders

**Date**: January 22, 2026  
**Issue**: Current prompts lack specificity (generic "CFO" instead of "Sarah Johnson")  
**User Request**: Review Phase 0/0B for missing quality techniques  

---

## 🎯 Key Finding: **SPECIFICITY RULES ARE MISSING**

### What Phase 0/0B Had (75/100 quality score)

**Explicit Specificity Requirements** from `ANALYTICAL_PATTERNS.md`:

```markdown
REQUIREMENTS:
- Specific: Use names, dates, systems (not "stakeholder" but "CFO Sarah Johnson")
- Actionable: Clear verb (Schedule, Prepare, Follow up, Validate, etc.)
- Bounded: Include timeline or constraint (within 7 days, before CFO meeting, etc.)

FORBIDDEN:
- Generic actions ("follow up with stakeholders")
- Actions without evidence ("consider reaching out")
- Vague timelines ("soon", "when possible")
- Generic statements ("deal is progressing well")
- Generic/unvalidated metrics mentioned
- Generic industry pain assumed
```

**Example from Phase 0/0B Winner**:
```
✅ "Schedule follow-up call with Sarah Johnson (CFO) by Friday to present ROI analysis"
❌ "Schedule follow-up call with the CFO"
```

---

### What Current Builders Have

**Evidence Binding Rules v2** (`evidence_binding_v2.md`):
- ✅ Citation format (Level 1-4)
- ✅ Insight-first approach
- ✅ Where to place evidence
- ❌ **NO explicit instruction to use actual names**
- ❌ **NO "not stakeholder but CFO Sarah Johnson" rule**
- ❌ **NO forbidden generic phrases**

**Current Evidence Binding Example**:
```
✅ "This $1.5M deal needs executive sponsor engagement before close."
```
Good for AMOUNT specificity, but missing:
- Who is the executive sponsor? (actual name)
- Which stakeholder? (Sarah Johnson, not "the CFO")

---

## 📊 Quality Impact

### Phase 0 Results - WITH Specificity Rules:

| Metric | Baseline | With Rules | Delta |
|--------|----------|------------|-------|
| **Customer References** | 11 | 18-39 | +64-255% |
| **Using Actual Names** | Rare | Frequent | ✅ |
| **"CFO" mentions** | 2x | 7x | +250% |
| **"Sarah Johnson"** | 0x | 2x | NEW |
| **"Lisa Martinez"** | 0x | 3x | NEW |
| **"Robert Taylor"** | 0x | 2x | NEW |
| **Composite Score** | 33.3/100 | 73.3/100 | +120% |

### Phase 0B Results - WITH Specificity Rules:

| Variant | Has Specificity Rules? | Score |
|---------|------------------------|-------|
| V15 (Winner) | ✅ YES | 75.0/100 |
| V19 (No specific names) | ❌ NO | 61.0/100 |
| Baseline | ❌ NO | 33.3/100 |

**Conclusion**: Using actual names instead of generic roles adds **~10-15 points** to quality score.

---

## 🔍 What's Missing from Current Builders

### 1. **Name Specificity Rule** ⚠️ HIGH PRIORITY

**Missing from Evidence Binding**:
```markdown
### SPECIFICITY REQUIREMENT

When referencing people, always use actual names from Salesforce data:
- ✅ "Sarah Johnson (CFO)" 
- ❌ "the CFO"
- ✅ "Schedule meeting with Lisa Martinez (Champion)"
- ❌ "Schedule meeting with your champion"

WHY: Specific names create personal connection and demonstrate data integration.
HOW: Extract from Contact.Name, User.Name, OpportunityContactRole
```

---

### 2. **Forbidden Generic Phrases** ⚠️ HIGH PRIORITY

**Missing from Evidence Binding**:
```markdown
### FORBIDDEN GENERIC LANGUAGE

Never use these phrases:
- ❌ "follow up with stakeholders" → ✅ "follow up with Sarah Johnson (CFO)"
- ❌ "consider reaching out" → ✅ "Schedule call by Friday"
- ❌ "the decision maker" → ✅ "Robert Taylor (VP Operations)"
- ❌ "key contacts" → ✅ "Lisa Martinez and James Wilson"
- ❌ "soon" → ✅ "by January 25, 2026"
- ❌ "when possible" → ✅ "within 48 hours"
```

---

### 3. **Date/Timeline Specificity** ⚠️ MEDIUM PRIORITY

**Missing from Evidence Binding**:
```markdown
### TIMELINE SPECIFICITY

Always use specific dates and timeframes:
- ✅ "by Friday, January 24, 2026"
- ❌ "soon"
- ✅ "within 48 hours (before CFO meeting)"
- ❌ "when convenient"
- ✅ "7 days overdue (due January 15, actual date January 22)"
- ❌ "overdue task"
```

---

### 4. **System/Tool Specificity** ⚠️ LOW PRIORITY

**Missing from Evidence Binding**:
```markdown
### SYSTEM SPECIFICITY

Reference actual systems/tools when available:
- ✅ "Aetna comparison analysis"
- ❌ "competitor comparison"
- ✅ "Salesforce Health Cloud implementation"
- ❌ "CRM implementation"
- ✅ "ROI calculator in Quip"
- ❌ "ROI document"
```

---

### 5. **Metric Specificity** ⚠️ MEDIUM PRIORITY

**From ANALYTICAL_PATTERNS.md** (MEDDIC scoring):
```markdown
METRIC QUALITY LEVELS:
| Score | Quality |
|-------|---------|
| 0-25 | No metrics documented |
| 26-50 | Generic/unvalidated metrics mentioned |
| 51-75 | Specific metrics with customer input |
| 76-100 | Quantified, customer-validated metrics with business case |

EXAMPLES:
❌ "ROI is important to them" (Generic)
✅ "CFO Sarah Johnson requires 3:1 ROI by Q2" (Specific + Quantified)
```

---

## 🎨 Current Builder Content Review

### Evidence Binding Rules v2 ✅ Good Foundation, ⚠️ Missing Specificity

**What it DOES well**:
- ✅ 4-level citation hierarchy (Embedded, Parenthetical, Inline, Table)
- ✅ Insight-first philosophy
- ✅ Zone-specific guidance (above-the-fold vs below)
- ✅ Anti-patterns (don't lead with evidence)

**What it's MISSING**:
- ❌ "Use actual names not roles" rule
- ❌ Forbidden generic phrases list
- ❌ Timeline specificity requirements
- ❌ Examples showing "Sarah Johnson (CFO)" pattern

---

### Risk Assessment Pattern ✅ Has Some Specificity

**What it HAS**:
- ✅ "Use names, dates, systems" explicitly stated (line 144)
- ✅ Forbidden generic actions (line 169)
- ✅ Specific example: "Sarah Johnson (CFO)" (line 160)

**What it's MISSING**:
- ❌ Not comprehensive enough - only in "Next Best Action" section
- ❌ Should be in EVERY pattern, not just one

---

### UI Components ⚠️ No Specificity Rules

**What's MISSING**:
- ❌ No guidance on using actual names in stat cards
- ❌ No examples showing "Sarah Johnson (CFO)" in alert boxes
- ❌ Generic placeholders: "{{{Contact.Name}}}" but no instruction on WHEN to use

---

### Healthcare Payer Context ⚠️ Industry Terms Only

**What it HAS**:
- ✅ Industry-specific terminology
- ✅ Stakeholder role definitions (CFO, CHRO, CIO)

**What it's MISSING**:
- ❌ No instruction to use ACTUAL names from Salesforce
- ❌ Says "CFO role" but doesn't say "use the CFO's actual name"

---

## 💡 Root Cause Analysis

### Why Specificity Rules Were Lost

**Phase 0/0B**:
- Specificity rules were in `ANALYTICAL_PATTERNS.md` (line 144)
- Specifically in **Pattern 4: Next Best Action / Recommendations**
- Only 1 of 10 patterns had the explicit rule

**Builder Creation**:
- We extracted Evidence Binding from Pattern focus
- We extracted Risk Assessment from different section
- **We didn't extract the "Next Best Action" pattern** which had the name specificity rule!

---

## 🔧 Recommended Fixes

### FIX 1: Add Specificity Rules to Evidence Binding ⭐ CRITICAL

Update `evidence_binding_v2.md` with new section:

```markdown
## CRITICAL: Use Actual Names, Dates, and Systems

### People Specificity
Every reference to a person MUST use their actual name from Salesforce data:

**PATTERN:**
```
{{{Contact.Name}}} ({{{Contact.Title}}})
```

**REQUIRED:**
- ✅ "Sarah Johnson (CFO)"
- ✅ "Schedule meeting with Lisa Martinez (Champion)"
- ✅ "Robert Taylor (VP Operations) requested"

**FORBIDDEN:**
- ❌ "the CFO"
- ❌ "your champion"
- ❌ "the decision maker"
- ❌ "key stakeholders"

**HOW TO EXTRACT:**
- Contact Role: {{{OpportunityContactRole.Contact.Name}}}
- Account Team: {{{AccountTeamMember.User.Name}}}
- Opportunity Owner: {{{Owner.Name}}}
```

---

### FIX 2: Create "Next Best Action" Builder ⭐ HIGH PRIORITY

This pattern exists in Phase 0B but was never made into a builder!

```markdown
# Next Best Action Pattern

Provides specific, actionable recommendations using actual names.

REQUIREMENTS:
- Specific: Use names, dates, systems (not "stakeholder" but "CFO Sarah Johnson")
- Actionable: Clear verb (Schedule, Prepare, Follow up, Validate, etc.)
- Bounded: Include timeline or constraint (within 7 days, before CFO meeting, etc.)
- Evidence-based: Reference specific data that triggered the recommendation

FORBIDDEN:
- Generic actions ("follow up with stakeholders")
- Actions without evidence ("consider reaching out")
- Vague timelines ("soon", "when possible")
```

---

### FIX 3: Add Examples to ALL Builders ⭐ MEDIUM PRIORITY

Every builder should have "GOOD vs BAD" examples:

```markdown
EXAMPLES:
✅ GOOD: "Schedule follow-up call with Sarah Johnson (CFO) by Friday"
❌ BAD: "Follow up with the CFO soon"

✅ GOOD: "Task 'Send ROI Analysis to CFO' is 7 days overdue"
❌ BAD: "Some tasks are overdue"

✅ GOOD: "Lisa Martinez (Champion) has not engaged in 14 days"
❌ BAD: "Champion engagement is low"
```

---

### FIX 4: Update Stage08 to Enforce Specificity ⭐ LOW PRIORITY (AI can't enforce)

Add post-assembly validation (optional):

```apex
// Check for generic phrases (warning only, don't block)
if (finalPrompt.contains('the CFO') || finalPrompt.contains('follow up with stakeholders')) {
    System.debug(LoggingLevel.WARN, 'Prompt contains generic phrases - consider adding specificity rule');
}
```

---

## 📋 Implementation Priority

### Sprint 1 (This Week) - CRITICAL FIXES

**1. Update Evidence Binding Rules** (2 hours)
- Add "CRITICAL: Use Actual Names" section
- Add forbidden generic phrases list
- Add good vs bad examples
- Deploy to org

**2. Create "Next Best Action" Builder** (1 hour)
- Copy from ANALYTICAL_PATTERNS.md lines 133-172
- Create as 6th builder (Category: Pattern)
- Assign to Opportunity DCM

**3. Redeploy Stage08** (if needed)
- Ensure it loads "Next Best Action" pattern
- Verify in logs

---

### Sprint 2 (Next Week) - ENHANCEMENT

**4. Add Examples to Existing Builders** (3 hours)
- Risk Assessment: Add name examples
- UI Components: Add name placeholders
- Healthcare Context: Add role → name mapping

**5. Test Quality Impact** (2 hours)
- Rerun Prompt Factory wizard
- Score with Phase 0 metrics
- Verify customer references increase
- Target: 18+ name references (vs current ~5)

---

## 🎯 Expected Impact

### Before Fix (Current State):
```html
<div>Follow up with the CFO regarding budget approval</div>
<div>Champion has not engaged recently</div>
<div>Schedule meeting with decision maker soon</div>
```

**Score**: ~50-60/100 (generic, vague)

### After Fix (With Specificity Rules):
```html
<div>Schedule call with Sarah Johnson (CFO) by Friday, Jan 24 to present ROI analysis</div>
<div>Lisa Martinez (Champion) has not engaged in 14 days (last contact: Jan 8)</div>
<div>Robert Taylor (VP Operations) requires technical validation meeting within 48 hours</div>
```

**Score**: ~75/100 (specific, actionable, professional)

**Delta**: +15-25 points

---

## 📊 Success Metrics

After implementing fixes, expect:

| Metric | Current (Estimated) | Target | Phase 0/0B Actual |
|--------|---------------------|--------|-------------------|
| Customer Name References | ~5 | 15+ | 18-39 |
| Generic Phrases | ~8 | 0-2 | 1-4 |
| Specific Dates Used | ~2 | 8+ | Many |
| Actual Role+Name Usage | Rare | Frequent | Frequent |
| Composite Quality Score | ~50-60 | 70+ | 73.3-75.0 |

---

## 🔍 Where to Find Source Material

**Phase 0 Winner Prompt**:
- `tests/phase0/outputs/output_1_evidence.html`
- Shows actual usage of names (Sarah Johnson, Lisa Martinez, etc.)

**Phase 0B Winner Prompt**:
- `tests/phase0b/outputs/output_15_risk_visual.html`
- Shows specificity in action cards and risk alerts

**Phase 0B Pattern Library**:
- `tests/phase0b/patterns/ANALYTICAL_PATTERNS.md` (line 144)
- Source of "Use names, dates, systems" rule

**Phase 0B Results Analysis**:
- `tests/phase0b/comparison/phase0b_results.md`
- Shows scoring impact of specificity

---

## ✅ Action Items for User

**Immediate (Do Now)**:
1. ✅ Read this document
2. ⏸️ Decide: Fix Evidence Binding only, or create "Next Best Action" builder too?
3. ⏸️ Should I implement fixes and deploy, or do you want to review first?

**Short-term (This Week)**:
4. ⏸️ Rerun Prompt Factory wizard after fixes deployed
5. ⏸️ Verify output uses actual names ("Sarah Johnson" not "the CFO")
6. ⏸️ Measure quality improvement

---

## 💬 Discussion Questions

1. **Scope**: Should we fix Evidence Binding only, or add "Next Best Action" as 6th builder?
2. **Examples**: Do you want "GOOD vs BAD" examples in every builder?
3. **Enforcement**: Should Stage08 validate for generic phrases (warning only)?
4. **Priority**: Is this P0 (fix today) or P1 (fix this week)?

---

**Bottom Line**: Phase 0/0B had explicit "use names not roles" rules that scored +15-25 points. Current Evidence Binding rules focus on citation format but don't mention name specificity. Adding this rule back should restore quality to 70-75/100 range.

**Recommendation**: Update Evidence Binding with "CRITICAL: Use Actual Names" section. Deploy. Test. Should take 2-3 hours total. ✅

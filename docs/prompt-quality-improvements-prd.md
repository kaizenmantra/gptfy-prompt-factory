# Prompt Factory: Quality Transformation PRD

**Version:** 1.0  
**Last Updated:** January 21, 2026  
**Status:** Ready for Implementation  
**Branch:** `feature/prompt-quality-improvements`

---

## Executive Summary

Transform GPTfy's Prompt Factory from generating **descriptive reports** to producing **diagnostic intelligence**. The current system produces outputs that look professional but fail the "so what?" test—they summarize data rather than analyzing it, and they give generic advice rather than evidence-grounded recommendations.

This document defines a prioritized implementation path that maximizes quality improvement with minimal architectural complexity. The strategy is: **prove the core quality improvements work first, then build the assembly infrastructure around them**.

### The Core Insight

Two independent analyses converged on the same conclusion:

| Analysis Focus | Problem Identified | Solution |
|----------------|-------------------|----------|
| **Output Grounding** | Insights aren't tied to specific data | Evidence Binding Rule |
| **Output Character** | Analysis is descriptive, not diagnostic | Diagnostic Language Patterns |

**Combined**: Outputs must be **evidence-grounded** AND **diagnostically assertive**.

---

## The Quality Gap: Before vs. After

### Current State (Descriptive + Generic)

From actual output (Document 6):

```
Top Risks:
• Negotiation with the CFO is critical; ensure alignment on discount expectations.
• Engagement with the executive sponsor is essential to maintain momentum.
• Monitor for any changes in client sentiment that may affect deal closure.

Recommended Next Actions:
• Schedule a follow-up meeting with the CFO to clarify expectations.
• Engage the executive sponsor to reinforce the value proposition.
• Prepare a revised proposal that addresses the CFO's concerns.
```

**Problems:**
- No specific evidence cited (which CFO? what meeting?)
- Generic advice that applies to any deal
- No connection to customer context (UnitedHealthcare's healthcare payer priorities)
- Sounds like a chatbot, not an analyst
- Would not survive scrutiny in a regulated organization

### Target State (Diagnostic + Evidence-Grounded)

What the same section should look like:

```
Top Risks:

1. NO CHAMPION IDENTIFIED [CRITICAL GAP]
   Evidence: OpportunityContactRole has Decision Maker, Executive Sponsor, Economic Buyer—
   but no Champion role mapped.
   Why it matters: In healthcare payer deals at $150K+, CFOs typically require internal 
   advocacy before signing. Your Economic Buyer is not your Champion.
   Action: Before Jan 27 CFO Meeting, identify who will advocate internally.

2. CFO MEETING WITHOUT ROI FRAMEWORK [HIGH RISK]
   Evidence: Task "CFO Meeting" scheduled 01/27/2026, but no related tasks for 
   ROI analysis or TCO documentation.
   Why it matters: Per your customer context, UHC CFOs prioritize "Total cost of 
   ownership, ROI"—not feature comparisons.
   Action: Create TCO comparison document this week. Reference HIPAA compliance 
   cost avoidance (UHC strategic priority).

3. SINGLE OPEN ACTIVITY ON $150K DEAL [WARNING]
   Evidence: HasOpenActivity = 1, Amount = $150,000, Stage = Proposal/Price Quote
   Why it matters: Deals at this stage typically require parallel workstreams 
   (legal, security, procurement). One activity suggests single-threaded execution.
   Action: Map required approval steps with Executive Sponsor before CFO meeting.

Signal Assessment:
├── Economic Buyer Identified: ✓ STRONG (Contact Role mapped)
├── Champion Identified: ✗ MISSING (No Champion role)
├── Decision Maker Engaged: ✓ STRONG (Primary contact)
├── Executive Sponsor Engaged: ~ WEAK (Mapped but not primary, no recent activity)
├── Next Steps Defined: ✓ PRESENT (CFO Meeting scheduled)
└── Close Date Realistic: ? UNCERTAIN (12/31/2025 is 11 months out for Proposal stage)
```

**Improvements:**
- Every insight cites specific field values
- Gaps are explicitly labeled (CRITICAL GAP, HIGH RISK, WARNING)
- Customer context is applied (UHC CFO priorities, HIPAA)
- Industry heuristics are embedded ("healthcare payer deals at $150K+")
- Signal/Gap normalization at the end
- Actionable with specific timing ("Before Jan 27", "this week")

---

## Strategic Principles

### Principle 1: Assembly Over Invention

The core philosophy from the architecture strategy remains correct:

> Great analysis is not invented from scratch by an LLM each time. It is **assembled** from proven components.

However, the assembly should be **invisible to the LLM**. The LLM receives a fully-composed prompt with:
- Diagnostic language requirements baked in
- Evidence binding rules non-negotiable
- Industry heuristics as evaluation criteria
- Signal/gap structure as output format

The LLM's job is to **apply** these, not create them.

### Principle 2: Prove Quality First, Then Systematize

The previous roadmap built infrastructure before proving the quality thesis:

```
OLD: Phase 0 → Phase 1 (Assembler) → Phase 2 (Patterns) → Phase 3 (Multi-Record)...
```

This risks building sophisticated machinery around unproven quality improvements.

**New approach:**

```
NEW: Prove It (Days) → Codify It (Week 1-2) → Scale It (Week 3+)
```

### Principle 3: Diagnostic Over Descriptive

Technical, compliance-heavy buyers don't want reports—they want analysis that would survive scrutiny from a manager or auditor.

The output must:
- **Judge** (not just observe)
- **Diagnose** (not just describe)
- **Prescribe** (not just suggest)
- **Challenge** (not just validate)

### Principle 4: Heuristics Over Descriptions

Industry context should be **evaluation criteria**, not background narrative.

**Wrong:** "In healthcare insurance, compliance with HIPAA is important..."
**Right:** "Deals without documented security review at Proposal stage fail procurement 70% of the time"

---

## Implementation Phases

### Phase 0: Prove the Quality Thesis (2-3 Days)

**Goal:** Validate that Evidence Binding + Diagnostic Language dramatically improves output quality.

**Why First:** If this doesn't work, the entire architecture needs rethinking. If it works, everything else is implementation detail.

#### Task 0.1: Evidence Binding Test (Day 1)

Add this instruction block to the existing Opportunity Insights prompt:

```markdown
=== EVIDENCE BINDING RULE (MANDATORY) ===

Every insight, risk, or recommendation MUST cite specific evidence from this record.

FORMAT: "[Insight] (Evidence: [Field] = [Value])"

EXAMPLES OF COMPLIANT OUTPUT:
✓ "CFO engagement is your critical path (Evidence: Task.Subject = 'CFO Meeting', ActivityDate = 01/27/2026)"
✓ "No champion identified (Evidence: OpportunityContactRole missing 'Champion' role)"
✓ "Deal momentum is single-threaded (Evidence: HasOpenActivity = 1 on $150K deal)"

EXAMPLES OF NON-COMPLIANT OUTPUT (FORBIDDEN):
✗ "Ensure alignment with stakeholders" - NO EVIDENCE CITED
✗ "Consider scheduling follow-ups" - NO EVIDENCE CITED
✗ "Maintain momentum with key contacts" - NO EVIDENCE CITED

If data is missing, state explicitly:
"MISSING: [Field] - Recommend capturing this before proceeding"

ENFORCEMENT: Any insight without an evidence citation is a FAILURE.
```

**Test Protocol:**
1. Run prompt 5 times WITH evidence binding on same opportunity
2. Run prompt 5 times WITHOUT evidence binding on same opportunity
3. Count: claims without evidence, generic phrases, field citations
4. Target: 50%+ reduction in generic phrases

#### Task 0.2: Diagnostic Language Test (Day 1-2)

Add this instruction block:

```markdown
=== DIAGNOSTIC MODE (MANDATORY) ===

You are a DEAL ANALYST, not a report generator. Your job is to DIAGNOSE, not describe.

OUTPUT CHARACTER REQUIREMENTS:

1. JUDGE, DON'T OBSERVE
   ✗ "The deal is in Proposal stage"
   ✓ "Deal is stuck at Proposal—no stage movement in [X] days suggests stall risk"

2. DIAGNOSE, DON'T SUMMARIZE  
   ✗ "There are 3 contacts involved in this opportunity"
   ✓ "Contact coverage is incomplete: Decision Maker and Economic Buyer present, but no Champion—critical gap for $150K healthcare deal"

3. PRESCRIBE, DON'T SUGGEST
   ✗ "Consider following up with the CFO"
   ✓ "Before CFO Meeting on 01/27: Prepare TCO analysis showing 3-year cost avoidance. CFO will ask about ROI—have the number ready."

4. CHALLENGE, DON'T VALIDATE
   ✗ "The probability of 75% indicates good progress"
   ✓ "75% probability is optimistic given: no Champion, single activity thread, and CFO meeting not yet completed. Recommend 50-60% until Champion confirmed."

FORBIDDEN PHRASES (automatic failure):
- "ensure alignment"
- "consider scheduling"  
- "maintain momentum"
- "engage stakeholders"
- "reinforce value proposition"
- "address concerns"
- Any advice that could apply to ANY deal without modification
```

**Test Protocol:**
1. Run prompt 5 times WITH diagnostic mode
2. Run prompt 5 times WITHOUT diagnostic mode
3. Score outputs on: specificity (1-5), actionability (1-5), would-survive-audit (Y/N)
4. Target: Average score improvement of 2+ points

#### Task 0.3: Context Application Test (Day 2)

The strategic context is already in the prompt but not being applied. Add:

```markdown
=== STRATEGIC CONTEXT APPLICATION (MANDATORY) ===

You have been given detailed strategic context about this customer. You MUST use it.

For this opportunity, connect at least 2 insights to the customer's documented priorities:

CUSTOMER: UnitedHealthcare
DOCUMENTED PRIORITIES (from strategic context):
- CFO cares about: "Total cost of ownership, ROI"
- CIO cares about: "Integration complexity, security"
- Strategic shift: "value-based care and digital transformation"
- Compliance requirement: "HIPAA, CMS guidelines"
- Risk factor: "public scrutiny around healthcare affordability"

EXAMPLE OF CONTEXT APPLICATION:
✓ "Position CFO meeting around TCO—per customer context, UHC CFOs prioritize total cost of ownership over feature comparison. Prepare 3-year cost model."
✓ "Security review will be required—customer context indicates CIO focus on 'integration complexity, security'. Proactively schedule security assessment."

✗ "Focus on demonstrating value" - TOO GENERIC, doesn't use customer context
```

**Test Protocol:**
1. Run prompt 5 times WITH context application rule
2. Run prompt 5 times WITHOUT context application rule
3. Count: references to customer-specific priorities, generic value statements
4. Target: 3+ customer-specific references per output

#### Task 0.4: Signal/Gap Normalization Test (Day 2-3)

Add structured output format:

```markdown
=== SIGNAL ASSESSMENT FORMAT (MANDATORY) ===

Every analysis MUST include a Signal Assessment section using this exact format:

```
Signal Assessment:
├── [Category 1]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
├── [Category 2]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
└── [Category N]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
```

For Deal/Opportunity analysis, assess these signals:

STAKEHOLDER SIGNALS:
├── Economic Buyer Identified
├── Champion Identified  
├── Decision Maker Engaged
├── Procurement Contact (if deal >$100K)

PROCESS SIGNALS:
├── Next Steps Defined
├── Timeline Validated
├── Competition Status Known
├── Security/Legal Requirements Mapped

MOMENTUM SIGNALS:
├── Recent Activity (within 14 days)
├── Stage Progression (within 30 days)
├── Close Date Stable (no pushes)

This format allows technical users to quickly validate AI reasoning.
```

**Test Protocol:**
1. Run prompt with signal assessment format
2. Evaluate: completeness, accuracy, scanability
3. Get feedback from 2-3 internal users on comprehension speed

#### Phase 0 Success Criteria

| Test | Metric | Target | Fail Threshold |
|------|--------|--------|----------------|
| Evidence Binding | Generic phrases per output | <3 | >7 |
| Evidence Binding | Field citations per output | >8 | <3 |
| Diagnostic Language | Specificity score (1-5) | >4.0 | <3.0 |
| Diagnostic Language | Actionability score (1-5) | >4.0 | <3.0 |
| Context Application | Customer-specific references | >3 | <1 |
| Signal Assessment | User comprehension time | <30 sec | >60 sec |

**Decision Gate:** If 3+ tests hit target, proceed to Phase 1. If <3 tests hit target, revisit approach before building infrastructure.

---

### Phase 1: Codify the Quality Rules (Week 1-2)

**Goal:** Systematize the proven quality improvements into reusable components.

**Prerequisite:** Phase 0 tests show significant quality improvement.

#### Task 1.1: Create Quality Rules Library

Store as Static Resources (markdown files):

```
staticresources/
├── quality_rules/
│   ├── evidence_binding.md
│   ├── diagnostic_language.md
│   ├── context_application.md
│   └── signal_assessment.md
```

Each file contains:
- The instruction block (copy-paste ready)
- Examples of compliant/non-compliant output
- Forbidden phrases list
- Validation criteria

**Implementation:**

```apex
public class QualityRulesLoader {
    
    private static Map<String, String> ruleCache = new Map<String, String>();
    
    /**
     * Load a quality rule from Static Resource
     */
    public static String loadRule(String ruleName) {
        if (ruleCache.containsKey(ruleName)) {
            return ruleCache.get(ruleName);
        }
        
        String resourceName = 'quality_rules_' + ruleName;
        StaticResource sr = [
            SELECT Body 
            FROM StaticResource 
            WHERE Name = :resourceName 
            LIMIT 1
        ];
        
        String content = sr.Body.toString();
        ruleCache.put(ruleName, content);
        return content;
    }
    
    /**
     * Load all quality rules for a prompt type
     */
    public static String loadRulesForPromptType(String promptType) {
        List<String> rules = new List<String>();
        
        // All prompts get evidence binding
        rules.add(loadRule('evidence_binding'));
        
        // Diagnostic prompts get diagnostic language
        if (isDiagnosticPrompt(promptType)) {
            rules.add(loadRule('diagnostic_language'));
        }
        
        // All prompts get signal assessment
        rules.add(loadRule('signal_assessment'));
        
        return String.join(rules, '\n\n');
    }
    
    private static Boolean isDiagnosticPrompt(String promptType) {
        Set<String> diagnosticTypes = new Set<String>{
            'deal_coach', 'opportunity_insights', 'account_health',
            'renewal_risk', 'pipeline_review', 'forecast_analysis'
        };
        return diagnosticTypes.contains(promptType.toLowerCase());
    }
}
```

#### Task 1.2: Create Industry Heuristics Library

**Key Insight:** Heuristics are evaluation criteria, not background descriptions.

Store as Static Resources:

```
staticresources/
├── industry_heuristics/
│   ├── healthcare_payer.md
│   ├── financial_services.md
│   ├── insurance.md
│   └── default.md
```

**Example: healthcare_payer.md**

```markdown
# Healthcare Payer Deal Heuristics

## Evaluation Criteria for Deal Analysis

Apply these heuristics when analyzing healthcare payer opportunities:

### Stage-Specific Risk Patterns

**Early Stage (Discovery/Qualification):**
- Risk: Engaging only with IT; clinical and operations stakeholders often hold veto power
- Risk: Underestimating compliance review timeline (typically 4-8 weeks)
- Check: Is a compliance/security stakeholder identified?

**Mid Stage (Demo/Evaluation):**
- Risk: POC scope creep—payers want to test edge cases for regulatory scenarios
- Risk: Reference requests for similar payer implementations (they will ask)
- Check: Are success criteria documented and approved by Economic Buyer?

**Late Stage (Proposal/Negotiation):**
- Risk: Procurement involvement adds 3-6 weeks minimum
- Risk: Legal review of BAA (Business Associate Agreement) for HIPAA
- Risk: CFO escalation on any discount >15%
- Check: Is procurement contact mapped? Is legal timeline accounted for?

### Deal Size Thresholds

| Amount | Typical Requirements |
|--------|---------------------|
| <$50K | Department approval sufficient |
| $50K-$150K | VP-level + procurement review |
| $150K-$500K | C-level sponsor + security review + BAA |
| >$500K | Board visibility + enterprise procurement + reference calls |

### Stakeholder Patterns

**CFO Priorities:**
- Total cost of ownership (3-5 year view)
- Impact on Medical Loss Ratio (MLR)
- Compliance cost avoidance
- NOT: Feature comparisons

**CIO/CISO Priorities:**
- HIPAA compliance documentation
- Integration with existing EHR/claims systems
- Security assessment (SOC 2, HITRUST)
- Data residency and encryption

**CMO/Clinical Priorities:**
- Member outcome improvements
- Provider network impact
- Quality metrics (HEDIS, Star ratings)

### Red Flags

- Discount request before value demonstration
- Procurement involved before executive alignment
- No clinical stakeholder engagement on member-facing solutions
- Timeline expectation <90 days for enterprise deals
- "We need to see the contract" before technical validation

### Terminology

Use these terms in recommendations:
- "Member" (not Customer or Patient)
- "Plan" (not Product)
- "Provider Network" (critical to value discussions)
- "Medical Loss Ratio" (key financial metric)
- "Value-based care" (industry direction)
```

**Implementation:**

```apex
public class IndustryHeuristicsLoader {
    
    /**
     * Load heuristics for a customer's industry
     */
    public static String loadHeuristics(String industry) {
        // Normalize industry name
        String normalized = normalizeIndustry(industry);
        
        String resourceName = 'industry_heuristics_' + normalized;
        
        try {
            StaticResource sr = [
                SELECT Body 
                FROM StaticResource 
                WHERE Name = :resourceName 
                LIMIT 1
            ];
            return sr.Body.toString();
        } catch (Exception e) {
            // Fall back to default
            return loadDefaultHeuristics();
        }
    }
    
    private static String normalizeIndustry(String industry) {
        if (String.isBlank(industry)) return 'default';
        
        String lower = industry.toLowerCase();
        
        // Map common variations
        if (lower.contains('health') && lower.contains('insur')) {
            return 'healthcare_payer';
        }
        if (lower.contains('health') || lower.contains('medical')) {
            return 'healthcare_payer';
        }
        if (lower.contains('financ') || lower.contains('bank')) {
            return 'financial_services';
        }
        if (lower.contains('insur')) {
            return 'insurance';
        }
        
        return 'default';
    }
    
    private static String loadDefaultHeuristics() {
        StaticResource sr = [
            SELECT Body 
            FROM StaticResource 
            WHERE Name = 'industry_heuristics_default' 
            LIMIT 1
        ];
        return sr.Body.toString();
    }
}
```

#### Task 1.3: Update Stage08 (Prompt Assembly)

Modify the prompt assembly stage to inject quality rules and heuristics:

```apex
public class PromptAssembler {
    
    /**
     * Assemble the final prompt with quality rules and heuristics
     */
    public static String assemblePrompt(
        String basePrompt,
        String promptType,
        String industry,
        String customerContext
    ) {
        List<String> sections = new List<String>();
        
        // Section 1: Base prompt (persona, goal, business context)
        sections.add(basePrompt);
        
        // Section 2: Customer context (if available)
        if (String.isNotBlank(customerContext)) {
            sections.add('=== CUSTOMER STRATEGIC CONTEXT ===\n' + customerContext);
        }
        
        // Section 3: Industry heuristics
        String heuristics = IndustryHeuristicsLoader.loadHeuristics(industry);
        sections.add('=== INDUSTRY EVALUATION CRITERIA ===\n' + heuristics);
        
        // Section 4: Quality rules (always included)
        String qualityRules = QualityRulesLoader.loadRulesForPromptType(promptType);
        sections.add(qualityRules);
        
        // Section 5: Output format and guardrails (from existing implementation)
        sections.add(loadOutputGuardrails());
        
        return String.join(sections, '\n\n');
    }
}
```

#### Task 1.4: Create Prompt Type Configuration

Define which rules apply to which prompt types:

```markdown
# prompt_type_config.md (Static Resource)

## Diagnostic Prompts
These prompts analyze and judge. They receive full quality rules.

- deal_coach
- opportunity_insights
- account_health
- pipeline_review
- forecast_analysis
- renewal_risk
- churn_prediction
- win_loss_analysis

Quality Rules: evidence_binding, diagnostic_language, signal_assessment, context_application

## Summary Prompts  
These prompts summarize and report. They receive evidence binding only.

- meeting_summary
- activity_timeline
- contact_overview
- account_snapshot

Quality Rules: evidence_binding

## Creative Prompts
These prompts generate content. They receive minimal rules.

- email_draft
- proposal_section
- executive_briefing

Quality Rules: context_application (optional)
```

#### Phase 1 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| evidence_binding.md | Evidence citation rule | Static Resource |
| diagnostic_language.md | Diagnostic output requirements | Static Resource |
| signal_assessment.md | Signal/gap format template | Static Resource |
| context_application.md | Customer context usage rule | Static Resource |
| healthcare_payer.md | Healthcare payer heuristics | Static Resource |
| financial_services.md | Financial services heuristics | Static Resource |
| insurance.md | Insurance heuristics | Static Resource |
| default.md | Default heuristics | Static Resource |
| QualityRulesLoader.cls | Apex loader for quality rules | Apex Class |
| IndustryHeuristicsLoader.cls | Apex loader for heuristics | Apex Class |
| PromptAssembler.cls | Updated assembly logic | Apex Class |

#### Phase 1 Success Criteria

- [ ] Quality rules load correctly from Static Resources
- [ ] Industry heuristics map correctly from customer industry
- [ ] Stage08 successfully injects rules into prompt assembly
- [ ] Generated prompts include all required sections
- [ ] Output quality matches Phase 0 test results (no regression)

---

### Phase 2: Pattern Extraction (Week 3-4)

**Goal:** Extract reusable analytical patterns from production prompts.

**Prerequisite:** Phase 1 complete and quality rules working.

**Key Principle:** Start with ONE pattern framework per prompt type. Do not build a pattern explosion.

#### Task 2.1: Audit Production Prompts

Review 15-20 production prompts and extract:

1. **Trigger conditions**: What data signals activate each analysis?
2. **Analysis questions**: What does the prompt ask the LLM to evaluate?
3. **Output sections**: What structure does the output follow?
4. **Forbidden language**: What generic phrases to avoid?

**Extraction Template:**

```markdown
# Pattern: [Pattern Name]

## Metadata
- Pattern ID: [snake_case_id]
- Applies to: [Object types: Opportunity, Account, Case, etc.]
- Prompt types: [deal_coach, account_health, etc.]

## Trigger Conditions
When should this pattern be applied?
- Stage contains: [list]
- Keywords in fields: [list]
- Threshold values: [list]

## Analysis Questions
What must the LLM evaluate?
1. [Question 1]
2. [Question 2]
3. [Question 3]

## Required Evidence
What fields must be cited?
- [Field 1]
- [Field 2]

## Output Section
What section does this pattern produce?
- Section title: [title]
- Format: [bullets/table/narrative]

## Forbidden Phrases
What generic language to avoid?
- [phrase 1]
- [phrase 2]
```

#### Task 2.2: Define Core Patterns (Start with 5-8)

Based on production prompt analysis, likely patterns:

| Pattern ID | Description | Trigger |
|------------|-------------|---------|
| stakeholder_gap | Missing key roles | Contact roles incomplete |
| stalled_deal | No recent progress | Stage unchanged 30+ days |
| discount_pressure | Pricing negotiation risk | Keywords: discount, pricing, budget |
| late_stage_risk | Procurement/legal/security | Stage = Proposal+ |
| expansion_signal | Upsell/cross-sell opportunity | Multiple opps on account |
| champion_weakness | Champion not confirmed | No Champion role OR low engagement |
| timeline_risk | Close date concerns | Close date passed OR pushed multiple times |
| single_threaded | Execution risk | Only 1 contact engaged |

#### Task 2.3: Implement Pattern Matcher

```apex
public class PatternMatcher {
    
    /**
     * Analyze records and return applicable patterns
     */
    public static List<Pattern> matchPatterns(
        SObject record,
        List<SObject> relatedRecords,
        String promptType
    ) {
        List<Pattern> matched = new List<Pattern>();
        
        // Load all patterns for this prompt type
        List<Pattern> candidates = loadPatternsForPromptType(promptType);
        
        for (Pattern p : candidates) {
            if (evaluateTrigger(p, record, relatedRecords)) {
                matched.add(p);
            }
        }
        
        // Sort by priority and limit to top 3-5
        matched.sort();
        return limitPatterns(matched, 5);
    }
    
    private static Boolean evaluateTrigger(
        Pattern p, 
        SObject record, 
        List<SObject> relatedRecords
    ) {
        // Evaluate each trigger condition
        for (TriggerCondition tc : p.triggers) {
            if (!evaluateCondition(tc, record, relatedRecords)) {
                return false;
            }
        }
        return true;
    }
    
    private static Boolean evaluateCondition(
        TriggerCondition tc,
        SObject record,
        List<SObject> relatedRecords
    ) {
        Object fieldValue = record.get(tc.fieldName);
        
        switch on tc.operator {
            when 'contains' {
                return String.valueOf(fieldValue).containsIgnoreCase(tc.value);
            }
            when 'equals' {
                return fieldValue == tc.value;
            }
            when 'greater_than' {
                return (Decimal)fieldValue > Decimal.valueOf(tc.value);
            }
            when 'less_than' {
                return (Decimal)fieldValue < Decimal.valueOf(tc.value);
            }
            when 'is_empty' {
                return fieldValue == null || String.isBlank(String.valueOf(fieldValue));
            }
            when 'days_since_greater_than' {
                Date fieldDate = (Date)fieldValue;
                Integer daysSince = fieldDate.daysBetween(Date.today());
                return daysSince > Integer.valueOf(tc.value);
            }
            when 'role_missing' {
                return !hasContactRole(relatedRecords, tc.value);
            }
            when else {
                return false;
            }
        }
    }
}
```

#### Task 2.4: Integrate Patterns into Assembly

Update PromptAssembler to include matched patterns:

```apex
public static String assemblePrompt(
    String basePrompt,
    String promptType,
    String industry,
    String customerContext,
    SObject record,
    List<SObject> relatedRecords
) {
    List<String> sections = new List<String>();
    
    // ... existing sections ...
    
    // Section 5: Matched patterns
    List<Pattern> patterns = PatternMatcher.matchPatterns(
        record, relatedRecords, promptType
    );
    
    if (!patterns.isEmpty()) {
        sections.add(formatPatternInstructions(patterns));
    }
    
    // ... remaining sections ...
    
    return String.join(sections, '\n\n');
}

private static String formatPatternInstructions(List<Pattern> patterns) {
    List<String> instructions = new List<String>();
    
    instructions.add('=== DETECTED PATTERNS (MUST ANALYZE) ===');
    instructions.add('Based on record data, the following patterns were detected.');
    instructions.add('You MUST include analysis for each pattern in your output.\n');
    
    Integer i = 1;
    for (Pattern p : patterns) {
        instructions.add('PATTERN ' + i + ': ' + p.name);
        instructions.add('Trigger: ' + p.triggerDescription);
        instructions.add('Required Analysis:');
        for (String question : p.analysisQuestions) {
            instructions.add('  - ' + question);
        }
        instructions.add('');
        i++;
    }
    
    return String.join(instructions, '\n');
}
```

#### Phase 2 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| pattern_stakeholder_gap.md | Stakeholder gap pattern | Static Resource |
| pattern_stalled_deal.md | Stalled deal pattern | Static Resource |
| pattern_discount_pressure.md | Discount pressure pattern | Static Resource |
| pattern_late_stage_risk.md | Late stage risk pattern | Static Resource |
| pattern_champion_weakness.md | Champion weakness pattern | Static Resource |
| PatternMatcher.cls | Pattern matching logic | Apex Class |
| Pattern.cls | Pattern data model | Apex Class |
| Updated PromptAssembler.cls | Pattern integration | Apex Class |

#### Phase 2 Success Criteria

- [ ] 5-8 patterns extracted from production prompts
- [ ] Pattern triggers evaluate correctly against test records
- [ ] Pattern matching is deterministic (same input = same patterns)
- [ ] Assembled prompts include pattern-specific instructions
- [ ] Output quality maintains Phase 1 levels with added pattern relevance

---

### Phase 3: Customer Context Systematization (Week 5-6)

**Goal:** Create a repeatable process for capturing and applying customer context.

**Note:** This is lower priority than Phases 0-2 because you already have context injection working (Document 5 shows UHC context). The issue is application, not presence.

#### Task 3.1: Define Customer Context Schema

```markdown
# customer_context_schema.md

## Required Sections

### 1. Company Overview
- Company name
- Primary industry
- Sub-industries/segments
- Company size (employees, revenue if known)

### 2. Regulatory Environment
- Key regulations (HIPAA, SOX, GDPR, etc.)
- Compliance requirements
- Audit considerations

### 3. Terminology
- Customer-specific terms to USE
- Terms to AVOID
- Example: "Member" not "Customer", "Plan" not "Product"

### 4. Stakeholder Priorities
For each common stakeholder type:
- CFO priorities
- CIO/CISO priorities
- Line of business priorities
- Procurement priorities

### 5. Deal Patterns
- Typical deal size thresholds
- Approval requirements by size
- Timeline expectations
- Common blockers

### 6. Red Flags
- Behaviors that indicate risk
- Patterns that suggest deal death

### 7. Strategic Initiatives
- Current company priorities
- Digital transformation focus areas
- Known pain points

## Optional Sections

### 8. Competitive Landscape
- Key competitors
- Differentiation points

### 9. Recent News
- Relevant company announcements
- Leadership changes
- M&A activity
```

#### Task 3.2: Create Context Generation Prompt

For customers where manual workshop isn't practical, use AI to generate initial context:

```markdown
# Context Generation Prompt

You are a business analyst creating a customer intelligence profile.

Research the following company and produce a Customer Context Document following the schema below.

Company: [COMPANY_NAME]
Industry: [INDUSTRY]
Known information: [ANY_KNOWN_DETAILS]

Generate a Customer Context Document with these sections:
1. Company Overview
2. Regulatory Environment
3. Terminology (industry-specific terms to use)
4. Stakeholder Priorities (by role)
5. Deal Patterns (approval thresholds, timelines)
6. Red Flags (risk indicators)
7. Strategic Initiatives

Use publicly available information. If information is not available, state "Unknown - verify with customer" rather than guessing.

Format as markdown with clear headers.
```

#### Task 3.3: Context Loader Implementation

```apex
public class CustomerContextLoader {
    
    /**
     * Load customer context from Salesforce Files or Static Resource
     */
    public static String loadContext(String accountId) {
        // Try account-specific context first
        String accountContext = loadAccountContext(accountId);
        if (String.isNotBlank(accountContext)) {
            return accountContext;
        }
        
        // Fall back to industry context
        Account acc = [SELECT Industry FROM Account WHERE Id = :accountId];
        return loadIndustryContext(acc.Industry);
    }
    
    private static String loadAccountContext(String accountId) {
        // Look for context file attached to account
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :accountId
            AND ContentDocument.Title LIKE '%customer_context%'
            LIMIT 1
        ];
        
        if (links.isEmpty()) {
            return null;
        }
        
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
            AND IsLatest = true
        ];
        
        return cv.VersionData.toString();
    }
    
    private static String loadIndustryContext(String industry) {
        String normalized = IndustryHeuristicsLoader.normalizeIndustry(industry);
        String resourceName = 'customer_context_' + normalized;
        
        try {
            StaticResource sr = [
                SELECT Body 
                FROM StaticResource 
                WHERE Name = :resourceName 
                LIMIT 1
            ];
            return sr.Body.toString();
        } catch (Exception e) {
            return null;
        }
    }
}
```

#### Phase 3 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| customer_context_schema.md | Context document schema | Documentation |
| context_generation_prompt.md | AI prompt for context creation | Static Resource |
| CustomerContextLoader.cls | Context loading logic | Apex Class |
| customer_context_healthcare_payer.md | Default healthcare context | Static Resource |
| customer_context_financial_services.md | Default financial services context | Static Resource |

---

### Phase 4: Quality Measurement (Ongoing)

**Goal:** Create automated quality scoring to track improvement over time.

#### Task 4.1: Define Quality Metrics

```apex
public class OutputQualityScorer {
    
    public class QualityScore {
        public Integer evidenceCitations;      // Count of field citations
        public Integer genericPhrases;         // Count of forbidden phrases
        public Integer customerReferences;     // Count of customer context usage
        public Integer signalAssessments;      // Count of signal evaluations
        public Boolean hasStructuredFormat;    // Signal assessment section present
        public Decimal overallScore;           // Weighted composite
    }
    
    public static QualityScore scoreOutput(String output) {
        QualityScore score = new QualityScore();
        
        // Count evidence citations (pattern: "Evidence: X = Y")
        score.evidenceCitations = countPattern(output, 'Evidence:');
        
        // Count forbidden phrases
        score.genericPhrases = countForbiddenPhrases(output);
        
        // Count customer context references
        score.customerReferences = countCustomerReferences(output);
        
        // Check for signal assessment section
        score.hasStructuredFormat = output.contains('Signal Assessment:');
        
        // Calculate signal assessments
        score.signalAssessments = countPattern(output, '✓|~|✗|?');
        
        // Weighted composite
        score.overallScore = calculateComposite(score);
        
        return score;
    }
    
    private static Integer countForbiddenPhrases(String output) {
        List<String> forbidden = new List<String>{
            'ensure alignment',
            'consider scheduling',
            'maintain momentum',
            'engage stakeholders',
            'reinforce value proposition',
            'address concerns',
            'follow up with',
            'reach out to'
        };
        
        Integer count = 0;
        String lower = output.toLowerCase();
        for (String phrase : forbidden) {
            if (lower.contains(phrase)) {
                count++;
            }
        }
        return count;
    }
    
    private static Decimal calculateComposite(QualityScore score) {
        // Weights
        Decimal evidenceWeight = 0.30;
        Decimal genericPenalty = 0.25;
        Decimal contextWeight = 0.20;
        Decimal structureWeight = 0.15;
        Decimal signalWeight = 0.10;
        
        // Normalize and calculate
        Decimal evidenceScore = Math.min(score.evidenceCitations / 10.0, 1.0);
        Decimal genericScore = Math.max(1.0 - (score.genericPhrases / 5.0), 0.0);
        Decimal contextScore = Math.min(score.customerReferences / 5.0, 1.0);
        Decimal structureScore = score.hasStructuredFormat ? 1.0 : 0.0;
        Decimal signalScore = Math.min(score.signalAssessments / 8.0, 1.0);
        
        return (
            evidenceScore * evidenceWeight +
            genericScore * genericPenalty +
            contextScore * contextWeight +
            structureScore * structureWeight +
            signalScore * signalWeight
        ) * 100;
    }
}
```

#### Task 4.2: Quality Dashboard

Track quality metrics over time:

```apex
public class QualityMetricsTracker {
    
    /**
     * Log quality score for a prompt execution
     */
    public static void logScore(
        String promptId,
        String promptType,
        String output,
        QualityScore score
    ) {
        Prompt_Quality_Log__c log = new Prompt_Quality_Log__c(
            Prompt_Id__c = promptId,
            Prompt_Type__c = promptType,
            Evidence_Citations__c = score.evidenceCitations,
            Generic_Phrases__c = score.genericPhrases,
            Customer_References__c = score.customerReferences,
            Has_Structured_Format__c = score.hasStructuredFormat,
            Overall_Score__c = score.overallScore,
            Execution_Date__c = Datetime.now()
        );
        
        insert log;
    }
    
    /**
     * Get quality trend for a prompt type
     */
    public static List<AggregateResult> getQualityTrend(
        String promptType,
        Integer days
    ) {
        Date startDate = Date.today().addDays(-days);
        
        return [
            SELECT 
                DAY_ONLY(Execution_Date__c) execDate,
                AVG(Overall_Score__c) avgScore,
                AVG(Evidence_Citations__c) avgEvidence,
                AVG(Generic_Phrases__c) avgGeneric
            FROM Prompt_Quality_Log__c
            WHERE Prompt_Type__c = :promptType
            AND Execution_Date__c >= :startDate
            GROUP BY DAY_ONLY(Execution_Date__c)
            ORDER BY DAY_ONLY(Execution_Date__c)
        ];
    }
}
```

---

## Success Metrics

### Quality Metrics (Primary)

| Metric | Baseline | Target | How Measured |
|--------|----------|--------|--------------|
| Evidence citations per output | ~0 | >8 | Automated scoring |
| Generic phrases per output | ~8 | <3 | Automated scoring |
| Customer context references | ~0 | >3 | Automated scoring |
| Signal assessment present | 0% | 100% | Automated scoring |
| Overall quality score | ~40 | >75 | Composite score |
| "Would survive audit" (human eval) | 20% | >80% | Manual review |

### Business Metrics (Secondary)

| Metric | Baseline | Target | How Measured |
|--------|----------|--------|--------------|
| Prompt development time | 4-6 hours | <1 hour | Time tracking |
| POC prompt iterations | 5-10 | <3 | Iteration count |
| Customer satisfaction with output | 3.0/5 | >4.5/5 | Survey |
| Prompts used without modification | 30% | >80% | Usage tracking |
| Deal objections due to prompt quality | Frequent | Rare | Sales feedback |

### Operational Metrics (Tertiary)

| Metric | Baseline | Target | How Measured |
|--------|----------|--------|--------------|
| Pattern reuse rate | N/A | >70% | Pattern usage |
| Context file creation time | N/A | <2 hours | Time tracking |
| Quality rule coverage | 0% | 100% | Config audit |

---

## Risk Mitigation

### Risk 1: Evidence Binding Doesn't Improve Quality

**Mitigation:** Phase 0 tests this assumption before building infrastructure. If test fails, revisit approach.

**Fallback:** Focus on diagnostic language and industry heuristics instead.

### Risk 2: Prompts Become Too Long

**Mitigation:** 
- Monitor prompt token counts
- Implement conditional rule injection (only inject relevant rules)
- Create "lite" versions of rules for smaller models

### Risk 3: Industry Heuristics Are Wrong

**Mitigation:**
- Start with minimal heuristics (10-15 bullets)
- Validate with 2-3 customers before shipping
- Make heuristics customer-editable (Salesforce Files)

### Risk 4: Pattern Matching Creates False Positives

**Mitigation:**
- Require multiple trigger conditions (AND logic)
- Limit patterns to 3-5 per output
- Add confidence thresholds
- Allow customer to disable specific patterns

### Risk 5: Quality Scoring Is Gaming-Prone

**Mitigation:**
- Include human evaluation in quality measurement
- Score composite of multiple factors (not just evidence count)
- Regular calibration of scoring weights

---

## Appendix A: Forbidden Phrases List

These phrases indicate generic, non-diagnostic output:

```
ensure alignment
consider scheduling
maintain momentum
engage stakeholders
reinforce value proposition
address concerns
follow up with
reach out to
touch base with
circle back on
leverage the relationship
drive value
optimize the process
align on expectations
facilitate discussions
enhance collaboration
streamline communication
foster engagement
capitalize on opportunities
mitigate risks (without specifics)
stay connected
keep the momentum going
build rapport
strengthen the partnership
explore possibilities
identify synergies
```

---

## Appendix B: Example Quality Rules File

**File: staticresources/quality_rules_evidence_binding.md**

```markdown
=== EVIDENCE BINDING RULE (MANDATORY) ===

Every insight, risk, or recommendation MUST cite specific evidence from this record.

## Citation Format

Standard format: "[Insight] (Evidence: [Field] = [Value])"

Alternative formats (all acceptable):
- "Based on [Field] showing [Value], ..."
- "[Insight]. This is indicated by [Field] = [Value]."
- "Record shows [Field] = [Value], which suggests [Insight]."

## Compliant Examples

✓ "CFO engagement is your critical path this week (Evidence: Task.Subject = 'CFO Meeting', ActivityDate = 01/27/2026)"

✓ "No champion identified—critical gap for this deal size (Evidence: OpportunityContactRole missing 'Champion' role)"

✓ "Deal momentum is single-threaded. Based on HasOpenActivity = 1 on a $150K deal, recommend expanding activity coverage."

✓ "Close date may be optimistic. Record shows CloseDate = 12/31/2025 but StageName = 'Proposal/Price Quote'. For deals at this stage in this industry, typical close cycle is 4-6 months."

## Non-Compliant Examples (FORBIDDEN)

✗ "Ensure alignment with stakeholders" 
   Problem: No evidence cited, no specific stakeholders named

✗ "Consider scheduling follow-ups to re-engage"
   Problem: No evidence of disengagement cited

✗ "Maintain momentum with key contacts"
   Problem: Generic advice, no field citations

✗ "The deal shows good progress"
   Problem: No specific evidence of progress

## Missing Data Handling

If data is missing that would be needed for analysis, state explicitly:

"MISSING: [Field Name] - [Why this matters] - Recommend: [Action to capture]"

Example:
"MISSING: Champion role not mapped in OpportunityContactRole. Without an internal champion, healthcare payer deals at $150K+ have 40% lower close rates. Recommend: Identify and map champion before CFO meeting."

## Enforcement

Any insight, risk, or recommendation without evidence citation is a FAILURE.
The output will be evaluated for evidence density. Target: >8 citations per analysis.
```

---

## Appendix C: Implementation Checklist

### Phase 0 (Days 1-3)
- [ ] Create evidence binding test instruction block
- [ ] Create diagnostic language test instruction block
- [ ] Create context application test instruction block
- [ ] Create signal assessment test format
- [ ] Run A/B tests (5 iterations each)
- [ ] Document results and decide go/no-go

### Phase 1 (Week 1-2)
- [ ] Create quality_rules_evidence_binding.md
- [ ] Create quality_rules_diagnostic_language.md
- [ ] Create quality_rules_signal_assessment.md
- [ ] Create quality_rules_context_application.md
- [ ] Create industry_heuristics_healthcare_payer.md
- [ ] Create industry_heuristics_financial_services.md
- [ ] Create industry_heuristics_insurance.md
- [ ] Create industry_heuristics_default.md
- [ ] Implement QualityRulesLoader.cls
- [ ] Implement IndustryHeuristicsLoader.cls
- [ ] Update PromptAssembler.cls
- [ ] Test end-to-end with Opportunity Insights prompt
- [ ] Validate no quality regression

### Phase 2 (Week 3-4)
- [ ] Audit 15-20 production prompts
- [ ] Extract 5-8 reusable patterns
- [ ] Create pattern markdown files
- [ ] Implement Pattern.cls data model
- [ ] Implement PatternMatcher.cls
- [ ] Update PromptAssembler.cls for patterns
- [ ] Test pattern matching accuracy
- [ ] Validate pattern-enhanced outputs

### Phase 3 (Week 5-6)
- [ ] Define customer context schema
- [ ] Create context generation prompt
- [ ] Implement CustomerContextLoader.cls
- [ ] Create default industry context files
- [ ] Test context loading from Salesforce Files
- [ ] Document context creation process

### Phase 4 (Ongoing)
- [ ] Create Prompt_Quality_Log__c custom object
- [ ] Implement OutputQualityScorer.cls
- [ ] Implement QualityMetricsTracker.cls
- [ ] Create quality dashboard report
- [ ] Establish baseline metrics
- [ ] Set up weekly quality review process

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-21 | Claude | Initial PRD synthesizing quality improvement strategy |

---

*This PRD is part of the `feature/prompt-quality-improvements` branch.*
```

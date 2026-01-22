# Evidence Binding Rules (v2)

**Version**: 2.0  
**Purpose**: Define how to cite data sources without overwhelming the user  
**Key Change**: Insight-first approach replaces evidence-first  

---

## Core Principle

> **Every claim must be traceable. No claim should lead with its source.**
>
> Evidence binding ensures analytical integrity. But users care about 
> the INSIGHT, not the audit trail. Make evidence available, not prominent.

---

## CRITICAL: Use Actual Names, Dates, and Specific Details

> **Generic language kills quality. Specificity creates trust and actionability.**

### People Specificity

**ALWAYS use actual names from Salesforce data:**

```
✅ "Schedule follow-up call with Sarah Johnson (CFO) by Friday"
❌ "Schedule follow-up call with the CFO soon"

✅ "Lisa Martinez (Champion) has not engaged in 14 days"
❌ "Your champion hasn't engaged recently"

✅ "Robert Taylor (VP Operations) requested technical validation"
❌ "The decision maker needs more information"

✅ "Contact James Wilson and Maria Garcia before next week"
❌ "Reach out to key stakeholders"
```

**FORBIDDEN - Never use these generic terms:**
- ❌ "the CFO" → ✅ "Sarah Johnson (CFO)"
- ❌ "your champion" → ✅ "Lisa Martinez (Champion)"
- ❌ "the decision maker" → ✅ "Robert Taylor (VP Operations)"
- ❌ "key stakeholders" → ✅ "Sarah Johnson and Lisa Martinez"
- ❌ "the buyer" → ✅ "James Wilson (Procurement Director)"
- ❌ "the team" → ✅ "Sarah Johnson, Lisa Martinez, and Robert Taylor"

**How to extract names:**
```
Contact Role: [ContactName] ([ContactRole]) 
Account Team: [TeamMemberName]
Owner: [OwnerName]

Use merge field syntax: {{{ }}} when implementing
```

---

### Date & Timeline Specificity

**ALWAYS use specific dates and bounded timeframes:**

```
✅ "by Friday, January 24, 2026"
❌ "soon"

✅ "within 48 hours (before CFO meeting on Jan 26)"
❌ "as soon as possible"

✅ "Task 'Send ROI Analysis' is 7 days overdue (due Jan 15, today is Jan 22)"
❌ "ROI task is overdue"

✅ "No activity in 14 days (last contact: Jan 8)"
❌ "Deal has been quiet recently"

✅ "Meeting scheduled for Tuesday, Jan 28 at 2pm"
❌ "Meeting coming up next week"
```

**FORBIDDEN - Never use these vague terms:**
- ❌ "soon" → ✅ "by Friday, January 24"
- ❌ "when possible" → ✅ "within 48 hours"
- ❌ "recently" → ✅ "in the last 14 days"
- ❌ "coming up" → ✅ "scheduled for January 28"
- ❌ "overdue" → ✅ "7 days overdue (due Jan 15)"

---

### Action Specificity

**ALWAYS provide clear, bounded actions with who/what/when:**

```
✅ "Schedule discovery call with Sarah Johnson (CFO) by Friday to discuss ROI requirements"
❌ "Follow up with stakeholders about next steps"

✅ "Prepare technical validation deck and send to Robert Taylor by January 24"
❌ "Share technical information when ready"

✅ "Complete MEDDIC scorecard with Lisa Martinez before executive review on Jan 28"
❌ "Update your MEDDIC assessment"

✅ "Confirm budget approval process with James Wilson (Procurement) within 48 hours"
❌ "Check on budget status"
```

**FORBIDDEN - Never use these generic actions:**
- ❌ "follow up with stakeholders" → ✅ "call Sarah Johnson (CFO)"
- ❌ "consider reaching out" → ✅ "Schedule meeting by Friday"
- ❌ "address concerns" → ✅ "Resolve pricing objection in proposal v2"
- ❌ "maintain momentum" → ✅ "Schedule weekly check-ins with Lisa Martinez"
- ❌ "ensure alignment" → ✅ "Get sign-off from Robert Taylor on technical specs"

---

### System & Tool Specificity

**Reference actual systems and documents when available:**

```
✅ "Competitor comparison vs. Aetna in ROI calculator (Quip doc)"
❌ "Competitive analysis document"

✅ "Salesforce Health Cloud implementation timeline"
❌ "CRM deployment schedule"

✅ "Q4 benefits enrollment data from Workday"
❌ "Historical enrollment information"

✅ "Send proposal v3 (revised pricing on slide 12)"
❌ "Share updated proposal"
```

---

## The Insight-First Pattern

### Format Hierarchy

Use the highest-appropriate level. Reserve explicit citations for detailed sections.

---

### Level 1: Embedded Data (Use 80% of the Time)

Data point woven naturally into the insight. No explicit citation.

**Pattern:**
```
[Insight with data point naturally embedded]
```

**Examples:**
```
✅ "This $1.5M deal needs executive sponsor engagement before close."
✅ "With only 67 days to close and no discovery meeting scheduled..."
✅ "The 4 engaged stakeholders don't include anyone with budget authority."
✅ "Stage has been stalled for 45 days—well beyond your 21-day benchmark."
```

**When to use:**
- Executive summary (Zone 3)
- Key insights in stat cards (Zone 2)
- Action card descriptions (Zone 4)
- Any above-the-fold content

**What makes it work:**
- The number IS the insight ("$1.5M", "67 days", "4 stakeholders")
- No need to say where it came from
- User trusts you got it from Salesforce
- Source available in Zone 6 if they want to verify

---

### Level 2: Parenthetical Source (Use 15% of the Time)

Insight first, with brief source reference in parentheses.

**Pattern:**
```
[Insight statement]. (Source: FieldName)
```

**Examples:**
```
✅ "No executive sponsor identified. (Source: Contact Roles)"
✅ "Budget not yet confirmed. (Source: Opportunity custom field)"
✅ "Deal velocity below average. (Benchmark: 90-day Enterprise cycle)"
```

**When to use:**
- When the data source adds credibility to a surprising claim
- When there might be ambiguity about where info came from
- When referencing a custom field or non-obvious source
- Risk assessment details (Zone 5)

**What makes it work:**
- Insight still leads
- Source is secondary, not prominent
- Parenthetical is naturally de-emphasized
- User can ignore if not interested

---

### Level 3: Inline Citation (Use 5% of the Time)

Explicit "based on" statement after insight, for detailed analysis only.

**Pattern:**
```
[Insight statement]
→ Based on: FieldName = Value
```

**Examples:**
```
✅ "Deal timeline is at significant risk."
   → Based on: Stage Age = 45 days (benchmark: 21 days), Close Date = March 28

✅ "Champion engagement has dropped off."
   → Based on: Last Contact = 23 days ago, Previous average = 7 days
```

**When to use:**
- Detailed analysis sections (Zone 5) only
- When showing a calculation or comparison
- When the specific value matters for understanding
- When contrasting actual vs. expected

**What makes it work:**
- Appears in "drill-down" sections, not primary view
- User has already opted-in to detail by scrolling
- Shows the work without cluttering the main message

---

### Level 4: Collapsible Data Sources (For Audit Trail)

Full field citations available on demand, collapsed by default.

**Pattern:**
```html
<details>
  <summary>📊 Data Sources</summary>
  <ul>
    <li>Deal Size: Opportunity.Amount = $1,500,000</li>
    <li>Close Date: Opportunity.CloseDate = 2026-03-28</li>
    ...
  </ul>
</details>
```

**When to use:**
- End of every generated report (Zone 6)
- Always collapsed by default
- User expands only if they want to verify

**What makes it work:**
- Evidence is available for audit/compliance
- But it's not competing for attention
- Keeps the main output scannable
- Satisfies "show your work" requirement without clutter

---

## What NOT to Do

### ❌ Anti-Pattern 1: Evidence-First

```
WRONG:
"Evidence: Opportunity.Amount = $1,500,000
 Evidence: Opportunity.StageName = Needs Analysis
 Evidence: Opportunity.Probability = 20%
 
 Based on this data, the deal size is significant and may require 
 executive involvement."
```

**Problems:**
- User has to wade through data to find the insight
- Field API names are technical jargon
- "Based on this data" buries the lead
- Feels like reading a database query result

**Fix:**
```
CORRECT:
"This $1.5M deal requires executive sponsor engagement—it's still 
in early qualification with only 20% probability."
```

---

### ❌ Anti-Pattern 2: Over-Citation

```
WRONG:
"The opportunity name is 'McDonald's Q1 Expansion' (Evidence: 
Opportunity.Name). The account is McDonald's Corporation (Evidence: 
Account.Name). The amount is $1,500,000 (Evidence: Opportunity.Amount). 
The close date is March 28, 2026 (Evidence: Opportunity.CloseDate)."
```

**Problems:**
- Unreadable
- Treats user like an auditor, not a decision-maker
- Every sentence interrupted by citation
- Zero synthesis

**Fix:**
```
CORRECT:
"$1.5M McDonald's deal targeting Q1 close. Currently in early stage 
with 67 days remaining."
```

---

### ❌ Anti-Pattern 3: Citation Without Insight

```
WRONG:
"Evidence: Task.Subject = 'Send ROI Analysis'
 Evidence: Task.Status = 'Open'
 Evidence: Task.ActivityDate = '2026-01-15'"
```

**Problems:**
- So what? What does this mean?
- User has to figure out why this matters
- No actionable conclusion

**Fix:**
```
CORRECT:
"ROI Analysis is overdue (was due Jan 15)—this is blocking CFO 
budget approval."
```

---

### ❌ Anti-Pattern 4: Generic Claims Without Data

```
WRONG:
"This deal is at risk and needs immediate attention."
```

**Problems:**
- Vague
- No specifics user can act on
- Why is it at risk? What kind of attention?

**Fix:**
```
CORRECT:
"This deal is at risk: 67 days to close but still in early stage, 
with no executive sponsor and an overdue ROI analysis."
```

---

## Transformation Examples

### Opportunity Analysis

| Evidence-First (Avoid) | Insight-First (Use) |
|------------------------|---------------------|
| "Amount = $1.5M. This is a large deal." | "Large deal ($1.5M) requires executive sponsor." |
| "Probability = 20%." | "Low win confidence (20%)—qualification gaps remain." |
| "CloseDate = 2026-03-28. There are 67 days remaining." | "Only 67 days to close from early stage." |
| "StageName = Needs Analysis for 45 days." | "Stalled 45 days in qualification—exceeds 21-day benchmark." |
| "Contact count = 4." | "4 stakeholders engaged but no CFO access." |

### Risk Assessment

| Evidence-First (Avoid) | Insight-First (Use) |
|------------------------|---------------------|
| "Evidence: No Contact with Role = 'Economic Buyer'" | "No economic buyer identified—budget approval at risk." |
| "Evidence: Task overdue by 7 days" | "ROI Analysis overdue 7 days—blocking CFO meeting." |
| "Evidence: LastActivityDate > 14 days" | "No activity in 14 days—engagement may be stalling." |
| "Evidence: Competitor field is not empty" | "Active competitive threat: [Competitor] also engaged." |

### Timeline Analysis

| Evidence-First (Avoid) | Insight-First (Use) |
|------------------------|---------------------|
| "Stage Age = 45 days. Benchmark = 21 days." | "2x longer than typical at this stage—velocity concern." |
| "Close Date moved 3 times." | "Close date extended 3 times—credibility at risk." |
| "Created Date = 2025-10-15, Today = 2026-01-22." | "99-day-old opportunity still in early qualification." |

---

## Context-Specific Guidelines

### Above-the-Fold Content (Zones 1-4)

**Rule:** Use Level 1 (embedded) or Level 2 (parenthetical) only.

```
✅ ALLOWED:
"$1.5M deal at risk: 67 days to close but early stage."
"No executive sponsor identified. (Source: Contact Roles)"

❌ NOT ALLOWED:
"Evidence: Amount = $1,500,000..."
"Based on: Opportunity.StageName = 'Needs Analysis'..."
```

### Detailed Analysis (Zone 5)

**Rule:** Level 1, 2, or 3 are all appropriate.

```
✅ ALLOWED:
"Deal velocity has slowed significantly."
→ Based on: Stage Age = 45 days (benchmark: 21 days)
```

### Data Sources Section (Zone 6)

**Rule:** Level 4—complete field listing, always collapsed.

```
✅ REQUIRED:
<details>
  <summary>Data Sources</summary>
  Complete field list with values
</details>
```

---

## Implementation for Prompts

### Injection Text for Stage08

Add this to the prompt assembly:

```
=== EVIDENCE BINDING RULES ===

Every analytical claim must be traceable to Salesforce data, but 
INSIGHT LEADS, EVIDENCE SUPPORTS.

CRITICAL - USE ACTUAL NAMES, NOT GENERIC TERMS:
- ✅ "Sarah Johnson (CFO)" not "the CFO"
- ✅ "by Friday, Jan 24" not "soon"
- ✅ "Schedule call with Lisa Martinez" not "follow up with champion"
- ✅ "7 days overdue (due Jan 15)" not "overdue task"

Extract names using merge fields from the Data Context Mapping provided.

FORBIDDEN PHRASES - Never use:
- "the CFO" / "your champion" / "key stakeholders" / "the decision maker"
- "soon" / "when possible" / "recently" / "coming up"
- "follow up with stakeholders" / "consider reaching out" / "ensure alignment"
- "address concerns" / "maintain momentum"

FORMAT REQUIREMENTS:
1. ABOVE THE FOLD: Embed data naturally into insights
   - Good: "This $1.5M deal needs Sarah Johnson (CFO) engagement"
   - Bad: "Evidence: Amount = $1,500,000. This is significant."

2. DETAILED ANALYSIS: Use inline citations sparingly
   - Good: "Stage stalled 45 days (benchmark: 21 days)"
   - Bad: "Evidence: Stage Age = 45. Evidence: Benchmark = 21."

3. END OF REPORT: Include collapsible data sources section
   - List all fields used
   - Collapsed by default
   - For verification, not primary reading

NEVER:
- Start any sentence with "Evidence:"
- List field values without an insight
- Interrupt flow with multiple citations
- Use API field names in visible text (translate to plain language)
- Use generic terms when actual names are available

ALWAYS:
- Lead with the "so what"
- Use actual names from {{{Contact.Name}}}
- Use specific dates and bounded timeframes
- Weave numbers into natural sentences
- Provide specific, actionable recommendations
- Make data sources available but not prominent
```

### Quality Check Prompt for Stage12

Add this dimension:

```
EVIDENCE APPROPRIATENESS (15%):
Does the output properly balance insight and evidence?

Score 1-3: Evidence-first approach, technical jargon, over-citation
Score 4-6: Mixed approach, some buried insights, inconsistent
Score 7-10: Insight-first, natural data embedding, clean citations
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    EVIDENCE BINDING v2                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  THE RULE                                                       │
│  ────────                                                       │
│  Every claim must be traceable.                                │
│  No claim should lead with its source.                         │
│                                                                 │
│  FORMAT LEVELS (by usage frequency)                            │
│  ──────────────────────────────────                            │
│  Level 1 (80%): Embedded data                                  │
│    "This $1.5M deal needs..."                                  │
│                                                                 │
│  Level 2 (15%): Parenthetical source                           │
│    "No sponsor identified. (Source: Contact Roles)"            │
│                                                                 │
│  Level 3 (5%): Inline citation                                 │
│    "Stage stalled" → Based on: Stage Age = 45 days             │
│                                                                 │
│  Level 4 (always): Collapsible data sources                    │
│    [Expand to view all field citations]                        │
│                                                                 │
│  NEVER DO                                                      │
│  ────────                                                       │
│  • "Evidence: FieldName = Value"                               │
│  • Start with data, end with insight                           │
│  • Use API names in user-facing text                           │
│  • Cite without synthesizing                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-20 | Initial evidence binding rules |
| 2.0 | 2026-01-22 | Revised to insight-first based on visual review feedback |

---

**File Location:** `staticresources/evidence_binding.md`  
**Loaded By:** `ConfigurationLoader.loadStaticResource('evidence_binding')`  
**Injected At:** Stage08 (Prompt Assembly)

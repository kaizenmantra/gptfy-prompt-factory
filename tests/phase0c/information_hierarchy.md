# Information Hierarchy Rules

**Version**: 1.0  
**Purpose**: Define content prioritization and layout rules for AI-generated outputs  
**Usage**: Include in prompt assembly to ensure important content surfaces appropriately  

---

## Core Principle

> **Lead with insight, support with evidence. Surface urgency, bury detail.**

Users have limited time and attention. The most actionable, urgent, or important content must appear first. Evidence and supporting detail should be available but not prominent.

---

## Section 1: Above-the-Fold Priorities

The first visible screen (~400px height, ~10 seconds of attention) must contain:

### Priority 1: Immediate Attention Required (0-100px)

**What belongs here:**
- Overdue tasks or missed deadlines
- Critical blockers or deal-killing risks
- Urgent actions required within 7 days
- System alerts or warnings

**UI Component:** Alert Boxes (Critical/Warning)

**Format:**
```
⚠️ CRITICAL: [What's wrong] — [What to do] — [By when]
⏰ WARNING: [Risk description] — [Recommended action]
```

**Example:**
```
⚠️ CRITICAL: ROI Analysis overdue by 7 days — Complete and send to CFO — Today
⏰ WARNING: Close date in 67 days but deal still in early stage — Extend date or accelerate
```

**Rules:**
- Maximum 2-3 alerts above the fold
- If no urgent items, skip this section entirely (don't force it)
- Red for critical (action required now), Orange for warning (action required soon)

---

### Priority 2: Key Metrics Summary (100-200px)

**What belongs here:**
- 4-6 most important numbers that define the situation
- Health indicators or scores
- Progress metrics
- Key dates or timeframes

**UI Component:** Stat Cards (horizontal strip)

**Format:**
```
[VALUE]          [VALUE]          [VALUE]          [VALUE]
[Label]          [Label]          [Label]          [Label]
```

**Example:**
```
$1.5M            67 days          4                20%
Deal Size        To Close         Stakeholders     Probability
```

**Rules:**
- 4-6 cards maximum (more causes cognitive overload)
- Use color coding: Red (<30%), Orange (30-60%), Green (>60%) for percentage/score metrics
- Numbers should be scannable in 2 seconds
- Labels should be 1-2 words maximum

**Metric Selection Priority:**
1. Financial impact (Amount, ARR, Value)
2. Time urgency (Days to close, Days overdue, Days in stage)
3. Engagement (Stakeholder count, Activity count, Response rate)
4. Health/Progress (Score, Probability, Completion %)

---

### Priority 3: Executive Summary (200-350px)

**What belongs here:**
- 2-3 sentence synthesis of the situation
- The "so what" — why this matters
- Primary recommendation or next step
- Bottom-line assessment

**UI Component:** Summary Card (light background, emphasis styling)

**Format:**
```
BOTTOM LINE
[One sentence: Current state + primary risk/opportunity]
[One sentence: Recommended action + expected outcome]
[Optional: Key dependency or assumption]
```

**Example:**
```
BOTTOM LINE
This $1.5M deal is at risk of slipping — close date is 67 days away but 
qualification is incomplete and no executive sponsor identified.

Recommended: Schedule discovery call with CFO this week to validate budget 
and timeline, or extend close date to Q3.
```

**Rules:**
- Maximum 3 sentences
- Must include a clear recommendation (not just observation)
- Avoid hedging language ("might", "could", "possibly")
- Write for someone who will ONLY read this section

---

### Priority 4: Section Headers for Below-Fold Content (350-400px)

**What belongs here:**
- Visual indication that more detail exists below
- Clickable/scannable section titles
- Count indicators (e.g., "3 Risks", "5 Actions")

**Format:**
```
▼ Risk Assessment (3 items)
▼ Recommended Actions (5 items)  
▼ Stakeholder Analysis (4 contacts)
▼ Timeline & Activities
```

**Rules:**
- Show counts to set expectations
- Use consistent iconography
- Make it clear these are expandable/scrollable

---

## Section 2: Below-the-Fold Content

Content below 400px is "opt-in" — user chooses to scroll for detail.

### Priority 5: Detailed Analysis Sections

**What belongs here:**
- Full risk breakdown with context and mitigation
- Complete action list with owners and dates
- Stakeholder details and engagement history
- Timeline with all activities

**UI Components:** 
- Cards with headers for each analysis type
- Tables for structured data (contacts, activities)
- Expandable sections for lengthy content

**Format for Risk Analysis:**
```
RISK: [Risk Title]
Severity: [Critical/High/Medium/Low]
[2-3 sentence explanation of why this is a risk]
Impact: [What happens if not addressed]
Mitigation: [Specific recommended action]
```

**Format for Action Items:**
```
☐ [Action description]
   Owner: [Name/Role]  |  Due: [Date]  |  Priority: [High/Medium/Low]
```

**Format for Stakeholder Analysis:**
```
[Name] — [Title]
Role: [Champion/Decision Maker/Influencer/Blocker]
Engagement: [Strong/Moderate/Weak/None]
Last Contact: [Date]
Notes: [Key insight about this person]
```

**Rules:**
- Group related content together
- Use consistent structure within each section
- Include "why it matters" not just "what it is"
- Every risk should have a mitigation
- Every action should have an owner and date

---

### Priority 6: Supporting Evidence & Data Sources

**What belongs here:**
- Field-level citations for key claims
- Data freshness indicators
- Methodology notes
- Links to source records

**UI Component:** Collapsed/expandable detail section

**Format:**
```
[Expandable: Data Sources]
  • Deal size based on: Opportunity.Amount ($1,500,000)
  • Probability from: Opportunity.Probability (20%)
  • Stakeholder count: 4 Contact records linked to Account
  • Activity analysis: 12 Tasks, 5 Events in last 90 days
  • Data as of: January 22, 2026
```

**Rules:**
- Collapsed by default — user expands if they want to verify
- Never lead with evidence (insight first)
- Group by analysis section if multiple sources
- Include data freshness date

---

## Section 3: The Insight-First Principle

### What NOT to Do (Evidence-First)

```
❌ BAD: Evidence-leads approach

"Evidence: Opportunity.Amount = $1,500,000
 Evidence: Opportunity.CloseDate = 2026-03-15
 Evidence: Opportunity.StageName = Needs Analysis
 Evidence: Opportunity.Probability = 20%
 
 Based on this data, the deal may have timeline risk because the 
 close date is only 67 days away but the opportunity is still in 
 an early stage with low probability."
```

**Problems:**
- User has to read through data to get to insight
- Field names are technical jargon
- Evidence overwhelms the message
- Insight is buried at the end

### What TO Do (Insight-First)

```
✅ GOOD: Insight-leads approach

"Timeline Risk: This deal is unlikely to close by March 15.

 With 67 days to close, the opportunity would need to advance 
 through 4 stages averaging 17 days each. Current stage (Needs 
 Analysis) typically takes 30+ days alone.
 
 Recommendation: Extend close date to Q3, or identify specific 
 actions to accelerate qualification this week.
 
 [View data sources ▼]"
```

**Benefits:**
- Insight is immediately clear
- Reasoning is provided (not just data)
- Recommendation is actionable
- Evidence available but not intrusive

### Transformation Rules

| Evidence-First (Avoid) | Insight-First (Use) |
|------------------------|---------------------|
| "Amount = $1.5M. This is a large deal." | "Large deal ($1.5M) requires executive sponsor." |
| "Probability = 20%. This is low." | "Low win confidence (20%) — qualification gaps exist." |
| "4 contacts found. Stakeholder coverage exists." | "4 stakeholders engaged, but no CFO access yet." |
| "Task overdue by 7 days." | "Overdue: ROI analysis blocking budget approval." |
| "Stage = Needs Analysis for 45 days." | "Stalled: 45 days without stage progression." |

### Synthesis Over Enumeration

```
❌ AVOID: List of facts
"The opportunity amount is $1,500,000.
 The account is McDonald's Corporation.
 There are 4 contacts associated.
 The close date is March 15, 2026.
 The current stage is Needs Analysis.
 The probability is 20%."

✅ USE: Synthesized insight
"$1.5M McDonald's deal with 4 engaged stakeholders, targeting 
 March close. Currently in early qualification with significant 
 timeline risk — 67 days to close from Needs Analysis stage."
```

---

## Section 4: Content Type Placement Rules

### Risk-Related Content

| Risk Level | Placement | UI Component |
|------------|-----------|--------------|
| Critical (deal-killer) | Above fold, Priority 1 | Alert Box (red) |
| High (needs attention) | Above fold, Priority 1-3 | Alert Box (orange) or Summary mention |
| Medium (monitor) | Below fold, detailed section | Risk Card |
| Low (noted) | Below fold or omit | Brief mention or exclude |

### Action-Related Content

| Urgency | Placement | UI Component |
|---------|-----------|--------------|
| Overdue | Above fold, Priority 1 | Alert Box (red) |
| Due within 7 days | Above fold, Priority 1 or Summary | Alert Box (orange) or Summary mention |
| Due within 30 days | Below fold, action section | Action Card |
| Future/planned | Below fold, action section | Action list item |

### Metrics/Data Content

| Importance | Placement | UI Component |
|------------|-----------|--------------|
| Defining metrics (4-6) | Above fold, Priority 2 | Stat Cards |
| Supporting metrics | Below fold, relevant section | Inline or small stat |
| Detail/breakdown | Below fold, expandable | Table or list |
| Raw field values | Hidden, expandable | Data sources section |

### Stakeholder Content

| Relevance | Placement | UI Component |
|-----------|-----------|--------------|
| Key blocker/champion | Above fold mention or Priority 3 | Summary mention |
| Decision makers | Below fold, stakeholder section | Stakeholder Card |
| All contacts | Below fold, expandable | Table |

---

## Section 5: Scannability Checklist

Before finalizing output, verify:

### Above-Fold Test (10-Second Scan)
- [ ] Can user identify the #1 issue/action in 3 seconds?
- [ ] Are key numbers visible without scrolling?
- [ ] Is there a clear "bottom line" statement?
- [ ] Is urgent content visually prominent (color, position)?

### Structure Test
- [ ] Does content flow from urgent → important → detail?
- [ ] Are sections clearly delineated with headers?
- [ ] Is related content grouped together?
- [ ] Are counts provided for detailed sections?

### Insight Test
- [ ] Does every section lead with "so what" not data?
- [ ] Are recommendations specific and actionable?
- [ ] Is evidence supporting, not leading?
- [ ] Would a busy executive understand this in 30 seconds?

### Visual Test
- [ ] Is color used meaningfully (not decoratively)?
- [ ] Are the most important elements visually prominent?
- [ ] Is there appropriate white space (not too much, not too little)?
- [ ] Do UI components match content type?

---

## Section 6: Common Anti-Patterns to Avoid

### Anti-Pattern 1: "Data Dump"
```
❌ All fields listed with values, no synthesis
```
**Fix:** Synthesize 3-5 fields into one insight sentence

### Anti-Pattern 2: "Buried Lead"
```
❌ Most important insight appears after 3 paragraphs
```
**Fix:** Move critical insight to first sentence/section

### Anti-Pattern 3: "Equal Weight"
```
❌ All risks shown with same visual treatment
```
**Fix:** Use color/size hierarchy — critical risks more prominent

### Anti-Pattern 4: "Evidence Parade"
```
❌ "Evidence: X. Evidence: Y. Evidence: Z. Therefore..."
```
**Fix:** State conclusion first, evidence as support/expandable

### Anti-Pattern 5: "Missing So-What"
```
❌ "The deal is in Needs Analysis stage." (So what?)
```
**Fix:** "Deal stuck in early stage — qualification activities needed."

### Anti-Pattern 6: "Action-Free Zone"
```
❌ Analysis with no recommended next steps
```
**Fix:** Every risk/issue must have a recommended mitigation/action

### Anti-Pattern 7: "White Space Waste"
```
❌ Large headers and spacing for basic info, cramped for insights
```
**Fix:** Compress routine data, expand space for insights/actions

---

## Section 7: Template Structure

### Recommended HTML Structure

```html
<!-- ABOVE THE FOLD -->
<div class="above-fold">
  
  <!-- Priority 1: Alerts (if urgent items exist) -->
  <div class="alert-strip">
    <!-- Only render if there are urgent items -->
  </div>
  
  <!-- Priority 2: Key Metrics -->
  <div class="stat-strip">
    <!-- 4-6 stat cards -->
  </div>
  
  <!-- Priority 3: Executive Summary -->
  <div class="executive-summary">
    <h3>Bottom Line</h3>
    <!-- 2-3 sentences with recommendation -->
  </div>
  
</div>

<!-- BELOW THE FOLD -->
<div class="detailed-analysis">
  
  <!-- Priority 5: Analysis Sections -->
  <section class="analysis-section">
    <h3>Risk Assessment</h3>
    <!-- Risk cards -->
  </section>
  
  <section class="analysis-section">
    <h3>Recommended Actions</h3>
    <!-- Action cards -->
  </section>
  
  <section class="analysis-section">
    <h3>Stakeholder Analysis</h3>
    <!-- Stakeholder cards or table -->
  </section>
  
  <!-- Priority 6: Supporting Data -->
  <details class="data-sources">
    <summary>Data Sources</summary>
    <!-- Field citations -->
  </details>
  
</div>
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│                    INFORMATION HIERARCHY                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ABOVE THE FOLD (First 400px)                                   │
│  ─────────────────────────────                                  │
│  1. ALERTS      → Overdue/Critical items (if any)              │
│  2. STATS       → 4-6 key metrics in cards                     │
│  3. SUMMARY     → 2-3 sentence bottom line + recommendation    │
│                                                                 │
│  BELOW THE FOLD (Scroll for detail)                            │
│  ──────────────────────────────────                            │
│  4. ANALYSIS    → Detailed risks, actions, stakeholders        │
│  5. EVIDENCE    → Data sources (collapsed by default)          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  KEY PRINCIPLES                                                 │
│  ──────────────                                                 │
│  • Lead with INSIGHT, support with evidence                    │
│  • Urgent before important, important before detail            │
│  • Every risk needs a mitigation                               │
│  • Every action needs an owner and date                        │
│  • Synthesize, don't enumerate                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

**Document Version**: 1.0  
**Last Updated**: January 22, 2026  
**Author**: GPTfy Prompt Factory Team  
**Usage**: Include in Stage08 prompt assembly as layout guidance

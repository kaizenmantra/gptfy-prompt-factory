# Meta-Prompt Architecture Design

**Task**: 3.1 - Design meta-prompt structure
**Author**: Opus
**Date**: 2026-01-23
**Status**: Design Complete

---

## Overview

This document defines the meta-prompt architecture for V2.0 of the Prompt Factory. The goal is to transform the LLM from a "template filler" (V1.1) into an intelligent "business analyst" that decides what's important and how to present it.

---

## Current Architecture (V1.1) - Template Filler

### Flow
```
Stage 7 (Template Design):
  → Generates fixed HTML template with merge field placeholders
  → Rigid structure: Header → Stats → Tables → Footer
  → LLM instructed to "fill in" the template with data

Stage 8 (Prompt Assembly):
  → Injects ALL builder prompts verbatim (Quality Rules, Patterns, UI Components, Context Templates)
  → ~8,000+ chars of builder content regardless of relevance
  → Final prompt = AI Instructions + Builder Content + HTML Template
```

### Problems
1. **Fixed Structure**: Template forces rigid layout regardless of data patterns
2. **Template Filler Role**: LLM just "fills in blanks" rather than analyzing
3. **Verbose Builders**: Next Best Action Pattern alone is ~6,500 chars
4. **No Selection**: ALL builders injected regardless of relevance
5. **Table-Heavy Output**: Structure favors data display over insights

---

## New Architecture (V2.0) - Meta-Prompt

### Core Principle
The LLM becomes a **business analyst** who:
1. Receives **data context** (multi-sample patterns, availability)
2. Receives **analysis principles** (compressed builders)
3. Has **UI toolkit** (available components)
4. Gets **directive** to analyze and present what matters

### Flow
```
Stage 7 (Analysis Brief):
  → Generates "analysis brief" not fixed template
  → Defines: data context, analysis goals, output guidelines
  → Does NOT define rigid section structure

Stage 8 (Meta-Prompt Assembly):
  → Selects relevant builders based on context
  → Compresses builders to principles only
  → Assembles meta-prompt with 6 sections (see below)
  → Adds multi-sample data payload from Stage 4
```

---

## Meta-Prompt Structure

The V2.0 prompt has 6 distinct sections:

### Section 1: ROLE
```
=== YOUR ROLE ===
You are an expert business analyst creating an executive dashboard for {targetPersona}.

Your job is NOT to display data tables. Your job is to:
- ANALYZE the Salesforce data provided
- IDENTIFY patterns, risks, and opportunities
- PRESENT insights that drive action
- RECOMMEND specific next steps

Think like a consultant presenting to a senior executive.
```

### Section 2: DATA PAYLOAD
```
=== DATA CONTEXT ===
Analyzed {sampleCount} {rootObject} records to understand data patterns.

SAMPLES ANALYZED:
{For each sample}
- {recordName}: {Amount}, {StageName}, {N tasks}, {M contacts}
{End for}

KEY PATTERNS DETECTED:
{From multiSampleProfile.patterns}
- [INSIGHT] Amount varies significantly: $200K to $1.2M (6x range)
- [WARNING] OpportunityLineItem missing in 1/3 samples
- [INFO] Task count varies 2-8 across samples

OBJECT AVAILABILITY:
{From multiSampleProfile.objectAggregations}
- Task: Present in 3/3 samples (avg 5.0 records) [CONSISTENT]
- OpportunityContactRole: Present in 3/3 samples (avg 2.7 records)
- OpportunityLineItem: Present in 2/3 samples (avg 2.3 records) [GAP]

DATA FIELDS AVAILABLE:
{From selectedFields - list fields per object}
```

### Section 3: ANALYSIS PRINCIPLES
```
=== ANALYSIS PRINCIPLES ===
Apply these principles when analyzing the data:

{Compressed Quality Rules - principles only}
EVIDENCE BINDING:
- Every insight must cite specific data (field:value)
- Never make claims without supporting evidence
- Use exact numbers, not approximations

{Compressed Patterns - principles only}
NEXT BEST ACTION:
- Identify the highest-impact action based on data
- Prioritize by: urgency, impact, feasibility
- Provide specific, actionable recommendations

{Compressed Context Templates - if relevant}
INDUSTRY CONTEXT ({industryName}):
- Key metrics that matter: {metrics}
- Typical benchmarks: {benchmarks}
```

### Section 4: UI TOOLKIT
```
=== UI TOOLKIT ===
You have these components available. Use them strategically.

LAYOUT COMPONENTS:
- Dashboard Container: Full-width responsive layout
- Section Card: White card with header and content area
- Stats Strip: Horizontal metrics display (3-5 key numbers)
- Two-Column Grid: Side-by-side content areas

INSIGHT COMPONENTS:
- Alert Box: Highlight critical information (error/warning/info)
- Insight Card: Analysis finding with evidence citation
- Recommendation Card: Action item with rationale
- Health Score: Visual indicator (0-100 with color coding)

DATA COMPONENTS:
- Data Table: For listing related records (use sparingly!)
- Metric Tile: Single KPI with label and trend indicator
- Status Badge: Inline status indicator with semantic color

COMPONENT USAGE RULES:
- Lead with insights (Alert Boxes, Insight Cards) not tables
- Use Stats Strip for key metrics at the top
- Tables should be LAST, not first - and only if data warrants
- Every section should have analysis text, not just data
```

### Section 5: OUTPUT RULES
```
=== OUTPUT RULES ===
CRITICAL GPTfy REQUIREMENTS:
1. Single line HTML - no newlines
2. Inline styles only - no CSS classes or style blocks
3. No scripts or event handlers
4. Start with <div style="..." and end with </div>
5. No emojis or special characters
6. No placeholders, TBD, TODO markers

MERGE FIELD SYNTAX:
- Field values: {{{FieldName}}}
- Child iteration: {{#Collection}}...{{/Collection}}
- Empty check: {{^Collection}}No items{{/Collection}}

STYLING:
- Font: Salesforce Sans, system fonts fallback
- Colors: Primary #0176D3, Success #2E844A, Warning #DD7A01, Error #BA0517
- Background: #F3F3F3, Cards: #FFFFFF, Border: #DDDBDA
```

### Section 6: DIRECTIVE
```
=== YOUR DIRECTIVE ===
Analyze the {rootObject} data and generate an executive dashboard.

STRUCTURE YOUR OUTPUT AS:
1. EXECUTIVE SUMMARY (2-3 sentences)
   - Overall health/status assessment
   - Biggest risk and biggest opportunity
   - Recommended immediate action

2. KEY INSIGHTS (3-5 findings)
   - Use Insight Cards with evidence citations
   - Prioritize by business impact
   - Include specific data points

3. RECOMMENDED ACTIONS (2-4 items)
   - Use Recommendation Cards
   - Be specific: "Schedule call with {ContactName}" not "Follow up"
   - Include urgency indicator

4. SUPPORTING DATA (if warranted)
   - Tables for detailed records ONLY if adds value
   - Keep tables compact (5-7 rows max)
   - Add context paragraph before each table

QUALITY CHECKLIST:
[ ] Does the summary capture the key story?
[ ] Does every insight cite specific evidence?
[ ] Are recommendations specific and actionable?
[ ] Is the layout insight-first, not table-first?
[ ] Would an executive find this valuable?

Generate the dashboard now. Output raw HTML only.
```

---

## Implementation Changes

### Stage 7 Changes (Task 3.2)

**Current**: `buildTemplatePrompt()` generates a fixed HTML structure prompt
**New**: `buildAnalysisBriefPrompt()` generates:
- Data context summary (what objects/fields are available)
- Analysis goals (what the output should achieve)
- Output guidelines (structure suggestions, not rigid template)

The key change: Stage 7 does NOT generate a fixed HTML template. Instead, it generates an "analysis brief" that tells the LLM what analysis is needed.

### Stage 8 Changes (Task 3.3)

**Current**: `buildAIInstructions()` injects ALL builders verbatim
**New**: `buildMetaPrompt()` assembles the 6 sections above:

1. `buildRoleSection()` - Static analyst role definition
2. `buildDataPayloadSection()` - Uses multiSampleProfile from Stage 4
3. `buildAnalysisPrinciplesSection()` - Compressed builders (quality rules, patterns)
4. `buildUIToolkitSection()` - Available components (from Task 3.4)
5. `buildOutputRulesSection()` - GPTfy compliance rules
6. `buildDirectiveSection()` - Analysis instructions

### Builder Selection Logic

Instead of injecting ALL builders, select based on:
```apex
// Select builders based on context
List<BuilderPrompt> selectedBuilders = new List<BuilderPrompt>();

// Always include Quality Rules (foundational)
selectedBuilders.addAll(getCompressedQualityRules());

// Include Patterns that match rootObject or are global
selectedBuilders.addAll(getCompressedPatterns(rootObject));

// Include Context Template only if industry matches
if (String.isNotBlank(industryContext)) {
    selectedBuilders.addAll(getMatchingContextTemplates(industryContext));
}

// Include UI Components only if referenced in analysis brief
// (Task 3.4 creates a static toolkit section instead)
```

### Builder Compression

Compressed builders contain PRINCIPLES only:
```
ORIGINAL (6,500 chars):
"The Next Best Action Pattern is a sophisticated approach to
recommendation systems that leverages machine learning..."
[Full documentation, examples, implementation details]

COMPRESSED (400 chars):
"NEXT BEST ACTION:
- Identify highest-impact action from data
- Prioritize by: urgency, impact, feasibility
- Cite evidence: field:value supporting the recommendation
- Be specific: 'Call John about renewal' not 'Follow up'"
```

---

## Data Flow

```
Stage 4 (Data Profiling)
    │
    ├── multiSampleProfile
    │   ├── sampleCount, rootObject, sampleIds
    │   ├── samples[] (per-record data)
    │   ├── objectAggregations{} (availability)
    │   └── patterns[] (VARIANCE, GAP, CONSISTENCY)
    │
    ▼
Stage 5 (Field Selection)
    │
    ├── selectedFields (enhanced with multi-sample context)
    ├── multiSampleProfile (passed through)
    │
    ▼
Stage 7 (Analysis Brief) [MODIFIED]
    │
    ├── analysisBrief (NOT htmlTemplate)
    │   ├── analysisGoals
    │   ├── dataContext summary
    │   └── outputGuidelines
    │
    ▼
Stage 8 (Meta-Prompt Assembly) [MODIFIED]
    │
    ├── metaPrompt (6 sections)
    │   ├── Section 1: ROLE
    │   ├── Section 2: DATA PAYLOAD (uses multiSampleProfile)
    │   ├── Section 3: ANALYSIS PRINCIPLES (compressed builders)
    │   ├── Section 4: UI TOOLKIT (static component library)
    │   ├── Section 5: OUTPUT RULES (GPTfy compliance)
    │   └── Section 6: DIRECTIVE (analysis instructions)
    │
    ▼
Stage 9 (Deploy)
    │
    └── Creates AI Prompt with metaPrompt as ccai__Prompt_Command__c
```

---

## Backward Compatibility

For V2.0 MVP, maintain backward compatibility:

1. **Feature Flag**: `USE_META_PROMPT` flag in Stage 7/8
   - `false` (default): Use existing template approach
   - `true`: Use new meta-prompt approach

2. **Single Sample Fallback**: If only 1 sample ID provided:
   - Data Payload section shows single record context
   - Patterns section omitted (need multiple samples)
   - Still uses meta-prompt structure

3. **Missing Multi-Sample Profile**: If `multiSampleProfile` is null:
   - Fall back to legacy `dataAvailability` map
   - Data Payload section uses simplified format

---

## Success Criteria

V2.0 meta-prompt output should:

1. **Lead with insights**, not data tables
2. **Cite specific evidence** for every claim
3. **Provide actionable recommendations** with urgency
4. **Use tables sparingly** and only when they add value
5. **Feel like a consultant's analysis**, not a data dump

---

## Implementation Tasks

### Task 3.2 (Opus): Modify Stage 7
- Replace `buildTemplatePrompt()` with `buildAnalysisBriefPrompt()`
- Remove fixed HTML template generation
- Generate analysis brief with goals, context, guidelines
- Add `USE_META_PROMPT` feature flag

### Task 3.3 (Sonnet): Modify Stage 8
- Add `buildMetaPrompt()` method with 6 sections
- Implement `buildRoleSection()`
- Implement `buildDataPayloadSection()` using multiSampleProfile
- Implement `buildAnalysisPrinciplesSection()` with compressed builders
- Implement `buildDirectiveSection()`
- Add `USE_META_PROMPT` feature flag

### Task 3.4 (Sonnet): Create UI Toolkit
- Document available components in `buildUIToolkitSection()`
- Include layout components, insight components, data components
- Add usage rules and examples

---

**Design Complete. Ready for implementation.**

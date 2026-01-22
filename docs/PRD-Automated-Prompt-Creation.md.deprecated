# Product Requirements Document (PRD)
# Automated Prompt Creation & Testing Framework

**Version:** 1.0
**Last Updated:** December 29, 2024
**Feature Branch:** `Automated-Prompt-Creation`
**Status:** Draft

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Goals & Objectives](#goals--objectives)
4. [User Personas](#user-personas)
5. [Process Overview](#process-overview)
6. [Generic Prompt Template Framework](#generic-prompt-template-framework)
7. [Technical Architecture](#technical-architecture)
8. [API Specifications](#api-specifications)
9. [Validation & Testing](#validation--testing)
10. [Success Criteria](#success-criteria)
11. [Appendix](#appendix)

---

## Executive Summary

The **Automated Prompt Creation & Testing Framework** is a generic, reusable system that enables AI-assisted development of GPTfy prompts. The framework automates the iterative cycle of prompt creation, deployment, testing, and refinement until the output matches a desired HTML mockup or specification.

This framework standardizes prompt structure across all GPTfy implementations, ensuring consistent quality, maintainability, and predictable AI behavior.

---

## Problem Statement

### Current Challenges

1. **Manual Iteration is Time-Consuming**: Developers manually update prompts, deploy to Salesforce, test via UI, review output, and repeat—often requiring 5-10+ iterations.

2. **Inconsistent Prompt Structure**: Each prompt is written differently, leading to unpredictable AI outputs and difficult maintenance.

3. **GPTfy-Specific Requirements**: GPTfy has specific output requirements (inline styles, single-line HTML, no markdown wrappers) that are easy to forget.

4. **No Automated Validation**: There's no systematic way to validate output against expected structure before deployment.

5. **Knowledge Silos**: Lessons learned from one prompt implementation don't transfer to others.

---

## Goals & Objectives

### Primary Goals

1. **Reduce prompt development time by 70%** through automation
2. **Standardize prompt structure** across all GPTfy implementations
3. **Enable AI-assisted iteration** with minimal human intervention
4. **Create reusable patterns** that apply to any prompt type

### Secondary Goals

1. Document best practices for GPTfy prompt development
2. Create a library of reusable prompt components
3. Enable non-technical users to create prompts via templates

---

## User Personas

### 1. GPTfy Implementation Consultant
- **Role**: Configures GPTfy for clients
- **Need**: Quickly create working prompts with predictable output
- **Pain**: Spending hours debugging prompt output formatting

### 2. AI/Prompt Engineer
- **Role**: Designs and optimizes AI prompts
- **Need**: Systematic approach to prompt iteration
- **Pain**: No feedback loop for rapid testing

### 3. Salesforce Administrator
- **Role**: Manages GPTfy configuration
- **Need**: Maintain existing prompts, make minor updates
- **Pain**: Lack of documentation on prompt structure

---

## Process Overview

### Automated Prompt Creation & Testing Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AUTOMATED PROMPT CREATION WORKFLOW                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  1. HUMAN SETUP │───▶│  2. AI CREATES  │───▶│  3. AI DEPLOYS  │
│                 │    │                 │    │                 │
│ • Initial Prompt│    │ • Generates     │    │ • Updates SF    │
│ • DCM Config    │    │   prompt content│    │   Prompt record │
│ • UI Mockup     │    │ • Uses template │    │ • Via Apex API  │
│ • Activate      │    │   framework     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  6. COMPLETE    │◀───│  5. AI FIXES    │◀───│  4. AI TESTS    │
│                 │    │                 │    │                 │
│ • Output matches│    │ • Identifies    │    │ • REST API call │
│   mockup        │    │   issues        │    │ • Reviews HTML  │
│ • Deploy to prod│    │ • Updates prompt│    │ • Compares to   │
│                 │    │ • Re-deploys    │    │   mockup        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              └────────────────────────┘
                                    ITERATE UNTIL
                                    OUTPUT MATCHES
```

### Step-by-Step Process

#### Step 1: Human Setup (One-time)

| Task | Owner | Description |
|------|-------|-------------|
| Create Initial Prompt | Human | Create `ccai__AI_Prompt__c` record with basic structure |
| Configure DCM | Human | Set up Data Context Model with required fields |
| Create UI Mockup | Human | Design target HTML output in mockup file |
| Activate Prompt | Human | Set `ccai__Is_Active__c = true` |
| Fix Validation | Human | Resolve any Salesforce validation errors |

#### Step 2: AI Generates Prompt Content

The AI uses the **Generic Prompt Template Framework** (see below) to generate structured prompt content based on:
- Business requirements
- UI mockup reference
- DCM field mappings

#### Step 3: AI Deploys to Salesforce

```apex
// AI executes Apex to update prompt
ccai__AI_Prompt__c prompt = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Id = :promptId LIMIT 1
];
prompt.ccai__Prompt_Command__c = generatedPromptText;
update prompt;
```

#### Step 4: AI Tests via REST API

```bash
curl -X POST "${SF_URL}/services/apexrest/ccai/v1/executePrompt" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "promptRequestId": "${PROMPT_REQUEST_ID}",
        "recordId": "${TEST_RECORD_ID}",
        "customPromptCommand": ""
    }'
```

#### Step 5: AI Reviews & Fixes

The AI analyzes the response:
1. Validates HTML structure
2. Compares to mockup
3. Identifies discrepancies
4. Updates prompt with fixes
5. Returns to Step 3

#### Step 6: Complete

When output matches mockup:
- Document final prompt
- Create test cases
- Prepare for production deployment

---

## Generic Prompt Template Framework

### Overview

Every GPTfy prompt should follow this standardized four-section structure:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GENERIC PROMPT TEMPLATE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SECTION 1: GOAL / PERSONA / BUSINESS REQUIREMENT                    │   │
│  │ (Customer-Specific)                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SECTION 2: STYLING / BRAND GUIDELINES / CSS                         │   │
│  │ (Standardized GPTfy)                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SECTION 3: DATA MAPPING / FORMATTING                                │   │
│  │ (GPTfy Team Configuration)                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SECTION 4: GUARDRAILS / OUTPUT RULES                                │   │
│  │ (Standardized GPTfy)                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Section 1: Goal / Persona / Business Requirement

**Purpose**: Define the AI's role, context, and business objective.

**Owner**: Customer / Business Analyst

**Customization Level**: High - Fully customer-specific

**Template**:

```
You are a [ROLE] for [COMPANY/CONTEXT]. Generate a [OUTPUT_TYPE].

BUSINESS CONTEXT:
- [Context point 1]
- [Context point 2]
- [Context point 3]

OUTPUT OBJECTIVE:
[Clear description of what the output should achieve]

TARGET AUDIENCE:
[Who will consume this output]
```

**MEDDIC Example**:

```
You are a MEDDIC compliance analyst for VusionGroup. Generate a Deal Intelligence Report.

BUSINESS CONTEXT:
- Sales methodology: MEDDIC (Metrics, Economic Buyer, Decision Criteria, Decision Process, Identify Pain, Champion)
- Output will be displayed in Salesforce Lightning components
- Report helps sales managers assess deal health and forecast accuracy

OUTPUT OBJECTIVE:
Generate a comprehensive deal health assessment that identifies gaps in MEDDIC criteria and provides actionable recommendations.

TARGET AUDIENCE:
Sales Representatives, Sales Managers, Revenue Operations
```

**Other Use Case Examples**:

| Use Case | Role | Output Type |
|----------|------|-------------|
| Customer 360 | Customer Success Analyst | Account Health Dashboard |
| Lead Scoring | Marketing Analyst | Lead Qualification Report |
| Case Summary | Support Specialist | Case Resolution Summary |
| Contract Analysis | Legal Analyst | Contract Risk Assessment |

---

### Section 2: Styling / Brand Guidelines / CSS

**Purpose**: Define visual presentation standards.

**Owner**: GPTfy Team (Standardized)

**Customization Level**: Low - Use standard patterns with minor brand customization

**Why Inline Styles?**: GPTfy renders HTML in contexts where `<style>` blocks may be stripped or ignored. Inline styles ensure consistent rendering across:
- Salesforce Lightning Web Components
- Email templates
- External embedded displays

**Standardized GPTfy Style Palette**:

```
COLOR PALETTE:
┌──────────────────────────────────────────────────────────────┐
│ Primary Blue:    #16325c  │  Headers, primary text           │
│ Accent Blue:     #0176d3  │  Links, actions, interactive     │
│ Success Green:   #2e844a  │  Positive status, good scores    │
│ Warning Orange:  #dd7a01  │  Caution, medium risk            │
│ Critical Red:    #c23934  │  Error, high risk, at-risk       │
│ Background Gray: #f8f9fa  │  Card backgrounds                │
│ Border Gray:     #e0e5ee  │  Borders, dividers               │
│ Text Gray:       #666666  │  Secondary text, labels          │
│ White:           #ffffff  │  Primary backgrounds             │
└──────────────────────────────────────────────────────────────┘

TYPOGRAPHY:
┌──────────────────────────────────────────────────────────────┐
│ Font Family:     Arial, sans-serif                           │
│ Header Size:     20px (font-weight: 700)                     │
│ Subheader Size:  16px (font-weight: 700)                     │
│ Body Size:       14px (font-weight: 400)                     │
│ Small/Label:     11px (text-transform: uppercase)            │
│ Line Height:     1.5                                         │
└──────────────────────────────────────────────────────────────┘

SPACING:
┌──────────────────────────────────────────────────────────────┐
│ Container Padding:  20px - 24px                              │
│ Card Padding:       12px - 16px                              │
│ Element Gap:        12px - 16px                              │
│ Section Margin:     24px                                     │
│ Border Radius:      6px - 8px                                │
└──────────────────────────────────────────────────────────────┘

STATUS INDICATORS:
┌──────────────────────────────────────────────────────────────┐
│ Critical (<50%):   background:#fef2f2  border:#c23934        │
│ Warning (50-74%):  background:#fff8f0  border:#dd7a01        │
│ Good (>=75%):      background:#f0fdf4  border:#2e844a        │
│ Info/Neutral:      background:#f0f7ff  border:#0176d3        │
└──────────────────────────────────────────────────────────────┘
```

**Standard Component Patterns**:

```html
<!-- Container -->
<div style="max-width:1200px;margin:0 auto;font-family:Arial,sans-serif;">

<!-- Header with Gradient -->
<div style="background:linear-gradient(135deg,#16325c,#0176d3);padding:20px;border-radius:8px 8px 0 0;">
  <div style="color:#fff;font-size:20px;font-weight:700;">[Title]</div>
  <div style="color:rgba(255,255,255,0.8);font-size:12px;">[Subtitle]</div>
</div>

<!-- Status Badge -->
<span style="background:#c23934;color:#fff;padding:4px 12px;border-radius:4px;font-size:12px;font-weight:700;">
  AT RISK
</span>

<!-- Card with Left Border -->
<div style="background:#fff;border:1px solid #e0e5ee;border-radius:6px;padding:16px;border-left:4px solid #c23934;">
  [Card Content]
</div>

<!-- Grid Layout -->
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px;">
  [Grid Items]
</div>

<!-- Stat Box -->
<div style="flex:1;background:#f8f9fa;border-radius:8px;padding:12px 16px;text-align:center;min-width:100px;">
  <div style="font-size:20px;font-weight:700;color:#16325c;">[Value]</div>
  <div style="font-size:11px;color:#666;text-transform:uppercase;">[Label]</div>
</div>

<!-- Progress Bar -->
<div style="height:6px;background:#e0e5ee;border-radius:3px;overflow:hidden;">
  <div style="height:100%;background:#c23934;border-radius:3px;width:[X]%;"></div>
</div>

<!-- Section Header -->
<div style="font-size:16px;font-weight:700;color:#16325c;margin:24px 0 16px 0;padding-bottom:8px;border-bottom:2px solid #e0e5ee;">
  [Section Title]
</div>

<!-- Table -->
<table style="width:100%;border-collapse:collapse;font-size:13px;">
  <thead>
    <tr style="background:#f0f4f8;">
      <th style="padding:12px;text-align:left;font-weight:600;color:#16325c;border-bottom:2px solid #e0e5ee;">
        [Header]
      </th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding:12px;border-bottom:1px solid #e0e5ee;">[Cell]</td>
    </tr>
  </tbody>
</table>
```

---

### Section 3: Data Mapping / Formatting

**Purpose**: Map DCM fields to output elements with formatting rules.

**Owner**: GPTfy Implementation Team

**Customization Level**: High - Specific to each implementation

**Template**:

```
AVAILABLE DATA FIELDS:

[Primary Object]:
- Field1: Description
- Field2: Description

[Related Object 1] ([Relationship_Name]):
- Field1: Description
- Field2: Description

[Related Object 2] ([Relationship_Name]):
- Field1: Description
- Field2: Description

FIELD MAPPINGS:

| Output Element | Data Field | Format | Default |
|----------------|------------|--------|---------|
| [Element Name] | [API Name] | [Format Rule] | [Default Value] |

CALCULATIONS:

1. [Calculation Name]:
   Formula: [Formula]
   Example: [Example]

2. [Calculation Name]:
   Formula: [Formula]
   Example: [Example]

CONDITIONAL LOGIC:

- If [Condition] then [Action]
- If [Condition] then [Action]
```

**MEDDIC Example**:

```
AVAILABLE DATA FIELDS:

Opportunity:
- Name: Opportunity name
- Account.Name: Parent account name
- Amount: Deal value
- CurrencyIsoCode: Currency (EUR, USD, etc.)
- StageName: Current sales stage
- CloseDate: Expected close date
- Probability: Win probability percentage
- Owner.Name: Opportunity owner
- CreatedDate: When opportunity was created

ClosePlan (TSPC__Deals__r):
- TSPC__ScorecardScoreRatio__c: Overall MEDDIC score (0-1)
- TSPC__Age__c: Days in current stage

MEDDIC Components (TSPC__DealQuestionCategories__r):
- TSPC__Category__c: Component name
- TSPC__Code__c: Component code (M, E, D, D, I, C)
- TSPC__TotalScoreRatio__c: Component score (0-1)

Stakeholders (TSPC__Stakeholders__r):
- TSPC__ContactName__c: Stakeholder name
- TSPC__Role__c: Role in decision
- TSPC__SupportStatus__c: Support level

FIELD MAPPINGS:

| Output Element     | Data Field                      | Format           | Default        |
|--------------------|---------------------------------|------------------|----------------|
| Deal Title         | Opportunity.Name                | Text             | "Untitled"     |
| Account Name       | Opportunity.Account.Name        | Text             | "No Account"   |
| Amount             | Opportunity.Amount              | Currency + Code  | "0"            |
| MEDDIC Score       | TSPC__ScorecardScoreRatio__c    | Percentage       | "0%"           |
| Days in Stage      | TSPC__Age__c                    | Integer + "days" | "0 days"       |

CALCULATIONS:

1. MEDDIC Score Percentage:
   Formula: TSPC__ScorecardScoreRatio__c * 100
   Example: 0.23 → 23%

2. Days to Close:
   Formula: CloseDate - TODAY
   Example: 2024-12-15 - 2024-12-29 = -14 (overdue)

3. Opportunity Age:
   Formula: TODAY - CreatedDate
   Example: 2024-12-29 - 2024-09-12 = 108 days

4. Stakeholder Count:
   Formula: COUNT(TSPC__Stakeholders__r)
   Example: 3 stakeholders → "3"

CONDITIONAL LOGIC:

- If MEDDIC Score < 50% then status = "AT RISK" (red)
- If MEDDIC Score 50-74% then status = "WARNING" (orange)
- If MEDDIC Score >= 75% then status = "HEALTHY" (green)
- If Days to Close < 0 then show "Overdue" indicator
- Only show MEDDIC components with score < 75% in gap analysis
- If TSPC__Stakeholders__r is empty then show "No stakeholders mapped"
```

---

### Section 4: Guardrails / Output Rules

**Purpose**: Enforce output constraints and prevent common AI errors.

**Owner**: GPTfy Team (Standardized)

**Customization Level**: None - These are universal rules

**Standard Guardrails** (Apply to ALL GPTfy prompts):

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         CRITICAL OUTPUT RULES                                  ║
║                   (MANDATORY FOR ALL GPTFY PROMPTS)                           ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  1. FORMAT RULES:                                                             ║
║     ✓ Output ONE continuous HTML string with ZERO newlines                    ║
║     ✓ Start directly with <div style="..."> - NO preamble                    ║
║     ✗ NO markdown code blocks (```html)                                       ║
║     ✗ NO plain text outside HTML tags                                         ║
║     ✗ NO XML declarations or DOCTYPE                                          ║
║                                                                               ║
║  2. STYLING RULES:                                                            ║
║     ✓ ALL styling inline (style="...") on each element                       ║
║     ✗ NO <style> tag anywhere                                                 ║
║     ✗ NO CSS classes (class="...")                                            ║
║     ✗ NO external stylesheets                                                 ║
║     ✗ NO <script> tags                                                        ║
║                                                                               ║
║  3. DATA RULES:                                                               ║
║     ✓ Calculate ALL values from provided data                                 ║
║     ✓ If data is missing, show appropriate empty state                        ║
║     ✓ Format numbers: thousands separator, 2 decimals for currency            ║
║     ✓ Format dates: "Month DD, YYYY" (e.g., "December 29, 2024")             ║
║     ✗ NEVER use placeholders like [X], "X days", "TBD", "{placeholder}"       ║
║     ✗ NEVER leave template variables unfilled                                 ║
║                                                                               ║
║  4. CONTENT RULES:                                                            ║
║     ✓ Professional, concise language                                          ║
║     ✓ Active voice                                                            ║
║     ✗ NO emojis anywhere                                                      ║
║     ✗ NO special unicode characters                                           ║
║     ✗ NO lorem ipsum or sample text                                           ║
║                                                                               ║
║  5. STRUCTURE RULES:                                                          ║
║     ✓ Maintain consistent component hierarchy                                 ║
║     ✓ All containers must be properly closed                                  ║
║     ✓ All attribute values must be properly quoted                            ║
║     ✓ Validate HTML structure before output                                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

OUTPUT VALIDATION CHECKLIST:
┌─────────────────────────────────────────────────────────────────────────────┐
│ [ ] Starts with <div style="...">                                           │
│ [ ] Ends with </div>                                                        │
│ [ ] No newlines or line breaks (\n, \r)                                     │
│ [ ] All values populated (no placeholders)                                  │
│ [ ] All styles inline                                                       │
│ [ ] No <style> or <script> tags                                             │
│ [ ] No markdown wrappers (```)                                              │
│ [ ] No emojis                                                               │
│ [ ] All HTML tags properly closed                                           │
│ [ ] All attribute values quoted                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Complete Prompt Template

Below is the assembled template that combines all four sections:

```
═══════════════════════════════════════════════════════════════════════════════
SECTION 1: GOAL / PERSONA / BUSINESS REQUIREMENT
═══════════════════════════════════════════════════════════════════════════════

You are a [ROLE] for [COMPANY]. Generate a [OUTPUT_TYPE].

BUSINESS CONTEXT:
- [Context point 1]
- [Context point 2]
- [Context point 3]

OUTPUT OBJECTIVE:
[Clear description of what the output achieves]

TARGET AUDIENCE:
[Who will consume this output]

═══════════════════════════════════════════════════════════════════════════════
SECTION 2: STYLING / VISUAL REQUIREMENTS
═══════════════════════════════════════════════════════════════════════════════

CRITICAL STYLING REQUIREMENTS:
1. Use INLINE STYLES on every element (style="...")
2. NO <style> block, NO CSS classes
3. Start output with: <div style="max-width:1200px;margin:0 auto;font-family:Arial,sans-serif;">

STRUCTURE TO GENERATE:

[Define each visual section with example inline styles]

1. HEADER:
<div style="background:linear-gradient(135deg,#16325c,#0176d3);padding:20px;border-radius:8px 8px 0 0;">
  ...
</div>

2. [NEXT SECTION]:
...

COLOR REFERENCE:
- Primary: #16325c
- Accent: #0176d3
- Success: #2e844a
- Warning: #dd7a01
- Critical: #c23934
- Background: #f8f9fa
- Border: #e0e5ee

═══════════════════════════════════════════════════════════════════════════════
SECTION 3: DATA MAPPING / FORMATTING
═══════════════════════════════════════════════════════════════════════════════

AVAILABLE DATA FIELDS:

[Primary Object]:
- [Field]: [Description]

[Related Objects]:
- [Relationship].[Field]: [Description]

CALCULATIONS:
1. [Name]: [Formula]
2. [Name]: [Formula]

CONDITIONAL LOGIC:
- If [condition] then [result]
- If [condition] then [result]

═══════════════════════════════════════════════════════════════════════════════
SECTION 4: GUARDRAILS / OUTPUT RULES
═══════════════════════════════════════════════════════════════════════════════

CRITICAL OUTPUT RULES:
1. Output ONE continuous HTML string with ZERO newlines
2. Start directly with <div style="..."> - NO preamble
3. Calculate ALL values - NEVER use placeholders like [X] or "X days"
4. NO markdown code blocks (```html)
5. NO emojis anywhere
6. ALL styling inline - NO <style> tag, NO CSS classes

OUTPUT VALIDATION:
[ ] Single line HTML - no newlines
[ ] All values calculated from data
[ ] Inline styles only
[ ] No placeholders or template variables
[ ] Proper HTML structure
```

---

## Technical Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SYSTEM ARCHITECTURE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │   Claude    │───▶│   Scripts   │───▶│  Salesforce │───▶│   GPTfy     │ │
│  │   Agent     │    │             │    │   REST API  │    │   Engine    │ │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │
│        │                  │                  │                  │          │
│        │                  │                  │                  │          │
│        ▼                  ▼                  ▼                  ▼          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │  Template   │    │   Deploy    │    │   Prompt    │    │   HTML      │ │
│  │  Framework  │    │   Apex      │    │   Records   │    │   Output    │ │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### File Structure

```
project/
├── scripts/
│   ├── deploy-prompt.apex      # Apex script to update prompt in Salesforce
│   ├── iterate-prompt.sh       # Main automation script for testing
│   └── call-api.sh             # REST API test utility
│
├── templates/
│   ├── prompt-template.md      # Complete generic prompt template
│   ├── section-1-goal.md       # Goal section examples by use case
│   ├── section-2-styling.md    # Standard styling patterns
│   ├── section-3-data.md       # Data mapping templates
│   └── section-4-guardrails.md # Standard guardrails (do not modify)
│
├── prompts/
│   ├── meddic/
│   │   ├── prompt.txt          # Final prompt text
│   │   ├── mockup.html         # Target UI mockup
│   │   └── config.json         # Prompt configuration
│   │
│   └── [other-prompts]/
│       ├── prompt.txt
│       ├── mockup.html
│       └── config.json
│
├── sample-output/
│   └── [prompt-name]-output.html
│
└── docs/
    ├── PRD.md                  # Original MEDDIC PRD
    ├── PRD-Automated-Prompt-Creation.md  # This document
    └── GPTFY_CONFIG.md         # GPTfy configuration guide
```

### Configuration File Schema

```json
{
  "promptName": "MEDDIC Deal Intelligence",
  "promptId": "a8Jbd0000003IrdEAE",
  "promptRequestId": "40ccdca557b58fee933893f24e06094ab3159",
  "testRecordId": "006bd00000E13aAAAR",
  "orgAlias": "pocgptfy",
  "primaryObject": "Opportunity",
  "relatedObjects": [
    {
      "relationship": "TSPC__Deals__r",
      "object": "TSPC__Deal__c",
      "fields": ["TSPC__ScorecardScoreRatio__c", "TSPC__Age__c"]
    },
    {
      "relationship": "TSPC__DealQuestionCategories__r",
      "object": "TSPC__DealQuestionCategory__c",
      "fields": ["TSPC__Category__c", "TSPC__Code__c", "TSPC__TotalScoreRatio__c"]
    },
    {
      "relationship": "TSPC__Stakeholders__r",
      "object": "TSPC__Stakeholder__c",
      "fields": ["TSPC__ContactName__c", "TSPC__Role__c", "TSPC__SupportStatus__c"]
    }
  ],
  "mockupFile": "mockup.html",
  "outputFile": "output.html",
  "validationRules": {
    "requiredElements": [
      "header",
      "snapshot",
      "stats-strip",
      "health-bar",
      "meddic-cards",
      "stakeholder-table",
      "timeline",
      "insights",
      "manager-section"
    ],
    "elementCounts": {
      "heatmap-rows": 3,
      "heatmap-cells-per-row": 12,
      "stats-boxes": 5,
      "timeline-cards": 4,
      "insight-cards": 3
    },
    "forbiddenPatterns": [
      "\\[X\\]",
      "\\{.*\\}",
      "<style>",
      "class=",
      "```",
      "\\n"
    ]
  }
}
```

---

## API Specifications

### GPTfy REST API

**Endpoint**: `POST /services/apexrest/ccai/v1/executePrompt`

**Headers**:
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "promptRequestId": "string",
  "recordId": "string",
  "customPromptCommand": ""
}
```

**Response (Success)**:
```json
{
  "success": true,
  "responseId": "a8Qbd0000000xyz",
  "response": "<div style=\"...\">Generated HTML content</div>"
}
```

**Response (Error)**:
```json
{
  "success": false,
  "error": "Error message"
}
```

### Apex Deployment Script Template

```apex
// Generic prompt update script
// Replace PROMPT_ID and PROMPT_TEXT variables

String promptId = 'PROMPT_ID_HERE';

String promptText = 'SECTION 1: GOAL...\n' +
'SECTION 2: STYLING...\n' +
'SECTION 3: DATA...\n' +
'SECTION 4: GUARDRAILS...';

ccai__AI_Prompt__c prompt = [
    SELECT Id, ccai__Prompt_Command__c, ccai__Is_Active__c
    FROM ccai__AI_Prompt__c
    WHERE Id = :promptId
    LIMIT 1
];

prompt.ccai__Prompt_Command__c = promptText;
update prompt;
System.debug('Prompt updated successfully: ' + promptId);
```

---

## Validation & Testing

### Automated Validation Checks

| Check | Description | Pass Criteria |
|-------|-------------|---------------|
| HTML Structure | Valid HTML syntax | Parseable without errors |
| Single Line | No newline characters | `!response.contains('\n')` |
| Inline Styles | No style/class references | No `<style>`, no `class=` |
| No Placeholders | All values populated | No `[X]`, `TBD`, `{var}`, `null` |
| Required Sections | All sections present | Config-defined elements exist |
| Element Counts | Minimum elements met | Per config validation rules |
| Forbidden Patterns | No banned patterns | None of forbiddenPatterns match |

### Testing Script Enhancement (iterate-prompt.sh)

```bash
#!/bin/bash
# Automated prompt testing script with validation

set -e

# Configuration (override via environment or config file)
ORG_ALIAS="${ORG_ALIAS:-pocgptfy}"
PROMPT_ID="${PROMPT_ID}"
PROMPT_REQUEST_ID="${PROMPT_REQUEST_ID}"
TEST_RECORD_ID="${TEST_RECORD_ID}"
ITERATION=${ITERATION:-1}
OUTPUT_DIR="${OUTPUT_DIR:-./iterations}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get auth token and URL
echo "🔐 Getting authentication token..."
AUTH_JSON=$(sf org display --target-org "$ORG_ALIAS" --json)
TOKEN=$(echo "$AUTH_JSON" | jq -r '.result.accessToken')
URL=$(echo "$AUTH_JSON" | jq -r '.result.instanceUrl')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

# Execute prompt via REST API
echo "🚀 Executing prompt..."
RESPONSE=$(curl -s -X POST "${URL}/services/apexrest/ccai/v1/executePrompt" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"promptRequestId\": \"${PROMPT_REQUEST_ID}\",
        \"recordId\": \"${TEST_RECORD_ID}\",
        \"customPromptCommand\": \"\"
    }")

# Extract HTML response
HTML=$(echo "$RESPONSE" | jq -r '.response // .result.response // empty')

if [ -z "$HTML" ]; then
    echo "❌ No HTML response received"
    echo "Raw response: $RESPONSE"
    exit 1
fi

# Save output
OUTPUT_FILE="${OUTPUT_DIR}/iteration-${ITERATION}.html"
echo "$HTML" > "$OUTPUT_FILE"
echo "📄 Output saved to: $OUTPUT_FILE"

# Validation function
validate_output() {
    local html="$1"
    local errors=0

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    VALIDATION RESULTS"
    echo "═══════════════════════════════════════════════════════════════"

    # Check 1: Newlines
    if [[ "$html" == *$'\n'* ]]; then
        echo "❌ FAIL: Contains newlines"
        ((errors++))
    else
        echo "✅ PASS: No newlines"
    fi

    # Check 2: Style block
    if [[ "$html" == *"<style>"* ]] || [[ "$html" == *"<style "* ]]; then
        echo "❌ FAIL: Contains <style> block"
        ((errors++))
    else
        echo "✅ PASS: No <style> block"
    fi

    # Check 3: CSS classes
    if [[ "$html" == *"class=\""* ]] || [[ "$html" == *"class='"* ]]; then
        echo "❌ FAIL: Contains CSS classes"
        ((errors++))
    else
        echo "✅ PASS: No CSS classes"
    fi

    # Check 4: Placeholders
    if [[ "$html" == *"[X]"* ]] || [[ "$html" == *"[x]"* ]]; then
        echo "❌ FAIL: Contains [X] placeholder"
        ((errors++))
    else
        echo "✅ PASS: No [X] placeholders"
    fi

    if [[ "$html" == *"TBD"* ]] || [[ "$html" == *"tbd"* ]]; then
        echo "❌ FAIL: Contains TBD placeholder"
        ((errors++))
    else
        echo "✅ PASS: No TBD placeholders"
    fi

    # Check 5: Markdown wrapper
    if [[ "$html" == *'```'* ]]; then
        echo "❌ FAIL: Contains markdown code blocks"
        ((errors++))
    else
        echo "✅ PASS: No markdown wrappers"
    fi

    # Check 6: Starts with div
    if [[ "$html" == "<div style="* ]]; then
        echo "✅ PASS: Starts with <div style="
    else
        echo "❌ FAIL: Does not start with <div style="
        ((errors++))
    fi

    # Check 7: Ends with div
    if [[ "$html" == *"</div>" ]]; then
        echo "✅ PASS: Ends with </div>"
    else
        echo "❌ FAIL: Does not end with </div>"
        ((errors++))
    fi

    echo "═══════════════════════════════════════════════════════════════"

    if [ $errors -eq 0 ]; then
        echo "✅ ALL VALIDATIONS PASSED"
        return 0
    else
        echo "❌ $errors VALIDATION(S) FAILED"
        return 1
    fi
}

# Run validation
validate_output "$HTML"
VALIDATION_RESULT=$?

# Summary
echo ""
echo "📊 ITERATION ${ITERATION} SUMMARY"
echo "   Output file: $OUTPUT_FILE"
echo "   HTML length: ${#HTML} characters"
echo "   Validation: $([ $VALIDATION_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"

exit $VALIDATION_RESULT
```

---

## Success Criteria

### Iteration Success

An iteration is considered successful when:

| Criterion | Validation Method |
|-----------|-------------------|
| ✅ HTML output is valid | No parse errors |
| ✅ Output is single line | No `\n` characters |
| ✅ All styles are inline | No `<style>`, no `class=` |
| ✅ No placeholders remain | No `[X]`, `TBD`, `{var}` |
| ✅ All required sections present | Config-defined sections exist |
| ✅ Element counts match spec | Heatmap: 12 cells, etc. |
| ✅ Visual matches mockup | Manual review or diff |

### Framework Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Average iterations to success | ≤5 | Track per prompt |
| Prompt development time | 70% reduction | Before/after comparison |
| Template adoption rate | 100% | All new prompts use template |
| First-pass validation rate | ≥80% | Automated validation pass |
| Prompt maintainability | Improved | Developer feedback |

---

## Appendix

### A. MEDDIC Component Reference

| Code | Name | Description |
|------|------|-------------|
| M | Metrics | Quantifiable measures of success |
| E | Economic Buyer | Person with budget authority |
| D | Decision Criteria | Formal evaluation criteria |
| D | Decision Process | Steps to make decision |
| I | Identify Pain | Business pain points |
| C | Champion | Internal advocate |

### B. Status Color Reference

| Status | Score Range | Background | Border | Text |
|--------|-------------|------------|--------|------|
| Critical | <50% | #fef2f2 | #c23934 | #b91c1c |
| Warning | 50-74% | #fff8f0 | #dd7a01 | #92400e |
| Good | ≥75% | #f0fdf4 | #2e844a | #166534 |
| Info | N/A | #f0f7ff | #0176d3 | #1d4ed8 |

### C. Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Style block missing | AI skips large CSS | Use inline styles instead |
| 11 heatmap cells | AI counts wrong | Explicit 12-cell template with example |
| Generic month labels | AI uses "Month 1, 2, 3" | Specify actual months (Oct, Nov, Dec) |
| Markdown wrapper | AI adds ```html | Add "NO markdown code blocks" rule |
| Placeholder values | AI uses [X] | Add "NEVER use placeholders" rule |
| Newlines in output | AI formats for readability | Add "ZERO newlines" rule |
| Missing data handling | AI leaves blanks | Specify default/empty state values |

### D. Lessons Learned from MEDDIC Implementation

1. **Inline styles are mandatory** - GPTfy may strip `<style>` blocks in some render contexts
2. **Explicit counts matter** - Always specify exact element counts (e.g., "12 cells")
3. **Negative examples help** - Tell AI what NOT to do (NO markdown, NO emojis)
4. **Single-line requirement** - Must explicitly forbid newlines
5. **Calculation instructions** - Show formulas with examples, not just field names
6. **Default values** - Specify what to show when data is missing
7. **Iteration is expected** - Plan for 3-6 iterations minimum
8. **Study successful outputs** - Analyze working GPTfy responses to learn patterns

### E. Template Section Ownership Matrix

| Section | Owner | Customization | Update Frequency |
|---------|-------|---------------|------------------|
| Section 1: Goal | Customer | High | Per prompt |
| Section 2: Styling | GPTfy Team | Low | Rarely |
| Section 3: Data | Implementation | High | Per prompt |
| Section 4: Guardrails | GPTfy Team | None | Never |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 29, 2024 | GPTfy Team | Initial PRD for Automated Prompt Creation Framework |

---

*This PRD is part of the `Automated-Prompt-Creation` feature branch. For questions, contact the VusionGroup GPTfy team.*

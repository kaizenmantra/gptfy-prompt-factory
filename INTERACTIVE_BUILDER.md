# Interactive Prompt Builder

> **Single source of truth** for the new prompt builder implementation.
> All architecture, decisions, tasks, and progress tracked here.

---

## Current Status

| Version | Status | Description |
|---------|--------|-------------|
| **V1** | ⚠️ Partial | Chat works, but deployed prompts fail in GPTfy (outputs markdown, GPTfy needs HTML) |
| **V2** | 🔴 Not Started | Fix HTML output + add child object data (see V2 Task Queue below) |

**V1 Limitations (discovered during testing):**
1. ❌ Outputs markdown, GPTfy requires single-line HTML with inline styles
2. ❌ Only queries root object, missing child object data (Tasks, Contacts, etc.)
3. ❌ Prompt works in chat, fails when run in GPTfy

**V2 Will Add:**
1. ✓ HTML output generation (GPTfy-compliant)
2. ✓ Child object data fetching (2nd and 3rd level relationships)
3. ✓ Reuse patterns from existing 12-stage pipeline (Stage05-08)

---

## MODEL INSTRUCTIONS (READ THIS FIRST)

**When you start working on this project, follow these rules:**

1. **Read this entire file** to understand the context and architecture
2. **Check the Task Queue below** - find the first task with status `not_started`
3. **Check if the task is assigned to you:**
   - If task says `Sonnet` and you are Sonnet → Work on it
   - If task says `Opus` and you are Opus → Work on it
   - If task is assigned to the OTHER model → **STOP and tell the user**
4. **While working:** Update task status to `in_progress`
5. **When done:** Update task status to `done`, then check next task
6. **If you hit a blocker:** Update status to `blocked` with notes, alert user
7. **If next task is for other model:** Stop and say:
   ```
   ✋ HANDOFF NEEDED
   I've completed [task X]. The next task requires [Opus/Sonnet].
   Please switch models and say "Continue" to proceed.
   ```

**COMMIT AFTER EACH TASK:**
After completing each task (or group of related small tasks), commit your work:
```bash
./scripts/gitcommit.sh "Task X: Brief description of what was done"
```
This ensures work is saved and visible to the other model on handoff.

**DEPLOY TO SALESFORCE:**
When a task involves deploying to Salesforce, use:
```bash
sf project deploy start -o agentictso -d force-app
```
Wait for deployment to complete and check for errors before marking task as done.

**Key files to reference:**
- Reuse: `SchemaHelper.cls`, `AIServiceClient.cls`, `DCMBuilder.cls`
- Create: `PromptBuilderController.cls`, `promptBuilderChat/` LWC

---

## Task Queue

| ID | Task | Model | Status | Blocked By | Notes |
|----|------|-------|--------|------------|-------|
| 1 | Create `PromptBuilderController.cls` scaffold with `initializeSession` method | Sonnet | done | - | Reuse SchemaHelper for schema queries |
| 2 | Create `promptBuilderChat.html` - record selection UI | Sonnet | done | 1 | Object picker, record selector, business context input |
| 3 | Create `promptBuilderChat.js` - wire up controller | Sonnet | done | 1,2 | Call initializeSession, handle responses |
| 4 | Create `promptBuilderChat.css` - basic styling | Sonnet | done | 2 | Keep it simple, Salesforce-like |
| 5 | Deploy Phase 1 to Salesforce and test | Sonnet | done | 1,2,3,4 | `sf project deploy start -o agentictso`, then test in org |
| 6 | **Design self-evaluating prompt template** | Opus | done | 5 | See [Prompt Template Design](#prompt-template-design-task-6) section |
| 7 | Create `PromptExemplars` static resource | Sonnet | done | 6 | Store Deal Coach + Account 360 exemplars |
| 8 | Add `chat` method to controller | Sonnet | done | 6,7 | Build prompt, call AIServiceClient, return response |
| 9 | Add chat UI to LWC (message list, input, send) | Sonnet | done | 8 | Render markdown responses |
| 10 | Deploy Phase 2 to Salesforce and test | Sonnet | done | 7,8,9 | `sf project deploy start -o agentictso`, test chat flow |
| 11 | **Review Phase 2 quality, adjust prompt if needed** | Opus | done | 10 | Fixed follow-up prompts, added Current_Draft__c field |
| 12 | Add `deployPrompt` method to controller | Sonnet | done | 11 | Extract fields, create DCM + Prompt |
| 13 | Add deploy UI (approve button, success message) | Sonnet | done | 12 | Show created record IDs, next steps |
| 14 | Deploy Phase 3 to Salesforce and test | Sonnet | done | 12,13 | **NOTE:** Includes new `Current_Draft__c` field (Task 11). Full deploy + test |
| 15 | **Final review and polish** | Opus | done | 14 | All 15 tasks complete - ready for testing! |

**Status values:** `not_started` | `in_progress` | `done` | `blocked` | `skipped`

**Salesforce Org:** `agentictso` (agentictso@gptfy.com)
**Deploy command:** `sf project deploy start -o agentictso -d force-app`

---

## Quick Reference: When to Use Which Model

| Use Opus | Use Sonnet |
|----------|------------|
| Architecture decisions | Writing code from clear specs |
| Complex reasoning about approach | Implementing defined features |
| Debugging tricky issues | Refactoring existing code |
| Reviewing PRs or designs | Creating tests |
| Exploring unfamiliar territory | Routine scaffolding |
| This document was created with Opus | Most of Phase 1-3 implementation |

**Rule of thumb:**
- If you need to *think*, use Opus
- If you need to *do*, use Sonnet
- When in doubt, start with Sonnet, escalate to Opus if stuck

---

## The Problem We're Solving

The current 12-stage waterfall pipeline produces mediocre output because:
1. **Infrastructure over intelligence** - 12 stages of plumbing, weak prompts
2. **No iteration before deployment** - Can't test until DCM+Prompt created
3. **Rules-heavy, example-light** - Tells LLM what NOT to do, doesn't show what good looks like
4. **Template-first** - Generates HTML structure before validating content quality
5. **DML/Callout limitation** - Feedback loop broken by Salesforce transaction rules

---

## The New Approach

### Core Principles

1. **Content-first, template-later** - Get the analysis right in markdown, then templatize
2. **Interactive, not waterfall** - Chat interface with real-time iteration
3. **Self-evaluating LLM** - Model scores its own output against rubric before presenting
4. **Exemplar-driven** - Show what good looks like, don't just list rules
5. **Vertical slices** - Each phase produces something testable

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: Setup                                                 │
│  User selects: object, 3-5 sample records, business context     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: Interactive Chat (NO DML - iterate freely)            │
│  • System queries actual data from samples                      │
│  • LLM analyzes data, self-evaluates against rubric             │
│  • User reviews markdown output, provides feedback              │
│  • Loop until user approves                                     │
└────────────────────────────┬────────────────────────────────────┘
                             │ [User clicks "Approve"]
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: Deploy (DML transaction)                              │
│  • Convert approved structure to template with merge fields     │
│  • Create DCM + Prompt records                                  │
│  • Return prompt ID for testing                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 4: Test & Style (Separate transaction, optional)         │
│  • User manually tests prompt via GPTfy                         │
│  • Can return later to add HTML styling                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## What We're Reusing

These existing classes work well and should be reused as-is:

| Class | Purpose | Notes |
|-------|---------|-------|
| `SchemaHelper.cls` | Schema introspection, field metadata | Well-tested, has caching |
| `AIServiceClient.cls` | Multi-provider LLM client | Supports Claude, Azure, DeepSeek |
| `DCMBuilder.cls` | Builds Data Context Mapping config | Handles relationship detection |
| `MergeFieldValidator.cls` | Validates merge fields in templates | Useful for Phase 3 |

---

## New Files to Create

```
force-app/main/default/
├── classes/
│   └── PromptBuilderController.cls      # Single controller for all operations
│   └── PromptBuilderController.cls-meta.xml
│
├── lwc/
│   └── promptBuilderChat/               # Main interactive component
│       ├── promptBuilderChat.html
│       ├── promptBuilderChat.js
│       ├── promptBuilderChat.css
│       └── promptBuilderChat.js-meta.xml
│
├── objects/
│   └── PF_Builder_Session__c/           # Session state (optional - could use PF_Run__c)
│
└── staticresources/
    └── PromptExemplars.resource         # Gold standard examples
```

---

## Implementation Phases

### Phase 1: Discovery & Data Fetch
**Goal:** User can select records, system fetches and displays data summary.
**Estimated effort:** 2-3 hours
**Model:** Sonnet (clear specs, straightforward implementation)

**Tasks:**
- [ ] Create `PromptBuilderController.cls` with `initializeSession` method
- [ ] Create `promptBuilderChat.html` - record selection UI
- [ ] Create `promptBuilderChat.js` - wire up controller
- [ ] Test: Select records, see data summary in console

**Controller signature:**
```apex
@AuraEnabled
public static Map<String, Object> initializeSession(
    String rootObject,
    List<Id> sampleRecordIds,
    String businessContext
)
```

---

### Phase 2: Chat Interface + LLM
**Goal:** User can chat with LLM, see markdown output, iterate.
**Estimated effort:** 3-4 hours
**Model:** Sonnet for UI, Opus for prompt engineering

**Tasks:**
- [ ] Add `chat` method to controller
- [ ] Build chat UI in LWC (message list, input, send button)
- [ ] Create self-evaluating prompt template
- [ ] Add exemplars to static resource
- [ ] Create quality rubric
- [ ] Test: Full conversation loop works

**Controller signature:**
```apex
@AuraEnabled
public static Map<String, Object> chat(
    Id sessionId,
    String userMessage
)
```

**Self-Evaluating Prompt Structure:**

The prompt is split into **System Prompt** (static) and **User Prompt** (dynamic).
This design is documented in detail in the [Prompt Template Design](#prompt-template-design-task-6) section below.

---

### Phase 3: Deploy
**Goal:** User clicks "Approve & Deploy" → DCM + Prompt created.
**Estimated effort:** 2-3 hours
**Model:** Sonnet (reusing existing patterns)

**Tasks:**
- [ ] Add `deployPrompt` method to controller
- [ ] Extract field manifest from approved content
- [ ] Reuse DCMBuilder for DCM creation
- [ ] Create Prompt record with AI instructions
- [ ] Add success UI with next steps
- [ ] Test: End-to-end flow, records created

**Controller signature:**
```apex
@AuraEnabled
public static Map<String, Object> deployPrompt(Id sessionId)
```

---

### Phase 4: Styling (Future)
**Goal:** User can return to add HTML styling to deployed prompt.
**Estimated effort:** 4-6 hours
**Model:** Mix - Opus for template strategy, Sonnet for implementation

**Tasks:**
- [ ] (Defer until Phases 1-3 are solid)

---

## Quality Rubric (Full Version)

### 1. Actionable Insights
- **1-3:** Just displays data ("Revenue: $5M")
- **4-6:** Basic interpretation ("Revenue is high")
- **7-8:** Insight + implication ("Revenue grew 20% YoY, expansion opportunity")
- **9-10:** Insight + implication + action ("Revenue grew 20%. Schedule QBR to discuss Enterprise tier upsell.")

### 2. Data Grounding
- **1-3:** Assertions without data
- **4-6:** Some data references
- **7-8:** Most claims backed by specific data
- **9-10:** Every claim tied to specific data with attribution

### 3. Risk Identification
- **1-3:** No risks mentioned
- **4-6:** Obvious risks only ("Deal is overdue")
- **7-8:** Non-obvious risks ("No technical champion - deals without one close 40% less")
- **9-10:** Risks + severity + mitigation path

### 4. Specificity
- **1-3:** Generic ("Follow up soon")
- **4-6:** Somewhat specific ("Follow up this week")
- **7-8:** Specific ("Send ROI calculator by Thursday")
- **9-10:** Specific + contextualized ("Send ROI calculator addressing Q4 budget freeze")

### 5. Executive Tone
- **1-3:** Too technical or casual
- **4-6:** Acceptable but inconsistent
- **7-10:** Appropriate for VP/C-level, business impact focused

### 6. Completeness
For Opportunity: Pipeline health, stakeholders, competitive position, timeline, next steps
For Account: Revenue, pipeline, support health, engagement, contacts, risks, opportunities

---

## Exemplars

### Deal Coach (Opportunity)

```markdown
## Acme Corp - $400K Enterprise Deal

### Deal Health Score: 6/10 (At Risk)

This opportunity is **15 days past the expected close date** with $400K at stake.
While the technical evaluation was positive, we're seeing warning signs that require immediate attention.

### Key Risks

1. **No Executive Sponsor** (HIGH)
   - Our only contact is Sarah Chen (Manager level)
   - Enterprise deals without VP+ sponsorship close 40% less often
   - *Action: Request intro to VP of Operations through Sarah*

2. **Competitor Activity** (MEDIUM)
   - Competitor X mentioned in last meeting notes
   - No formal bake-off scheduled yet
   - *Action: Prepare competitive displacement deck, schedule technical deep-dive*

3. **Budget Timing** (MEDIUM)
   - Q4 budget freeze mentioned
   - Deal may slip to Q1 if not closed by Dec 15
   - *Action: Present 18-month ROI analysis showing payback before Q2*

### Stakeholder Coverage

| Role | Contact | Engagement | Risk |
|------|---------|------------|------|
| Economic Buyer | Unknown | None | HIGH |
| Technical Champion | David Park | Active | Low |
| Day-to-day Contact | Sarah Chen | Active | Low |
| Procurement | Unknown | None | MEDIUM |

**Gap:** No relationship with economic buyer. This must be addressed before final negotiation.

### Recommended Actions (This Week)

1. **Monday:** Ask Sarah for intro to her VP (script: "To ensure executive alignment...")
2. **Wednesday:** Send updated ROI analysis with Q4 budget freeze scenario
3. **Friday:** Schedule technical validation with David + their IT security team

### Pipeline Context

This deal represents 15% of your Q4 quota. Slippage to Q1 would leave you at 85% attainment.
Prioritize this over smaller deals this week.
```

### Account 360

```markdown
## TechCorp Industries - Account Health Report

### Overall Health: 7/10 (Stable with Opportunities)

TechCorp is a $2.4M ARR account with strong product adoption but declining engagement
over the past quarter. Immediate attention needed on support escalations.

### Executive Summary

**The Good:**
- Revenue up 12% YoY ($2.4M ARR)
- 3 products deployed, high usage metrics
- Net Promoter champion (Sarah Chen) actively referring

**The Concerning:**
- No executive contact in 90+ days
- 2 high-priority cases open (oldest: 34 days)
- Pipeline coverage: only 0.5x (risk to renewal)

**Recommended Focus:** Re-establish executive relationship, resolve support backlog before QBR.

### Revenue & Pipeline

| Metric | Value | Trend | Benchmark |
|--------|-------|-------|-----------|
| Current ARR | $2.4M | +12% YoY | Above avg |
| Open Pipeline | $1.2M | -20% QoQ | Below avg |
| Pipeline Coverage | 0.5x | Declining | Target: 1.5x |

**Risk:** Pipeline coverage insufficient for healthy renewal. Need $2.4M+ in pipeline for Q2 renewal.

### Support Health

| Priority | Open | Avg Age | Oldest |
|----------|------|---------|--------|
| High | 2 | 28 days | 34 days |
| Medium | 3 | 12 days | 18 days |
| Low | 1 | 5 days | 5 days |

**Alert:** Two high-priority cases approaching SLA breach (35 days).
Escalate to Support Manager immediately.

### Engagement Timeline

- **Today:** No open meetings scheduled
- **Last Contact:** 32 days ago (email from CSM)
- **Last Executive Meeting:** 94 days ago
- **Last QBR:** 180 days ago

**Risk:** Account going cold. Engagement gap exceeds 30-day threshold.

### Recommended Actions

1. **Immediate:** Escalate 2 high-priority cases to Support Manager
2. **This Week:** Schedule check-in call with Sarah Chen (champion)
3. **Next Week:** Request QBR with VP sponsor
4. **This Quarter:** Build $1.5M+ pipeline through expansion opportunities
```

---

## Prompt Template Design (Task 6)

> **Designed by Opus** - This is the core intellectual work that makes output quality excellent.

### Design Principles

1. **System prompt = Persona + Rules + Rubric + Exemplar** (static, reusable)
2. **User prompt = Context + Data + Conversation** (dynamic, per-request)
3. **Self-evaluation happens internally** - LLM iterates before presenting
4. **Scores shown for transparency** - User sees confidence level
5. **One relevant exemplar** - Don't overwhelm with all examples

### System Prompt Template

```
You are an expert Salesforce business analyst creating insightful analysis for sales and customer success teams. Your outputs should be immediately actionable, data-grounded, and executive-ready.

## YOUR PROCESS (Internal - Do Not Show To User)

Before presenting ANY output, you MUST:

1. Generate an initial draft analysis
2. Score your draft against EACH criterion in the rubric below (be brutally honest)
3. If ANY score is below 7:
   - Identify specifically what's weak
   - Revise that section
   - Re-score
4. Repeat until ALL scores are 7 or higher
5. Only then present your final output

This self-evaluation is MANDATORY. Mediocre output is unacceptable.

## QUALITY RUBRIC

Score each criterion 1-10. Minimum acceptable: 7 for each.

### 1. Actionable Insights (Not Data Regurgitation)
- 1-3: Just displays data ("Revenue: $5M", "Stage: Negotiation")
- 4-6: Basic interpretation ("Revenue is high", "Deal is progressing")
- 7-8: Insight + implication ("Revenue grew 20% YoY, suggesting expansion appetite")
- 9-10: Insight + implication + specific action ("Revenue grew 20% YoY. Schedule QBR this week to discuss Enterprise tier upsell - they're likely hitting plan limits based on usage patterns.")

### 2. Data Grounding (Every Claim Backed By Evidence)
- 1-3: Assertions without data ("This account is healthy")
- 4-6: Some data references ("Revenue is $2M")
- 7-8: Most claims cite specific data points ("Revenue is $2.4M, up 12% from last year's $2.1M")
- 9-10: Every claim tied to specific data with clear attribution ("Based on the 32-day gap since last contact and the 2 escalated cases, this account shows early churn signals")

### 3. Risk Identification (Proactive, Not Obvious)
- 1-3: No risks mentioned
- 4-6: Only obvious risks ("Deal is past close date")
- 7-8: Non-obvious risks with reasoning ("No technical champion identified - enterprise deals without one close 40% less often")
- 9-10: Risks + severity rating + specific mitigation ("No technical champion (HIGH RISK). Mitigation: Ask Sarah to introduce you to their Solutions Architect in tomorrow's call - use the integration discussion as the hook.")

### 4. Specificity (Concrete, Not Generic)
- 1-3: Generic advice ("Follow up soon", "Build relationship")
- 4-6: Somewhat specific ("Follow up this week", "Schedule a call")
- 7-8: Specific with details ("Send the ROI calculator by Thursday COB")
- 9-10: Specific + contextualized + reasoning ("Send the updated ROI calculator by Thursday that addresses their Q4 budget freeze concern - reference the 18-month payback period Sarah mentioned in the June call")

### 5. Executive Tone (Appropriate for VP/C-Level)
- 1-3: Too technical, too casual, or inappropriate
- 4-6: Acceptable but inconsistent tone
- 7-8: Professional, business-focused throughout
- 9-10: Crisp, confident, focuses on business impact and decisions (not activities)

### 6. Completeness (Covers All Relevant Dimensions)
For Opportunities: Deal health, stakeholder coverage, competitive position, timeline risk, pipeline impact, specific next steps
For Accounts: Revenue trend, pipeline coverage, support health, engagement recency, key contacts, risks, expansion opportunities

## OUTPUT FORMAT

Always structure your response as:

```
SELF-EVALUATION (for transparency):
- Actionable Insights: [score]/10
- Data Grounding: [score]/10
- Risk Identification: [score]/10
- Specificity: [score]/10
- Executive Tone: [score]/10
- Completeness: [score]/10
Average: [avg]/10

---

[Your analysis in clean markdown format]
```

## WHAT TO AVOID

- Never say "Based on the data provided" or "According to the information" - just analyze
- Never use placeholder text like "[Insert X here]" or "TBD"
- Never give generic advice that could apply to any deal/account
- Never just list data without interpretation
- Never skip the self-evaluation step
```

### User Prompt Template

The user prompt is constructed dynamically based on:
- First message vs. follow-up
- Root object type (determines which exemplar to include)
- Actual data from sample records

#### First Message Template

```
## WHAT I'M BUILDING

{businessContext}

## EXEMPLAR: What Excellent Output Looks Like

{relevantExemplar}

Note: This exemplar uses different data. Your analysis should follow the same STRUCTURE and QUALITY, but use the actual data provided below.

## ACTUAL DATA TO ANALYZE

### Sample Records ({recordCount} {rootObject} records)

{formattedSampleData}

### Related Data

{formattedChildData}

---

Generate an analysis following the exemplar's structure and quality level. Remember to self-evaluate against the rubric before presenting.
```

#### Follow-Up Message Template

```
## USER FEEDBACK

{userMessage}

## PREVIOUS ANALYSIS

{previousDraft}

---

Revise your analysis based on the feedback above. Self-evaluate the revision against the rubric before presenting.
```

### Data Formatting Guidelines

When formatting sample data for the prompt, follow these rules:

#### For Root Object Records
```
### Record 1: {Name or Primary Identifier}
- **Key Fields:** {Amount}, {Stage}, {CloseDate}, etc.
- **Status:** {relevant status fields}
- **Owner:** {OwnerName}
- **Last Modified:** {LastModifiedDate}

### Record 2: {Name or Primary Identifier}
...
```

#### For Child Objects
```
### Related {ChildObjectLabel} ({count} records)

| {Key Field 1} | {Key Field 2} | {Key Field 3} |
|---------------|---------------|---------------|
| {value} | {value} | {value} |
...
```

### Exemplar Selection Logic

```javascript
// In the controller/helper, select exemplar based on root object:
function selectExemplar(rootObject) {
    switch(rootObject) {
        case 'Opportunity':
            return EXEMPLARS.DEAL_COACH;
        case 'Account':
            return EXEMPLARS.ACCOUNT_360;
        case 'Case':
            return EXEMPLARS.CASE_SUMMARY; // TODO: Create this exemplar
        case 'Lead':
            return EXEMPLARS.LEAD_SCORING; // TODO: Create this exemplar
        default:
            return EXEMPLARS.ACCOUNT_360; // Default to comprehensive view
    }
}
```

### Implementation Notes for Sonnet

**Task 7 (Static Resource):** Store the exemplars in `PromptExemplars.resource` as JSON:
```json
{
    "DEAL_COACH": "## Acme Corp - $400K Enterprise Deal\n\n### Deal Health Score...",
    "ACCOUNT_360": "## TechCorp Industries - Account Health Report\n\n### Overall Health...",
    "SYSTEM_PROMPT": "[The full system prompt template above]"
}
```

**Task 8 (Chat Method):** The `chat` method should:
1. Load the session and previous conversation
2. Load the system prompt from static resource
3. Select the right exemplar based on root object
4. Format the sample data from the session
5. Construct user prompt (first message vs follow-up)
6. Call `AIServiceClient.callAI(systemPrompt, userPrompt, 4096, 1.0)`
7. Store the response in session, update conversation history
8. Return response to LWC

### Token Budget Estimation

| Component | Estimated Tokens |
|-----------|------------------|
| System prompt (rubric, rules) | ~1,200 |
| Exemplar | ~800 |
| Sample data (5 records) | ~1,500 |
| Child data | ~500 |
| Conversation history (3 turns) | ~2,000 |
| **Total Input** | **~6,000** |
| Response (with evaluation) | ~2,000 |
| **Total per call** | **~8,000** |

This is well within Claude's context window. For very large accounts with many child records, consider summarizing rather than including raw data.

---

## Session State Management

Option A: New custom object `PF_Builder_Session__c`
Option B: Reuse existing `PF_Run__c` with new fields

**Recommend Option B** - less schema changes, can compare old vs new approach.

**Fields needed on PF_Run__c:**
- `Session_Mode__c` (picklist): "Interactive" | "Legacy"
- `Conversation_History__c` (long text): JSON array of messages
- `Current_Draft__c` (long text): Current markdown output
- `Approved_Draft__c` (long text): Locked when user approves
- `Field_Manifest__c` (long text): JSON of fields used, by object
- `Sample_Record_Ids__c` (long text): JSON array of 3-5 record IDs

---

## Progress Log

### 2025-01-22 - Project Kickoff (Opus)
- [x] Reviewed existing 12-stage architecture, identified quality issues
- [x] Designed new content-first, interactive approach
- [x] Created feature branch: `feature/interactive-prompt-builder`
- [x] Created this document with architecture, exemplars, rubric
- [x] Created task queue with model assignments
- [x] Phase 1: Discovery & Data Fetch (Tasks 1-5) - DONE by Sonnet
- [ ] Phase 2: Chat Interface + LLM (Tasks 6-11)
- [ ] Phase 3: Deploy (Tasks 12-15)

### 2025-01-22 - Task 6: Self-Evaluating Prompt Design (Opus)
- [x] Designed system prompt with quality rubric (6 dimensions, 1-10 scoring)
- [x] Designed user prompt templates (first message vs follow-up)
- [x] Defined data formatting guidelines for sample records
- [x] Defined exemplar selection logic based on root object
- [x] Documented implementation notes for Sonnet (Tasks 7-8)
- [x] Estimated token budget (~8,000 tokens per call)

### 2025-01-22 - Task 11: Phase 2 Quality Review (Opus)
**Issues Found & Fixed:**
1. **CRITICAL FIX:** Follow-up prompts were broken - didn't include sample data or previous AI response
   - Updated `buildUserPrompt` to accept `previousDraft` and `isFirstMessage` parameters
   - Follow-ups now include: user feedback + previous analysis + data reference
2. **CRITICAL FIX:** Added `Current_Draft__c` field to PF_Run__c to persist AI responses
   - Created field definition (LongTextArea, 131072 chars)
   - `chat` method now saves AI response after each call
3. **Updated method signature:** `buildUserPrompt` now has 8 parameters instead of 6

**Still TODO (for Sonnet in Task 12-13):**
- Add "Approve & Deploy" button to UI (transition to Phase 3) ✓ DONE
- Better markdown rendering (tables don't render properly) - Minor polish
- Loading spinner during chat messages (currently only shows on init) - Minor polish

### 2025-01-22 - Task 15: Final Review (Opus)

**Implementation Complete - All 15 Tasks Done**

**What Was Built:**
1. **Phase 1 (Setup):** Object selection, 3-5 sample records, business context input
2. **Phase 2 (Chat):** Interactive conversation with self-evaluating AI, iteration support
3. **Phase 3 (Deploy):** Creates DCM + Prompt records, shows success with record links

**Quality Assessment:**
- Controller: Clean 3-method API (initializeSession, chat, deployPrompt) ✓
- LWC: Clean phase transitions, proper state management ✓
- Prompt Design: Self-evaluating with 6-dimension rubric ✓
- Dependencies: DCMBuilder, PromptBuilder, SchemaHelper all exist ✓

### 2025-01-22 - V1 Testing & Critical Discovery (Opus)

**Testing Revealed Critical Compatibility Issues:**

**Deployment Fixes Applied:**
1. ✓ Added HTML template default (later discovered this wasn't the root cause)
2. ✓ Fixed Description field length (LLM generates 255-char summary)
3. ✓ Added `generatePromptMetadata` for description + "How it Works" rich text
4. ✓ Fixed prompt command to not include sample analysis output

**Critical Discovery: GPTfy Requires HTML Output**

When testing deployed prompts, GPTfy threw runtime errors. Investigation revealed:
- Our prompts output **markdown** text
- GPTfy expects **single-line HTML** with inline styles
- The 12-stage pipeline complexity exists precisely to generate HTML dashboards

**What GPTfy Actually Needs:**
```
ONE continuous HTML line | NO newlines | Inline styles only | NO <style> tags | NO CSS classes
```

This is a fundamental architecture mismatch. V2 must address this.

**Also Missing: Child Object Data**
- Current implementation only queries root object fields
- Deal Coach needs: OpportunityContactRoles, Tasks, Events, Competitors
- Account 360 needs: Contacts, Opportunities, Cases, Activities

**See V2 Task Queue below for remediation plan.**

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-01-22 | Single markdown file for all docs | Previous approach scattered info across PRD, architecture, roadmap, tasks |
| 2025-01-22 | Reuse PF_Run__c not new object | Less schema changes, can compare approaches |
| 2025-01-22 | Content-first, template-later | Current template-first approach produces mediocre output |
| 2025-01-22 | Self-evaluating LLM prompts | Get quality right before user sees first draft |
| 2025-01-22 | 3-5 sample records | Better understanding of data patterns than single record |
| 2025-01-22 | Task queue with model assignments | Enables Sonnet to work autonomously, hand off to Opus when needed |
| 2025-01-22 | Opus for thinking, Sonnet for doing | Cost/speed optimization - use the right model for the right task |
| 2025-01-22 | **Markdown for iteration, HTML for deploy** | GPTfy requires HTML output, but markdown is better for human review during chat |
| 2025-01-22 | **Hybrid HTML generation (JSON → HTML)** | LLM outputs structured JSON, controller converts to GPTfy-compliant HTML - keeps LLM focused on content |
| 2025-01-22 | **Must include child object data** | Deal Coach needs stakeholders, activities; Account 360 needs contacts, opportunities, cases |
| 2025-01-22 | **Reuse Stage05-08 patterns** | 12-stage pipeline has proven patterns for HTML generation - extract and reuse rather than rebuild |

---

## Open Questions

1. **Exemplar storage:** Static resource (JSON/MD) or custom object?
   - Leaning toward static resource for simplicity

2. **Session persistence:** How long to keep sessions? Auto-cleanup?
   - Probably 7 days, then archive

3. **Multi-user:** Can multiple users build prompts simultaneously?
   - Yes, each gets their own session

---

## GPTfy Output Requirements (Critical for V2)

> **Discovered during V1 testing.** GPTfy has specific HTML rendering requirements that differ from our markdown approach.

### HTML Format Rules

GPTfy prompts must output HTML following these strict rules:

1. **ONE continuous HTML line** - No newlines in the output
2. **All inline styles** - No `<style>` tags, no CSS classes
3. **No markdown** - GPTfy doesn't render markdown, only HTML
4. **Specific structure** - Dashboard-style output with sections

### Template Structure (4 Sections)

GPTfy prompts follow a 4-section template pattern:

| Section | Purpose | Example |
|---------|---------|---------|
| **Goal/Persona** | Define AI role and objective | "You are an expert sales analyst..." |
| **Styling/CSS** | Inline style definitions | Color codes, font sizes, spacing |
| **Data Mapping** | Merge field references | `{{{Account.Name}}}`, `{{{Opportunity.Amount}}}` |
| **Guardrails** | Output constraints | "Do not include PII", "Maximum 500 words" |

### Merge Field Syntax

GPTfy uses triple curly braces for merge fields:
```
{{{Object.FieldName}}}
```

Examples:
- `{{{Account.Name}}}` - Account name
- `{{{Opportunity.Amount}}}` - Opportunity amount
- `{{{Opportunity.StageName}}}` - Current stage

### Standard Styling Patterns

From `docs/PROMPT_TEMPLATE.txt`:
```html
<div style="font-family: Arial, sans-serif; background: #f8fafc; padding: 20px;">
  <h2 style="color: #1e40af; margin: 0 0 16px 0;">{{{Account.Name}}}</h2>
  <div style="background: white; border-radius: 8px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
    <span style="color: #059669; font-weight: bold;">Revenue:</span>
    <span style="color: #374151;">{{{Account.AnnualRevenue}}}</span>
  </div>
</div>
```

### Why This Matters

The 12-stage pipeline exists because:
1. Stage 4-5: Determine which fields to include
2. Stage 6: Build the DCM with field mappings
3. Stage 7: Design HTML template structure
4. Stage 8: Assemble prompt with styling + merge fields

Our simplified approach skipped the HTML templating, which is why GPTfy couldn't render the output.

---

## Child Object Data Fetching (V2 Requirement)

> **Current limitation:** V1 only queries root object fields. For useful analysis, we need related data.

### Data Hierarchy Pattern

```
Root Object (e.g., Opportunity)
├── 1st Level: Direct fields (Amount, Stage, CloseDate)
├── 2nd Level: Parent lookups (Account.Name, Account.Industry)
└── 3rd Level: Child objects (Tasks, Events, OpportunityContactRoles)
```

### Required Child Objects by Root

#### For Opportunity Analysis
| Object | Key Fields | Purpose |
|--------|------------|---------|
| OpportunityContactRole | Contact.Name, Role, IsPrimary | Stakeholder coverage |
| Task | Subject, Status, ActivityDate | Activity history |
| Event | Subject, StartDateTime | Meeting history |
| Competitor | CompetitorName, Strengths, Weaknesses | Competitive landscape |
| OpportunityLineItem | Product2.Name, Quantity, TotalPrice | Product mix |

#### For Account Analysis
| Object | Key Fields | Purpose |
|--------|------------|---------|
| Contact | Name, Title, Email, Phone | Key contacts |
| Opportunity | Name, Amount, StageName, CloseDate | Pipeline view |
| Case | Subject, Status, Priority, CreatedDate | Support health |
| Task | Subject, Status, ActivityDate | Engagement history |
| Contract | Status, StartDate, EndDate | Contract status |

### Existing Implementation Reference

The step wizard in the existing pipeline handles child object navigation. Key classes:

- **`SchemaHelper.cls`** - Already has `getChildRelationships(objectName)` method
- **`Stage05_FieldSelection.cls`** - Handles related object field selection
- **`DCMBuilder.cls`** - Creates field mappings for parent/child relationships

### Proposed Data Fetching Architecture

```apex
// In PromptBuilderController.initializeSession()

// 1. Get root object fields (existing)
Map<String, Object> rootFields = SchemaHelper.getFieldsForObject(rootObject);

// 2. Get parent relationships (2nd level)
Map<String, Schema.SObjectField> parentFields = getParentLookups(rootObject);

// 3. Get child relationships (3rd level)
List<Schema.ChildRelationship> children = SchemaHelper.getChildRelationships(rootObject);

// 4. Query sample data with relationships
String soql = buildRelationshipQuery(rootObject, sampleRecordIds, parentFields, children);
List<SObject> records = Database.query(soql);

// 5. Format for LLM context
Map<String, Object> formattedData = formatRecordsWithRelationships(records);
```

### SOQL Query Pattern

```sql
SELECT Id, Name, Amount, StageName, CloseDate,
       Account.Name, Account.Industry, Account.AnnualRevenue,
       (SELECT Contact.Name, Role, IsPrimary FROM OpportunityContactRoles),
       (SELECT Subject, Status, ActivityDate FROM Tasks ORDER BY ActivityDate DESC LIMIT 10),
       (SELECT Subject, StartDateTime FROM Events ORDER BY StartDateTime DESC LIMIT 5)
FROM Opportunity
WHERE Id IN :sampleRecordIds
```

---

## V2 Task Queue

> **Goal:** Make deployed prompts work in GPTfy by outputting HTML and including child object data.

| ID | Task | Model | Status | Blocked By | Notes |
|----|------|-------|--------|------------|-------|
| 16 | **Design HTML output architecture** | Opus | done | - | See [Task 16 Details](#task-16-html-output-architecture-opus---complete) |
| 16a | **UI Redesign: Split-screen layout** | Sonnet | done | - | Fixed alignment bug + implemented 75/25 split layout |
| 17 | Add child object relationship detection to initializeSession | Sonnet | done | - | Prioritizes top 3-5 relationships per object type |
| 18 | Build SOQL query with parent/child relationships | Sonnet | not_started | 17 | Query 2nd/3rd level data |
| 19 | Format relationship data for LLM context | Sonnet | not_started | 18 | Tables for child objects in prompt |
| 20 | **Design HTML template generation strategy** | Opus | done | 16 | Merged into Task 16 - see conversion prompt approach |
| 21 | Update system prompt for HTML output | Sonnet | not_started | 16 | Add `convertToHTML()` method using conversion prompt |
| 22 | Create HTML exemplars (Deal Coach, Account 360) | Sonnet | not_started | 16 | Convert markdown exemplars to HTML with merge fields |
| 23 | Update deployPrompt to handle HTML output | Sonnet | not_started | 21,22 | Call conversion, validate, create DCM+Prompt |
| 24 | Add HTML preview in chat UI | Sonnet | not_started | 21 | Render HTML safely in LWC |
| 25 | Deploy V2 to Salesforce and test | Sonnet | not_started | 17-24 | End-to-end GPTfy execution test |
| 26 | **V2 Quality Review** | Opus | not_started | 25 | Verify GPTfy renders output correctly |

### Task Details

#### Task 16: HTML Output Architecture (Opus) - COMPLETE

> **Designed by Opus** - Architecture decision for GPTfy-compliant output.

**Key Questions Answered:**

1. **Should LLM output raw HTML or structured JSON?**
   → **Keep markdown during chat, convert to HTML on deploy**

2. **How do we maintain the self-evaluation loop with HTML output?**
   → **Self-evaluation stays in markdown** - it's about content quality, not format

3. **Should we keep markdown for iteration, then convert to HTML on deploy?**
   → **YES** - This is the recommended architecture

**Architecture Decision: Markdown-to-HTML Conversion Pipeline**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: Chat (Markdown Focus)                                         │
│                                                                          │
│  User ←→ LLM (Self-Evaluating)                                          │
│           │                                                              │
│           ↓                                                              │
│  Markdown Output with Quality Rubric                                     │
│  - Actionable insights (not data display)                               │
│  - Data-grounded analysis                                                │
│  - Risk identification                                                   │
│  - Executive tone                                                        │
│                                                                          │
│  ✓ Human readable                                                        │
│  ✓ Easy to iterate                                                       │
│  ✓ Focus on CONTENT QUALITY                                              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ [User clicks "Approve & Deploy"]
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 3a: Extract Field Manifest                                        │
│                                                                          │
│  Parse approved markdown to identify:                                    │
│  - Data values mentioned (e.g., "$400K", "Acme Corp")                   │
│  - Map to DCM fields (e.g., {{{Opportunity.Amount}}}, {{{Account.Name}}} │
│  - Build field whitelist for validation                                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 3b: HTML Conversion (Separate LLM Call)                           │
│                                                                          │
│  Conversion Prompt includes:                                             │
│  - Approved markdown structure                                           │
│  - Field whitelist (only allowed fields)                                 │
│  - GPTfy HTML requirements:                                              │
│    • Single line, no newlines                                           │
│    • Inline styles only (no CSS classes)                                │
│    • No <style> or <script> tags                                        │
│    • Merge fields as {{{Object.Field}}}                                 │
│  - Inline style patterns (from PF_UIPatterns)                           │
│  - Color scheme (Salesforce brand)                                       │
│  - Pattern guidance (Account 360, Deal Coach layouts)                   │
│                                                                          │
│  Output: Single-line HTML with merge fields                              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 3c: Validation & DCM Creation                                     │
│                                                                          │
│  1. Validate merge fields against whitelist                              │
│  2. Sanitize HTML (remove scripts, enforce single line)                  │
│  3. Create DCM with field mappings                                       │
│  4. Create Prompt with HTML template as Prompt_Command__c                │
└─────────────────────────────────────────────────────────────────────────┘
```

**Why This Architecture?**

| Concern | Markdown Phase | HTML Conversion Phase |
|---------|---------------|----------------------|
| Focus | Content quality, insights, analysis | Format compliance, merge fields |
| LLM skill | Analytical thinking, business context | Template formatting, syntax |
| Iteration | Fast, human-readable | One-time conversion |
| Validation | Self-evaluation rubric | Field whitelist, HTML safety |

**Reusable Components from Stage07_TemplateDesign.cls:**

1. **`buildFieldWhitelist()`** - Already validates fields against schema
2. **`getColorSchemePrompt()`** - Returns Salesforce brand colors
3. **`getStylePatternsPrompt()`** - Returns inline style patterns
4. **`getPatternGuidance()`** - Returns layout guidance for Account, Opportunity, etc.
5. **`validateHTMLSafety()`** - Checks for scripts, classes, line breaks
6. **`sanitizeHTML()`** - Removes disallowed elements
7. **`removeEmojis()`** - Strips emoji characters

**Conversion Prompt Template:**

```
You are converting approved analysis content into a GPTfy-compatible HTML template.

=== APPROVED CONTENT (Markdown) ===
{approvedMarkdown}

=== FIELD WHITELIST (Only these fields are available) ===
{fieldWhitelistFormatted}

=== GPTfy HTML REQUIREMENTS ===
1. Output as ONE continuous line - NO line breaks
2. Use ONLY inline styles (style="...") - NO class="..." attributes
3. NO <style> blocks or CSS classes
4. NO <script> tags or event handlers
5. Start with <div style=" and end with </div>

=== MERGE FIELD SYNTAX ===
- Root object fields: {{{FieldName}}}
- Lookup fields: {{{Relationship.FieldName}}}
- Child collections: {{#ChildCollection}}...{{/ChildCollection}}
- Empty check: {{^ChildCollection}}No items{{/ChildCollection}}

=== INLINE STYLE PATTERNS (copy exactly) ===
{inlineStylePatterns}

=== COLOR SCHEME ===
{colorScheme}

=== LAYOUT PATTERN ===
{patternGuidance}

TASK:
Convert the approved markdown content into a single-line HTML template.
Replace specific data values with appropriate merge fields from the whitelist.
Use the style patterns and colors provided.

Output ONLY raw HTML starting with <div - no explanation:
```

**Implementation Notes for Sonnet (Tasks 21-23):**

1. **Task 21 (Update system prompt):**
   - No changes needed to chat phase prompts
   - Add new `convertToHTML()` method to controller
   - Use conversion prompt template above

2. **Task 22 (Create HTML exemplars):**
   - Convert existing markdown exemplars to HTML format
   - These are used as examples in conversion prompt
   - Include merge field examples

3. **Task 23 (Update deployPrompt):**
   - Add HTML conversion step before DCM/Prompt creation
   - Call conversion LLM with approved markdown
   - Validate output with `validateHTMLSafety()`
   - Store HTML template in `ccai__Prompt_Command__c`

#### Task 20: HTML Template Generation - MERGED INTO TASK 16

This was merged into the comprehensive architecture above. The "conversion prompt" approach (Phase 3b) handles template generation.

**Key Decision:** LLM-to-LLM conversion rather than JSON intermediate format.

Why not JSON intermediate?
- Markdown → JSON → HTML adds complexity
- LLM can directly understand markdown structure
- Stage07 already proves LLM can output valid HTML
- Simpler debugging (can see markdown and final HTML)

---

## UI Redesign: Split-Screen Layout

> **Task 16a** - Fix alignment issues and implement split-screen layout for better UX.

### Current Issues

1. **Alignment bug:** Root Object (combobox) and Sample Record IDs (input) fields are not vertically aligned
   - Cause: `lightning-combobox` has built-in label, while Record IDs uses custom `div` wrapper
   - Fix: Use consistent form element structure

2. **Sequential layout:** Chat and content are stacked vertically, requiring scrolling

### New Layout Design

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Interactive Prompt Builder                                          [Header]
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────┐  ┌──────────────────────────┐ │
│  │                                         │  │                          │ │
│  │  MAIN CONTENT AREA (75%)                │  │  CHAT PANEL (25%)        │ │
│  │                                         │  │                          │ │
│  │  Phase 1: Setup Form                    │  │  [Chat messages scroll   │ │
│  │  - Root Object    [combobox        ]    │  │   area - grows with      │ │
│  │  - Record IDs     [input           ]    │  │   conversation]          │ │
│  │  - Business       [textarea        ]    │  │                          │ │
│  │    Context                              │  │  User: ...               │ │
│  │                                         │  │  AI: ...                 │ │
│  │  [Initialize Session]                   │  │  User: ...               │ │
│  │                                         │  │  AI: ...                 │ │
│  │  ─────────────────────────────────────  │  │                          │ │
│  │                                         │  │                          │ │
│  │  Phase 2: Markdown Output               │  ├──────────────────────────┤ │
│  │  (after initialization)                 │  │ [Type message...]   [>]  │ │
│  │                                         │  │ [Start Analysis]         │ │
│  │  ## Deal Health: 7/10                   │  └──────────────────────────┘ │
│  │  ### Key Risks                          │                               │
│  │  - No executive sponsor (HIGH)          │                               │
│  │  - Competitor activity (MEDIUM)         │                               │
│  │  ...                                    │                               │
│  │                                         │                               │
│  │  [scrollable markdown preview]          │                               │
│  │                                         │                               │
│  └─────────────────────────────────────────┘                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┤
│  │  Phase 3: Deploy                                                        │
│  │  Prompt Name: [________________]  [Approve & Deploy]                    │
│  └─────────────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────┘
```

### Layout Behavior

| Phase | Left Panel (75%) | Right Panel (25%) |
|-------|------------------|-------------------|
| **Setup** | Setup form (object, records, context) | Empty or instructions |
| **Initialized** | Session info + Markdown output (scrollable) | Chat window with "Start Analysis" |
| **Chatting** | Latest AI response (scrollable) | Chat history + input |
| **Deploy** | Markdown preview | Chat + Deploy section |

### CSS Implementation

```css
/* Split Screen Container */
.split-container {
    display: flex;
    gap: 1rem;
    min-height: calc(100vh - 120px);
}

/* Main Content Panel (75%) */
.main-panel {
    flex: 3;
    display: flex;
    flex-direction: column;
}

/* Chat Panel (25%) */
.chat-panel {
    flex: 1;
    min-width: 300px;
    max-width: 400px;
    display: flex;
    flex-direction: column;
    background: #fff;
    border-radius: 0.25rem;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* Chat panel sections */
.chat-header {
    padding: 0.75rem;
    border-bottom: 1px solid #e0e0e0;
    font-weight: 600;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 0.75rem;
}

.chat-input {
    padding: 0.75rem;
    border-top: 1px solid #e0e0e0;
}

/* Markdown output area */
.markdown-output {
    flex: 1;
    overflow-y: auto;
    background: #fff;
    padding: 1rem;
    border-radius: 0.25rem;
}

/* Fix form alignment */
.form-row {
    display: flex;
    gap: 1rem;
    align-items: flex-end; /* Align inputs at bottom */
}

.form-field {
    flex: 1;
}

/* Mobile: Stack vertically */
@media (max-width: 1024px) {
    .split-container {
        flex-direction: column;
    }

    .chat-panel {
        max-width: none;
        max-height: 400px;
    }
}
```

### HTML Structure Changes

```html
<!-- After session initialized -->
<div class="split-container">
    <!-- Left: Main Content -->
    <div class="main-panel">
        <!-- Session Info Card -->
        <div class="slds-card">...</div>

        <!-- Markdown Output (scrollable) -->
        <div class="markdown-output">
            <lightning-formatted-rich-text value={latestAIResponse}>
            </lightning-formatted-rich-text>
        </div>

        <!-- Deploy Section -->
        <div class="slds-card">...</div>
    </div>

    <!-- Right: Chat Panel -->
    <div class="chat-panel">
        <div class="chat-header">
            <lightning-icon icon-name="utility:comments" size="x-small"></lightning-icon>
            Chat
        </div>
        <div class="chat-messages">
            <!-- All messages scroll here -->
        </div>
        <div class="chat-input">
            <lightning-textarea ...></lightning-textarea>
            <lightning-button label="Send" ...></lightning-button>
        </div>
    </div>
</div>
```

### Key UX Improvements

1. **Side-by-side view:** User sees output and chat simultaneously
2. **Scrollable output:** Long markdown responses don't push chat off screen
3. **Persistent chat:** Chat input always visible for quick iteration
4. **Clear separation:** Content vs conversation clearly delineated
5. **Responsive:** Stacks on mobile/tablet

### Implementation Notes for Sonnet

1. **Fix alignment first** (quick win):
   - Change Record IDs to use `lightning-input` with `label` attribute
   - Remove custom div wrapper
   - Both fields will align automatically

2. **Split layout** (after alignment):
   - Add `split-container` wrapper after session initialization
   - Move chat UI to right panel
   - Keep markdown in left panel
   - Add CSS for flex layout

3. **State management**:
   - `latestAIResponse` - Shows in main panel
   - `messages` array - Shows in chat panel (scrollable history)
   - May need to track which message is "selected" for main display

---

## Integration with Existing Pipeline

### Reusable Components from 12-Stage Pipeline

| Stage | Class | What We Can Reuse |
|-------|-------|-------------------|
| Stage 5 | `Stage05_FieldSelection.cls` | Related object navigation logic |
| Stage 6 | `Stage06_ConfigurationValidation.cls` | Field validation patterns |
| Stage 7 | `Stage07_TemplateDesign.cls` | HTML template structure patterns |
| Stage 8 | `Stage08_PromptAssembly.cls` | Prompt assembly with guardrails |

### Key Code Patterns to Extract

**From Stage05 - Child Object Navigation:**
```apex
// Get child relationships for an object
public static List<ChildObjectInfo> getChildObjects(String parentObject) {
    List<ChildObjectInfo> children = new List<ChildObjectInfo>();
    Schema.DescribeSObjectResult descResult = Schema.getGlobalDescribe()
        .get(parentObject).getDescribe();

    for (Schema.ChildRelationship rel : descResult.getChildRelationships()) {
        if (rel.getRelationshipName() != null) {
            children.add(new ChildObjectInfo(
                rel.getChildSObject().getDescribe().getName(),
                rel.getRelationshipName(),
                rel.getField().getDescribe().getName()
            ));
        }
    }
    return children;
}
```

**From Stage07 - HTML Template Pattern:**
```apex
// Standard GPTfy card component
private static String buildCard(String title, String content) {
    return '<div style="background: white; border-radius: 8px; padding: 16px; ' +
           'margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">' +
           '<h3 style="color: #1e40af; margin: 0 0 8px 0;">' + title + '</h3>' +
           '<div style="color: #374151;">' + content + '</div>' +
           '</div>';
}
```

---

## Files Changed This Branch

```
A  INTERACTIVE_BUILDER.md                           # This file
A  force-app/main/default/classes/PromptBuilderController.cls
A  force-app/main/default/classes/PromptBuilderController.cls-meta.xml
A  force-app/main/default/lwc/promptBuilderChat/promptBuilderChat.html
A  force-app/main/default/lwc/promptBuilderChat/promptBuilderChat.js
A  force-app/main/default/lwc/promptBuilderChat/promptBuilderChat.css
A  force-app/main/default/lwc/promptBuilderChat/promptBuilderChat.js-meta.xml
A  force-app/main/default/staticresources/PromptExemplars.resource
A  force-app/main/default/staticresources/PromptExemplars.resource-meta.xml
```

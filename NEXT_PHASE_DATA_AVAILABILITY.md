# Next Phase: Data Availability & Context Enhancement

**Priority**: HIGH  
**Status**: Ready for Implementation  
**Estimated Effort**: 1-2 hours  
**Branch**: `feature/data-availability-context`  

---

## Problem Statement

**Discovery Date**: January 22, 2026  
**Issue**: Builder prompts (Evidence Binding, Next Best Action) inject successfully but AI doesn't follow them  

### Root Cause

Builders tell the AI to:
- ✅ "Use actual names like Sarah Johnson (CFO), not 'the CFO'"
- ✅ "Calculate days since last activity"
- ✅ "Reference specific task subjects and due dates"

But the AI doesn't know:
- ❌ What Contact.Name fields exist in the template
- ❌ How to reference them (`{{{Contact.Name}}}`)
- ❌ What fields are available for calculation

**Current Output Example** (Generic):
```
"Schedule a follow-up meeting with the CFO to discuss pricing"
```

**Desired Output** (Specific):
```
"Schedule pricing review with Sarah Johnson (CFO) by Jan 27 - 
CFO Meeting already scheduled but ROI deck not prepared (Task 'Prepare ROI Analysis' 7 days overdue)"
```

---

## Solution: Data Availability Section

Add a **DATA AVAILABILITY** section to `Stage08_PromptAssembly.buildAIInstructions()` that explicitly lists:

1. **Available merge fields** from the HTML template
2. **How to reference them** in AI output
3. **Enforcement rules** for using specific data

### Implementation Location

**File**: `force-app/main/default/classes/Stage08_PromptAssembly.cls`  
**Method**: `buildAIInstructions()`  
**Position**: **BEFORE builder injection** (before Quality Rules, Patterns, etc.)  
**Line**: ~376 (after ANALYSIS REQUIREMENTS section)

---

## Detailed Implementation Plan

### Phase 1: Add Data Availability Section (30 min)

**Insert this section in `buildAIInstructions()` after line 375**:

```apex
// === DATA AVAILABILITY (CRITICAL FOR BUILDER COMPLIANCE) ===
instructions += '=== DATA AVAILABLE FOR ANALYSIS ===\n\n';
instructions += 'The template below contains merge fields that will be replaced with real Salesforce data.\n';
instructions += 'You MUST use these specific field references in your analysis and recommendations.\n\n';

instructions += 'CRITICAL ENFORCEMENT RULES:\n';
instructions += '1. BEFORE writing recommendations, mentally enumerate all available Contact.Name values\n';
instructions += '2. ALWAYS use actual {{{Contact.Name}}} in recommendations, NEVER "the CFO" or "the champion"\n';
instructions += '3. ALWAYS calculate days between dates (e.g., "CloseDate was 22 days ago (12/31/2025)")\n';
instructions += '4. ALWAYS reference specific {{{Task.Subject}}} when mentioning tasks\n';
instructions += '5. NEVER say "Follow up with stakeholder" - use "{{{Contact.Name}}} ({{{Role}}})" format\n\n';

// Add field mapping based on rootObject
if (rootObject == 'Opportunity') {
    instructions += buildOpportunityFieldMapping();
} else if (rootObject == 'Account') {
    instructions += buildAccountFieldMapping();
} else if (rootObject == 'Case') {
    instructions += buildCaseFieldMapping();
}

instructions += '\n\n';
```

### Phase 2: Field Mapping Methods (30 min)

Create helper methods to generate field mappings:

```apex
private String buildOpportunityFieldMapping() {
    String mapping = 'OPPORTUNITY FIELDS (direct reference):\n';
    mapping += '- {{{Name}}} - Opportunity name\n';
    mapping += '- {{{StageName}}} - Current stage\n';
    mapping += '- {{{CloseDate}}} - Target close date (ALWAYS calculate days from TODAY)\n';
    mapping += '- {{{Amount}}} - Deal value\n';
    mapping += '- {{{Probability}}} - Win probability %\n';
    mapping += '- {{{Description}}} - Deal context\n';
    mapping += '- {{{NextStep}}} - Next step description\n\n';
    
    mapping += 'CONTACT ROLES (loop: {{#OpportunityContactRole}}...{{/OpportunityContactRole}}):\n';
    mapping += '- {{{Contact.Name}}} - FULL NAME (USE THIS in recommendations!)\n';
    mapping += '- {{{Role}}} - Role title (e.g., "Economic Buyer", "Champion")\n';
    mapping += '- {{{IsPrimary}}} - Primary contact flag\n';
    mapping += 'EXAMPLE: "Contact Sarah Johnson (CFO)" NOT "Contact the CFO"\n\n';
    
    mapping += 'TASKS (loop: {{#Task}}...{{/Task}}):\n';
    mapping += '- {{{Subject}}} - Task subject (REFERENCE THIS exactly!)\n';
    mapping += '- {{{ActivityDate}}} - Due date (CALCULATE days overdue!)\n';
    mapping += '- {{{Status}}} - Status (e.g., "Completed", "Not Started")\n';
    mapping += 'EXAMPLE: "Task \'Send ROI Deck\' is 7 days overdue (Due: 01/15/2026)"\n\n';
    
    mapping += 'EVENTS (loop: {{#Event}}...{{/Event}}):\n';
    mapping += '- {{{Subject}}} - Meeting subject\n';
    mapping += '- {{{StartDateTime}}} - Meeting date/time\n';
    mapping += '- {{{Who.Name}}} - Attendee name\n\n';
    
    mapping += 'DATE CALCULATIONS REQUIRED:\n';
    mapping += '- If CloseDate < TODAY: "Close date was X days ago (OVERDUE)"\n';
    mapping += '- If Task.ActivityDate < TODAY: "Task is X days overdue"\n';
    mapping += '- If no activity in 14+ days: "No engagement in X days (last: date)"\n';
    
    return mapping;
}

private String buildAccountFieldMapping() {
    String mapping = 'ACCOUNT FIELDS (direct reference):\n';
    mapping += '- {{{Name}}} - Account name\n';
    mapping += '- {{{Industry}}} - Industry\n';
    mapping += '- {{{AnnualRevenue}}} - Annual revenue\n';
    mapping += '- {{{NumberOfEmployees}}} - Employee count\n\n';
    
    mapping += 'CONTACTS (loop: {{#Contact}}...{{/Contact}}):\n';
    mapping += '- {{{Name}}} - Contact full name (USE THIS!)\n';
    mapping += '- {{{Title}}} - Job title\n';
    mapping += '- {{{Email}}} - Email address\n\n';
    
    mapping += 'OPPORTUNITIES (loop: {{#Opportunity}}...{{/Opportunity}}):\n';
    mapping += '- {{{Name}}} - Opportunity name\n';
    mapping += '- {{{StageName}}} - Stage\n';
    mapping += '- {{{Amount}}} - Deal value\n';
    mapping += '- {{{CloseDate}}} - Close date (CALCULATE!)\n';
    
    return mapping;
}

private String buildCaseFieldMapping() {
    String mapping = 'CASE FIELDS (direct reference):\n';
    mapping += '- {{{CaseNumber}}} - Case number\n';
    mapping += '- {{{Subject}}} - Case subject\n';
    mapping += '- {{{Status}}} - Current status\n';
    mapping += '- {{{Priority}}} - Priority level\n';
    mapping += '- {{{CreatedDate}}} - Created date (CALCULATE age!)\n\n';
    
    mapping += 'CASE COMMENTS (loop: {{#CaseComment}}...{{/CaseComment}}):\n';
    mapping += '- {{{CommentBody}}} - Comment text\n';
    mapping += '- {{{CreatedBy.Name}}} - Author name\n';
    mapping += '- {{{CreatedDate}}} - Comment date\n';
    
    return mapping;
}
```

### Phase 3: Dynamic Field Extraction (Advanced - 1 hour)

**Future Enhancement**: Automatically extract available merge fields from HTML template:

```apex
private String buildDynamicFieldMapping(String htmlTemplate, String rootObject) {
    // Parse template to find all {{{FieldName}}} patterns
    // Group by object (root vs related)
    // Generate field mapping automatically
    // This ensures AI knows EXACTLY what's available
}
```

---

## Phase 2: Missing Builder Patterns (1-2 hours)

Extract these patterns from Phase 0B MEDDIC work and create as Builder Prompts:

### 1. Timeline Analysis Pattern

**Category**: Pattern  
**Purpose**: Force temporal calculations and velocity analysis  

**Content**:
```
=== TIMELINE ANALYSIS PATTERN ===

REQUIRED CALCULATIONS:
1. Days Since Close Date:
   - If CloseDate < TODAY: "Close date was X days ago (OVERDUE)"
   - If CloseDate > TODAY: "Closes in X days"

2. Days Since Last Activity:
   - Find most recent Task.ActivityDate or Event.StartDateTime
   - Calculate: "Last activity X days ago (Subject: {{{Subject}}})"
   - If > 14 days: FLAG as "Going Cold"

3. Stage Duration:
   - If StageName + LastModifiedDate available
   - Calculate: "In {{{StageName}}} for X days"
   - Compare to average stage duration

4. Task Aging:
   - For each Task where ActivityDate < TODAY AND Status != 'Completed'
   - Report: "Task '{{{Subject}}}' is X days overdue (Due: {{{ActivityDate}}})"

OUTPUT FORMAT:
⏰ Timeline Status
- Close Date: [Status + Days calculation]
- Last Activity: [X days ago with subject]
- Current Stage: [Stage name + duration]
- Overdue Tasks: [Count + specifics]
```

### 2. MEDDIC Scoring Pattern

**Category**: Pattern  
**Purpose**: Structured deal qualification framework  

**Content** (extracted from `docs/pattern-meddic/ENHANCED_PROMPT.md`):
```
=== MEDDIC SCORING PATTERN ===

For each MEDDIC element, provide:
- Score (0-100)
- Status: STRONG (76-100) | PROGRESSING (51-75) | AT RISK (26-50) | MISSING (0-25)
- Evidence: Cite specific field values
- Gaps: What's missing
- Actions: Next steps with WHO/WHAT/WHEN

[Include full MEDDIC framework from meddic-analysis.md]
```

### 3. Stakeholder Coverage Pattern

**Category**: Pattern  
**Purpose**: Analyze contact roles and influence  

**Content**:
```
=== STAKEHOLDER COVERAGE PATTERN ===

REQUIRED ANALYSIS:
1. Enumerate all contacts with roles
2. Identify missing key roles (Economic Buyer, Champion, Decision Maker)
3. Calculate engagement frequency per contact
4. Flag single-threading risk

OUTPUT FORMAT:
👥 Stakeholder Coverage
- Economic Buyer: [Name + last contact date OR "MISSING - CRITICAL"]
- Champion: [Name + engagement frequency OR "MISSING - HIGH RISK"]
- Decision Maker: [Name + validation status]
- Technical Buyer: [Name or "Not Identified"]

GAPS:
- [List missing roles with priority]

ENGAGEMENT RISK:
- Single-threaded: [Yes/No + contact name]
- Going cold: [Contacts with 14+ days no contact]
```

---

## Testing Plan

### Test 1: Name Usage (5 min)

**Input**: Opportunity with Contact Role "John Smith (CFO)"  
**Expected**: "Schedule pricing call with John Smith (CFO) by Jan 27"  
**NOT**: "Schedule call with the CFO"  

### Test 2: Date Calculations (5 min)

**Input**: CloseDate = 12/31/2025 (22 days ago)  
**Expected**: "Deal is 22 days overdue (Close Date: 12/31/2025)"  
**NOT**: "Close date is in the past"  

### Test 3: Task Specificity (5 min)

**Input**: Task "Send ROI Deck", Due 01/15/2026, Status "Not Started"  
**Expected**: "Task 'Send ROI Deck' is 7 days overdue (Due: 01/15/2026)"  
**NOT**: "Follow up on pending tasks"  

---

## Deployment Strategy

### Recommended Approach: New Feature Branch

**YES** - This is the right time for a release and new branch:

**Reasons**:
1. ✅ **Current branch is stable** - Builders inject successfully (16KB+ content)
2. ✅ **Core architecture complete** - Stage pipeline works, logging deployed
3. ✅ **Clear phase boundary** - Moving from "infrastructure" to "intelligence"
4. ✅ **Testable milestone** - Can release v1.0 with working builder injection
5. ✅ **Data availability is a new feature** - Not a bug fix, it's enhancement

**Release Plan**:
```
Current: feature/prompt-quality-improvements
  → Merge to main
  → Tag as v1.0-builder-architecture
  → Deploy to production org

Next: feature/data-availability-context
  → Implement DATA AVAILABILITY section
  → Create missing builder patterns
  → Test prompt quality improvements
```

### NOT Recommended: Continue Current Branch

**Why not**:
- Current branch name is about "prompt quality" (done)
- Risk mixing infrastructure changes with intelligence features
- Harder to rollback if data availability changes break something
- Loses clear commit history

---

## Success Metrics

**Before** (Current State):
- ❌ Generic: "Contact the CFO"
- ❌ Vague: "Follow up soon"
- ❌ No calculations: "Close date in the past"

**After** (Target State):
- ✅ Specific: "Contact Sarah Johnson (CFO)"
- ✅ Actionable: "Schedule by Jan 27 (CFO Meeting already booked)"
- ✅ Calculated: "Deal 22 days overdue, last activity 16 days ago"
- ✅ Evidence-based: "Task 'Send ROI Deck' 7 days overdue"

---

## Files to Modify

### Core Changes
- `force-app/main/default/classes/Stage08_PromptAssembly.cls`
  - Add `buildOpportunityFieldMapping()`
  - Add `buildAccountFieldMapping()`
  - Add `buildCaseFieldMapping()`
  - Insert DATA AVAILABILITY section in `buildAIInstructions()`

### New Builders (Create via REST API or UI)
- Timeline Analysis Pattern (Category: Pattern)
- MEDDIC Scoring Pattern (Category: Pattern)
- Stakeholder Coverage Pattern (Category: Pattern)

### Documentation
- Update `docs/quality-rules/IMPLEMENTATION_ROADMAP.md`
- Create test cases in `tests/mvp/`

---

## Estimated Timeline

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1 | Create new feature branch | 5 min | Current branch merged to main |
| 2 | Add DATA AVAILABILITY section | 30 min | None |
| 3 | Create field mapping methods | 30 min | Phase 2 |
| 4 | Deploy to org | 5 min | Phase 3 |
| 5 | Test with existing prompts | 15 min | Phase 4 |
| 6 | Extract Timeline pattern | 20 min | None (parallel) |
| 7 | Extract MEDDIC pattern | 20 min | None (parallel) |
| 8 | Create builder records | 15 min | Phase 6-7 |
| 9 | End-to-end test | 15 min | All |
| **TOTAL** | | **2h 35min** | |

---

## Risk Mitigation

**Risk**: DATA AVAILABILITY section too long (exceeds token limits)  
**Mitigation**: Make field mappings concise, focus on most-used fields

**Risk**: AI still ignores specific names  
**Mitigation**: Add ENFORCEMENT RULES at top with examples and counter-examples

**Risk**: Template doesn't have Contact.Name field  
**Mitigation**: Parse template first to only show available fields

---

## References

- Phase 0B MEDDIC Work: `docs/pattern-meddic/ENHANCED_PROMPT.md`
- Evidence Binding: `docs/quality-rules/evidence_binding_v2.md`
- Next Best Action: `docs/quality-rules/next_best_action_pattern.md`
- Current victory: `VICTORY.md` (builders inject 16,534 chars)

---

## Approval Required

- [ ] User approves release strategy (v1.0 + new branch)
- [ ] User approves implementation approach (DATA AVAILABILITY section)
- [ ] User approves timeline (2-3 hours)
- [ ] User wants to extract missing builders from Phase 0B

---

**Next Command After Approval**:
```bash
# Merge and release current branch
git checkout main
git merge feature/prompt-quality-improvements
git tag -a v1.0-builder-architecture -m "Builder injection working - 16KB+ content"
git push origin main --tags

# Create new feature branch
git checkout -b feature/data-availability-context
```

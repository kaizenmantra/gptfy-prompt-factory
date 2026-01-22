# Handoff Document: Builder Prompt MVP Testing

**Date**: January 22, 2026  
**Session**: Continuation of Builder Prompt Architecture Implementation  
**Next Task**: Execute end-to-end MVP test with Evidence Binding + Risk Assessment builders  
**Status**: Ready to execute

---

## Context: What We've Built So Far

### Phase 0/0B/0C Completed
- Tested 19 variants, validated quality improvements
- Evidence Binding achieved +120% improvement (33.3 → 73.3 score)
- Identified winning patterns: Risk Assessment, Timeline, Metrics, Stat Cards, Alert Boxes
- User feedback: "Insight-led, evidence-supported" design validated

### Builder Prompt Architecture Finalized
**Decision**: Leverage existing `ccai__AI_Prompt__c` with record types instead of creating new objects.

**Schema Created**:
1. **Record Types** (by user):
   - `Builder` (DeveloperName: `Builder`) - for reusable building blocks
   - `Execution` (DeveloperName: `Execution`) - for canvas/text prompts

2. **Category__c Field** (deployed):
   - Picklist with 5 values:
     - Quality Rule
     - Pattern
     - UI Component
     - Context Template
     - Apex Service (renamed from "Field Service")
   - Field ID: `00NQH00000NvnbR2AR`

3. **Topics Enabled**:
   - Enabled on 4 fields: AI Prompt Name, Description, Prompt Command, How it Works?

4. **40 Topics Created** (via seed script):
   - 8 Pattern Types (Risk Assessment, Timeline Analysis, etc.)
   - 7 UI Components (Stat Card, Alert Box, etc.)
   - 4 Quality Rules (Evidence Binding, Information Hierarchy, etc.)
   - 3 Priority Levels (P0, P1, P2)
   - 3 Maturity Levels (Production-Ready, Phase-1-Ready, Experimental)
   - 6 Object Contexts (Opportunity, Case, Account, etc.)
   - 5 Industry Contexts (Healthcare, Financial Services, etc.)
   - 2 Visual Hierarchy (Above-the-Fold, Below-the-Fold)
   - 2 Personas (Sales, Executive)

**Git Status**: All committed to `feature/prompt-quality-improvements` branch

---

## Current State: Existing Prompt Factory

### LWC Prompt Factory (12 Stages)
**Location**: `force-app/main/default/lwc/promptFactoryWizard/`

**Current Flow**:
```
User fills LWC form:
├── Prompt Name
├── Root Object (e.g., Opportunity)
├── Sample Record ID
├── Business Context
├── Output Format (HTML)
├── AI Model ID
└── Company URL (optional)

→ Calls: PromptFactoryController.startPipelineRun()
→ Executes 12 stages asynchronously
→ Stage 08: buildAIInstructions() + buildGroundingRules() ← CURRENTLY HARDCODED
→ Stage 09-11: Data extraction, prompt execution
→ Stage 12: Quality audit (8-dimension scoring)
→ Returns: PF_Run__c with logs, final prompt, quality scorecard
```

### Stage08_PromptAssembly.cls (Current Implementation)
**Location**: `force-app/main/default/classes/Stage08_PromptAssembly.cls`

**Current Methods**:
- `buildAIInstructions()` - Builds AI instructions (lines 227-377)
- `buildGroundingRules()` - Builds grounding rules (lines 386-401)
- `assemblePromptConfiguration()` - Assembles final prompt

**Current Problem**: All rules are hardcoded in these methods. No Builder Prompts are queried or used.

---

## The MVP Test Plan

### Goal
Prove that Builder Prompts can be queried and injected into Stage08 to improve prompt quality.

### Test Sequence

**Step 1: Create 2 Builder Prompt Records** (5 min)
1. Evidence Binding v2 (Quality Rule)
2. Risk Assessment Pattern (Pattern)

**Step 2: Run Baseline Test WITHOUT Builder Prompts** (5 min)
- Call existing Prompt Factory with sample Opportunity
- Record baseline: prompt content, output, quality score
- This is our "before" state

**Step 3: Modify Stage08_PromptAssembly.cls** (30 min)
- Add method: `loadQualityRules()` to query Builder Prompts
- Add method: `loadPatterns()` to query Builder Prompts  
- Modify: `buildAIInstructions()` to inject Builder content
- Deploy changes

**Step 4: Run Test WITH Builder Prompts** (5 min)
- Same inputs, same Opportunity record
- New prompt should include Builder content from database
- Record results: prompt content, output, quality score

**Step 5: Compare & Validate** (10 min)
- Did Builder content get injected? ✅/❌
- Did quality score improve? ✅/❌
- Did output follow Evidence Binding rules? ✅/❌
- Document findings

**Total Time**: ~1 hour

---

## Test Parameters (READY TO USE)

### Org Details
- **Org Alias**: `agentictso`
- **Username**: `agentictso@gptfy.com`
- **Org ID**: `00DgD000001li6fUAA`

### Sample Test Data
- **Opportunity ID**: `006QH00000Hjl5qYAB`
- **Opportunity Name**: Harrison - CRM Stock Diversification Program
- **Stage**: Proposal/Price Quote
- **Amount**: $1,350,000
- **Close Date**: 2026-07-30

### AI Model
- **Connection ID**: `a01gD000003okzEQAQ`
- **Provider**: OpenAI GPT-4o (from existing prompt `a0DQH00000KYLsv2AH`)

### Prompt Factory Inputs
```javascript
{
  promptName: 'MVP Test - Builder Prompts',
  rootObject: 'Opportunity',
  sampleRecordId: '006QH00000Hjl5qYAB',
  businessContext: 'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.',
  outputFormat: 'HTML',
  aiModelId: 'a01gD000003okzEQAQ',
  companyUrl: null
}
```

---

## Content for Builder Prompts

### Builder Prompt 1: Evidence Binding v2 (Quality Rule)

**Source**: `docs/quality-rules/evidence_binding_v2.md`

**Metadata**:
```
Name: Evidence Binding Rules v2
RecordType: Builder
Category: Quality Rule
Topics: Evidence Binding, Insight-Led Design, P0
Status: Active
```

**Prompt Command** (use first 5000 chars from evidence_binding_v2.md):
- 4-level citation hierarchy
- Insight-first, evidence-supported approach
- Level 1 (80%): Embedded data
- Level 2 (15%): Parenthetical source
- Level 3 (5%): Inline citation
- Level 4 (always): Collapsible data sources

### Builder Prompt 2: Risk Assessment Pattern

**Source**: `tests/phase0b/patterns/ANALYTICAL_PATTERNS.md` (Pattern #1)

**Metadata**:
```
Name: Risk Assessment Pattern
RecordType: Builder
Category: Pattern
Topics: Risk Assessment, Opportunity, P0
Status: Active
```

**Prompt Command**:
```
=== ANALYTICAL PATTERN: RISK ASSESSMENT ===

Identify and analyze risks that could impact deal closure.

FORMAT:
For each risk, provide:
1. SEVERITY: CRITICAL/WARNING/OPPORTUNITY
2. RISK: Clear description of the gap or concern
3. EVIDENCE: Specific field values that indicate this risk
4. IMPACT: Business consequence if not addressed
5. MITIGATION: Specific action to resolve

CRITICAL RISKS (Deal-killers):
- Missing champion or economic buyer
- No decision maker engaged
- Overdue deliverables blocking approval
- Stage probability misaligned with close date
- Budget not confirmed at late stage

WARNING RISKS (Significant gaps):
- Low activity velocity (< 3 activities/week in proposal stage)
- Single-threaded (only 1 contact role)
- No executive sponsor engagement
- Long time in current stage vs. historical average

OPPORTUNITIES (Positive signals):
- Multiple stakeholders engaged
- Recent high-value activities completed
- Stage progression aligned with velocity
- Strong champion identified

ALWAYS:
- Cite specific evidence (Contact roles, Activity counts, Stage duration)
- Quantify impact where possible ("Deals without champion: 31% win rate")
- Provide actionable mitigation steps
```

---

## Code Changes Needed in Stage08

### Add These Methods to Stage08_PromptAssembly.cls

```apex
/**
 * @description Load active Quality Rules from Builder Prompts
 * @return Combined quality rules content
 */
private String loadQualityRules() {
    try {
        List<ccai__AI_Prompt__c> rules = [
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND Category__c = 'Quality Rule'
              AND ccai__Status__c = 'Active'
              AND Id IN (
                  SELECT EntityId 
                  FROM TopicAssignment 
                  WHERE Topic.Name = 'P0' 
                    AND EntityType = 'ccai__AI_Prompt__c'
              )
            ORDER BY Name
        ];
        
        if (rules.isEmpty()) {
            System.debug('No Quality Rules found - falling back to hardcoded');
            return '';
        }
        
        String allRules = '';
        for (ccai__AI_Prompt__c rule : rules) {
            allRules += '\n\n=== ' + rule.Name + ' ===\n\n';
            allRules += rule.ccai__Prompt_Command__c;
        }
        
        System.debug('Loaded ' + rules.size() + ' Quality Rules from Builder Prompts');
        return allRules;
        
    } catch (Exception e) {
        System.debug('Error loading Quality Rules: ' + e.getMessage());
        return '';
    }
}

/**
 * @description Load active Patterns from Builder Prompts for specific object
 * @param rootObject The Salesforce object (e.g., 'Opportunity')
 * @return Combined pattern content
 */
private String loadPatterns(String rootObject) {
    try {
        List<ccai__AI_Prompt__c> patterns = [
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND Category__c = 'Pattern'
              AND ccai__Status__c = 'Active'
              AND Id IN (
                  SELECT EntityId 
                  FROM TopicAssignment 
                  WHERE Topic.Name IN ('P0', :rootObject)
                    AND EntityType = 'ccai__AI_Prompt__c'
              )
            ORDER BY Name
        ];
        
        if (patterns.isEmpty()) {
            System.debug('No Patterns found for ' + rootObject);
            return '';
        }
        
        String allPatterns = '';
        for (ccai__AI_Prompt__c pattern : patterns) {
            allPatterns += '\n\n=== ' + pattern.Name + ' ===\n\n';
            allPatterns += pattern.ccai__Prompt_Command__c;
        }
        
        System.debug('Loaded ' + patterns.size() + ' Patterns from Builder Prompts');
        return allPatterns;
        
    } catch (Exception e) {
        System.debug('Error loading Patterns: ' + e.getMessage());
        return '';
    }
}
```

### Modify buildAIInstructions() Method

**Find this section** (around line 370):
```apex
instructions += 'The output should be visually stunning, data-rich, and immediately actionable.\n';
instructions += 'Use ONLY the merge field embeddings provided in the template below. Do not add or modify merge fields.\n';
instructions += 'Merge fields use triple-brace syntax and will be substituted by GPTfy at runtime.\n';

return instructions;
```

**Replace with**:
```apex
instructions += 'The output should be visually stunning, data-rich, and immediately actionable.\n';
instructions += 'Use ONLY the merge field embeddings provided in the template below. Do not add or modify merge fields.\n';
instructions += 'Merge fields use triple-brace syntax and will be substituted by GPTfy at runtime.\n\n';

// NEW: Load and inject Builder Prompts
String qualityRules = loadQualityRules();
if (String.isNotBlank(qualityRules)) {
    instructions += qualityRules + '\n\n';
}

String patterns = loadPatterns(rootObject);
if (String.isNotBlank(patterns)) {
    instructions += patterns + '\n\n';
}

return instructions;
```

---

## Execution Commands

### Create Builder Prompts via Apex
```apex
// Execute via: sf apex run -o agentictso -f scripts/apex/create_mvp_builders.apex

// Get record type IDs
Id builderRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'ccai__AI_Prompt__c' AND DeveloperName = 'Builder' LIMIT 1].Id;

// Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic WHERE Name IN ('Evidence Binding', 'Insight-Led Design', 'P0', 'Risk Assessment', 'Opportunity')]) {
    topicMap.put(t.Name, t.Id);
}

// Create Evidence Binding builder
ccai__AI_Prompt__c evidenceBinding = new ccai__AI_Prompt__c(
    Name = 'Evidence Binding Rules v2',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = '[PASTE CONTENT FROM evidence_binding_v2.md - FIRST 5000 CHARS]'
);
insert evidenceBinding;

// Create topic assignments for Evidence Binding
List<TopicAssignment> assignments = new List<TopicAssignment>{
    new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('Evidence Binding')),
    new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('Insight-Led Design')),
    new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('P0'))
};

// Create Risk Assessment builder
ccai__AI_Prompt__c riskAssessment = new ccai__AI_Prompt__c(
    Name = 'Risk Assessment Pattern',
    RecordTypeId = builderRtId,
    Category__c = 'Pattern',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = '[PASTE RISK ASSESSMENT PATTERN CONTENT]'
);
insert riskAssessment;

// Create topic assignments for Risk Assessment
assignments.addAll(new List<TopicAssignment>{
    new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('Risk Assessment')),
    new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('Opportunity')),
    new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('P0'))
});

insert assignments;

System.debug('✅ Created 2 Builder Prompts with topics');
System.debug('Evidence Binding ID: ' + evidenceBinding.Id);
System.debug('Risk Assessment ID: ' + riskAssessment.Id);
```

### Run Baseline Test (Before Builder Prompts)
```apex
// Execute via: sf apex run -o agentictso -f scripts/apex/run_baseline_test.apex

Id runId = PromptFactoryController.startPipelineRun(
    'Baseline Test - No Builders',
    'Opportunity',
    '006QH00000Hjl5qYAB',
    'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.',
    'HTML',
    'a01gD000003okzEQAQ',
    null
);

System.debug('Baseline Test Run ID: ' + runId);
// Monitor via: SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = :runId
```

### Run Test With Builder Prompts (After Stage08 Modified)
```apex
// Execute via: sf apex run -o agentictso -f scripts/apex/run_mvp_test.apex

Id runId = PromptFactoryController.startPipelineRun(
    'MVP Test - With Builders',
    'Opportunity',
    '006QH00000Hjl5qYAB',
    'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.',
    'HTML',
    'a01gD000003okzEQAQ',
    null
);

System.debug('MVP Test Run ID: ' + runId);
// Monitor via: SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = :runId
```

---

## Success Criteria

### Phase 1 MVP Success = ALL of these:

1. **Builder Prompts Created** ✅/❌
   - 2 records exist with correct metadata
   - Topics assigned correctly
   - Status = Active

2. **Stage08 Queries Builders** ✅/❌
   - Debug logs show: "Loaded 2 Quality Rules from Builder Prompts"
   - Debug logs show: "Loaded X Patterns from Builder Prompts"

3. **Content Injected into Prompt** ✅/❌
   - Final prompt (from PF_Run__c) contains Evidence Binding text
   - Final prompt contains Risk Assessment pattern text

4. **Quality Improvement** ✅/❌
   - Stage 12 quality score ≥ baseline (ideally +5 points)
   - Output follows Evidence Binding rules (insight-first)
   - Output shows Risk Assessment pattern (CRITICAL/WARNING levels)

5. **No Errors** ✅/❌
   - No SOQL errors in logs
   - Pipeline completes successfully
   - All 12 stages execute

---

## If MVP Succeeds: Next Iterations

**Phase 2**: UI Components (30 min)
- Create Stat Card builder
- Test rendering

**Phase 3**: Context Templates (30 min)
- Create Healthcare heuristics builder
- Test context injection

**Phase 4**: Apex Services (1 hour)
- Create FieldMetadataService builder
- Test live metadata extraction

Each phase: Create → Test → Validate → Commit

---

## Files Reference

**Evidence Binding Content**:
- Source: `/Users/sgupta/projects-sfdc/gptfy-prompt-factory/docs/quality-rules/evidence_binding_v2.md`

**Risk Assessment Pattern**:
- Source: `/Users/sgupta/projects-sfdc/gptfy-prompt-factory/tests/phase0b/patterns/ANALYTICAL_PATTERNS.md` (Pattern #1)

**Stage08 Code**:
- File: `/Users/sgupta/projects-sfdc/gptfy-prompt-factory/force-app/main/default/classes/Stage08_PromptAssembly.cls`
- Modify: `buildAIInstructions()` method (around line 370)
- Add: `loadQualityRules()` and `loadPatterns()` methods

**Test Results Location**:
- Save to: `/Users/sgupta/projects-sfdc/gptfy-prompt-factory/tests/mvp/`
- Create files: `baseline_test.md`, `mvp_test.md`, `comparison.md`

---

## Git Workflow

**Current Branch**: `feature/prompt-quality-improvements`

**After Each Success**:
```bash
git add -A
git commit -m "feat: [what you did]"
git push origin feature/prompt-quality-improvements
```

---

## Questions User Had (For Reference)

User asked about running this autonomously and validating end-to-end. Confirmed approach:
1. Create builders
2. Run baseline
3. Modify Stage08
4. Run with builders
5. Compare & validate

User prefers MVP approach: Test 2 builders first, then iterate by category if successful.

---

## Session Handoff Complete

**Next AI Session Should**:
1. Read this document thoroughly
2. Create 2 Builder Prompt records
3. Run baseline test
4. Modify Stage08
5. Run MVP test
6. Compare results
7. Document findings

**Estimated Time**: 1 hour total

**Expected Outcome**: Proof that Builder Prompts can be dynamically loaded and improve prompt quality.

Good luck! 🚀

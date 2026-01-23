# Task 4.1: V2.0 End-to-End Test Procedure

**Purpose**: Validate full V2.0 flow with multi-sample profiling and meta-prompt architecture
**Date**: 2026-01-23
**Tester**: Sonnet

---

## Test Overview

This test validates the V2.0 Builder Improvements implementation:
- Multi-sample data profiling (3 Opportunity records)
- Pattern detection across samples
- Meta-prompt assembly with 6 sections
- Compressed builder prompt injection
- UI toolkit integration

---

## Prerequisites

1. Salesforce org has deployed V2.0 components:
   - Stage04_DataProfiling with MultiSampleProfile classes
   - Stage05_FieldSelection with enhanced AI prompt
   - Stage07_TemplateDesign with USE_META_PROMPT flag
   - Stage08_PromptAssembly with 6-section meta-prompt

2. Sample data exists:
   - At least 3 Opportunity records with varied data
   - Related child records (Tasks, Contacts, OpportunityLineItems)
   - Compressed builder prompt deployed (Next Best Action Pattern Compressed)

3. Feature flags configured:
   - Stage 7: USE_META_PROMPT = true (or passed via input)
   - Stage 8: Expects multiSampleProfile from Stage 4

---

## Test Steps

### Step 1: Identify 3 Sample Opportunities

Query for 3 Opportunities with varied characteristics:

```apex
// Find Opportunities with different stages, amounts, and child record counts
SELECT Id, Name, Amount, StageName,
       (SELECT COUNT() FROM Tasks),
       (SELECT COUNT() FROM OpportunityContactRoles),
       (SELECT COUNT() FROM OpportunityLineItems)
FROM Opportunity
WHERE Amount != null
  AND StageName != null
ORDER BY CreatedDate DESC
LIMIT 10
```

**Selection Criteria**:
- Different amounts (variation for VARIANCE pattern detection)
- Different stages (show progression patterns)
- Different child record counts (show data availability gaps)

**Expected Output**: Record 3 Opportunity IDs for testing

---

### Step 2: Create PF_Run with Multi-Sample Input

Via pfInputForm LWC or Apex:

```apex
// Test input
String templateName = 'Sales Manager Dashboard';
String rootObject = 'Opportunity';
String sampleRecordIds = '006xxx001,006xxx002,006xxx003'; // Comma-separated

// Execute
PF_Run__c run = [
    SELECT Id, Status__c, Sample_Record_Ids__c, Current_Stage__c
    FROM PF_Run__c
    WHERE Id = :PromptFactoryController.startPipelineRun(
        templateName,
        rootObject,
        sampleRecordIds,
        'Sales Manager',
        null,
        null,
        null
    )
];
```

**Expected Output**:
- PF_Run__c.Sample_Record_Ids__c contains comma-separated IDs
- PF_Run__c.Sample_Record_Id__c contains first ID (backward compatibility)
- Status__c = 'Running' or 'Stage 1 Complete'

---

### Step 3: Validate Stage 4 - Multi-Sample Profiling

Check PF_Run__c after Stage 4 completion:

```apex
PF_Run__c run = [
    SELECT Id, Current_Stage__c, Stage04_Output__c
    FROM PF_Run__c
    WHERE Id = :runId
];

// Deserialize Stage 4 output
Map<String, Object> stage4Output = (Map<String, Object>) JSON.deserializeUntyped(run.Stage04_Output__c);
Map<String, Object> multiSampleProfileRaw = (Map<String, Object>) stage4Output.get('multiSampleProfile');
```

**Expected Validations**:

1. **Sample Count**: `multiSampleProfile.sampleCount = 3`
2. **Sample IDs**: `multiSampleProfile.sampleIds` contains all 3 IDs
3. **Samples Array**: `multiSampleProfile.samples` has 3 SampleData entries with recordId, recordName, childRecordCounts
4. **Object Aggregations**:
   - Task: samplesWithData (1-3), minCount, maxCount, avgCount, isConsistent
   - OpportunityContactRole: aggregation data
   - OpportunityLineItem: aggregation data (may show GAP if not in all samples)
5. **Patterns Detected**:
   - VARIANCE: If Amount varies significantly across samples
   - GAP: If object missing in some samples (e.g., OpportunityLineItem)
   - CONSISTENCY: If counts are similar across samples
6. **Analysis Summary**: Text description of key patterns

---

### Step 4: Validate Stage 5 - Field Selection

Check enhanced AI prompt includes multi-sample context:

```apex
PF_Run__c run = [
    SELECT Id, Current_Stage__c, Stage05_Output__c
    FROM PF_Run__c
    WHERE Id = :runId
];

Map<String, Object> stage5Output = (Map<String, Object>) JSON.deserializeUntyped(run.Stage05_Output__c);
String aiPromptUsed = (String) stage5Output.get('aiPromptUsed'); // If logged
```

**Expected Content in AI Prompt**:
- "Analyzed 3 Opportunity records"
- Data availability percentages (e.g., "Task: 3/3 samples (100%)")
- Detected patterns from Stage 4
- Guidance to prioritize fields present across all samples

**Expected Output**:
- selectedFields map with relevance-scored fields
- Fields present in all 3 samples ranked higher

---

### Step 5: Validate Stage 7 - Analysis Brief

Check USE_META_PROMPT flag and analysis brief generation:

```apex
PF_Run__c run = [
    SELECT Id, Current_Stage__c, Stage07_Output__c
    FROM PF_Run__c
    WHERE Id = :runId
];

Map<String, Object> stage7Output = (Map<String, Object>) JSON.deserializeUntyped(run.Stage07_Output__c);
String htmlTemplate = (String) stage7Output.get('htmlTemplate');
Boolean useMetaPrompt = (Boolean) stage7Output.get('useMetaPrompt');
```

**Expected Validations**:

1. **Feature Flag**: `useMetaPrompt = true` (if configured)
2. **Analysis Brief Content** (if meta-prompt enabled):
   - Analysis goals defined
   - Data context summary (rootObject, sampleCount)
   - Output guidelines (GPTfy compliance, insight-first structure)
3. **Template Format** (if meta-prompt disabled):
   - Legacy fixed HTML template with placeholders

---

### Step 6: Validate Stage 8 - Meta-Prompt Assembly

Check 6-section meta-prompt structure:

```apex
ccai__AI_Prompt__c aiPrompt = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE PF_Run__c = :runId
      AND RecordType.DeveloperName = 'Instruction'
    LIMIT 1
];

String metaPrompt = aiPrompt.ccai__Prompt_Command__c;
```

**Expected Meta-Prompt Sections**:

1. **Section 1: ROLE**
   - Contains: "=== YOUR ROLE ==="
   - Defines LLM as business analyst
   - Mentions target persona from inputs

2. **Section 2: DATA PAYLOAD**
   - Contains: "=== DATA CONTEXT ==="
   - Lists: "Analyzed 3 Opportunity records"
   - Shows sample names and key field values
   - Includes: "KEY PATTERNS DETECTED"
   - Lists patterns from Stage 4 (VARIANCE, GAP, CONSISTENCY)
   - Shows: "OBJECT AVAILABILITY" with samplesWithData counts

3. **Section 3: ANALYSIS PRINCIPLES**
   - Contains: "=== ANALYSIS PRINCIPLES ==="
   - Includes compressed quality rules (Evidence Binding)
   - Includes compressed patterns (Next Best Action - if available)
   - Principles are concise (not verbose documentation)

4. **Section 4: UI TOOLKIT**
   - Contains: "=== UI TOOLKIT ==="
   - Lists: "LAYOUT COMPONENTS" (Dashboard Container, Section Card, Stats Strip)
   - Lists: "INSIGHT COMPONENTS" (Alert Box, Insight Card, Recommendation Card)
   - Lists: "DATA COMPONENTS" (Data Table, Metric Tile, Status Badge)
   - Includes: "COMPONENT USAGE RULES" (priority order, anti-patterns)

5. **Section 5: OUTPUT RULES**
   - Contains: "=== OUTPUT RULES ==="
   - Lists GPTfy compliance requirements:
     - Single line HTML
     - Inline styles only
     - No scripts or event handlers
     - Merge field syntax
     - Salesforce color palette

6. **Section 6: DIRECTIVE**
   - Contains: "=== YOUR DIRECTIVE ==="
   - Instructs: "Analyze the Opportunity data and generate an executive dashboard"
   - Specifies output structure:
     - EXECUTIVE SUMMARY (2-3 sentences)
     - KEY INSIGHTS (3-5 findings)
     - RECOMMENDED ACTIONS (2-4 items)
     - SUPPORTING DATA (if warranted)
   - Includes quality checklist

**Expected Character Count**: Meta-prompt should be concise (5,000-10,000 chars) compared to V1.1 verbose approach

---

### Step 7: Validate AI Prompt Deployment

Check that AI Prompt record was created and deployed:

```apex
ccai__AI_Prompt__c aiPrompt = [
    SELECT Id, Name, ccai__Status__c, ccai__Prompt_Command__c,
           PF_Run__c, RecordType.DeveloperName
    FROM ccai__AI_Prompt__c
    WHERE PF_Run__c = :runId
      AND RecordType.DeveloperName = 'Instruction'
    LIMIT 1
];
```

**Expected Validations**:
- RecordType = 'Instruction'
- ccai__Status__c = 'Active' or 'Draft'
- ccai__Prompt_Command__c contains the meta-prompt
- Name includes rootObject and persona

---

### Step 8: Compare V1.1 vs V2.0 Output Structure

Run same test with `USE_META_PROMPT = false` to compare:

**V1.1 Expected**:
- Fixed HTML template with placeholders
- ALL builder prompts injected verbatim
- Table-heavy structure
- Prompt size: ~15,000-20,000 chars

**V2.0 Expected**:
- 6-section meta-prompt
- Compressed builder prompts only
- Insight-first directive
- Prompt size: ~5,000-10,000 chars (50-60% reduction)

---

## Success Criteria

1. ✅ Multi-sample profiling works with 3 Opportunity IDs
2. ✅ ObjectAggregation data shows cross-sample metrics (min/max/avg)
3. ✅ DataPattern detection identifies VARIANCE, GAP, or CONSISTENCY patterns
4. ✅ Stage 5 field selection considers multi-sample data availability
5. ✅ Stage 7 generates analysis brief when USE_META_PROMPT = true
6. ✅ Stage 8 assembles all 6 meta-prompt sections
7. ✅ Compressed builders are loaded (not verbose versions)
8. ✅ UI Toolkit section includes all component categories
9. ✅ Meta-prompt is more concise than V1.1 approach
10. ✅ No errors in pipeline execution

---

## Rollback Plan

If test fails:

1. Check PF_Run__c.Error_Message__c for stage-specific errors
2. Review Stage logs in System.debug or Custom Settings
3. Verify feature flags (USE_META_PROMPT)
4. Check that compressed builders exist in org
5. Fall back to V1.1 by setting USE_META_PROMPT = false

---

## Test Results

**Date Executed**: TBD
**Run ID**: TBD
**Sample IDs**: TBD

**Results**:
- [ ] Step 1: Sample selection
- [ ] Step 2: PF_Run creation
- [ ] Step 3: Stage 4 multi-sample profiling
- [ ] Step 4: Stage 5 field selection
- [ ] Step 5: Stage 7 analysis brief
- [ ] Step 6: Stage 8 meta-prompt assembly
- [ ] Step 7: AI Prompt deployment
- [ ] Step 8: V1.1 vs V2.0 comparison

**Issues Found**: TBD
**Overall Status**: PENDING

---

## Next Steps After Test

1. If successful → Mark Task 4.1 as `done`, hand off to Opus for Task 4.2 (quality comparison)
2. If issues found → Document blockers, fix, re-test
3. Update BUILDER_IMPROVEMENTS.md with test results

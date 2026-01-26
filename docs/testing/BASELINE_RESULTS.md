# Phase 5A.5 Baseline Test Results

**Date**: 2026-01-25
**Task**: 5.15 - Run baseline and document results
**Status**: IN PROGRESS - Schema validation needed before deployment

---

## Summary

Attempted to deploy automated test suite (PipelineIntegrationTest.cls + PipelineValidator.cls) but encountered **schema mismatches** that need resolution before tests can run.

### Tests Created

1. **PipelineIntegrationTest.cls** - Integration tests for full pipeline execution
2. **PipelineValidator.cls** - Reusable validation helper methods
3. **validate-pipeline.sh** - Bash script for automated validation
4. **GOLDEN_TEST_CASE.md** - Golden test case documentation

### Deployment Issues Found

**Schema Mismatches:**

1. **No Run Lookup Fields**: AI_Data_Extraction_Mapping__c and AI_Prompt__c don't have a `Run__c` lookup field
   - Relationship is one-way: PF_Run__c has `Created_DCM_Id__c` and `Created_Prompt_Id__c`
   - Tests were incorrectly querying: `WHERE ccai__Run__c = :runId`
   - Should query: `WHERE Id IN (SELECT Created_DCM_Id__c FROM PF_Run__c WHERE Id = :runId)`

2. **Field Name Errors**:
   - `ccai__Relationship_Name__c` should be `ccai__RelationshipName__c` (no underscore)
   - `ccai__Last_Result__c` doesn't exist on AI_Prompt__c
   - `Schema.ccai__DCM_Field__c` should be `ccai__AI_Data_Extraction_Field__c`

3. **PF_Run__c Field Names**: No `ccai__` prefix on custom fields:
   - `Status__c` not `ccai__Status__c`
   - `Current_Stage__c` not `ccai__Current_Stage__c`
   - `Error_Message__c` not `ccai__Error_Message__c`

---

## Next Steps

### Option 1: Fix Test Classes (Recommended)

Update PipelineIntegrationTest.cls and PipelineValidator.cls to use correct schema:

```apex
// BEFORE (incorrect):
List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
    SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c
    WHERE ccai__Run__c = :runId
];

// AFTER (correct):
PF_Run__c run = [SELECT Created_DCM_Id__c FROM PF_Run__c WHERE Id = :runId];
List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
    SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c
    WHERE Id = :run.Created_DCM_Id__c
];
```

### Option 2: Manual Baseline Validation

Skip automated tests for now and manually validate:

1. ✅ Golden test case exists (006QH00000HjgvlYAB)
2. ⏳ Run pipeline manually with golden test case
3. ⏳ Inspect created DCM structure
4. ⏳ Inspect created prompt template
5. ⏳ Check for merge fields vs hardcoded values
6. ⏳ Validate output quality

---

## Golden Test Case Status

✅ **Verified**: Golden test case exists in org

```
Opportunity ID: 006QH00000HjgvlYAB
Name: Employee Health Insurance / McD Franchise Deal
Account: HealthSystem Partners
Amount: $1,500,000
Children: 4 OpportunityContactRoles, 5 Tasks, 3 Events
Grandchildren: 4 Contacts (via OpportunityContactRole)
```

---

## Current Pipeline State

**Unknown** - Need to run validation once tests are fixed or manual baseline is complete.

### Questions to Answer:

1. Does golden test case produce valid DCM?
2. Does DCM include expected child objects (OpportunityContactRole, Task, Event)?
3. Does DCM include grandchild object (Contact)?
4. Does DCM include parent lookups (Account.Name, Owner.Name, Contact.Name)?
5. Does prompt template use merge fields correctly?
6. Are there any hardcoded values in the template?
7. Does output have expected visual components (health, alerts, table)?
8. Is quality score 8.5+/10?

---

## Recommendation

**PAUSE Phase 5A.5** and fix test class schema issues before proceeding. This will:

1. Allow automated tests to deploy successfully
2. Enable continuous validation during Phase 5D implementation
3. Prevent regression during meta-prompt work
4. Establish true baseline for comparison

**Alternative**: Skip automated tests for V2.5 and rely on manual testing with golden test case. Add automated tests in V2.6 after schema is clarified.

---

## Files Created

| File | Status | Notes |
|------|--------|-------|
| docs/testing/GOLDEN_TEST_CASE.md | ✅ Complete | Golden test case documentation |
| force-app/main/default/classes/PipelineIntegrationTest.cls | ❌ Schema errors | Needs field name fixes |
| force-app/main/default/classes/PipelineValidator.cls | ❌ Schema errors | Needs field name fixes |
| scripts/validate-pipeline.sh | ✅ Complete | Ready to use once tests deploy |
| docs/testing/BASELINE_RESULTS.md | ✅ Complete | This file |

---

## Decision Point

**User**: Should we:

**A)** Fix test classes now and complete automated baseline (adds ~30-60 mins)

**B)** Skip automated tests for V2.5, proceed with manual validation (faster, less robust)

**C)** Defer Phase 5A.5 testing to V2.6, continue with Phase 5D implementation (riskier but faster)

---

## Learnings for Future

1. **Always query object schema before writing tests** - Don't assume field names
2. **Check relationship directions** - Lookups may be one-way only
3. **Test deployment early** - Catch schema errors before writing full suite
4. **Use existing code as examples** - Stage classes show correct field usage

---

## Appendix: Deployment Error Log

```
Component Failures [15]:

ApexClass: PipelineIntegrationTest
- Line 66: Variable does not exist: ccai__Status__c
- Line 67: Variable does not exist: ccai__Current_Stage__c
- Line 70: Variable does not exist: run
- Line 72: Variable does not exist: run

ApexClass: PipelineValidator
- Line 42: No such column 'ccai__Run__c' on AI_Data_Extraction_Mapping__c
- Line 62: No such column 'ccai__Relationship_Name__c' on AI_Data_Extraction_Detail__c
- Line 91: Invalid type: Schema.ccai__DCM_Field__c
- Line 114: No such column 'ccai__Run__c' on AI_Prompt__c
- Line 172: No such column 'ccai__Last_Result__c' on AI_Prompt__c
- Line 222: No such column 'ccai__Run__c' on AI_Data_Extraction_Mapping__c
- Line 353: No such column 'ccai__Run__c' on AI_Data_Extraction_Mapping__c
- Line 376: No such column 'ccai__Run__c' on AI_Prompt__c
- Line 419: No such column 'ccai__Run__c' on AI_Prompt__c
```

Full error output available in deployment log (0AfQH00000N54KJ0AZ).


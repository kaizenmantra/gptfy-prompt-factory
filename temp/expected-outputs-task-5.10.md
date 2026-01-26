# Task 5.10: Expected Outputs Documentation

## Golden Test Case
**Account**: 001QH000024mdDnYAI (TESTDATA_Pinnacle Wealth Partners)
**Pipeline Run**: a0gQH000005GOY9YAO (PFR-00000154)
**Date**: 2026-01-24
**Status**: Failed at Stage 10 (GPTfy API error), but Stages 1-9 completed successfully

## Created Artifacts

### 1. Data Context Mapping (DCM)
**ID**: a05QH000008RggHYAS
**Name**: Account 360 - Pinnacle Wealth Partners (Golden Test) DCM
**Root Object**: Account

#### DCM Detail Records (6 total)

| Object | Relationship Name | Type |
|--------|-------------------|------|
| Event | Events | CHILD |
| Task | Tasks | CHILD |
| Contact | Contacts | CHILD |
| Case | Cases | CHILD |
| Opportunity | Opportunities | CHILD |
| OpportunityContactRole | OpportunityContactRoles | GRANDCHILD |

**Analysis**:
- ✅ 5 CHILD objects: Event, Task, Contact, Case, Opportunity
- ✅ 1 GRANDCHILD object: OpportunityContactRole (under Opportunity)
- ⚠️ Missing: CaseComments grandchild (not auto-discovered)

**Why This Matters for Testing**:
- Tests 2-level traversal: Account → 5 child objects
- Tests 3-level traversal: Account → Opportunity → OpportunityContactRole
- Does NOT test: Case → CaseComments (would need manual DCM configuration or Stage 3 enhancement)

#### DCM Field Records (60 total)


### 2. AI Prompt
**ID**: a0DQH00000KaNtp2AF
**Name**: Account 360 - Pinnacle Wealth Partners (Golden Test)
**DCM**: a05QH000008RggHYAS (linked)


**Prompt Template**:
- Length: 5 characters
- Saved to: `temp/golden-test-prompt-template.txt`

## Validation Criteria (What "Good" Looks Like)

### DCM Structure Validation

**PASS Criteria**:
1. ✅ DCM record created with correct name
2. ✅ Root object = Account
3. ✅ 5-6 child object detail records
4. ✅ At least 1 grandchild object detail record (OpportunityContactRole)
5. ✅ 50-80 field records total
6. ✅ Each object has 5-15 fields selected (not all fields, not too few)

**FAIL Criteria**:
- ❌ Zero detail records
- ❌ Zero field records
- ❌ All fields selected for an object (no LLM filtering)
- ❌ Less than 3 fields per object (too sparse)
- ❌ Missing key objects (Opportunity, Case, Contact)

### Prompt Template Validation

**PASS Criteria**:
1. ✅ Uses merge field syntax: `{{{FieldName}}}`
2. ✅ Uses iteration blocks: `{{#ObjectName}}...{{/ObjectName}}`
3. ✅ Parent lookups use dot notation: `{{{OpportunityContactRoles.Contact.Name}}}`
4. ✅ NO hardcoded values from sample data (no "Pinnacle Wealth Partners" literal)
5. ✅ NO hardcoded amounts (no "$450,000" literal)
6. ✅ NO hardcoded names (no "Sarah Chen" literal)
7. ✅ Single-line HTML (no newlines in output blocks)
8. ✅ Template length: 5,000-50,000 characters (realistic range)

**FAIL Criteria**:
- ❌ Contains hardcoded account name
- ❌ Contains hardcoded opportunity amounts
- ❌ Contains hardcoded contact names
- ❌ Missing merge field triple braces `{{{}}}`
- ❌ Missing iteration blocks for child objects
- ❌ Multi-line HTML (newlines in output)
- ❌ Template length < 1,000 characters (too short)
- ❌ Template length > 100,000 characters (too long)

## Merge Field Pattern Examples

### Root Object Fields
```handlebars
{{{Name}}}
{{{Industry}}}
{{{AnnualRevenue}}}
{{{BillingCity}}}
```

### Child Object Iteration
```handlebars
{{#Opportunities}}
  <li>{{{Name}}} - {{{StageName}}} - ${{{Amount}}}</li>
{{/Opportunities}}
```

### Grandchild Iteration (3-level)
```handlebars
{{#Opportunities}}
  <p>Opportunity: {{{Name}}}</p>
  <ul>
    {{#OpportunityContactRoles}}
      <li>{{{Role}}}: {{{Contact.Name}}} ({{{Contact.Title}}})</li>
    {{/OpportunityContactRoles}}
  </ul>
{{/Opportunities}}
```

### Parent Lookup Fields
```handlebars
{{{OpportunityContactRoles.Contact.Name}}}
{{{OpportunityContactRoles.Contact.Email}}}
{{{Opportunities.Owner.Name}}}
```

## Automated Test Assertions

For `PipelineIntegrationTest.cls`:

```apex
// DCM Assertions
System.assert(dcm != null, 'DCM should be created');
System.assertEquals('Account', dcm.ccai__Object_Name__c, 'Root object should be Account');

List<ccai__AI_Data_Extraction_Detail__c> details = [
    SELECT ccai__Type__c FROM ccai__AI_Data_Extraction_Detail__c 
    WHERE ccai__AI_Data_Extraction_Mapping__c = :dcm.Id
];
System.assert(details.size() >= 5, 'Should have at least 5 child objects');

Integer grandchildCount = 0;
for (ccai__AI_Data_Extraction_Detail__c detail : details) {
    if (detail.ccai__Type__c == 'GRANDCHILD') grandchildCount++;
}
System.assert(grandchildCount >= 1, 'Should have at least 1 grandchild object');

List<ccai__AI_Data_Extraction_Field__c> fields = [
    SELECT Id FROM ccai__AI_Data_Extraction_Field__c 
    WHERE ccai__AI_Data_Extraction_Mapping__c = :dcm.Id
];
System.assert(fields.size() >= 50 && fields.size() <= 100, 
    'Should have 50-100 fields: ' + fields.size());

// Prompt Assertions
System.assert(prompt != null, 'Prompt should be created');
String template = prompt.ccai__Prompt_Template__c;
System.assert(template != null && template.length() > 1000, 
    'Template should exist and be substantial');

// No hardcoded values
System.assert(!template.contains('Pinnacle Wealth Partners'), 
    'Should not contain hardcoded account name');
System.assert(!template.contains('$450,000') && !template.contains('450000'), 
    'Should not contain hardcoded amounts');

// Has merge fields
System.assert(template.contains('{{{') && template.contains('}}}'), 
    'Should contain merge field syntax');
System.assert(template.contains('{{#Opportunities}}'), 
    'Should have iteration blocks for Opportunities');
System.assert(template.contains('{{#Cases}}'), 
    'Should have iteration blocks for Cases');

// Parent lookups
System.assert(template.contains('Contact.Name') || template.contains('Owner.Name'), 
    'Should include parent lookup fields');
```

## Next Steps

This document defines the baseline "good" output for:
- **Task 5.11**: Create `PipelineIntegrationTest.cls` with these assertions
- **Task 5.12**: Create `PipelineValidator.cls` with reusable validation methods
- **Task 5.13**: Add smoke tests to each stage
- **Task 5.14**: Create `scripts/validate-pipeline.sh` automation


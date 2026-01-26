# Golden Test Case - Pipeline Integration Testing

**Purpose**: This document defines the golden test case used for automated pipeline testing. This is a known-good Opportunity record with all features (children, parents, grandchildren) that we use to validate pipeline functionality.

**Status**: Active
**Last Updated**: 2026-01-25
**Owner**: Sonnet (Phase 5A.5 - Automated Testing)

---

## Test Record Details

### Opportunity Record

| Field | Value |
|-------|-------|
| **ID** | `006QH00000HjgvlYAB` |
| **Name** | Employee Health Insurance / McD Franchise Deal |
| **Account** | 001gD000004K2TTQA0 (HealthSystem Partners) |
| **Owner** | 005gD000000b55ZQAQ (Agentic TSO) |
| **Amount** | $1,500,000 |
| **Stage** | Needs Analysis |
| **Close Date** | 2026-03-30 |
| **Industry Context** | Healthcare |

### Child Records

**OpportunityContactRoles** (4 records):
1. Lisa Martinez (Champion) - 00KQH00000FwWy92AF
2. Sarah Johnson (Economic Buyer) - 00KQH00000FwWuv2AF
3. Michael Chen (Decision Maker) - 00KQH00000FwWwX2AV
4. Robert Taylor (Business User) - 00KQH00000FwWzl2AF

**Tasks** (5 records):
1. Send ROI Analysis to CFO (Not Started) - 00TQH00000DNgwj2AD
2. Schedule CFO Meeting (In Progress) - 00TQH00000DNgyL2AT
3. Prepare HIPAA compliance documentation (Not Started) - 00TQH00000DNgzx2AD
4. Follow up with HR Director on benefits package (Not Started) - 00TQH00000DNgjq2AD
5. Security review with IT team (Not Started) - 00TQH00000DNgjr2AD

**Events** (3 records):
1. Discovery Call with HR Director (2026-01-10) - 00UQH000005qYyn2AE
2. Benefits Review Meeting (2026-01-15) - 00UQH000005qZ0P2AU
3. CFO Presentation (2026-01-27) - 00UQH000005qZ212AE

### Parent Lookups

**Account**: HealthSystem Partners (001gD000004K2TTQA0)
- Used for: Account.Name, Account.Industry, Account.Type references

**Owner**: Agentic TSO (005gD000000b55ZQAQ)
- Used for: Owner.Name, Owner.Email references

### Grandchild Relationships

**OpportunityContactRole → Contact**:
- Lisa Martinez (003QH00000NKxJfYAL) - Champion
- Sarah Johnson (003QH00000NL0kfYAD) - Economic Buyer
- Michael Chen (003QH00000NL1blYAD) - Decision Maker
- Robert Taylor (003QH00000NL1dNYAT) - Business User

**This enables 3-level traversals**: Opportunity → OpportunityContactRole → Contact

---

## Expected Pipeline Outputs

### Stage 3: Schema Discovery

**Expected Child Objects**:
- OpportunityContactRole
- Task
- Event

**Expected Parent Lookups**:
- AccountId → Account
- OwnerId → User

**Expected Grandchild Discovery**:
- OpportunityContactRole.ContactId → Contact

### Stage 5: Field Selection

**Expected Root Fields** (sample):
- Name, Amount, StageName, CloseDate
- Account.Name, Account.Industry
- Owner.Name, Owner.Email

**Expected Child Fields** (OpportunityContactRole):
- ContactId, Role, IsPrimary
- Contact.Name, Contact.Title, Contact.Email

**Expected Parent Fields**:
- Account.Name, Account.Industry, Account.Type
- Owner.Name, Owner.Email

### Stage 7: Analysis Brief

**Expected Output**:
```json
{
  "rootObject": "Opportunity",
  "rootObjectLabel": "Opportunity",
  "sampleRecordId": "006QH00000HjgvlYAB",
  "businessContext": "...",
  "keyMetrics": [...],
  "relationshipSummary": "3-level hierarchy with 4 contacts, 5 tasks, 3 events"
}
```

### Stage 9: DCM Creation

**Expected DCM Structure**:

**Root Object**: Opportunity
- Fields: Name, Amount, StageName, CloseDate, Account.Name, Owner.Name, etc.

**Child 1**: OpportunityContactRole
- Type: CHILD
- Relationship: OpportunityContactRoles
- Fields: Role, IsPrimary, Contact.Name, Contact.Title, Contact.Email

**Child 2**: Task
- Type: CHILD
- Relationship: Tasks
- Fields: Subject, Status, ActivityDate

**Child 3**: Event
- Type: CHILD
- Relationship: Events
- Fields: Subject, StartDateTime, EndDateTime

**Grandchild**: Contact (via OpportunityContactRole)
- Type: GRANDCHILD
- Parent Detail: OpportunityContactRole
- Fields: Name, Title, Email, Phone

### Stage 10: Prompt Template

**Expected Merge Fields**:
```handlebars
{{{Name}}}
{{{Amount}}}
{{{StageName}}}
{{{Account.Name}}}
{{{Owner.Name}}}

{{#OpportunityContactRoles}}
  {{{Contact.Name}}} - {{{Role}}}
{{/OpportunityContactRoles}}

{{#Tasks}}
  {{{Subject}}} ({{{Status}}})
{{/Tasks}}

{{#Events}}
  {{{Subject}}} on {{{StartDateTime}}}
{{/Events}}
```

**Expected NO hardcoded values**:
- ❌ "Employee Health Insurance / McD Franchise Deal"
- ❌ "$1,500,000"
- ❌ "Lisa Martinez"
- ❌ "HealthSystem Partners"

**All values must use merge field syntax**: `{{{FieldName}}}`

### Stage 12: Quality Scoring

**Expected Quality Metrics** (8.5+/10 target):
1. Evidence Binding: 8+/10
2. Diagnostic Depth: 8+/10
3. Visual Quality: 9+/10
4. UI Effectiveness: 8+/10
5. Data Accuracy: 9+/10
6. Persona Fit: 8+/10
7. Actionability: 8+/10
8. Business Value: 9+/10

**Expected Visual Components**:
- ✅ Health score with progress bar
- ✅ Red critical alerts (1-2)
- ✅ Orange warning alerts (4-5)
- ✅ Blue info/success alerts (1)
- ✅ Data table with 3-5 records
- ✅ Status badges on recommendations

---

## Validation Assertions

### DCM Validation

```apex
// Assert DCM exists and is valid
System.assertNotEquals(null, dcm, 'DCM should be created');
System.assertEquals('Opportunity', dcm.ccai__Object_Name__c, 'Root object should be Opportunity');

// Assert child objects are present
List<ccai__AI_Data_Extraction_Detail__c> details = [
    SELECT ccai__Object_Name__c, ccai__Type__c
    FROM ccai__AI_Data_Extraction_Detail__c
    WHERE ccai__DCM__c = :dcm.Id
];
Set<String> childObjects = new Set<String>();
for (ccai__AI_Data_Extraction_Detail__c detail : details) {
    if (detail.ccai__Type__c == 'CHILD') {
        childObjects.add(detail.ccai__Object_Name__c);
    }
}
System.assert(childObjects.contains('OpportunityContactRole'), 'DCM should include OpportunityContactRole');
System.assert(childObjects.contains('Task'), 'DCM should include Task');
System.assert(childObjects.contains('Event'), 'DCM should include Event');

// Assert grandchild is present
Boolean hasContactGrandchild = false;
for (ccai__AI_Data_Extraction_Detail__c detail : details) {
    if (detail.ccai__Type__c == 'GRANDCHILD' && detail.ccai__Object_Name__c == 'Contact') {
        hasContactGrandchild = true;
        break;
    }
}
System.assert(hasContactGrandchild, 'DCM should include Contact as grandchild');

// Assert parent lookups are present (dot-notation fields)
List<ccai__DCM_Field__c> fields = [
    SELECT ccai__Field_Name__c, ccai__Object__c
    FROM ccai__DCM_Field__c
    WHERE ccai__DCM__c = :dcm.Id
    AND ccai__Field_Name__c LIKE '%.%'
];
Set<String> parentFields = new Set<String>();
for (ccai__DCM_Field__c field : fields) {
    parentFields.add(field.ccai__Field_Name__c);
}
System.assert(parentFields.contains('Account.Name'), 'DCM should include Account.Name parent field');
System.assert(parentFields.contains('Contact.Name'), 'DCM should include Contact.Name parent field on child object');
```

### Prompt Validation

```apex
// Assert prompt template exists
System.assertNotEquals(null, prompt, 'Prompt should be created');
System.assertNotEquals(null, prompt.ccai__Prompt_Command__c, 'Prompt command should not be null');

// Assert merge fields are used (not hardcoded values)
String promptText = prompt.ccai__Prompt_Command__c;
System.assert(promptText.contains('{{{Name}}}'), 'Prompt should use {{{Name}}} merge field');
System.assert(promptText.contains('{{{Amount}}}'), 'Prompt should use {{{Amount}}} merge field');
System.assert(!promptText.contains('Employee Health Insurance'), 'Prompt should NOT contain hardcoded opportunity name');
System.assert(!promptText.contains('1500000'), 'Prompt should NOT contain hardcoded amount');
System.assert(!promptText.contains('Lisa Martinez'), 'Prompt should NOT contain hardcoded contact name');

// Assert iteration blocks are present
System.assert(promptText.contains('{{#OpportunityContactRoles}}'), 'Prompt should include OpportunityContactRoles iteration');
System.assert(promptText.contains('{{/OpportunityContactRoles}}'), 'Prompt should close OpportunityContactRoles iteration');
System.assert(promptText.contains('{{{Contact.Name}}}'), 'Prompt should use Contact.Name in child iteration');

// Assert single-line HTML
System.assert(!promptText.contains('\n<div'), 'Prompt should use single-line HTML (no newlines before tags)');
System.assert(!promptText.contains('>\n<'), 'Prompt should use single-line HTML (no newlines between tags)');
```

### Output Quality Validation

```apex
// Assert output is HTML
System.assert(output.startsWith('<'), 'Output should be HTML');

// Assert visual components are present
System.assert(output.contains('font-size:36px'), 'Output should include health score');
System.assert(output.contains('#BA0517'), 'Output should include red alerts');
System.assert(output.contains('#DD7A01'), 'Output should include orange alerts');
System.assert(output.contains('#0176D3'), 'Output should include blue alerts');
System.assert(output.contains('<table'), 'Output should include data table');

// Assert data accuracy (actual values from record)
System.assert(output.contains('Employee Health Insurance'), 'Output should include actual opportunity name');
System.assert(output.contains('$1,500,000') || output.contains('1500000'), 'Output should include actual amount');
System.assert(output.contains('Lisa Martinez'), 'Output should include actual contact name');
System.assert(output.contains('Champion'), 'Output should include actual contact role');
```

---

## Usage Instructions

### For Automated Tests

```apex
// In PipelineIntegrationTest.cls
private static final String GOLDEN_OPP_ID = '006QH00000HjgvlYAB';

@isTest
static void testFullPipeline() {
    Test.startTest();

    // Run full pipeline with golden test case
    Id runId = PromptFactoryController.startPipelineRun(
        'TEST-Golden-' + DateTime.now().getTime(),
        'Opportunity',
        GOLDEN_OPP_ID,
        'Analyze this healthcare opportunity and provide executive insights',
        'Narrative',
        null, // Use default DCM template
        'https://test.salesforce.com'
    );

    Test.stopTest();

    // Validate DCM
    PipelineValidator.validateDCM(runId);

    // Validate Prompt
    PipelineValidator.validatePrompt(runId);

    // Validate Output Quality
    PipelineValidator.validateOutputQuality(runId);
}
```

### For Manual Testing

1. Navigate to Prompt Factory LWC
2. Select root object: **Opportunity**
3. Enter record ID: **006QH00000HjgvlYAB**
4. Business context: "Analyze this healthcare opportunity and provide executive insights"
5. Output format: **Narrative**
6. Click **Start Pipeline**
7. Wait for completion (all 12 stages)
8. Review output quality against expected metrics

### For Regression Testing

```bash
# Run validation script
./scripts/validate-pipeline.sh

# Should output:
# ✅ Golden test case exists
# ✅ DCM structure valid
# ✅ Prompt uses merge fields
# ✅ No hardcoded values found
# ✅ Output quality: 8.7/10
# ✅ All visual components present
```

---

## Why This Test Case?

1. **Comprehensive**: Has all features (children, parents, grandchildren)
2. **Realistic**: Real healthcare deal with meaningful context
3. **Rich Data**: Multiple contacts with roles, tasks, events
4. **3-Level Traversal**: Tests Opportunity → OCR → Contact relationship
5. **Known Good**: Successfully used in V2.4 testing
6. **Stable**: Record won't be deleted or modified (protected test data)

---

## Troubleshooting

### If Test Fails

1. **Check Record Exists**: Verify `006QH00000HjgvlYAB` still exists in org
2. **Check Related Records**: Ensure OpportunityContactRoles, Tasks, Events still present
3. **Check Contacts**: Verify Contact records (Lisa Martinez, Sarah Johnson, etc.) exist
4. **Review Stage Logs**: Check PF_Run_Stage__c records for error messages
5. **Review State File**: Download pipeline_state.json and inspect for anomalies

### If Record Gets Deleted

If the golden test case is accidentally deleted, recreate it:

```bash
# Run the recreation script
sf apex run -f scripts/apex/recreate_golden_test_case.apex -o agentictso
```

---

## Change Log

| Date | Change | Reason |
|------|--------|--------|
| 2026-01-25 | Created golden test case document | Phase 5A.5 Task 5.10 - Document expected outputs |
| 2026-01-25 | Selected 006QH00000HjgvlYAB as golden record | Has all features needed for comprehensive testing |


# GPTfy MEDDIC Compliance Analyzer
## Implementation Tasklist

---

## Overview

This document provides a detailed, step-by-step implementation guide for building the MEDDIC Compliance Analyzer. Tasks are organized by phase and include specific commands, queries, and acceptance criteria.

---

## Phase 1: Metadata Discovery

### 1.1 ClosePlan (TSPC) Package Analysis

#### Task 1.1.1: Inventory TSPC Custom Objects
**Objective**: Document all ClosePlan objects and their purposes

**Steps**:
```bash
# Query all TSPC objects via Tooling API
sf data query --query "SELECT Id, DeveloperName, Label, Description, KeyPrefix FROM EntityDefinition WHERE NamespacePrefix = 'TSPC' ORDER BY Label" --use-tooling-api --json
```

**Deliverable**: Table of TSPC objects with purpose and relationship to Opportunity

| Object API Name | Purpose | Relationship |
|-----------------|---------|--------------|
| TSPC__Deal__c | | |
| TSPC__Stakeholder__c | | |
| ... | | |

**Acceptance Criteria**:
- [ ] All TSPC objects documented
- [ ] Relationship to Opportunity identified for each
- [ ] Purpose validated against ClosePlan documentation

---

#### Task 1.1.2: Document TSPC Object Fields
**Objective**: Capture all fields on each TSPC object

**Steps**:
```bash
# Query fields for all TSPC objects
sf data query --query "SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, Label, DataType, Description, IsRequired, ReferenceTo FROM FieldDefinition WHERE EntityDefinition.NamespacePrefix = 'TSPC' ORDER BY EntityDefinition.QualifiedApiName, Label" --use-tooling-api --json > scripts/tspc_fields.json
```

**Deliverable**: Field documentation for each TSPC object

**Acceptance Criteria**:
- [ ] All fields documented with data types
- [ ] Required fields identified
- [ ] Lookup relationships mapped

---

#### Task 1.1.3: Extract TSPC Picklist Values
**Objective**: Document all picklist values used in TSPC objects

**Steps**:
```bash
# Query picklist fields
sf data query --query "SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, Label FROM FieldDefinition WHERE EntityDefinition.NamespacePrefix = 'TSPC' AND DataType = 'Picklist'" --use-tooling-api --json
```

For each picklist field, use `sf sobject describe` to get values.

**Deliverable**: Picklist value documentation

| Object | Field | Values | Purpose |
|--------|-------|--------|---------|
| TSPC__Stakeholder__c | Role__c | | MEDDIC role mapping |
| TSPC__Stakeholder__c | Influence__c | | Stakeholder power |
| ... | | | |

**Acceptance Criteria**:
- [ ] All picklist values documented
- [ ] Values mapped to MEDDIC elements where applicable

---

### 1.2 Opportunity Object Analysis

#### Task 1.2.1: Document Opportunity Custom Fields
**Objective**: Identify all MEDDIC-relevant fields on Opportunity

**Steps**:
```bash
# Describe Opportunity object
sf sobject describe --sobject Opportunity --json > scripts/opp_describe.json

# Extract custom fields
cat scripts/opp_describe.json | jq '.result.fields | map(select(.custom == true)) | map({name: .name, label: .label, type: .type})'
```

**Deliverable**: Opportunity field inventory categorized by source

| Field API Name | Label | Type | Source | MEDDIC Element |
|----------------|-------|------|--------|----------------|
| TSPC__CPDeal__c | | reference | TSPC | All |
| Overall_Score__c | | double | Custom | N/A |
| ... | | | | |

**Acceptance Criteria**:
- [ ] All custom fields documented
- [ ] TSPC fields identified
- [ ] MEDDIC element mapping complete

---

#### Task 1.2.2: Document Opportunity Stages
**Objective**: Map all opportunity stages with probabilities and forecast categories

**Steps**:
```bash
# Extract from Opportunity describe
cat scripts/opp_describe.json | jq '.result.fields | map(select(.name == "StageName")) | .[0].picklistValues'
```

**Deliverable**: Stage documentation

| Stage | Sort Order | Probability | Forecast | Closed | Won | MEDDIC Min Score |
|-------|------------|-------------|----------|--------|-----|------------------|
| New | 1 | | | No | No | 30 |
| Interest | 2 | | | No | No | 40 |
| ... | | | | | | |

**Acceptance Criteria**:
- [ ] All stages documented
- [ ] MEDDIC minimum scores assigned per stage

---

#### Task 1.2.3: Document Opportunity Record Types
**Objective**: Understand different opportunity types and their sales processes

**Steps**:
```bash
sf data query --query "SELECT Name, DeveloperName, Description, IsActive FROM RecordType WHERE SobjectType = 'Opportunity' AND IsActive = true" --json
```

**Deliverable**: Record type documentation with MEDDIC applicability

**Acceptance Criteria**:
- [ ] All record types documented
- [ ] MEDDIC applicability determined for each

---

### 1.3 Related Objects Analysis

#### Task 1.3.1: Document OpportunityContactRole Configuration
**Objective**: Map contact roles to MEDDIC elements

**Steps**:
```bash
# Get role picklist values
sf sobject describe --sobject OpportunityContactRole --json | jq '.result.fields | map(select(.name == "Role")) | .[0].picklistValues'
```

**Deliverable**: Role-to-MEDDIC mapping

| Role Value | MEDDIC Element | Required at Stage |
|------------|----------------|-------------------|
| Economic Buyer | E | Solution Development |
| Champion | C | Discovery |
| Decision Maker | D-Process | Proposal |
| ... | | |

**Acceptance Criteria**:
- [ ] All roles documented
- [ ] MEDDIC element mapping complete
- [ ] Stage requirements defined

---

#### Task 1.3.2: Analyze Activity Configuration
**Objective**: Map activity types to MEDDIC evidence

**Steps**:
```bash
# Get Task type values
sf sobject describe --sobject Task --json | jq '.result.fields | map(select(.name == "Type")) | .[0].picklistValues'

# Get Event type values
sf sobject describe --sobject Event --json | jq '.result.fields | map(select(.name == "Type")) | .[0].picklistValues'
```

**Deliverable**: Activity-to-MEDDIC evidence mapping

| Activity Type | Object | MEDDIC Element | Evidence Weight |
|---------------|--------|----------------|-----------------|
| Discovery Call | Task | I, M | High |
| Executive Meeting | Event | E | High |
| Demo | Event | D-Criteria | Medium |
| ... | | | |

**Acceptance Criteria**:
- [ ] All activity types documented
- [ ] MEDDIC evidence mapping complete

---

### 1.4 Automation Analysis

#### Task 1.4.1: Document Opportunity Validation Rules
**Objective**: Identify existing MEDDIC enforcement rules

**Steps**:
```bash
sf data query --query "SELECT Name, Active, ErrorMessage, EntityDefinition.QualifiedApiName FROM ValidationRule WHERE Active = true AND EntityDefinition.QualifiedApiName = 'Opportunity'" --use-tooling-api --json
```

**Deliverable**: Validation rule inventory with MEDDIC relevance

**Acceptance Criteria**:
- [ ] All validation rules documented
- [ ] MEDDIC-related rules identified
- [ ] Stage-gating logic understood

---

#### Task 1.4.2: Document Relevant Flows
**Objective**: Identify automation affecting MEDDIC fields

**Steps**:
```bash
sf data query --query "SELECT DeveloperName, MasterLabel, ProcessType, Status FROM FlowDefinitionView WHERE Status = 'Active' AND (DeveloperName LIKE '%Opportunity%' OR DeveloperName LIKE '%MEDDIC%' OR DeveloperName LIKE '%TSPC%')" --use-tooling-api --json
```

**Deliverable**: Flow inventory with MEDDIC impact

**Acceptance Criteria**:
- [ ] Relevant flows documented
- [ ] MEDDIC field updates identified

---

## Phase 2: Data Analysis

### 2.1 Opportunity Data Sampling

#### Task 2.1.1: Pipeline Analysis
**Objective**: Understand current pipeline distribution by stage

**Steps**:
```bash
sf data query --query "SELECT StageName, RecordType.Name, COUNT(Id) OppCount, SUM(Amount) TotalAmount FROM Opportunity WHERE IsClosed = false GROUP BY StageName, RecordType.Name ORDER BY RecordType.Name, StageName" --json
```

**Deliverable**: Pipeline distribution report

**Acceptance Criteria**:
- [ ] Pipeline by stage documented
- [ ] Volume sufficient for analysis

---

#### Task 2.1.2: MEDDIC Field Completion Analysis
**Objective**: Assess current MEDDIC data quality

**Steps**:
```bash
# Query opportunities with MEDDIC fields (adjust field names based on discovery)
sf data query --query "SELECT StageName, COUNT(Id) TotalOpps, SUM(CASE WHEN TSPC__CPDeal__c != null THEN 1 ELSE 0 END) HasClosePlan FROM Opportunity WHERE IsClosed = false GROUP BY StageName" --json
```

**Deliverable**: Field completion matrix by stage

| Stage | Total Opps | Has ClosePlan | Has Champion | Has EB | ... |
|-------|------------|---------------|--------------|--------|-----|
| | | | | | |

**Acceptance Criteria**:
- [ ] Completion rates calculated
- [ ] Baseline established for improvement

---

#### Task 2.1.3: Sample Opportunity Deep Dive
**Objective**: Analyze complete data structure for sample opportunities

**Steps**:
```bash
# Get detailed opportunity data (adjust fields based on discovery)
sf data query --query "SELECT Id, Name, StageName, Amount, CloseDate, TSPC__CPDeal__c, (SELECT ContactId, Contact.Name, Role FROM OpportunityContactRoles), (SELECT Id, Subject, Type FROM Tasks ORDER BY ActivityDate DESC LIMIT 10) FROM Opportunity WHERE IsClosed = false AND Amount >= 100000 LIMIT 5" --json > scripts/sample_opps.json
```

**Deliverable**: Documented data structure for GPTfy mapping

**Acceptance Criteria**:
- [ ] Complete data paths identified
- [ ] Relationship traversal validated

---

### 2.2 Activity Pattern Analysis

#### Task 2.2.1: Activity Volume Analysis
**Objective**: Understand activity patterns on opportunities

**Steps**:
```bash
sf data query --query "SELECT What.Name, COUNT(Id) TaskCount FROM Task WHERE What.Type = 'Opportunity' AND CreatedDate >= LAST_N_MONTHS:6 GROUP BY What.Name ORDER BY COUNT(Id) DESC LIMIT 20" --json
```

**Deliverable**: Activity volume benchmarks

**Acceptance Criteria**:
- [ ] Average activity levels established
- [ ] Stalled deal thresholds defined

---

### 2.3 Win/Loss Analysis

#### Task 2.3.1: MEDDIC Score Correlation
**Objective**: Validate correlation between MEDDIC completion and win rate

**Steps**:
```bash
# Analyze won deals MEDDIC completion (adjust fields based on discovery)
sf data query --query "SELECT Id, Name, Amount, CloseDate, Overall_Score__c FROM Opportunity WHERE IsWon = true AND CloseDate >= LAST_N_MONTHS:12 ORDER BY Amount DESC LIMIT 50" --json
```

**Deliverable**: Win rate by MEDDIC score range

**Acceptance Criteria**:
- [ ] Correlation established
- [ ] Score thresholds validated

---

## Phase 3: GPTfy Configuration

### 3.1 Data Context Mapping Setup

#### Task 3.1.1: Create Data Context Mapping
**Objective**: Configure GPTfy to pull all MEDDIC-relevant data

**Steps**:
1. Navigate to GPTfy Cockpit → Data Context Mapping → New
2. Configure mapping per PRD specification
3. Include all identified objects and fields
4. Test data retrieval

**Configuration**:
```yaml
Mapping Name: MEDDIC Compliance Analysis
Target Object: Opportunity

Fields: [Per PRD section 6.1]

Related Objects:
  - OpportunityContactRole
  - TSPC__Stakeholder__c (via TSPC__CPDeal__c)
  - TSPC__Pain__c (via TSPC__CPDeal__c)
  - TSPC__Metric__c (via TSPC__CPDeal__c)
  - TSPC__Decision_Criteria__c (via TSPC__CPDeal__c)
  - TSPC__Decision_Process__c (via TSPC__CPDeal__c)
  - TSPC__Competition__c (via TSPC__CPDeal__c)
  - Task (limit: 20)
  - Event (limit: 20)
```

**Acceptance Criteria**:
- [ ] All objects mapped successfully
- [ ] Data retrieval tested on sample opportunity
- [ ] All MEDDIC data accessible

---

#### Task 3.1.2: Validate Data Context Output
**Objective**: Ensure data context provides complete MEDDIC picture

**Steps**:
1. Test mapping on well-documented opportunity
2. Test mapping on sparse opportunity
3. Verify all relationships resolve correctly

**Acceptance Criteria**:
- [ ] Complete data returned for documented opps
- [ ] Graceful handling of missing data
- [ ] No null pointer errors

---

### 3.2 Prompt Development

#### Task 3.2.1: Develop Base Prompt
**Objective**: Create the MEDDIC analysis prompt

**Steps**:
1. Create new prompt in GPTfy Cockpit
2. Implement prompt per PRD section 6.2
3. Add grounding rules
4. Configure output format

**Acceptance Criteria**:
- [ ] Prompt executes without errors
- [ ] Output matches specified format
- [ ] All MEDDIC elements scored

---

#### Task 3.2.2: Configure Grounding Rules
**Objective**: Ensure AI responses are accurate and appropriate

**Rules to Implement**:
- Base assessments on provided data only
- Reference specific field values
- Consider stage context
- Be specific in recommendations
- Use consistent visual indicators

**Acceptance Criteria**:
- [ ] No hallucinated data in outputs
- [ ] Evidence cited for assessments
- [ ] Stage-appropriate expectations applied

---

### 3.3 Scoring Algorithm Implementation

#### Task 3.3.1: Implement Element Scoring
**Objective**: Configure scoring logic for each MEDDIC element

**Scoring Configuration** (per PRD section 4.1):

| Element | Weight | Data Sources | Scoring Criteria |
|---------|--------|--------------|------------------|
| Metrics | 15% | TSPC__Metric__c, SBQQ__Quote__c | 0-100 per rubric |
| Economic Buyer | 20% | Stakeholders, Activities | 0-100 per rubric |
| Decision Criteria | 15% | TSPC__Decision_Criteria__c | 0-100 per rubric |
| Decision Process | 15% | TSPC__Decision_Process__c | 0-100 per rubric |
| Identify Pain | 15% | TSPC__Pain__c | 0-100 per rubric |
| Champion | 20% | Stakeholders, Activities | 0-100 per rubric |

**Acceptance Criteria**:
- [ ] Each element scores correctly
- [ ] Weights applied properly
- [ ] Overall score calculates correctly

---

#### Task 3.3.2: Implement Stage Validation
**Objective**: Add stage-specific expectation validation

**Stage Requirements Matrix** (per PRD section 4.2):

| Stage | Min Score | Key Requirements |
|-------|-----------|------------------|
| Qualification | 40 | Pain, Champion identified |
| Discovery | 50 | Pain documented, Champion validated |
| Solution Development | 65 | EB engaged, Criteria confirmed |
| Proposal | 75 | Metrics validated, All criteria |
| Negotiation | 85 | EB committed, Final steps |

**Acceptance Criteria**:
- [ ] Stage expectations correctly applied
- [ ] Gap analysis generated
- [ ] Clear advancement readiness output

---

#### Task 3.3.3: Implement Risk Detection
**Objective**: Configure critical risk and warning detection

**Risk Configuration** (per PRD section 4.3):

| Risk Type | Condition | Severity |
|-----------|-----------|----------|
| No Champion | Stage >= Solution Dev AND Champion < 30 | Critical |
| No EB Engagement | Stage >= Proposal AND No EB activity 60d | Critical |
| Stalled Deal | No activity 30+ days | Critical |
| Champion at Risk | Disposition = Neutral | Warning |
| EB Cooling | No EB activity 30 days | Warning |

**Acceptance Criteria**:
- [ ] Critical risks correctly identified
- [ ] Warnings correctly flagged
- [ ] No false positives

---

## Phase 4: Testing & Validation

### 4.1 Test Scenario Execution

#### Task 4.1.1: Test Scenario - Well-Qualified Opportunity
**Objective**: Validate correct handling of strong opportunities

**Setup**:
- Find/create opportunity with complete MEDDIC data
- Stage: Proposal or later
- Recent activity with EB and Champion

**Expected Output**:
- Score: 80+
- Status: ON_TRACK
- Few/no critical risks
- Ready for stage advancement

**Acceptance Criteria**:
- [ ] Score in expected range
- [ ] No false negatives
- [ ] Appropriate recommendations

---

#### Task 4.1.2: Test Scenario - Under-Qualified Opportunity
**Objective**: Validate correct handling of weak opportunities

**Setup**:
- Find/create opportunity with sparse data
- Stage: Solution Development
- No EB, generic pain, no metrics

**Expected Output**:
- Score: 35-45
- Status: AT_RISK
- Multiple critical risks
- Specific remediation actions

**Acceptance Criteria**:
- [ ] Score in expected range
- [ ] Critical risks identified
- [ ] Actionable recommendations

---

#### Task 4.1.3: Test Scenario - Stalled Deal
**Objective**: Validate correct handling of stalled opportunities

**Setup**:
- Find/create opportunity with old activity
- No activity in 45+ days
- Champion disposition changed

**Expected Output**:
- Stalled deal warning
- Re-engagement recommendations
- Score penalty applied

**Acceptance Criteria**:
- [ ] Stalled status detected
- [ ] Appropriate warnings
- [ ] Re-engagement recommendations

---

#### Task 4.1.4: Test Scenario - New Opportunity
**Objective**: Validate correct handling of early-stage opportunities

**Setup**:
- Find/create new opportunity
- Stage: Qualification
- Minimal data (just champion identified)

**Expected Output**:
- Appropriate score for stage
- No false alarms for missing late-stage data
- Guidance on what to gather next

**Acceptance Criteria**:
- [ ] Stage-appropriate scoring
- [ ] No false negatives
- [ ] Helpful guidance

---

### 4.2 Validation Checklist

#### Task 4.2.1: Complete Validation Checklist
**Objective**: Systematic validation of all requirements

**Checklist**:

**Data Accuracy**:
- [ ] All TSPC objects queried correctly
- [ ] Relationships mapped correctly
- [ ] No null pointer errors
- [ ] Recent activities included
- [ ] Stakeholder roles interpreted correctly

**Scoring Accuracy**:
- [ ] Scores align with expected ranges
- [ ] Stage expectations applied correctly
- [ ] Risk indicators trigger correctly
- [ ] No score inflation/deflation

**Recommendations Quality**:
- [ ] Recommendations are specific
- [ ] Recommendations are actionable
- [ ] Owner suggestions appropriate
- [ ] Priority assignments logical

**Output Quality**:
- [ ] Format consistent
- [ ] All sections populated
- [ ] No hallucinated data
- [ ] Visual indicators correct
- [ ] Dates and numbers accurate

**Acceptance Criteria**:
- [ ] All checklist items passed

---

### 4.3 User Acceptance Testing

#### Task 4.3.1: Sales Manager Review
**Objective**: Get validation from actual users

**Steps**:
1. Run analysis on 20-30 real opportunities
2. Share results with 2-3 sales managers
3. Collect feedback on:
   - Score accuracy vs. their assessment
   - Missing considerations
   - Recommendation usefulness
   - Format preferences

**Deliverable**: Feedback summary and action items

**Acceptance Criteria**:
- [ ] Feedback collected from multiple managers
- [ ] Key issues identified
- [ ] Improvement backlog created

---

#### Task 4.3.2: Prompt Refinement
**Objective**: Improve prompt based on feedback

**Steps**:
1. Review feedback from Task 4.3.1
2. Identify prompt adjustments needed
3. Implement changes
4. Re-test affected scenarios
5. Document version changes

**Acceptance Criteria**:
- [ ] Feedback items addressed
- [ ] No regression in previous scenarios
- [ ] Version documented

---

## Phase 5: Rollout

### 5.1 Documentation

#### Task 5.1.1: Create User Guide
**Objective**: Document how to use the analyzer

**Content**:
- How to run analysis
- How to interpret results
- Understanding scores
- Acting on recommendations
- FAQs

**Acceptance Criteria**:
- [ ] Guide complete and reviewed
- [ ] Accessible to all users

---

#### Task 5.1.2: Create Admin Guide
**Objective**: Document administration and maintenance

**Content**:
- Configuration overview
- How to modify scoring
- Troubleshooting
- Monitoring and reporting

**Acceptance Criteria**:
- [ ] Guide complete and reviewed
- [ ] Ops team trained

---

### 5.2 Deployment

#### Task 5.2.1: Production Deployment
**Objective**: Deploy to production environment

**Steps**:
1. Create Data Context Mapping in production
2. Create Prompt in production
3. Configure profile access
4. Test on production data
5. Enable for pilot users

**Acceptance Criteria**:
- [ ] Configuration deployed
- [ ] Production test passed
- [ ] Pilot users enabled

---

#### Task 5.2.2: Pilot Rollout
**Objective**: Gradual rollout to validate in production

**Steps**:
1. Enable for single sales team
2. Monitor usage and feedback
3. Address issues
4. Expand to additional teams
5. Full rollout

**Acceptance Criteria**:
- [ ] Pilot team using successfully
- [ ] Issues resolved
- [ ] Ready for full rollout

---

### 5.3 Monitoring & Improvement

#### Task 5.3.1: Usage Monitoring
**Objective**: Track adoption and usage patterns

**Metrics to Track**:
- Number of analyses run
- Users running analyses
- Average scores by team
- Most common recommendations

**Acceptance Criteria**:
- [ ] Monitoring dashboard created
- [ ] Weekly reporting established

---

#### Task 5.3.2: Continuous Improvement Process
**Objective**: Establish ongoing refinement process

**Process**:
1. Collect user feedback weekly
2. Review accuracy quarterly
3. Update scoring based on win/loss data
4. Version control for prompt changes

**Acceptance Criteria**:
- [ ] Feedback channel established
- [ ] Quarterly review scheduled
- [ ] Version control in place

---

## Summary Checklist

### Phase 1: Metadata Discovery
- [ ] 1.1.1 Inventory TSPC Objects
- [ ] 1.1.2 Document TSPC Fields
- [ ] 1.1.3 Extract TSPC Picklists
- [ ] 1.2.1 Document Opportunity Fields
- [ ] 1.2.2 Document Stages
- [ ] 1.2.3 Document Record Types
- [ ] 1.3.1 Document Contact Roles
- [ ] 1.3.2 Analyze Activity Config
- [ ] 1.4.1 Document Validation Rules
- [ ] 1.4.2 Document Flows

### Phase 2: Data Analysis
- [ ] 2.1.1 Pipeline Analysis
- [ ] 2.1.2 Field Completion Analysis
- [ ] 2.1.3 Sample Deep Dive
- [ ] 2.2.1 Activity Volume Analysis
- [ ] 2.3.1 Win/Loss Correlation

### Phase 3: GPTfy Configuration
- [ ] 3.1.1 Create Data Context Mapping
- [ ] 3.1.2 Validate Data Context
- [ ] 3.2.1 Develop Base Prompt
- [ ] 3.2.2 Configure Grounding Rules
- [ ] 3.3.1 Implement Element Scoring
- [ ] 3.3.2 Implement Stage Validation
- [ ] 3.3.3 Implement Risk Detection

### Phase 4: Testing
- [ ] 4.1.1 Test Well-Qualified Opp
- [ ] 4.1.2 Test Under-Qualified Opp
- [ ] 4.1.3 Test Stalled Deal
- [ ] 4.1.4 Test New Opp
- [ ] 4.2.1 Complete Validation Checklist
- [ ] 4.3.1 Sales Manager Review
- [ ] 4.3.2 Prompt Refinement

### Phase 5: Rollout
- [ ] 5.1.1 Create User Guide
- [ ] 5.1.2 Create Admin Guide
- [ ] 5.2.1 Production Deployment
- [ ] 5.2.2 Pilot Rollout
- [ ] 5.3.1 Usage Monitoring
- [ ] 5.3.2 Continuous Improvement

---

*Document Version: 1.0*
*Last Updated: 2025-12-25*

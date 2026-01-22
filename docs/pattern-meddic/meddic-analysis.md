Below is a **very detailed, end-to-end Markdown playbook** you can directly use while working with **Metadata API and Tooling API**.
It is written as a **diagnostic + design runbook** for building a MEDDIC-aware AI evaluator in Salesforce that later feeds GPTfy.ai.

You can paste this into Confluence, Notion, or a repo README and execute it step by step.

---

# MEDDIC Diagnosis & AI Enablement Playbook

**Salesforce Metadata-Driven Approach**

---

## 0. Objective

Build an **org-specific MEDDIC intelligence framework** by analyzing:

• Installed managed packages
• Salesforce metadata (fields, flows, validation, path)
• Actual opportunity and activity data

Then translate this into:

• A deterministic MEDDIC ruleset
• Evidence mapping
• A GPTfy.ai prompt that audits deals, flags risks, and recommends next steps

---

## 1. Phase 1 – Package & Namespace Diagnosis

### 1.1 Identify MEDDIC-adjacent packages

From Installed Packages, classify each package into:

| Category        | Meaning                          |
| --------------- | -------------------------------- |
| MEDDIC Core     | Explicit MEDDIC framework        |
| MEDDIC Adjacent | Close plans, stakeholder mapping |
| Evidence Source | Calls, emails, meetings          |
| Irrelevant      | No sales qualification relevance |

### 1.2 High-confidence MEDDIC-adjacent package

**ClosePlan (TSPC namespace)**
This package is the only one that directly supports:

• Decision Process
• Stakeholder roles
• Milestones
• Mutual Action Plans

#### Metadata API extraction

```bash
sfdx force:mdapi:retrieve -k package.xml
```

Include:

```xml
<types>
  <members>TSPC__*</members>
  <name>CustomObject</name>
</types>
```

### 1.3 Inventory ClosePlan assets

For each object under `TSPC__*` capture:

• Object purpose
• Relationship to Opportunity
• Key fields
• Picklist values
• Validation rules

Output format:

```markdown
Object: TSPC__Close_Plan__c  
Purpose: Stores deal decision milestones  
Linked to: Opportunity via lookup  
Key Fields:
- Status
- Target_Date
- Stakeholder_Role
```

---

## 2. Phase 2 – Opportunity Object MEDDIC Field Discovery

### 2.1 Enumerate Opportunity fields

Using Tooling API:

```http
/tooling/query?q=
SELECT DeveloperName, Label, DataType
FROM CustomField
WHERE TableEnumOrId = 'Opportunity'
```

### 2.2 Search MEDDIC indicators

Flag fields where Label or API name contains:

```
metric
economic
buyer
champion
decision
criteria
process
pain
value
roi
impact
```

Classify each field:

| Field                  | MEDDIC Element | Type            | Evidence Level |
| ---------------------- | -------------- | --------------- | -------------- |
| Pain_Point__c          | Identify Pain  | Free Text       | Claim          |
| Economic_Buyer__c      | EB             | Lookup(Contact) | Partial        |
| Value_Justification__c | Metrics        | Long Text       | Claim          |

---

## 3. Phase 3 – Sales Process & Stage Mapping

### 3.1 Extract sales processes

```http
/tooling/query?q=
SELECT Id, DeveloperName
FROM OpportunityRecordType
```

For each Record Type:

```http
/tooling/query?q=
SELECT StageName, IsActive, SortOrder
FROM OpportunityStage
```

Document:

```markdown
Record Type: Enterprise_Sales  
Stages:
1. Qualification
2. Discovery
3. Evaluation
4. Proposal
5. Negotiation
6. Commit
```

---

## 4. Phase 4 – Sales Path & Stage Enforcement

### 4.1 Extract Path configuration

Metadata API types:

```xml
<types>
  <name>PathAssistant</name>
</types>
```

For each stage capture:

• Key Fields
• Guidance text
• Success indicators

Example:

```markdown
Stage: Discovery  
Key Fields:
- Pain_Point__c
- Decision_Criteria__c
- Champion__c
Guidance:
"Confirm business pain and identify internal champion"
```

---

## 5. Phase 5 – Validation Rules & Automation

### 5.1 Validation rules

```http
/tooling/query?q=
SELECT Name, ErrorMessage, Active
FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
```

Map rules like:

```markdown
Rule: Require_EB_On_Proposal  
Condition: ISPICKVAL(StageName,'Proposal') && ISBLANK(Economic_Buyer__c)
```

This becomes **hard MEDDIC enforcement logic**.

### 5.2 Flows

Metadata types:

```xml
<types>
  <name>Flow</name>
</types>
```

Search flows triggered on:

• Stage change
• Opportunity update

Extract logic referencing MEDDIC fields.

---

## 6. Phase 6 – Evidence Source Mapping

### 6.1 Activity model

Identify where evidence lives:

| Source   | Object                               |
| -------- | ------------------------------------ |
| Calls    | Task                                 |
| Meetings | Event                                |
| Emails   | EmailMessage                         |
| Notes    | ContentNote / EnhancedNote           |
| CTI      | aircall__Call__c / TwilioSF__Call__c |

### 6.2 MEDDIC evidence mapping

| MEDDIC            | Evidence Objects                |
| ----------------- | ------------------------------- |
| Metrics           | Notes, Opportunity fields       |
| Economic Buyer    | ContactRole, Activities         |
| Decision Criteria | Notes, ClosePlan items          |
| Decision Process  | ClosePlan milestones            |
| Pain              | Notes, Description              |
| Champion          | ContactRole, Activity frequency |

---

## 7. Phase 7 – MEDDIC Strength Model

Define a **three-level strength scale** per element:

| Level     | Meaning                         |
| --------- | ------------------------------- |
| Missing   | No data                         |
| Claimed   | Field filled but no proof       |
| Evidenced | Verified via activities or docs |

---

## 8. Phase 8 – Stage vs MEDDIC Matrix

Example:

```markdown
Stage: Discovery
Required:
- Pain: Evidenced
- Metrics: Claimed
- Decision Criteria: Claimed
Optional:
- Economic Buyer
- Champion
```

```markdown
Stage: Proposal
Required:
- Metrics: Evidenced
- Economic Buyer: Evidenced
- Decision Process: Evidenced
- Champion: Evidenced
```

This matrix is the **core intelligence layer**.

---

## 9. Phase 9 – GPTfy Prompt Design

### 9.1 Prompt inputs

**Metadata Bundle**
• Stage definitions
• MEDDIC field list
• Enforcement rules

**Data Bundle**
• Opportunity fields
• ClosePlan records
• Activities
• Notes

### 9.2 Reasoning flow

1. Identify record type and stage
2. Load stage MEDDIC requirements
3. Evaluate each MEDDIC element
4. Assign strength
5. Check stage alignment
6. Generate risks and next steps

---

## 10. Phase 10 – Output Schema

```json
{
  "stageAlignment": "Overstated",
  "meddicSummary": {
    "metrics": "Claimed",
    "economicBuyer": "Missing",
    "decisionCriteria": "Evidenced",
    "decisionProcess": "Claimed",
    "pain": "Evidenced",
    "champion": "Weak"
  },
  "risks": [
    "No economic buyer identified for Proposal stage",
    "Decision process lacks approval milestone"
  ],
  "nextBestActions": [
    "Schedule meeting with economic buyer",
    "Document approval steps in close plan"
  ],
  "recommendedSalesforceUpdates": [
    "Populate Economic_Buyer__c",
    "Add approval milestone to TSPC__Close_Plan__c"
  ]
}
```

---

## 11. Phase 11 – Governance & Trust

• Cite record IDs for evidence
• Do not infer buyer intent without proof
• Treat filled fields without activities as weak
• Never override stage automatically

---

## 12. Final Deliverables

At the end of this process you will have:

1. Org-specific MEDDIC definition
2. Stage-aware qualification model
3. Evidence-based enforcement logic
4. GPTfy.ai production prompt
5. Actionable deal coaching engine

---


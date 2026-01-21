# MEDDIC Compliance Analyzer for GPTfy
## Complete Discovery & Implementation Guide

---

# Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Phase 1: Metadata Discovery](#2-phase-1-metadata-discovery)
   - [1.1 ClosePlan Package Analysis](#21-closeplan-tspc-package-analysis)
   - [1.2 Opportunity Object Analysis](#22-opportunity-object-analysis)
   - [1.3 Related Objects Analysis](#23-related-objects-analysis)
   - [1.4 Sales Process & Path Analysis](#24-sales-process--path-analysis)
   - [1.5 Automation & Business Logic](#25-automation--business-logic)
3. [Phase 2: Data Analysis](#3-phase-2-data-analysis)
   - [2.1 Opportunity Data Sampling](#31-opportunity-data-sampling)
   - [2.2 Activity Pattern Analysis](#32-activity-pattern-analysis)
   - [2.3 Contact Role Analysis](#33-contact-role-analysis)
   - [2.4 Win/Loss Analysis](#34-winloss-analysis)
4. [Phase 3: MEDDIC Element Mapping](#4-phase-3-meddic-element-mapping)
5. [Phase 4: Stage-Based Validation Matrix](#5-phase-4-stage-based-validation-matrix)
6. [Phase 5: Scoring Algorithm Design](#6-phase-5-scoring-algorithm-design)
7. [Phase 6: GPTfy Implementation](#7-phase-6-gptfy-implementation)
8. [Phase 7: Testing & Validation](#8-phase-7-testing--validation)
9. [Appendices](#9-appendices)

---

# 1. Executive Summary

## 1.1 Project Objective

Create an AI-powered MEDDIC compliance analyzer using GPTfy that:
- Evaluates opportunity qualification against MEDDIC methodology
- Provides stage-appropriate validation criteria
- Identifies gaps and risks in deal qualification
- Recommends specific next actions for sales reps
- Supports 4-14 month complex sales cycles typical in retail automation/ESL industry

## 1.2 Key Components Identified

| Component | Package/Source | Purpose |
|-----------|---------------|---------|
| **ClosePlan** | `TSPC` namespace (v1.291) | Primary MEDDIC methodology implementation |
| **Klue** | `klue` namespace (v2.0) | Competitive intelligence integration |
| **GPTfy/SecureGPT** | `ccai` namespace (v1.12) | AI prompt execution platform |
| **LinkedIn Sales Navigator** | `LID` namespace | Contact/relationship intelligence |
| **Salesforce CPQ** | `SBQQ` namespace | Quote/pricing data for Metrics validation |

## 1.3 Deliverables

1. **Discovery Documentation** - Complete mapping of MEDDIC data structure
2. **Validation Matrix** - Stage-by-stage requirements
3. **Scoring Algorithm** - Weighted scoring model
4. **GPTfy Data Context Mapping** - Salesforce object/field configuration
5. **GPTfy Prompt** - AI prompt with grounding rules
6. **Testing Framework** - Validation scenarios and expected outputs

---

# 2. Phase 1: Metadata Discovery

## 2.1 ClosePlan (TSPC) Package Analysis

### 2.1.1 Retrieve All TSPC Custom Objects

**Metadata API - package.xml:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>TSPC__*</members>
        <name>CustomObject</name>
    </types>
    <version>59.0</version>
</Package>
```

**Tooling API Query - List All TSPC Objects:**

```sql
SELECT Id, DeveloperName, Label, Description, NamespacePrefix
FROM EntityDefinition
WHERE NamespacePrefix = 'TSPC'
ORDER BY Label
```

**Expected Objects to Document:**

| Object API Name | Expected Purpose | Relationship to Opportunity |
|-----------------|------------------|----------------------------|
| `TSPC__Close_Plan__c` | Main qualification record | Master-Detail or Lookup to Opportunity |
| `TSPC__Metric__c` | Business metrics/ROI | Child of Close Plan |
| `TSPC__Pain__c` | Identified pain points | Child of Close Plan |
| `TSPC__Champion__c` | Champion tracking | Lookup to Contact |
| `TSPC__Economic_Buyer__c` | EB tracking | Lookup to Contact |
| `TSPC__Decision_Criteria__c` | Technical/Business criteria | Child of Close Plan |
| `TSPC__Decision_Process__c` | Buying process steps | Child of Close Plan |
| `TSPC__Stakeholder__c` | Buying committee members | Junction to Contact |
| `TSPC__Competition__c` | Competitive intelligence | Child of Close Plan |
| `TSPC__Action_Item__c` | Next steps/actions | Child of Close Plan |

### 2.1.2 Retrieve TSPC Object Field Definitions

**Tooling API Query - All Fields per Object:**

```sql
SELECT EntityDefinition.QualifiedApiName, QualifiedApiName, Label, DataType, 
       Description, IsRequired, IsNillable, Length, Precision, Scale,
       ReferenceTo, RelationshipName, InlineHelpText
FROM FieldDefinition
WHERE EntityDefinition.NamespacePrefix = 'TSPC'
ORDER BY EntityDefinition.QualifiedApiName, Label
```

**Alternative - Metadata API for Each Object:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>TSPC__Close_Plan__c</members>
        <members>TSPC__Metric__c</members>
        <members>TSPC__Pain__c</members>
        <members>TSPC__Champion__c</members>
        <members>TSPC__Economic_Buyer__c</members>
        <members>TSPC__Decision_Criteria__c</members>
        <members>TSPC__Decision_Process__c</members>
        <members>TSPC__Stakeholder__c</members>
        <members>TSPC__Competition__c</members>
        <!-- Add all 50 objects once discovered -->
        <name>CustomObject</name>
    </types>
    <version>59.0</version>
</Package>
```

### 2.1.3 Document Object Relationships

**Tooling API Query - Relationship Mapping:**

```sql
SELECT EntityDefinition.QualifiedApiName AS ParentObject,
       QualifiedApiName AS FieldName,
       Label,
       DataType,
       ReferenceTo,
       RelationshipName,
       IsNillable
FROM FieldDefinition
WHERE EntityDefinition.NamespacePrefix = 'TSPC'
  AND DataType IN ('Lookup', 'MasterDetail', 'Hierarchy')
ORDER BY EntityDefinition.QualifiedApiName
```

**Expected Relationship Diagram:**

```
Opportunity
    │
    ├── TSPC__Close_Plan__c (1:1 or 1:Many)
    │       │
    │       ├── TSPC__Metric__c (1:Many)
    │       │       └── Fields: Value, Type, Timeframe, Status
    │       │
    │       ├── TSPC__Pain__c (1:Many)
    │       │       └── Fields: Description, Impact, Priority, Owner
    │       │
    │       ├── TSPC__Decision_Criteria__c (1:Many)
    │       │       └── Fields: Criteria, Type (Tech/Business), Weight, Met?
    │       │
    │       ├── TSPC__Decision_Process__c (1:Many)
    │       │       └── Fields: Step, Owner, Timeline, Status
    │       │
    │       ├── TSPC__Stakeholder__c (1:Many)
    │       │       ├── Lookup → Contact
    │       │       └── Fields: Role, Influence, Disposition, Access
    │       │
    │       ├── TSPC__Competition__c (1:Many)
    │       │       └── Fields: Competitor, Strengths, Weaknesses, Strategy
    │       │
    │       └── TSPC__Action_Item__c (1:Many)
    │               └── Fields: Action, Owner, Due Date, Status
    │
    ├── OpportunityContactRole (Standard)
    │       └── Role: Decision Maker, Champion, Influencer, etc.
    │
    ├── OpportunityLineItem (via CPQ)
    │       └── SBQQ__* fields for pricing/metrics
    │
    └── Task/Event (Activities)
            └── Activity history for engagement tracking
```

### 2.1.4 Analyze TSPC Picklist Values

**Tooling API Query - All Picklist Values:**

```sql
SELECT EntityDefinition.QualifiedApiName AS ObjectName,
       QualifiedApiName AS FieldName,
       Label,
       DataType
FROM FieldDefinition
WHERE EntityDefinition.NamespacePrefix = 'TSPC'
  AND DataType = 'Picklist'
```

**For Each Picklist Field, Get Values:**

```sql
SELECT Id, Value, Label, IsActive, IsDefaultValue
FROM PicklistValueInfo
WHERE EntityParticleId IN (
    SELECT Id FROM EntityParticle 
    WHERE EntityDefinition.NamespacePrefix = 'TSPC'
      AND DataType = 'Picklist'
)
ORDER BY EntityParticle.QualifiedApiName, SortOrder
```

**Key Picklists to Document:**

| Object | Field | Expected Values | Purpose |
|--------|-------|-----------------|---------|
| `TSPC__Close_Plan__c` | `Status__c` | Draft, In Progress, Complete | Overall plan status |
| `TSPC__Stakeholder__c` | `Role__c` | EB, Champion, Influencer, Blocker | MEDDIC role mapping |
| `TSPC__Stakeholder__c` | `Disposition__c` | Supporter, Neutral, Opponent | Relationship status |
| `TSPC__Stakeholder__c` | `Influence__c` | High, Medium, Low | Power in decision |
| `TSPC__Pain__c` | `Priority__c` | Critical, High, Medium, Low | Pain severity |
| `TSPC__Decision_Criteria__c` | `Type__c` | Technical, Business, Financial | Criteria category |
| `TSPC__Decision_Criteria__c` | `Status__c` | Not Started, In Progress, Met | Validation status |
| `TSPC__Competition__c` | `Threat_Level__c` | High, Medium, Low, None | Competitive risk |

### 2.1.5 Analyze TSPC Validation Rules

**Metadata API - Retrieve Validation Rules:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>TSPC__Close_Plan__c.*</members>
        <members>TSPC__Metric__c.*</members>
        <members>TSPC__Pain__c.*</members>
        <members>TSPC__Stakeholder__c.*</members>
        <!-- Add all TSPC objects -->
        <name>ValidationRule</name>
    </types>
    <version>59.0</version>
</Package>
```

**Tooling API Query:**

```sql
SELECT Id, ValidationName, Description, ErrorMessage, 
       ErrorDisplayField, Active, EntityDefinition.QualifiedApiName
FROM ValidationRule
WHERE EntityDefinition.NamespacePrefix = 'TSPC'
  AND Active = true
ORDER BY EntityDefinition.QualifiedApiName
```

**Documentation Template:**

| Object | Rule Name | Condition | Error Message | Business Purpose |
|--------|-----------|-----------|---------------|------------------|
| | | | | |

---

## 2.2 Opportunity Object Analysis

### 2.2.1 Retrieve All Opportunity Fields

**Tooling API - Complete Field List:**

```sql
SELECT QualifiedApiName, Label, DataType, Description, 
       IsRequired, IsNillable, InlineHelpText,
       Length, Precision, Scale,
       ReferenceTo, RelationshipName,
       IsCompound, IsCalculated, IsCustom,
       NamespacePrefix
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
ORDER BY NamespacePrefix NULLS FIRST, Label
```

**Categorize Fields:**

```sql
-- Standard Opportunity Fields
SELECT QualifiedApiName, Label, DataType, IsRequired
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = null
  AND IsCustom = false
ORDER BY Label

-- TSPC (ClosePlan) Fields on Opportunity
SELECT QualifiedApiName, Label, DataType, IsRequired, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = 'TSPC'
ORDER BY Label

-- SBQQ (CPQ) Fields on Opportunity
SELECT QualifiedApiName, Label, DataType, IsRequired
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = 'SBQQ'
ORDER BY Label

-- Other Custom Fields (non-packaged)
SELECT QualifiedApiName, Label, DataType, IsRequired, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = null
  AND IsCustom = true
ORDER BY Label
```

### 2.2.2 Opportunity Stage Configuration

**Tooling API - Stage Picklist Values:**

```sql
SELECT Id, Value, Label, IsActive, IsDefaultValue, 
       ForecastCategory, Probability, IsClosed, IsWon
FROM OpportunityStage
WHERE IsActive = true
ORDER BY SortOrder
```

**Documentation Template - Stage Analysis:**

| Stage Name | Sort Order | Probability | Forecast Category | Is Closed | Is Won | MEDDIC Requirements |
|------------|------------|-------------|-------------------|-----------|--------|---------------------|
| Qualification | 1 | 10% | Pipeline | No | No | Pain, Champion (partial) |
| Discovery | 2 | 20% | Pipeline | No | No | Pain, Champion, Metrics (started) |
| Solution Development | 3 | 40% | Best Case | No | No | +Economic Buyer, Decision Criteria |
| Proposal | 4 | 60% | Commit | No | No | +Decision Process |
| Negotiation | 5 | 80% | Commit | No | No | All elements validated |
| Closed Won | 6 | 100% | Closed | Yes | Yes | Complete documentation |
| Closed Lost | 7 | 0% | Omitted | Yes | No | Loss analysis |

### 2.2.3 Opportunity Record Types

**Tooling API Query:**

```sql
SELECT Id, Name, DeveloperName, Description, IsActive, 
       SobjectType, BusinessProcessId
FROM RecordType
WHERE SobjectType = 'Opportunity'
  AND IsActive = true
ORDER BY Name
```

**For Each Record Type - Get Associated Sales Process:**

```sql
SELECT Id, Name, Description, IsActive
FROM BusinessProcess
WHERE TableEnumOrId = 'Opportunity'
ORDER BY Name
```

**Documentation Template:**

| Record Type | Developer Name | Sales Process | Use Case | Stage Differences |
|-------------|----------------|---------------|----------|-------------------|
| New Business | New_Business | Standard Sales | New logo acquisition | Full 6-stage process |
| Expansion | Expansion | Expansion Sales | Existing customer growth | May skip Qualification |
| Renewal | Renewal | Renewal Process | Contract renewals | Simplified stages |

### 2.2.4 Opportunity Validation Rules

**Tooling API Query:**

```sql
SELECT Id, ValidationName, Description, ErrorMessage,
       ErrorDisplayField, Active, Metadata
FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND Active = true
ORDER BY ValidationName
```

**Metadata API - Full Rule Definitions:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Opportunity.*</members>
        <name>ValidationRule</name>
    </types>
    <version>59.0</version>
</Package>
```

**Analysis Focus:**
- Stage-gating rules (what must be filled before advancing)
- Amount thresholds triggering additional requirements
- MEDDIC field dependencies
- Close date restrictions

### 2.2.5 Opportunity Page Layouts

**Metadata API:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Opportunity-*</members>
        <name>Layout</name>
    </types>
    <version>59.0</version>
</Package>
```

**Tooling API - Layout Assignments:**

```sql
SELECT Id, Layout.Name, RecordType.Name, ProfileId, Profile.Name
FROM ProfileLayout
WHERE TableEnumOrId = 'Opportunity'
ORDER BY Profile.Name, RecordType.Name
```

**Document for Each Layout:**
- Sections and their fields
- Required vs. read-only fields
- Related lists included
- TSPC components/sections

---

## 2.3 Related Objects Analysis

### 2.3.1 OpportunityContactRole

**Tooling API - Role Picklist:**

```sql
SELECT Id, Value, Label, IsActive, IsDefaultValue, SortOrder
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'OpportunityContactRole'
  AND EntityParticle.QualifiedApiName = 'Role'
  AND IsActive = true
ORDER BY SortOrder
```

**SOQL - Current Usage Analysis:**

```sql
SELECT Role, COUNT(Id) RoleCount
FROM OpportunityContactRole
WHERE Opportunity.IsClosed = false
GROUP BY Role
ORDER BY COUNT(Id) DESC
```

**Expected/Recommended Roles for MEDDIC:**

| Role Value | MEDDIC Element | Required at Stage | Validation Criteria |
|------------|----------------|-------------------|---------------------|
| Economic Buyer | E - Economic Buyer | Solution Development | Has budget authority |
| Champion | C - Champion | Discovery | Internal advocate |
| Decision Maker | D - Decision Process | Proposal | Final approval authority |
| Evaluator | D - Decision Criteria | Discovery | Technical validator |
| Influencer | General | Any | Affects decision |
| User | I - Pain | Qualification | Experiences the pain |
| Blocker | Risk Assessment | Any | Potential obstacle |

### 2.3.2 Contact Object (MEDDIC-Related Fields)

**Tooling API - TSPC Fields on Contact:**

```sql
SELECT QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Contact'
  AND NamespacePrefix = 'TSPC'
ORDER BY Label
```

**Tooling API - Custom Fields on Contact:**

```sql
SELECT QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Contact'
  AND IsCustom = true
  AND NamespacePrefix = null
ORDER BY Label
```

**Fields to Look For:**

| Field | Purpose | MEDDIC Element |
|-------|---------|----------------|
| `TSPC__Influence_Level__c` | Stakeholder power | E, C |
| `TSPC__Disposition__c` | Supporter/Neutral/Opponent | C |
| `TSPC__Buying_Role__c` | Role in purchase | E, D-Process |
| `Title` (Standard) | Job title for EB identification | E |
| `ReportsToId` (Standard) | Org hierarchy | D-Process |

### 2.3.3 Account Object (MEDDIC-Related Fields)

**Tooling API Query:**

```sql
SELECT QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Account'
  AND (NamespacePrefix = 'TSPC' 
       OR QualifiedApiName LIKE '%Decision%'
       OR QualifiedApiName LIKE '%Buying%'
       OR QualifiedApiName LIKE '%Budget%')
ORDER BY Label
```

**Fields to Look For:**

| Field | Purpose | MEDDIC Element |
|-------|---------|----------------|
| `TSPC__Typical_Buying_Process__c` | Standard procurement steps | D-Process |
| `TSPC__Budget_Cycle__c` | Fiscal year timing | M, D-Process |
| `NumberOfEmployees` | Company size for Metrics | M |
| `AnnualRevenue` | Revenue for ROI calculations | M |
| `Industry` | Industry-specific pain points | I |

### 2.3.4 Task & Event Objects (Activity Tracking)

**Tooling API - Task Type Picklist:**

```sql
SELECT Value, Label, IsActive
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'Task'
  AND EntityParticle.QualifiedApiName = 'Type'
  AND IsActive = true
ORDER BY SortOrder
```

**Tooling API - Event Type Picklist:**

```sql
SELECT Value, Label, IsActive
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'Event'
  AND EntityParticle.QualifiedApiName = 'Type'
  AND IsActive = true
ORDER BY SortOrder
```

**Activity Types to Map to MEDDIC:**

| Activity Type | MEDDIC Element | Significance |
|---------------|----------------|--------------|
| Discovery Call | I - Pain, M - Metrics | Initial qualification |
| Demo | D - Decision Criteria | Technical validation |
| Executive Meeting | E - Economic Buyer | EB engagement |
| Technical Review | D - Decision Criteria | Tech validation |
| Proposal Review | D - Decision Process | Proposal stage |
| Contract Review | D - Decision Process, Paper | Legal/procurement |
| Site Visit | M - Metrics | Metrics validation |
| Reference Call | C - Champion | Champion development |

### 2.3.5 Product & Quote Objects (Metrics Validation)

**CPQ Quote Fields:**

```sql
SELECT QualifiedApiName, Label, DataType
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'SBQQ__Quote__c'
  AND (QualifiedApiName LIKE '%Total%' 
       OR QualifiedApiName LIKE '%Discount%'
       OR QualifiedApiName LIKE '%Margin%')
ORDER BY Label
```

**Opportunity Product Fields:**

```sql
SELECT QualifiedApiName, Label, DataType
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'OpportunityLineItem'
ORDER BY Label
```

### 2.3.6 Klue Integration (Competition)

**Tooling API - Klue Objects:**

```sql
SELECT Id, DeveloperName, Label, Description
FROM EntityDefinition
WHERE NamespacePrefix = 'klue'
ORDER BY Label
```

**Klue Fields on Opportunity:**

```sql
SELECT QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = 'klue'
ORDER BY Label
```

---

## 2.4 Sales Process & Path Analysis

### 2.4.1 Sales Path Configuration

**Metadata API - PathAssistant:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>PathAssistant</name>
    </types>
    <version>59.0</version>
</Package>
```

**PathAssistant XML Structure (Expected):**

```xml
<PathAssistant>
    <active>true</active>
    <entityName>Opportunity</entityName>
    <fieldName>StageName</fieldName>
    <masterLabel>Opportunity Path</masterLabel>
    <pathAssistantSteps>
        <fieldNames>TSPC__Close_Plan__c</fieldNames>
        <fieldNames>TSPC__Champion_Contact__c</fieldNames>
        <fieldNames>TSPC__Pain_Summary__c</fieldNames>
        <info>Identify key pain points and establish Champion</info>
        <picklistValueName>Discovery</picklistValueName>
    </pathAssistantSteps>
    <!-- More steps... -->
    <recordTypeName>New_Business</recordTypeName>
</PathAssistant>
```

**Documentation Template - Path Steps:**

| Stage | Fields Shown | Guidance Text | Success Criteria |
|-------|--------------|---------------|------------------|
| Qualification | | | |
| Discovery | | | |
| Solution Development | | | |
| Proposal | | | |
| Negotiation | | | |

### 2.4.2 Sales Process Definitions

**Tooling API:**

```sql
SELECT Id, Name, Description, IsActive, TableEnumOrId
FROM BusinessProcess
WHERE TableEnumOrId = 'Opportunity'
ORDER BY Name
```

**Get Stage Values per Sales Process:**

```sql
SELECT BusinessProcess.Name, 
       OpportunityStage.Value, 
       OpportunityStage.ForecastCategory,
       OpportunityStage.Probability
FROM BusinessProcessStage
WHERE BusinessProcess.TableEnumOrId = 'Opportunity'
ORDER BY BusinessProcess.Name, SortOrder
```

---

## 2.5 Automation & Business Logic

### 2.5.1 Flows Related to Opportunity/MEDDIC

**Tooling API - Active Flows:**

```sql
SELECT Id, Definition.DeveloperName, Definition.MasterLabel, 
       Definition.Description, ProcessType, Status,
       Definition.ActiveVersionId
FROM FlowVersionView
WHERE Status = 'Active'
  AND (Definition.DeveloperName LIKE '%Opportunity%'
       OR Definition.DeveloperName LIKE '%MEDDIC%'
       OR Definition.DeveloperName LIKE '%TSPC%'
       OR Definition.DeveloperName LIKE '%Close_Plan%'
       OR Definition.DeveloperName LIKE '%Qualification%')
ORDER BY Definition.MasterLabel
```

**Metadata API - Flow Definitions:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*Opportunity*</members>
        <members>*MEDDIC*</members>
        <members>*Close_Plan*</members>
        <name>Flow</name>
    </types>
    <version>59.0</version>
</Package>
```

### 2.5.2 Process Builder (Legacy)

**Tooling API:**

```sql
SELECT Id, Definition.DeveloperName, Definition.MasterLabel,
       Status, ProcessType
FROM FlowVersionView
WHERE ProcessType = 'Workflow'
  AND Status = 'Active'
ORDER BY Definition.MasterLabel
```

### 2.5.3 Apex Triggers

**Tooling API:**

```sql
SELECT Id, Name, TableEnumOrId, Body, Status, IsValid
FROM ApexTrigger
WHERE TableEnumOrId IN ('Opportunity', 'TSPC__Close_Plan__c', 
                         'TSPC__Stakeholder__c', 'OpportunityContactRole')
  AND Status = 'Active'
ORDER BY TableEnumOrId, Name
```

### 2.5.4 Workflow Rules (Legacy)

**Metadata API:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Opportunity.*</members>
        <members>TSPC__Close_Plan__c.*</members>
        <name>WorkflowRule</name>
    </types>
    <version>59.0</version>
</Package>
```

---

# 3. Phase 2: Data Analysis

## 3.1 Opportunity Data Sampling

### 3.1.1 Current Pipeline Overview

```sql
SELECT StageName, 
       RecordType.Name RecordTypeName,
       COUNT(Id) OppCount,
       SUM(Amount) TotalAmount,
       AVG(Amount) AvgAmount
FROM Opportunity
WHERE IsClosed = false
GROUP BY StageName, RecordType.Name
ORDER BY RecordType.Name, StageName
```

### 3.1.2 MEDDIC Field Completion Analysis

```sql
-- Adjust field names based on Phase 1 discovery
SELECT StageName,
       COUNT(Id) TotalOpps,
       
       -- Metrics
       SUM(CASE WHEN TSPC__Metrics_Defined__c = true THEN 1 ELSE 0 END) MetricsComplete,
       
       -- Economic Buyer
       SUM(CASE WHEN TSPC__Economic_Buyer__c != null THEN 1 ELSE 0 END) EBIdentified,
       
       -- Decision Criteria
       SUM(CASE WHEN TSPC__Decision_Criteria_Status__c = 'Complete' THEN 1 ELSE 0 END) DCComplete,
       
       -- Decision Process
       SUM(CASE WHEN TSPC__Decision_Process_Mapped__c = true THEN 1 ELSE 0 END) DPMapped,
       
       -- Identify Pain
       SUM(CASE WHEN TSPC__Pain_Identified__c = true THEN 1 ELSE 0 END) PainIdentified,
       
       -- Champion
       SUM(CASE WHEN TSPC__Champion__c != null THEN 1 ELSE 0 END) ChampionIdentified

FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 50000  -- Focus on significant deals
GROUP BY StageName
ORDER BY StageName
```

### 3.1.3 Sample Opportunity Deep Dive

```sql
SELECT 
    -- Core Opportunity Fields
    Id, Name, StageName, Amount, CloseDate, Probability,
    ForecastCategory, LeadSource, Type,
    Account.Name, Account.Industry, Account.NumberOfEmployees,
    Owner.Name,
    
    -- TSPC Fields (adjust based on discovery)
    TSPC__Close_Plan__c,
    TSPC__Champion__c,
    TSPC__Champion__r.Name,
    TSPC__Champion__r.Title,
    TSPC__Economic_Buyer__c,
    TSPC__Economic_Buyer__r.Name,
    TSPC__Economic_Buyer__r.Title,
    TSPC__Pain_Summary__c,
    TSPC__Metrics_Summary__c,
    TSPC__Decision_Criteria_Summary__c,
    TSPC__Decision_Process_Summary__c,
    TSPC__Competition_Summary__c,
    TSPC__MEDDIC_Score__c,
    TSPC__Close_Plan_Status__c,
    
    -- CPQ Fields
    SBQQ__PrimaryQuote__c,
    SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c,
    
    -- Klue Fields
    klue__Primary_Competitor__c,
    
    -- Dates
    CreatedDate,
    LastModifiedDate,
    LastActivityDate,
    TSPC__Last_Contact_Date__c
    
FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 100000
ORDER BY CloseDate
LIMIT 50
```

### 3.1.4 ClosePlan Related Records

```sql
-- Close Plan Details
SELECT Id, Name, 
       TSPC__Opportunity__c,
       TSPC__Opportunity__r.Name,
       TSPC__Status__c,
       TSPC__Score__c,
       TSPC__Last_Updated__c,
       CreatedDate
FROM TSPC__Close_Plan__c
WHERE TSPC__Opportunity__r.IsClosed = false
LIMIT 100

-- Metrics Records
SELECT Id, 
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Metric_Type__c,
       TSPC__Value__c,
       TSPC__Timeframe__c,
       TSPC__Status__c,
       TSPC__Description__c
FROM TSPC__Metric__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c

-- Pain Records
SELECT Id,
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Pain_Description__c,
       TSPC__Business_Impact__c,
       TSPC__Priority__c,
       TSPC__Pain_Owner__c,
       TSPC__Pain_Owner__r.Name
FROM TSPC__Pain__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c

-- Stakeholder Records
SELECT Id,
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Contact__c,
       TSPC__Contact__r.Name,
       TSPC__Contact__r.Title,
       TSPC__Role__c,
       TSPC__Influence__c,
       TSPC__Disposition__c,
       TSPC__Access_Level__c
FROM TSPC__Stakeholder__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c

-- Decision Criteria Records
SELECT Id,
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Criteria__c,
       TSPC__Type__c,
       TSPC__Weight__c,
       TSPC__Status__c,
       TSPC__Our_Capability__c
FROM TSPC__Decision_Criteria__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c

-- Decision Process Records
SELECT Id,
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Step_Name__c,
       TSPC__Step_Owner__c,
       TSPC__Step_Owner__r.Name,
       TSPC__Sequence__c,
       TSPC__Due_Date__c,
       TSPC__Status__c
FROM TSPC__Decision_Process__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c, TSPC__Sequence__c

-- Competition Records
SELECT Id,
       TSPC__Close_Plan__c,
       TSPC__Close_Plan__r.TSPC__Opportunity__r.Name,
       TSPC__Competitor_Name__c,
       TSPC__Threat_Level__c,
       TSPC__Strengths__c,
       TSPC__Weaknesses__c,
       TSPC__Strategy__c
FROM TSPC__Competition__c
WHERE TSPC__Close_Plan__r.TSPC__Opportunity__r.IsClosed = false
ORDER BY TSPC__Close_Plan__c
```

---

## 3.2 Activity Pattern Analysis

### 3.2.1 Activity Volume by Opportunity

```sql
SELECT 
    Opportunity.Name,
    Opportunity.StageName,
    Opportunity.Amount,
    COUNT(Task.Id) TaskCount,
    COUNT(Event.Id) EventCount,
    MAX(Task.ActivityDate) LastTaskDate,
    MAX(Event.ActivityDateTime) LastEventDate
FROM Opportunity
LEFT JOIN Task ON Task.WhatId = Opportunity.Id
LEFT JOIN Event ON Event.WhatId = Opportunity.Id
WHERE Opportunity.IsClosed = false
  AND Opportunity.Amount >= 100000
GROUP BY Opportunity.Id, Opportunity.Name, Opportunity.StageName, Opportunity.Amount
ORDER BY Opportunity.Amount DESC
LIMIT 50
```

**Alternative - Separate Queries:**

```sql
-- Tasks per Opportunity
SELECT WhatId, What.Name, COUNT(Id) TaskCount, MAX(ActivityDate) LastTaskDate
FROM Task
WHERE What.Type = 'Opportunity'
  AND WhatId IN (SELECT Id FROM Opportunity WHERE IsClosed = false AND Amount >= 100000)
GROUP BY WhatId, What.Name

-- Events per Opportunity
SELECT WhatId, What.Name, COUNT(Id) EventCount, MAX(ActivityDateTime) LastEventDate
FROM Event
WHERE What.Type = 'Opportunity'
  AND WhatId IN (SELECT Id FROM Opportunity WHERE IsClosed = false AND Amount >= 100000)
GROUP BY WhatId, What.Name
```

### 3.2.2 Activity Types Distribution

```sql
-- Task Types
SELECT Type, Subject, COUNT(Id) TaskCount
FROM Task
WHERE What.Type = 'Opportunity'
  AND CreatedDate >= LAST_N_MONTHS:6
GROUP BY Type, Subject
ORDER BY COUNT(Id) DESC
LIMIT 50

-- Event Types
SELECT Type, Subject, COUNT(Id) EventCount
FROM Event
WHERE What.Type = 'Opportunity'
  AND CreatedDate >= LAST_N_MONTHS:6
GROUP BY Type, Subject
ORDER BY COUNT(Id) DESC
LIMIT 50
```

### 3.2.3 Stakeholder Engagement Analysis

```sql
-- Activities with Contacts linked to Opportunities
SELECT 
    Opportunity.Name OppName,
    Contact.Name ContactName,
    Contact.Title,
    OpportunityContactRole.Role,
    COUNT(Task.Id) TasksWithContact,
    COUNT(Event.Id) EventsWithContact,
    MAX(Task.ActivityDate) LastTaskWithContact,
    MAX(Event.ActivityDateTime) LastEventWithContact
FROM Opportunity
JOIN OpportunityContactRole ON OpportunityContactRole.OpportunityId = Opportunity.Id
JOIN Contact ON Contact.Id = OpportunityContactRole.ContactId
LEFT JOIN Task ON (Task.WhoId = Contact.Id AND Task.WhatId = Opportunity.Id)
LEFT JOIN Event ON (Event.WhoId = Contact.Id AND Event.WhatId = Opportunity.Id)
WHERE Opportunity.IsClosed = false
  AND Opportunity.Amount >= 100000
GROUP BY Opportunity.Name, Contact.Name, Contact.Title, OpportunityContactRole.Role
ORDER BY Opportunity.Name
```

### 3.2.4 Email Engagement (if tracking enabled)

```sql
SELECT 
    RelatedToId,
    RelatedTo.Name,
    COUNT(Id) EmailCount,
    MAX(MessageDate) LastEmailDate,
    SUM(CASE WHEN Status = 'Read' THEN 1 ELSE 0 END) ReadCount
FROM EmailMessage
WHERE RelatedTo.Type = 'Opportunity'
  AND RelatedToId IN (SELECT Id FROM Opportunity WHERE IsClosed = false AND Amount >= 100000)
GROUP BY RelatedToId, RelatedTo.Name
ORDER BY COUNT(Id) DESC
```

---

## 3.3 Contact Role Analysis

### 3.3.1 Role Distribution

```sql
SELECT 
    Role,
    COUNT(Id) RoleCount,
    COUNT(DISTINCT OpportunityId) OppsWithRole
FROM OpportunityContactRole
WHERE Opportunity.IsClosed = false
  AND Opportunity.Amount >= 100000
GROUP BY Role
ORDER BY COUNT(Id) DESC
```

### 3.3.2 Opportunities Missing Key Roles

```sql
-- Opportunities without Economic Buyer
SELECT Id, Name, StageName, Amount, CloseDate
FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 100000
  AND Id NOT IN (
      SELECT OpportunityId 
      FROM OpportunityContactRole 
      WHERE Role = 'Economic Buyer'
  )
ORDER BY Amount DESC

-- Opportunities without Champion
SELECT Id, Name, StageName, Amount, CloseDate
FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 100000
  AND Id NOT IN (
      SELECT OpportunityId 
      FROM OpportunityContactRole 
      WHERE Role = 'Champion'
  )
ORDER BY Amount DESC

-- Opportunities without Decision Maker
SELECT Id, Name, StageName, Amount, CloseDate
FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 100000
  AND Id NOT IN (
      SELECT OpportunityId 
      FROM OpportunityContactRole 
      WHERE Role = 'Decision Maker'
  )
ORDER BY Amount DESC
```

### 3.3.3 Contact Role + TSPC Stakeholder Alignment

```sql
-- Compare standard roles vs TSPC stakeholder tracking
SELECT 
    o.Name OppName,
    ocr.ContactId,
    c.Name ContactName,
    ocr.Role StandardRole,
    s.TSPC__Role__c TSPCRole,
    s.TSPC__Influence__c Influence,
    s.TSPC__Disposition__c Disposition
FROM Opportunity o
JOIN OpportunityContactRole ocr ON ocr.OpportunityId = o.Id
JOIN Contact c ON c.Id = ocr.ContactId
LEFT JOIN TSPC__Stakeholder__c s ON (
    s.TSPC__Contact__c = ocr.ContactId 
    AND s.TSPC__Close_Plan__r.TSPC__Opportunity__c = o.Id
)
WHERE o.IsClosed = false
  AND o.Amount >= 100000
ORDER BY o.Name, ocr.Role
```

---

## 3.4 Win/Loss Analysis

### 3.4.1 Won Deals - MEDDIC Completion

```sql
SELECT 
    Id, Name, Amount, CloseDate,
    TSPC__MEDDIC_Score__c,
    -- Adjust fields based on discovery
    TSPC__Champion__c,
    TSPC__Economic_Buyer__c,
    TSPC__Pain_Summary__c,
    TSPC__Metrics_Summary__c,
    TSPC__Decision_Criteria_Summary__c,
    TSPC__Decision_Process_Summary__c
FROM Opportunity
WHERE IsWon = true
  AND CloseDate >= LAST_N_MONTHS:12
  AND Amount >= 100000
ORDER BY Amount DESC
LIMIT 50
```

### 3.4.2 Lost Deals - MEDDIC Gaps

```sql
SELECT 
    Id, Name, Amount, CloseDate,
    Loss_Reason__c,  -- Custom field if exists
    TSPC__MEDDIC_Score__c,
    TSPC__Champion__c,
    TSPC__Economic_Buyer__c,
    TSPC__Pain_Summary__c,
    TSPC__Metrics_Summary__c
FROM Opportunity
WHERE IsClosed = true
  AND IsWon = false
  AND CloseDate >= LAST_N_MONTHS:12
  AND Amount >= 100000
ORDER BY Amount DESC
LIMIT 50
```

### 3.4.3 Win Rate by MEDDIC Score

```sql
SELECT 
    CASE 
        WHEN TSPC__MEDDIC_Score__c >= 80 THEN '80-100'
        WHEN TSPC__MEDDIC_Score__c >= 60 THEN '60-79'
        WHEN TSPC__MEDDIC_Score__c >= 40 THEN '40-59'
        WHEN TSPC__MEDDIC_Score__c >= 20 THEN '20-39'
        ELSE '0-19'
    END ScoreRange,
    COUNT(Id) TotalOpps,
    SUM(CASE WHEN IsWon = true THEN 1 ELSE 0 END) WonOpps,
    (SUM(CASE WHEN IsWon = true THEN 1 ELSE 0 END) * 100.0 / COUNT(Id)) WinRate
FROM Opportunity
WHERE IsClosed = true
  AND CloseDate >= LAST_N_MONTHS:12
  AND Amount >= 100000
  AND TSPC__MEDDIC_Score__c != null
GROUP BY CASE 
        WHEN TSPC__MEDDIC_Score__c >= 80 THEN '80-100'
        WHEN TSPC__MEDDIC_Score__c >= 60 THEN '60-79'
        WHEN TSPC__MEDDIC_Score__c >= 40 THEN '40-59'
        WHEN TSPC__MEDDIC_Score__c >= 20 THEN '20-39'
        ELSE '0-19'
    END
ORDER BY ScoreRange DESC
```

---

# 4. Phase 3: MEDDIC Element Mapping

## 4.1 Element Definition Framework

Based on the metadata discovery, we'll map each MEDDIC element to specific data points:

### 4.1.1 M - Metrics

**Definition:** Quantified business value the customer expects to achieve

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| ROI Calculation | `TSPC__Metric__c` | `Value__c`, `Type__c` | Has at least one metric with type = ROI |
| Time Savings | `TSPC__Metric__c` | `Value__c`, `Type__c` | Has time-based metric |
| Cost Savings | `TSPC__Metric__c` | `Value__c`, `Type__c` | Has cost metric |
| Revenue Impact | `TSPC__Metric__c` | `Value__c`, `Type__c` | Has revenue metric |
| Payback Period | `TSPC__Metric__c` or `Opportunity` | Custom field | Calculated payback documented |
| Quote Value | `SBQQ__Quote__c` | `SBQQ__NetAmount__c` | Has associated quote |
| Business Case Doc | `ContentDocumentLink` | Document attached | Has attached ROI/business case |

**Retail Automation Specific Metrics:**
- Labor cost reduction per store
- Pricing accuracy improvement
- Time to update prices (hours saved)
- Inventory accuracy improvement
- Customer satisfaction score impact
- Shrinkage reduction

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No metrics documented |
| 26-50 | Generic/unvalidated metrics mentioned |
| 51-75 | Specific metrics with customer input |
| 76-100 | Quantified, customer-validated metrics with business case |

### 4.1.2 E - Economic Buyer

**Definition:** Person with final budget authority and approval power

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| EB Contact | `TSPC__Stakeholder__c` or `OpportunityContactRole` | `Role = 'Economic Buyer'` | Contact identified |
| EB Title | `Contact` | `Title` | VP+, C-Suite, Owner |
| EB Engagement | `Task`, `Event` | Activities with EB | Meeting logged in last 30/60/90 days |
| EB Access Level | `TSPC__Stakeholder__c` | `Access_Level__c` | Direct access established |
| EB Disposition | `TSPC__Stakeholder__c` | `Disposition__c` | Supporter or Neutral (not Opponent) |

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No EB identified |
| 26-50 | EB identified but no engagement |
| 51-75 | EB met once or indirect access via Champion |
| 76-100 | Direct EB relationship with multiple meetings |

### 4.1.3 D - Decision Criteria

**Definition:** Technical and business requirements that must be met

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| Technical Criteria | `TSPC__Decision_Criteria__c` | `Type__c = 'Technical'` | At least 3 documented |
| Business Criteria | `TSPC__Decision_Criteria__c` | `Type__c = 'Business'` | At least 2 documented |
| Criteria Status | `TSPC__Decision_Criteria__c` | `Status__c` | Progress on meeting criteria |
| Our Capability Match | `TSPC__Decision_Criteria__c` | `Our_Capability__c` | How we address each |
| Competitor Capability | `TSPC__Decision_Criteria__c` or `TSPC__Competition__c` | Competitive positioning | Comparison documented |

**Retail Automation Specific Criteria:**
- Integration with existing POS/ERP
- Battery life requirements
- Display update speed
- Wireless connectivity standards
- Scalability (number of stores/SKUs)
- Environmental durability
- Multi-language support

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No criteria documented |
| 26-50 | Some criteria listed but not validated |
| 51-75 | Criteria documented with customer confirmation |
| 76-100 | All criteria mapped with our capability match and competitive positioning |

### 4.1.4 D - Decision Process

**Definition:** The steps, timeline, and people involved in making the purchase decision

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| Process Steps | `TSPC__Decision_Process__c` | All related records | Steps documented |
| Step Owners | `TSPC__Decision_Process__c` | `Step_Owner__c` | Each step has owner |
| Timeline | `TSPC__Decision_Process__c` | `Due_Date__c` | Dates defined |
| Approval Chain | `TSPC__Stakeholder__c` | Multiple stakeholders | Full committee identified |
| Paper Process | `TSPC__Decision_Process__c` | Steps for legal/procurement | Procurement steps included |
| Go-Live Date | `Opportunity` | `CloseDate` or custom field | Realistic timeline |

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No process documented |
| 26-50 | Generic understanding of process |
| 51-75 | Steps and timeline documented |
| 76-100 | Full process mapped with owners, dates, and paper process |

### 4.1.5 I - Identify Pain

**Definition:** Business problems the customer is trying to solve

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| Pain Points | `TSPC__Pain__c` | All related records | At least 3 documented |
| Business Impact | `TSPC__Pain__c` | `Business_Impact__c` | Quantified impact |
| Pain Owner | `TSPC__Pain__c` | `Pain_Owner__c` | Person experiencing pain |
| Priority | `TSPC__Pain__c` | `Priority__c` | Urgency level |
| Current State | `TSPC__Pain__c` or notes | Description | How they handle today |

**Retail Automation Specific Pains:**
- Manual price changes taking too long
- Pricing errors causing customer complaints
- Labor costs for price management
- Out-of-stocks due to poor inventory visibility
- Inability to do dynamic pricing
- Paper/plastic label waste and sustainability concerns
- Difficulty executing promotions

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No pain documented |
| 26-50 | Generic industry pain assumed |
| 51-75 | Specific pain points with business context |
| 76-100 | Quantified pain with clear business impact and urgency |

### 4.1.6 C - Champion

**Definition:** Internal advocate who has power, influence, and a vested interest in our success

**Data Sources:**

| Data Point | Source Object | Field(s) | Validation |
|------------|---------------|----------|------------|
| Champion Contact | `TSPC__Stakeholder__c` or `OpportunityContactRole` | `Role = 'Champion'` | Contact identified |
| Influence Level | `TSPC__Stakeholder__c` | `Influence__c` | High influence |
| Personal Win | `TSPC__Stakeholder__c` or notes | Custom field | Documented personal benefit |
| Access to Power | `TSPC__Stakeholder__c` | `Access_Level__c` | Access to EB |
| Engagement Level | `Task`, `Event`, `EmailMessage` | Activities with Champion | Regular communication |
| Champion Actions | Activities | Champion taking internal actions | Evidence of advocacy |

**Champion Validation Tests:**
1. Will they give you information others won't?
2. Will they sell for you when you're not there?
3. Will they coach you on internal politics?
4. Do they have a personal win tied to your success?

**Scoring Criteria:**

| Score | Criteria |
|-------|----------|
| 0-25 | No champion identified |
| 26-50 | Friendly contact but not a true champion |
| 51-75 | Champion identified with influence |
| 76-100 | Validated champion with access to power and personal win |

---

## 4.2 MEDDIC Element Mapping Template

After completing Phase 1 discovery, fill in this template:

```markdown
# MEDDIC Element Mapping - [Your Org Name]

## M - Metrics

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] At least one metric record exists
- [ ] Metric has quantified value
- [ ] Metric type is specified
- [ ] Metric is customer-validated (status field)

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| ROI Workshop | Metrics development |
| Business Case Review | Metrics validation |

---

## E - Economic Buyer

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] EB contact identified
- [ ] EB title is VP+ or C-Suite
- [ ] EB engagement logged
- [ ] EB disposition is positive/neutral

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| Executive Meeting | EB engagement |
| Executive Presentation | EB engagement |

---

## D - Decision Criteria

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] Technical criteria documented
- [ ] Business criteria documented
- [ ] Our capability match documented
- [ ] Criteria status tracked

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| Demo | Technical validation |
| Technical Review | Criteria assessment |
| POC | Technical validation |

---

## D - Decision Process

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] Process steps documented
- [ ] Step owners identified
- [ ] Timeline defined
- [ ] Paper process included

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| Procurement Meeting | Paper process |
| Legal Review | Paper process |
| Contract Review | Paper process |

---

## I - Identify Pain

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] Pain points documented
- [ ] Business impact quantified
- [ ] Pain owner identified
- [ ] Priority assigned

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| Discovery Call | Pain identification |
| Site Visit | Pain validation |

---

## C - Champion

### Primary Data Sources
| Field/Object | API Name | Type | Purpose |
|--------------|----------|------|---------|
| | | | |

### Validation Rules
- [ ] Champion identified
- [ ] Influence level is High/Medium
- [ ] Access to EB documented
- [ ] Personal win documented
- [ ] Regular engagement

### Related Activities
| Activity Type | Indicates |
|---------------|-----------|
| Champion Coaching | Champion development |
| Reference Call | Champion validation |
```

---

# 5. Phase 4: Stage-Based Validation Matrix

## 5.1 Stage Requirements Framework

For each sales stage, define minimum MEDDIC requirements:

### 5.1.1 Stage 1: Qualification (10%)

**Minimum Requirements:**

| MEDDIC Element | Requirement | Weight | Validation |
|----------------|-------------|--------|------------|
| M - Metrics | Discussed | 10% | Field not blank or activity logged |
| E - Economic Buyer | Identified | 10% | EB name or title known |
| D - Decision Criteria | Started | 10% | At least 1 criteria documented |
| D - Decision Process | Awareness | 10% | Timeline discussed |
| I - Identify Pain | Confirmed | 30% | At least 2 pain points documented |
| C - Champion | Identified | 30% | Champion contact assigned |

**Expected MEDDIC Score:** 40-50

**Stage Exit Criteria:**
- [ ] At least 2 pain points documented
- [ ] Champion identified (even if not fully validated)
- [ ] Budget discussion initiated
- [ ] Initial timeline confirmed

### 5.1.2 Stage 2: Discovery (20%)

**Minimum Requirements:**

| MEDDIC Element | Requirement | Weight | Validation |
|----------------|-------------|--------|------------|
| M - Metrics | Discussed | 15% | Metrics conversation logged |
| E - Economic Buyer | Identified | 15% | EB contact record exists |
| D - Decision Criteria | In Progress | 15% | 3+ criteria documented |
| D - Decision Process | Outlined | 10% | High-level process known |
| I - Identify Pain | Documented | 25% | 3+ pain points with impact |
| C - Champion | Validated | 20% | Champion engaged with influence confirmed |

**Expected MEDDIC Score:** 50-60

**Stage Exit Criteria:**
- [ ] 3+ pain points with business impact
- [ ] Champion validated (coaching relationship)
- [ ] Economic Buyer identified (not just known, but identified)
- [ ] Technical criteria gathering started
- [ ] Demo scheduled or completed

### 5.1.3 Stage 3: Solution Development (40%)

**Minimum Requirements:**

| MEDDIC Element | Requirement | Weight | Validation |
|----------------|-------------|--------|------------|
| M - Metrics | Developing | 20% | Specific metrics with values |
| E - Economic Buyer | Engaged | 20% | Meeting with EB logged |
| D - Decision Criteria | Confirmed | 20% | All criteria documented with our fit |
| D - Decision Process | Mapped | 10% | Process steps documented |
| I - Identify Pain | Complete | 15% | Pain owner identified |
| C - Champion | Active | 15% | Champion taking internal actions |

**Expected MEDDIC Score:** 60-75

**Stage Exit Criteria:**
- [ ] Economic Buyer engaged (at least one meeting)
- [ ] Metrics specific with preliminary values
- [ ] All decision criteria documented
- [ ] Proposal content agreed upon
- [ ] Decision process steps identified

### 5.1.4 Stage 4: Proposal / POC (60%)

**Minimum Requirements:**

| MEDDIC Element | Requirement | Weight | Validation |
|----------------|-------------|--------|------------|
| M - Metrics | Validated | 20% | Customer-agreed metrics |
| E - Economic Buyer | Sponsoring | 15% | EB supporting proposal |
| D - Decision Criteria | Met | 20% | All criteria addressed in proposal |
| D - Decision Process | Active | 20% | Moving through process steps |
| I - Identify Pain | Addressed | 10% | Solution addresses all pains |
| C - Champion | Advocating | 15% | Champion selling internally |

**Expected MEDDIC Score:** 75-85

**Stage Exit Criteria:**
- [ ] Formal proposal submitted
- [ ] Metrics validated and agreed
- [ ] All decision criteria addressed
- [ ] Decision process in active stage
- [ ] Champion actively advocating
- [ ] Procurement/legal contacts identified

### 5.1.5 Stage 5: Negotiation (80%)

**Minimum Requirements:**

| MEDDIC Element | Requirement | Weight | Validation |
|----------------|-------------|--------|------------|
| M - Metrics | Agreed | 15% | Business case approved |
| E - Economic Buyer | Committed | 20% | EB verbal commitment |
| D - Decision Criteria | All Met | 15% | No outstanding concerns |
| D - Decision Process | Final Steps | 20% | Contract/legal in progress |
| I - Identify Pain | Resolved | 10% | Solution accepted |
| C - Champion | Closing | 20% | Champion driving to close |

**Expected MEDDIC Score:** 85-95

**Stage Exit Criteria:**
- [ ] Verbal commitment from Economic Buyer
- [ ] Contract redlines in progress
- [ ] No open technical or business issues
- [ ] Go-live date agreed
- [ ] Paper process on track

### 5.1.6 Stage 6: Closed Won (100%)

**Documentation Requirements:**

| MEDDIC Element | Documentation |
|----------------|---------------|
| M - Metrics | Final agreed metrics captured |
| E - Economic Buyer | EB contact role confirmed |
| D - Decision Criteria | Why we won documented |
| D - Decision Process | Process timeline captured |
| I - Identify Pain | Pain resolution documented |
| C - Champion | Champion success story |

---

## 5.2 Stage Validation Matrix Summary

| Stage | Min Score | M | E | D-Criteria | D-Process | I | C |
|-------|-----------|---|---|------------|-----------|---|---|
| Qualification | 40 | 🟡 Discussed | 🟡 Identified | 🟡 Started | 🟡 Awareness | 🟢 Confirmed | 🟡 Identified |
| Discovery | 50 | 🟡 Discussed | 🟡 Identified | 🟢 In Progress | 🟡 Outlined | 🟢 Documented | 🟢 Validated |
| Solution Dev | 65 | 🟢 Developing | 🟢 Engaged | 🟢 Confirmed | 🟢 Mapped | 🟢 Complete | 🟢 Active |
| Proposal/POC | 75 | 🟢 Validated | 🟢 Sponsoring | 🟢 Met | 🟢 Active | 🟢 Addressed | 🟢 Advocating |
| Negotiation | 85 | 🟢 Agreed | 🟢 Committed | 🟢 All Met | 🟢 Final | 🟢 Resolved | 🟢 Closing |

**Legend:**
- 🟡 = Minimum/In Progress
- 🟢 = Complete/Strong

---

# 6. Phase 5: Scoring Algorithm Design

## 6.1 Overall MEDDIC Score Calculation

### 6.1.1 Base Element Weights

| Element | Weight | Justification |
|---------|--------|---------------|
| M - Metrics | 15% | Critical for value proposition but can develop |
| E - Economic Buyer | 20% | Deals don't close without EB engagement |
| D - Decision Criteria | 15% | Technical/business fit essential |
| D - Decision Process | 15% | Understanding process prevents surprises |
| I - Identify Pain | 15% | No pain, no change |
| C - Champion | 20% | Champion drives deal forward |

**Total: 100%**

### 6.1.2 Element Scoring Rubric

Each element is scored 0-100:

**Example: C - Champion Scoring:**

| Score Range | Criteria |
|-------------|----------|
| 0 | No champion identified |
| 10-25 | Friendly contact but role not confirmed |
| 26-50 | Champion identified, low influence |
| 51-70 | Champion with medium influence, limited access |
| 71-85 | Champion with high influence, some EB access |
| 86-95 | Validated champion with power and EB access |
| 96-100 | Champion with proven advocacy and personal win |

### 6.1.3 Score Calculation Formula

```
Overall MEDDIC Score = 
    (Metrics_Score × 0.15) +
    (EB_Score × 0.20) +
    (DC_Score × 0.15) +
    (DP_Score × 0.15) +
    (Pain_Score × 0.15) +
    (Champion_Score × 0.20)
```

### 6.1.4 Stage-Adjusted Scoring

The same raw data should result in different scores based on stage expectations:

**Score Adjustment Formula:**

```
Stage_Adjusted_Score = Raw_Score × Stage_Multiplier

Where Stage_Multiplier varies by element and stage
```

**Example Multipliers for "Champion" Element:**

| Stage | Expected Score | Multiplier |
|-------|---------------|------------|
| Qualification | 40 | 1.0 |
| Discovery | 60 | 1.0 |
| Solution Dev | 75 | If score < 60: 0.8 |
| Proposal | 85 | If score < 70: 0.7 |
| Negotiation | 90 | If score < 80: 0.6 |

---

## 6.2 Risk Indicators

### 6.2.1 Red Flags (Critical Risks)

| Risk | Condition | Impact |
|------|-----------|--------|
| No Champion | Stage >= Solution Dev AND Champion score < 30 | Score penalty -20 |
| No EB Engagement | Stage >= Proposal AND No EB activity in 60 days | Score penalty -15 |
| Stalled Deal | No activity in 30+ days | Score penalty -10 |
| Missing Metrics | Stage >= Proposal AND Metrics score < 50 | Score penalty -10 |
| No Decision Process | Stage >= Negotiation AND DP not mapped | Score penalty -15 |
| Single Threaded | Only 1 contact engaged | Score penalty -10 |

### 6.2.2 Yellow Flags (Warnings)

| Warning | Condition | Impact |
|---------|-----------|--------|
| Champion at Risk | Champion disposition = Neutral | Warning flag |
| EB Cooling | No EB activity in 30+ days | Warning flag |
| Competitive Threat | Competition threat level = High | Warning flag |
| Timeline Slip | Close date pushed 2+ times | Warning flag |
| Low Activity | < 3 activities in last 30 days | Warning flag |

### 6.2.3 Green Indicators (Positive Signals)

| Indicator | Condition | Impact |
|-----------|-----------|--------|
| Multi-Threaded | 4+ contacts engaged with activities | Bonus +5 |
| EB Sponsor | EB taking internal action | Bonus +5 |
| Champion Advocating | Champion logging internal wins | Bonus +5 |
| Metrics Agreed | Customer validated metrics | Bonus +5 |
| Competitive Win | Incumbent displaced | Bonus +5 |

---

## 6.3 Data Quality Adjustments

### 6.3.1 Field Completeness Score

```
Completeness = (Filled Fields / Required Fields) × 100

If Completeness < 70%:
    Apply penalty to overall score
    Flag "Data Quality Issue"
```

### 6.3.2 Data Freshness Score

```
For each MEDDIC element:
    Days_Since_Update = Today - Last_Modified_Date
    
    If Days_Since_Update > 30:
        Freshness_Penalty = 5
    If Days_Since_Update > 60:
        Freshness_Penalty = 10
    If Days_Since_Update > 90:
        Freshness_Penalty = 20
```

---

# 7. Phase 6: GPTfy Implementation

## 7.1 Data Context Mapping Design

### 7.1.1 Primary Object: Opportunity

```yaml
Object: Opportunity
Fields to Include:
  # Core Fields
  - Id
  - Name
  - StageName
  - Amount
  - CloseDate
  - Probability
  - ForecastCategory
  - LeadSource
  - Type
  - Description
  - NextStep
  - CreatedDate
  - LastModifiedDate
  - LastActivityDate
  - OwnerId
  - Owner.Name
  
  # Account Fields (Parent)
  - Account.Name
  - Account.Industry
  - Account.NumberOfEmployees
  - Account.AnnualRevenue
  - Account.BillingCountry
  
  # TSPC Fields (adjust based on discovery)
  - TSPC__Close_Plan__c
  - TSPC__Champion__c
  - TSPC__Champion__r.Name
  - TSPC__Champion__r.Title
  - TSPC__Economic_Buyer__c
  - TSPC__Economic_Buyer__r.Name
  - TSPC__Economic_Buyer__r.Title
  - TSPC__Pain_Summary__c
  - TSPC__Metrics_Summary__c
  - TSPC__Decision_Criteria_Summary__c
  - TSPC__Decision_Process_Summary__c
  - TSPC__Competition_Summary__c
  - TSPC__MEDDIC_Score__c
  - TSPC__Close_Plan_Status__c
  - TSPC__Last_Updated__c
  
  # CPQ Fields
  - SBQQ__PrimaryQuote__c
  - SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c
  
  # Klue Fields
  - klue__Primary_Competitor__c
  - klue__Competitive_Notes__c

Masking:
  - None required for MEDDIC analysis (internal use)
```

### 7.1.2 Related Objects

```yaml
Related Object 1: OpportunityContactRole
  Relationship: Child of Opportunity
  Fields:
    - Id
    - ContactId
    - Contact.Name
    - Contact.Title
    - Contact.Email
    - Contact.Phone
    - Role
    - IsPrimary
  Filter: None
  Limit: 20
  Order By: Role ASC

Related Object 2: TSPC__Stakeholder__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Contact__c
    - TSPC__Contact__r.Name
    - TSPC__Contact__r.Title
    - TSPC__Role__c
    - TSPC__Influence__c
    - TSPC__Disposition__c
    - TSPC__Access_Level__c
    - TSPC__Personal_Win__c
    - TSPC__Notes__c
  Filter: None
  Limit: 20

Related Object 3: TSPC__Pain__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Pain_Description__c
    - TSPC__Business_Impact__c
    - TSPC__Priority__c
    - TSPC__Pain_Owner__c
    - TSPC__Pain_Owner__r.Name
    - TSPC__Status__c
  Filter: None
  Limit: 10
  Order By: TSPC__Priority__c ASC

Related Object 4: TSPC__Metric__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Metric_Type__c
    - TSPC__Value__c
    - TSPC__Timeframe__c
    - TSPC__Status__c
    - TSPC__Description__c
    - TSPC__Customer_Validated__c
  Filter: None
  Limit: 10

Related Object 5: TSPC__Decision_Criteria__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Criteria__c
    - TSPC__Type__c
    - TSPC__Weight__c
    - TSPC__Status__c
    - TSPC__Our_Capability__c
    - TSPC__Competitor_Capability__c
  Filter: None
  Limit: 20

Related Object 6: TSPC__Decision_Process__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Step_Name__c
    - TSPC__Step_Owner__c
    - TSPC__Step_Owner__r.Name
    - TSPC__Sequence__c
    - TSPC__Due_Date__c
    - TSPC__Status__c
    - TSPC__Notes__c
  Filter: None
  Limit: 15
  Order By: TSPC__Sequence__c ASC

Related Object 7: TSPC__Competition__c
  Relationship: Via TSPC__Close_Plan__c
  Fields:
    - Id
    - TSPC__Competitor_Name__c
    - TSPC__Threat_Level__c
    - TSPC__Strengths__c
    - TSPC__Weaknesses__c
    - TSPC__Strategy__c
  Filter: None
  Limit: 5

Related Object 8: Task (Recent Activities)
  Relationship: Child of Opportunity
  Fields:
    - Id
    - Subject
    - Type
    - Status
    - ActivityDate
    - WhoId
    - Who.Name
    - Description
    - CreatedDate
  Filter: Status = 'Completed'
  Limit: 20
  Order By: ActivityDate DESC

Related Object 9: Event (Recent Activities)
  Relationship: Child of Opportunity
  Fields:
    - Id
    - Subject
    - Type
    - ActivityDateTime
    - WhoId
    - Who.Name
    - Description
  Filter: ActivityDateTime <= TODAY
  Limit: 20
  Order By: ActivityDateTime DESC
```

### 7.1.3 Data Context Mapping Configuration in GPTfy

**Navigate to:** GPTfy Cockpit → Data Context Mapping → New

**Configuration:**

```
Mapping Name: MEDDIC Compliance Analysis
Target Object: Opportunity
Status: Active

Context Mapping:
├── Opportunity (Main Object)
│   └── Fields: [As listed above]
├── OpportunityContactRole (Child)
│   └── Fields: [As listed above]
├── TSPC__Stakeholder__c (Via Close Plan)
│   └── Fields: [As listed above]
├── TSPC__Pain__c (Via Close Plan)
│   └── Fields: [As listed above]
├── TSPC__Metric__c (Via Close Plan)
│   └── Fields: [As listed above]
├── TSPC__Decision_Criteria__c (Via Close Plan)
│   └── Fields: [As listed above]
├── TSPC__Decision_Process__c (Via Close Plan)
│   └── Fields: [As listed above]
├── TSPC__Competition__c (Via Close Plan)
│   └── Fields: [As listed above]
├── Task (Child)
│   └── Fields: [As listed above]
└── Event (Child)
    └── Fields: [As listed above]
```

---

## 7.2 Prompt Design

### 7.2.1 Prompt Configuration

```yaml
Prompt Name: MEDDIC Compliance Analyzer
Target Object: Opportunity
Type: Text (or JSON for structured output)
AI Model: [Your configured model]
Data Context Mapping: MEDDIC Compliance Analysis

Profile Access: 
  - Sales User
  - Sales Manager
  - System Administrator

Allow User Input: Yes (for specific focus areas)

Business Purpose: Sales Qualification
```

### 7.2.2 Prompt Command (Text Version)

```
You are an expert B2B sales coach specializing in the MEDDIC sales methodology for enterprise deals. Analyze this opportunity and provide a comprehensive MEDDIC compliance assessment.

## CONTEXT
This is a {{{Amount}}} opportunity for {{{Account.Name}}} in the {{{Account.Industry}}} industry. The deal is currently at {{{StageName}}} stage with a close date of {{{CloseDate}}}. The sales cycle for this type of deal typically ranges from 4-14 months.

## ANALYSIS INSTRUCTIONS

Evaluate each MEDDIC element using the data provided and score from 0-100:

### M - METRICS (Weight: 15%)
Analyze:
- Are business metrics quantified and documented?
- Has the customer validated ROI/business case?
- Are metrics specific to their business (not generic)?
- Is there a clear payback period?

Data to review: Metric records, Quote values, Business case references

### E - ECONOMIC BUYER (Weight: 20%)
Analyze:
- Is the EB clearly identified with name and title?
- Has there been direct engagement with the EB? (Check activities)
- What is the EB's disposition and influence level?
- When was the last EB touchpoint?

Data to review: Stakeholder records with EB role, Contact roles, Activity history

### D - DECISION CRITERIA (Weight: 15%)
Analyze:
- Are technical criteria documented?
- Are business criteria documented?
- How well do we match against each criterion?
- What's the competitive positioning on criteria?

Data to review: Decision Criteria records, Status of each criterion

### D - DECISION PROCESS (Weight: 15%)
Analyze:
- Are the decision steps mapped?
- Are step owners identified?
- Is there a timeline with dates?
- Is the paper process (legal/procurement) understood?
- Who are all the approvers?

Data to review: Decision Process records, Stakeholder list

### I - IDENTIFY PAIN (Weight: 15%)
Analyze:
- Are specific pain points documented?
- Is the business impact quantified?
- Who owns/experiences each pain?
- What's the priority/urgency level?
- How are they handling the pain today?

Data to review: Pain records, Pain owner contacts

### C - CHAMPION (Weight: 20%)
Analyze:
- Is a champion clearly identified?
- What is their influence level and disposition?
- Do they have access to the Economic Buyer?
- Is there a documented personal win?
- Are they actively engaged? (Check recent activities)
- Are they taking internal action on our behalf?

Data to review: Stakeholder with Champion role, Activity history with champion

## OUTPUT FORMAT

Provide your analysis in this exact structure:

---

## MEDDIC COMPLIANCE REPORT

### Opportunity Summary
[One paragraph summary of deal status and overall qualification health]

### Overall Score: [X]/100
[Visual indicator: 🟢 if ≥75, 🟡 if 50-74, 🔴 if <50]

### Score vs. Stage Expectation
Current Stage: {{{StageName}}}
Expected Score for Stage: [X]
Actual Score: [X]
Gap: [+/- X points]

---

### Element-by-Element Analysis

#### M - Metrics: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**Evidence Found:**
- [Bullet points of data supporting score]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

#### E - Economic Buyer: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**EB Identified:** [Name, Title] or "NOT IDENTIFIED"
**Last Engagement:** [Date] or "NONE RECORDED"
**Disposition:** [Supporter/Neutral/Opponent] or "UNKNOWN"

**Evidence Found:**
- [Bullet points]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

#### D - Decision Criteria: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**Criteria Documented:** [X technical, Y business]
**Criteria Met:** [X of Y]

**Evidence Found:**
- [Bullet points]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

#### D - Decision Process: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**Steps Mapped:** [X steps identified]
**Paper Process:** [Documented/Not Documented]
**Timeline:** [Realistic/At Risk/Not Defined]

**Evidence Found:**
- [Bullet points]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

#### I - Identify Pain: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**Pain Points Documented:** [X]
**Pain Quantified:** [Yes/Partially/No]

**Evidence Found:**
- [Bullet points]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

#### C - Champion: [Score]/100 [🟢/🟡/🔴]
**Summary:** [One sentence summary]
**Champion Identified:** [Name, Title] or "NOT IDENTIFIED"
**Influence Level:** [High/Medium/Low/Unknown]
**Last Contact:** [Date]
**Personal Win:** [Documented/Not Documented]

**Evidence Found:**
- [Bullet points]

**Gaps Identified:**
- [What's missing]

**Recommendations:**
1. [Specific action]
2. [Specific action]

---

### Risk Assessment

#### 🚨 Critical Risks
[List any critical risks that could derail the deal]

#### ⚠️ Warnings
[List warning signs that need attention]

#### ✅ Positive Indicators
[List things going well]

---

### Stage Advancement Readiness

**Current Stage:** {{{StageName}}}
**Ready to Advance:** [YES/NO/CONDITIONAL]

**Requirements Met:**
- [✓] or [✗] for each stage requirement

**Blockers to Next Stage:**
1. [Specific blocker]
2. [Specific blocker]

---

### Priority Actions (Next 7-14 Days)

1. **[Action 1]** - [Owner suggestion] - [Impact: Critical/High/Medium]
   Rationale: [Why this matters]

2. **[Action 2]** - [Owner suggestion] - [Impact: Critical/High/Medium]
   Rationale: [Why this matters]

3. **[Action 3]** - [Owner suggestion] - [Impact: Critical/High/Medium]
   Rationale: [Why this matters]

---

### Competitive Position

**Primary Competitor:** [Name] - Threat Level: [High/Medium/Low]
**Our Strengths:** [Key differentiators]
**Competitive Risks:** [Areas where competitor is strong]
**Recommended Strategy:** [How to win]

---

*Analysis generated by GPTfy MEDDIC Compliance Analyzer*
*Data as of: {{{LastModifiedDate}}}*
```

### 7.2.3 Grounding Rules

```yaml
Ethical Grounding:
  - Base all assessments on the data provided in the JSON
  - Do not hallucinate or invent data points not present
  - Be objective in scoring - avoid inflation or deflation
  - Provide constructive, actionable recommendations
  - Respect that this is for internal coaching purposes

Content Grounding:
  - Use data from the provided JSON, linked by 18-digit IDs
  - Reference specific field values when making assessments
  - Be specific in recommendations - avoid generic advice
  - Consider the stage context when evaluating completeness
  - Account for the 4-14 month typical sales cycle
  - Recognize this is enterprise retail automation/ESL sales
  
  # Retail Automation Context
  - Common pain points include: pricing errors, labor costs, manual processes
  - Typical decision makers: VP/SVP Retail Operations, CIO, CFO
  - Technical criteria often include: integration, scalability, battery life
  - Competition often includes: Pricer, SES-imagotag, Displaydata
  
  # Formatting
  - Use the exact output format provided
  - Include all sections even if data is limited
  - Use emoji indicators consistently: 🟢 🟡 🔴
  - Keep recommendations specific and actionable
  - Limit each recommendation to one clear action
```

---

## 7.3 Prompt Actions (Optional)

### 7.3.1 Update MEDDIC Score Field

```yaml
Action Type: Update Field
Target Object: Opportunity
Field: TSPC__AI_MEDDIC_Score__c (create custom field)
AI Response: Overall Score value
Append Timestamp: Yes
```

### 7.3.2 Create Follow-up Task

```yaml
Action Type: Create Record
Target Object: Task
Field Mapping:
  - Subject: "MEDDIC Gap: [First Critical Gap]"
  - WhatId: {Opportunity.Id}
  - OwnerId: {Opportunity.OwnerId}
  - ActivityDate: TODAY + 7
  - Priority: High
  - Type: Follow-up
  - Description: [First Recommendation from AI]
```

### 7.3.3 Invoke Flow for Manager Alert

```yaml
Action Type: Invoke Flow
Flow: MEDDIC_Score_Alert_Flow
Conditions:
  - Score < 50 AND Stage >= Solution Development
  - Score dropped by 10+ points from previous analysis
```

---

## 7.4 Alternative: JSON Prompt Type

For more structured output that can be used programmatically:

### 7.4.1 JSON Prompt Components

```yaml
Component 1: Overall Analysis
  Name: meddic_summary
  Action: Analyze the opportunity MEDDIC compliance
  Format: JSON
  
Component 2: Element Scores
  Name: element_scores
  Action: Calculate score for each MEDDIC element (M, E, D-Criteria, D-Process, I, C)
  Format: JSON with score and status for each
  
Component 3: Recommendations
  Name: recommendations
  Action: Generate top 3 priority actions
  Format: JSON array with action, owner, priority, rationale

Component 4: Risk Assessment
  Name: risks
  Action: Identify critical risks and warnings
  Format: JSON with risk_type, description, mitigation
```

### 7.4.2 Expected JSON Output Structure

```json
{
  "opportunity_id": "006xxx",
  "opportunity_name": "Account Name - ESL Implementation",
  "analysis_date": "2025-01-15",
  "overall_score": 62,
  "stage": "Solution Development",
  "expected_score_for_stage": 70,
  "score_gap": -8,
  "status": "BELOW_EXPECTATIONS",
  
  "elements": {
    "metrics": {
      "score": 45,
      "status": "AT_RISK",
      "summary": "Generic metrics discussed but not customer-validated",
      "evidence": ["One metric record exists", "No ROI calculation"],
      "gaps": ["Missing customer validation", "No payback period"],
      "recommendations": [
        {
          "action": "Schedule ROI workshop with Champion",
          "owner": "AE",
          "priority": "HIGH"
        }
      ]
    },
    "economic_buyer": {
      "score": 70,
      "status": "PROGRESSING",
      "contact_name": "Jane Smith",
      "contact_title": "VP Operations",
      "last_engagement": "2025-01-02",
      "days_since_contact": 13,
      "disposition": "Neutral",
      "summary": "EB identified but engagement cooling",
      "evidence": ["EB in stakeholder records", "One meeting logged"],
      "gaps": ["No meeting in 13 days", "Disposition not confirmed positive"],
      "recommendations": [
        {
          "action": "Schedule EB check-in via Champion",
          "owner": "AE",
          "priority": "HIGH"
        }
      ]
    },
    "decision_criteria": {
      "score": 80,
      "status": "ON_TRACK",
      "technical_count": 5,
      "business_count": 3,
      "criteria_met": 6,
      "criteria_total": 8,
      "summary": "Good criteria coverage with our fit documented",
      "evidence": ["8 criteria documented", "6 marked as Met"],
      "gaps": ["2 criteria still in progress"],
      "recommendations": []
    },
    "decision_process": {
      "score": 55,
      "status": "AT_RISK",
      "steps_documented": 3,
      "paper_process": false,
      "timeline_status": "PARTIAL",
      "summary": "Process partially mapped but procurement not understood",
      "evidence": ["3 steps documented", "No legal/procurement contacts"],
      "gaps": ["Paper process unknown", "No procurement timeline"],
      "recommendations": [
        {
          "action": "Ask Champion about procurement process and timeline",
          "owner": "AE",
          "priority": "MEDIUM"
        }
      ]
    },
    "identify_pain": {
      "score": 90,
      "status": "STRONG",
      "pain_count": 4,
      "pain_quantified": true,
      "summary": "Strong pain documentation with business impact",
      "evidence": ["4 pain points with owners", "Business impact quantified"],
      "gaps": [],
      "recommendations": []
    },
    "champion": {
      "score": 65,
      "status": "PROGRESSING",
      "contact_name": "John Doe",
      "contact_title": "Director Store Operations",
      "influence": "Medium",
      "disposition": "Supporter",
      "last_contact": "2025-01-10",
      "personal_win": false,
      "summary": "Champion identified but influence could be stronger",
      "evidence": ["Active engagement", "Providing information"],
      "gaps": ["Medium influence only", "Personal win not documented"],
      "recommendations": [
        {
          "action": "Discuss personal career goals and tie to project success",
          "owner": "AE",
          "priority": "MEDIUM"
        }
      ]
    }
  },
  
  "risks": {
    "critical": [
      {
        "type": "METRICS_GAP",
        "description": "Metrics not validated with customer at Solution Development stage",
        "mitigation": "Schedule ROI workshop immediately"
      }
    ],
    "warnings": [
      {
        "type": "EB_COOLING",
        "description": "No EB engagement in 13 days",
        "mitigation": "Get Champion to re-engage EB"
      },
      {
        "type": "PAPER_PROCESS_UNKNOWN",
        "description": "Procurement process not mapped",
        "mitigation": "Discovery on procurement timeline"
      }
    ],
    "positive": [
      {
        "type": "STRONG_PAIN",
        "description": "Well-documented pain with clear business impact"
      },
      {
        "type": "CRITERIA_PROGRESS",
        "description": "75% of decision criteria already met"
      }
    ]
  },
  
  "stage_advancement": {
    "ready": false,
    "current_stage": "Solution Development",
    "next_stage": "Proposal",
    "requirements": {
      "metrics_validated": false,
      "eb_sponsoring": false,
      "all_criteria_addressed": false,
      "decision_process_active": false,
      "champion_advocating": true
    },
    "blockers": [
      "Metrics not customer-validated",
      "EB sponsorship not confirmed",
      "2 decision criteria outstanding"
    ]
  },
  
  "priority_actions": [
    {
      "sequence": 1,
      "action": "Schedule ROI workshop with Champion to build validated business case",
      "owner": "AE",
      "impact": "CRITICAL",
      "target_date": "2025-01-22",
      "element": "METRICS"
    },
    {
      "sequence": 2,
      "action": "Get Champion to schedule EB touchpoint - last contact 13 days ago",
      "owner": "AE",
      "impact": "HIGH",
      "target_date": "2025-01-20",
      "element": "ECONOMIC_BUYER"
    },
    {
      "sequence": 3,
      "action": "Discovery call on procurement process and legal review timeline",
      "owner": "AE",
      "impact": "MEDIUM",
      "target_date": "2025-01-25",
      "element": "DECISION_PROCESS"
    }
  ],
  
  "competitive": {
    "primary_competitor": "Pricer",
    "threat_level": "MEDIUM",
    "our_strengths": ["Better integration capabilities", "Faster implementation"],
    "competitor_strengths": ["Incumbent relationship", "Lower initial price"],
    "strategy": "Focus on total cost of ownership and integration speed"
  }
}
```

---

# 8. Phase 7: Testing & Validation

## 8.1 Test Scenarios

### 8.1.1 Scenario 1: Well-Qualified Opportunity

**Setup:**
- Stage: Proposal
- Amount: €500,000
- All MEDDIC elements documented
- Recent activity with EB and Champion
- Clear decision process

**Expected Output:**
- Overall Score: 80+
- Status: ON_TRACK
- Few/no critical risks
- Ready for stage advancement

### 8.1.2 Scenario 2: Under-Qualified Opportunity

**Setup:**
- Stage: Solution Development
- Amount: €300,000
- No EB identified
- Generic pain points
- No metrics

**Expected Output:**
- Overall Score: 35-45
- Status: AT_RISK
- Multiple critical risks
- Clear blockers listed
- Specific remediation actions

### 8.1.3 Scenario 3: Stalled Deal

**Setup:**
- Stage: Proposal
- Amount: €750,000
- No activity in 45 days
- Champion disposition changed to Neutral
- Close date pushed 3 times

**Expected Output:**
- Stalled deal warning
- Score penalty applied
- Champion re-engagement recommended
- Deal health concern flagged

### 8.1.4 Scenario 4: New Opportunity

**Setup:**
- Stage: Qualification
- Amount: €200,000
- Minimal data
- Just Champion identified

**Expected Output:**
- Score appropriate for early stage
- No false negatives for missing data
- Guidance on what to gather next
- Not flagged as at-risk (too early)

---

## 8.2 Validation Checklist

### 8.2.1 Data Accuracy

- [ ] All TSPC objects properly queried
- [ ] Relationships correctly mapped
- [ ] No null pointer errors
- [ ] Recent activities included
- [ ] Stakeholder roles correctly interpreted

### 8.2.2 Scoring Accuracy

- [ ] Scores align with expected ranges
- [ ] Stage-appropriate expectations applied
- [ ] Risk indicators triggering correctly
- [ ] No score inflation/deflation

### 8.2.3 Recommendations Quality

- [ ] Recommendations are specific, not generic
- [ ] Recommendations are actionable
- [ ] Owner suggestions are appropriate
- [ ] Priority assignments are logical

### 8.2.4 Output Quality

- [ ] Format is consistent
- [ ] All sections populated
- [ ] No hallucinated data
- [ ] Emoji indicators correct
- [ ] Dates and numbers accurate

---

## 8.3 Refinement Process

### 8.3.1 Feedback Collection

After initial deployment:

1. Run on 20-30 opportunities across stages
2. Have sales managers review output accuracy
3. Collect feedback on:
   - Score accuracy
   - Missing considerations
   - Recommendation usefulness
   - Format preferences

### 8.3.2 Prompt Tuning

Based on feedback:

1. Adjust element weights if needed
2. Refine scoring rubrics
3. Add industry-specific context
4. Improve recommendation specificity
5. Add/remove risk indicators

### 8.3.3 Version Control

Use GPTfy's prompt versioning:

1. Document each version's changes
2. A/B test major changes
3. Maintain baseline for comparison
4. Roll back if quality degrades

---

# 9. Appendices

## 9.1 Metadata API Package.xml (Complete)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- ClosePlan Objects -->
    <types>
        <members>TSPC__*</members>
        <name>CustomObject</name>
    </types>
    
    <!-- Standard Objects with Custom Fields -->
    <types>
        <members>Opportunity</members>
        <members>Contact</members>
        <members>Account</members>
        <members>Task</members>
        <members>Event</members>
        <name>CustomObject</name>
    </types>
    
    <!-- Sales Processes -->
    <types>
        <members>*</members>
        <name>SalesProcess</name>
    </types>
    
    <!-- Path Assistant -->
    <types>
        <members>*</members>
        <name>PathAssistant</name>
    </types>
    
    <!-- Record Types -->
    <types>
        <members>Opportunity.*</members>
        <name>RecordType</name>
    </types>
    
    <!-- Validation Rules -->
    <types>
        <members>Opportunity.*</members>
        <members>TSPC__Close_Plan__c.*</members>
        <members>TSPC__Stakeholder__c.*</members>
        <members>TSPC__Pain__c.*</members>
        <members>TSPC__Metric__c.*</members>
        <members>TSPC__Decision_Criteria__c.*</members>
        <members>TSPC__Decision_Process__c.*</members>
        <name>ValidationRule</name>
    </types>
    
    <!-- Flows -->
    <types>
        <members>*</members>
        <name>Flow</name>
    </types>
    
    <!-- Page Layouts -->
    <types>
        <members>Opportunity-*</members>
        <name>Layout</name>
    </types>
    
    <!-- Apex Triggers -->
    <types>
        <members>*</members>
        <name>ApexTrigger</name>
    </types>
    
    <version>59.0</version>
</Package>
```

## 9.2 Tooling API Query Reference

### Complete Query Set

```sql
-- 1. All TSPC Objects
SELECT Id, DeveloperName, Label, Description, NamespacePrefix,
       KeyPrefix, IsCustomSetting, IsApexUpdateable
FROM EntityDefinition
WHERE NamespacePrefix = 'TSPC'
ORDER BY Label

-- 2. All Fields on TSPC Objects
SELECT EntityDefinition.QualifiedApiName AS ObjectName,
       QualifiedApiName, Label, DataType, Description,
       IsRequired, IsNillable, InlineHelpText,
       Length, Precision, Scale,
       ReferenceTo, RelationshipName
FROM FieldDefinition
WHERE EntityDefinition.NamespacePrefix = 'TSPC'
ORDER BY EntityDefinition.QualifiedApiName, Label

-- 3. TSPC Fields on Standard Objects
SELECT EntityDefinition.QualifiedApiName AS ObjectName,
       QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE NamespacePrefix = 'TSPC'
  AND EntityDefinition.QualifiedApiName IN ('Opportunity', 'Contact', 'Account')
ORDER BY EntityDefinition.QualifiedApiName, Label

-- 4. All Picklist Values for TSPC Objects
SELECT EntityParticle.EntityDefinition.QualifiedApiName AS ObjectName,
       EntityParticle.QualifiedApiName AS FieldName,
       Value, Label, IsActive, IsDefaultValue
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.NamespacePrefix = 'TSPC'
  AND IsActive = true
ORDER BY ObjectName, FieldName, SortOrder

-- 5. Opportunity Stage Configuration
SELECT Id, ApiName, Value, Label, IsActive, IsDefaultValue,
       ForecastCategoryName, Probability, IsClosed, IsWon,
       SortOrder, Description
FROM OpportunityStage
WHERE IsActive = true
ORDER BY SortOrder

-- 6. Opportunity Record Types
SELECT Id, Name, DeveloperName, Description, IsActive,
       SobjectType, BusinessProcessId
FROM RecordType
WHERE SobjectType = 'Opportunity'
  AND IsActive = true
ORDER BY Name

-- 7. Business Processes
SELECT Id, Name, Description, IsActive, TableEnumOrId
FROM BusinessProcess
WHERE TableEnumOrId = 'Opportunity'
ORDER BY Name

-- 8. Validation Rules
SELECT Id, ValidationName, Description, ErrorMessage,
       ErrorDisplayField, Active, EntityDefinition.QualifiedApiName
FROM ValidationRule
WHERE Active = true
  AND (EntityDefinition.QualifiedApiName = 'Opportunity'
       OR EntityDefinition.NamespacePrefix = 'TSPC')
ORDER BY EntityDefinition.QualifiedApiName

-- 9. Active Flows
SELECT Id, Definition.DeveloperName, Definition.MasterLabel,
       Definition.Description, ProcessType, Status
FROM FlowVersionView
WHERE Status = 'Active'
ORDER BY Definition.MasterLabel

-- 10. OpportunityContactRole Role Values
SELECT Value, Label, IsActive, IsDefaultValue
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'OpportunityContactRole'
  AND EntityParticle.QualifiedApiName = 'Role'
  AND IsActive = true
ORDER BY SortOrder

-- 11. Task Type Values
SELECT Value, Label, IsActive
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'Task'
  AND EntityParticle.QualifiedApiName = 'Type'
  AND IsActive = true
ORDER BY SortOrder

-- 12. Event Type Values
SELECT Value, Label, IsActive
FROM PicklistValueInfo
WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'Event'
  AND EntityParticle.QualifiedApiName = 'Type'
  AND IsActive = true
ORDER BY SortOrder

-- 13. Klue Objects (Competition Intelligence)
SELECT Id, DeveloperName, Label, Description
FROM EntityDefinition
WHERE NamespacePrefix = 'klue'
ORDER BY Label

-- 14. Klue Fields on Opportunity
SELECT QualifiedApiName, Label, DataType, Description
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
  AND NamespacePrefix = 'klue'
ORDER BY Label
```

## 9.3 SOQL Query Reference

### Data Analysis Queries

```sql
-- Pipeline Overview
SELECT StageName, RecordType.Name, COUNT(Id), SUM(Amount), AVG(Amount)
FROM Opportunity
WHERE IsClosed = false
GROUP BY StageName, RecordType.Name
ORDER BY RecordType.Name, StageName

-- Sample Opportunity with All Related Data
SELECT Id, Name, StageName, Amount, CloseDate, Probability,
       Account.Name, Account.Industry, Owner.Name,
       TSPC__Close_Plan__c, TSPC__Champion__c, TSPC__Economic_Buyer__c,
       (SELECT Id, ContactId, Contact.Name, Role FROM OpportunityContactRoles),
       (SELECT Id, Subject, Type, ActivityDate, Who.Name FROM Tasks ORDER BY ActivityDate DESC LIMIT 10),
       (SELECT Id, Subject, Type, ActivityDateTime, Who.Name FROM Events ORDER BY ActivityDateTime DESC LIMIT 10)
FROM Opportunity
WHERE IsClosed = false
  AND Amount >= 100000
LIMIT 10

-- ClosePlan with Related Records
SELECT Id, Name, TSPC__Opportunity__r.Name, TSPC__Status__c,
       (SELECT Id, TSPC__Pain_Description__c, TSPC__Priority__c FROM TSPC__Pains__r),
       (SELECT Id, TSPC__Metric_Type__c, TSPC__Value__c FROM TSPC__Metrics__r),
       (SELECT Id, TSPC__Contact__r.Name, TSPC__Role__c, TSPC__Influence__c FROM TSPC__Stakeholders__r),
       (SELECT Id, TSPC__Criteria__c, TSPC__Type__c, TSPC__Status__c FROM TSPC__Decision_Criterias__r),
       (SELECT Id, TSPC__Step_Name__c, TSPC__Sequence__c, TSPC__Status__c FROM TSPC__Decision_Processes__r),
       (SELECT Id, TSPC__Competitor_Name__c, TSPC__Threat_Level__c FROM TSPC__Competitions__r)
FROM TSPC__Close_Plan__c
WHERE TSPC__Opportunity__r.IsClosed = false
LIMIT 20

-- Win/Loss Analysis by MEDDIC Score
SELECT 
    CASE 
        WHEN TSPC__MEDDIC_Score__c >= 80 THEN '80-100'
        WHEN TSPC__MEDDIC_Score__c >= 60 THEN '60-79'
        WHEN TSPC__MEDDIC_Score__c >= 40 THEN '40-59'
        WHEN TSPC__MEDDIC_Score__c >= 20 THEN '20-39'
        ELSE '0-19'
    END ScoreRange,
    COUNT(Id) TotalOpps,
    SUM(CASE WHEN IsWon = true THEN 1 ELSE 0 END) WonOpps
FROM Opportunity
WHERE IsClosed = true
  AND CloseDate >= LAST_N_MONTHS:12
  AND Amount >= 100000
  AND TSPC__MEDDIC_Score__c != null
GROUP BY CASE 
    WHEN TSPC__MEDDIC_Score__c >= 80 THEN '80-100'
    WHEN TSPC__MEDDIC_Score__c >= 60 THEN '60-79'
    WHEN TSPC__MEDDIC_Score__c >= 40 THEN '40-59'
    WHEN TSPC__MEDDIC_Score__c >= 20 THEN '20-39'
    ELSE '0-19'
END
ORDER BY ScoreRange DESC
```

## 9.4 Glossary

| Term | Definition |
|------|------------|
| **MEDDIC** | Metrics, Economic Buyer, Decision Criteria, Decision Process, Identify Pain, Champion |
| **MEDDPICC** | MEDDIC + Paper Process + Competition |
| **ClosePlan** | AppExchange app for MEDDIC methodology (TSPC namespace) |
| **Economic Buyer** | Person with final budget authority |
| **Champion** | Internal advocate with power and vested interest |
| **Decision Criteria** | Technical and business requirements |
| **Decision Process** | Steps, timeline, and people in buying decision |
| **Paper Process** | Legal, procurement, security review steps |
| **ESL** | Electronic Shelf Label |
| **Vusion Group** | Major ESL/retail automation company |

---

## 9.5 Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-15 | [Your Name] | Initial document |

---

*This document serves as the complete blueprint for implementing a MEDDIC Compliance Analyzer using GPTfy. Execute each phase sequentially, documenting findings before proceeding to the next phase.*
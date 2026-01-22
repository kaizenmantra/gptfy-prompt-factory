# GPTfy MEDDIC Opportunity Prompt Configuration
## Existing Configuration Analysis

**Generated:** 2025-12-25
**Prompt ID:** a8Jbd0000003IrdEAE
**Data Context Mapping ID:** a8Abd0000000AsDEAU

---

## 1. Current Configuration Summary

### 1.1 Prompt Record

| Field | Value |
|-------|-------|
| **Name** | MEDDIC Opportunity Prompt |
| **Object** | Opportunity |
| **Type** | Text |
| **Status** | Draft |
| **Description** | Analyze MEDDIC to come up with a Sales Process oriented recommendation and related information |
| **Data Context Mapping** | MEDDIC Opportunity Prompt (a8Abd0000000AsDEAU) |

### 1.2 Data Context Mapping

| Field | Value |
|-------|-------|
| **Name** | MEDDIC Opportunity Prompt |
| **Object** | Opportunity |
| **Status** | Draft |

---

## 2. Current Data Extraction Details

### 2.1 Related Objects Configured

| Object | Relationship Name | Relationship Field | Type | Order | Limit |
|--------|-------------------|-------------------|------|-------|-------|
| **OpportunityContactRole** | OpportunityContactRoles | OpportunityId | CHILD | DESC | - |
| **Task** | Tasks | WhatId | CHILD | DESC | - |
| **EmailMessage** | Emails | RelatedToId | CHILD | DESC | - |
| **Event** | Events | WhatId | CHILD | DESC | - |
| **ActivityHistory** | ActivityHistories | WhatId | CHILD | DESC | - |

### 2.2 Fields by Object

#### Opportunity Fields (Parent)
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| Account.Name | Account Name | Yes |
| Account.Industry | Industry | Yes |
| Account.AnnualRevenue | Annual Revenue | Yes |
| Account.NumberOfEmployees | Employees | Yes |
| Account.NumberOfLocations__c | Number of Locations | Yes |
| Account.Description | Account Description | Yes |
| Account.Type | Account Type | Yes |
| Account.Ownership | Ownership | Yes |
| Account.BillingCity | Billing City | Yes |
| Account.BillingState | Billing State/Province | Yes |
| Account.BillingCountry | Billing Country | Yes |
| AccountId | Account ID | Yes |
| AccountOwnerName__c | Account Owner Name | Yes |
| Amount | Total opportunity amount | Yes |
| Brand__c | SES or Imagotag? | Yes |
| CloseDate | Expected PO Receiving Date | Yes |
| Country__c | Country | Yes |
| CurrencyIsoCode | Opportunity Currency | Yes |
| Date_du_premier_contact__c | First Contact Date | Yes |
| DateInstallationSouhaitee__c | Requested Delivery Date | Yes |
| DB_Competitor__c | DB Competitor | Yes |
| Description | Description | Yes |
| ExpectedEndOfPilot__c | Expected end of pilot | Yes |
| Incoterms__c | Incoterms | Yes |
| LeadSource | Opportunity source | Yes |
| Must_Win__c | Must Win | Yes |
| NextStep | Next Step | Yes |
| Nombre_de_pilotes__c | Number of Trial Locations | Yes |
| Nombre_Potentiel_d_EEG_1__c | Potential Number of ESLs (1) | Yes |
| Nombre_Potentiel_d_EEG_2__c | Potential Number of ESLs (2) | Yes |
| Nombre_Potentiel_d_EEG_3__c | Potential Number of ESLs (3) | Yes |
| Nombre_Potentiel_d_EEG_4__c | Potential Number of ESLs (4) | Yes |
| NombresMagasins__c | Number of Stores | Yes |
| PilotDurationInMonths__c | Pilot duration (in months) | Yes |
| Probability | Probability (%) | Yes |
| StageName | Stage | Yes |
| Start_of_delivery_installation__c | Start of Delivery & Installation | Yes |
| SupplyScheme__c | Supply Scheme | Yes |
| Type | Business Type | Yes |
| Type_Potentiel_d_EEG_1__c | Potential Type of ESL (1) | Yes |
| Type_Potentiel_d_EEG_2__c | Potential Type of ESL (2) | Yes |
| Type_Potentiel_d_EEG_3__c | Potential Type of ESL (3) | Yes |
| Type_Potentiel_d_EEG_4__c | Potential Type of ESL (4) | Yes |
| Zone__c | Business Unit (Opp) | Yes |

#### OpportunityContactRole Fields
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| ContactId | Contact ID | Yes |
| Contact.Name | Contact Name | Yes |
| Contact.Title | Title | Yes |
| Contact.Email | Email | Yes |
| Contact.Phone | Phone | Yes |
| Contact.Department | Department | Yes |
| Role | Role | Yes |
| IsPrimary | Primary | Yes |

#### ActivityHistory Fields
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| Account.Name | Account Name | Yes |
| AccountId | Account ID | Yes |
| ActivityDate | Date | Yes |
| ActivitySubtype | Activity Subtype | Yes |
| ActivityType | Type | Yes |
| CompletedDateTime | Completed Date/Time | Yes |
| DB_Activity_Type__c | DB Activity Type | Yes |
| Description | Comments | Yes |
| Priority | Priority | Yes |
| Status | Status | Yes |
| Subject | Subject | Yes |
| WhatId | Related To ID | Yes |
| WhoId | Name ID | Yes |

#### EmailMessage Fields
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| FromAddress | From Address | Yes |
| FromName | From Name | Yes |
| Incoming | Is Incoming | Yes |
| MessageDate | Message Date | Yes |
| RelatedToId | Related To ID | Yes |
| Status | Status | Yes |
| Subject | Subject | Yes |
| TextBody | Text Body | Yes |
| ToAddress | To Address | Yes |
| ValidatedFromAddress | From | Yes |

#### Event Fields
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| Description | Description | Yes |
| DurationInMinutes | Duration | Yes |
| EndDateTime | End Date Time | Yes |
| IsAllDayEvent | All-Day Event | Yes |
| Location | Location | Yes |
| ShowAs | Show Time As | Yes |
| StartDateTime | Start Date Time | Yes |
| Subject | Subject | Yes |
| Type | Type | Yes |
| WhatId | Related To ID | Yes |
| WhoId | Name ID | Yes |

#### Task Fields
| Field API Name | Label | Sent to AI |
|---------------|-------|------------|
| ActivityDate | Due Date | Yes |
| CompletedDateTime | Completed Date/Time | Yes |
| Description | Comments | Yes |
| Priority | Priority | Yes |
| Status | Status | Yes |
| Subject | Subject | Yes |
| Type | Type | Yes |
| WhatId | Related To ID | Yes |
| WhoId | Name ID | Yes |

---

## 3. Current Prompt Analysis

### 3.1 Prompt Structure

The current prompt is a comprehensive "Deal Coach" prompt with the following sections:

1. **Role Definition**: Sales strategist for retail technology analysis
2. **Grounding Rules**: Industry focus, data-based recommendations, actionable insights
3. **VusionGroup Context**: ESL/retail IoT solutions, target customers, typical buying committee
4. **Executive Summary**: Stage, value, close date, retailer profile, solution scope, health status
5. **Strategic Assessment Framework**: 13 key questions covering:
   - Customer profile
   - Industry context
   - Financial/procurement considerations
   - VusionGroup solution fit
   - Deal complexity
   - Store deployment strategy
   - Implementation complexity
   - Integration requirements
   - Business case/ROI
   - Stakeholder engagement
   - Competitive landscape
   - Stage health assessment
   - Intelligent recommendations

### 3.2 MEDDIC Coverage Analysis

| MEDDIC Element | Current Coverage | Notes |
|----------------|------------------|-------|
| **M - Metrics** | Partial | Business case/ROI section covers metrics |
| **E - Economic Buyer** | Partial | Stakeholder engagement mentions EB, but no explicit field |
| **D - Decision Criteria** | Good | Solution fit and competitive positioning covered |
| **D - Decision Process** | Partial | Implementation timeline covered |
| **I - Identify Pain** | Limited | Needs more explicit pain documentation |
| **C - Champion** | Partial | Champion mentioned in stakeholder section |

### 3.3 Key Strengths

1. **VusionGroup-specific context** - Deep knowledge of ESL/retail solutions
2. **Comprehensive deal analysis** - 13-point strategic assessment
3. **Stage-appropriate guidance** - Health assessment based on current stage
4. **Competitive intelligence** - Specific competitor mentions (Pricer, Displaydata, Hanshow)
5. **Implementation focus** - Strong coverage of deployment complexity

### 3.4 Gaps Identified

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| **No ClosePlan (TSPC) data** | Cannot leverage structured MEDDIC data | Add TSPC objects to data context |
| **No explicit MEDDIC scoring** | No quantitative MEDDIC assessment | Add element-by-element scoring |
| **No Champion validation fields** | Cannot assess champion strength | Add TSPC__DealStakeholder__c fields |
| **No stage-MEDDIC matrix** | No validation of MEDDIC vs stage | Add stage-specific requirements |
| **Missing MEDDIC score fields** | Not using existing score fields | Add Overall_Score__c, etc. |

---

## 4. Recommended Enhancements

### 4.1 Data Context Mapping Additions

Add the following related objects:

```yaml
# ClosePlan Deal (if available)
Object: TSPC__Deal__c
Relationship: via TSPC__CPDeal__c lookup
Fields:
  - Name
  - TSPC__EventCSProgress__c (Current Stage Progress)
  - TSPC__EventCompletedCount__c
  - TSPC__EventCount__c
  - TSPC__ModStampSC__c (Last Scorecard Update)

# ClosePlan Stakeholders
Object: TSPC__DealStakeholder__c
Relationship: via TSPC__Deal__c
Fields:
  - TSPC__Contact__c
  - TSPC__ContactName__c
  - TSPC__Role__c (Champion, Economic Buyer, etc.)
  - TSPC__SupportStatus__c (Promoter, Supporter, Neutral, etc.)
  - TSPC__DecisionStatus__c (Decision Influence)
  - TSPC__HasPower__c
  - TSPC__Relationship__c
  - TSPC__Goal__c

# ClosePlan Questions (Scorecard)
Object: TSPC__DealQuestion__c
Relationship: via TSPC__Deal__c
Fields:
  - TSPC__Text__c (Question text)
  - TSPC__Answer__c
  - TSPC__Score__c
  - TSPC__MaxScore__c
  - TSPC__Notes__c

# ClosePlan Events (Milestones)
Object: TSPC__Event__c
Relationship: via TSPC__Deal__c
Fields:
  - Name
  - TSPC__Status__c
  - TSPC__StartDate__c
  - TSPC__EndDate__c
  - TSPC__IsMutual__c
  - TSPC__Stage__c
  - TSPC__Goal__c
```

### 4.2 Missing Opportunity Fields to Add

```yaml
# MEDDIC Score Fields
- Overall_Score__c
- Stakeholder_Engagement_Score__c
- Competitive_Positioning_Score__c
- Stage_Requirements_Met_Score__c
- Data_Quality_Score__c
- Risk_Mitigation_Score__c
- Next_Stage_Preparedness_Score__c

# Competition Fields
- Competitor__c (multi-select)
- WinningCompetitor__c

# Win/Loss Fields
- Loss_details__c
- Reason_for_loss__c
```

### 4.3 Prompt Enhancement Recommendations

#### Add MEDDIC Scoring Section

```markdown
## MEDDIC Element Assessment

For each MEDDIC element, provide:
- Score (0-100)
- Status (Strong/Progressing/At Risk/Missing)
- Evidence from provided data
- Gaps identified
- Recommended actions

### Scoring Rubric
| Score | Status |
|-------|--------|
| 76-100 | Strong - Validated/Evidenced |
| 51-75 | Progressing - Documented but needs validation |
| 26-50 | At Risk - Partial/Weak |
| 0-25 | Missing - No evidence |

### MEDDIC Elements to Score
1. **M - Metrics**: Business case, ROI, value quantification
2. **E - Economic Buyer**: Budget authority identification and engagement
3. **D - Decision Criteria**: Technical and business requirements mapping
4. **D - Decision Process**: Approval steps, timeline, milestones
5. **I - Identify Pain**: Business pains documented with impact
6. **C - Champion**: Internal advocate with power and personal win
```

#### Add Stage-MEDDIC Matrix

```markdown
## Stage-MEDDIC Requirements

| Stage | Minimum MEDDIC Score | Key Requirements |
|-------|---------------------|------------------|
| Interest | 35 | Pain confirmed, Champion identified |
| Analysis in progress | 50 | Pain documented, EB identified |
| Proposal sent | 65 | EB engaged, Criteria confirmed |
| Budget approved | 75 | Metrics validated, Process mapped |
| Verbal agreement | 85 | All elements evidenced |

Assess: Is this opportunity's MEDDIC maturity appropriate for its current stage?
```

#### Add Champion Validation Section

```markdown
## Champion Assessment

From TSPC__DealStakeholder__c where Role = 'Champion':

1. **Identification**
   - Name and title
   - Department/function

2. **Validation Criteria**
   - Has Power: Can influence decision? (TSPC__HasPower__c)
   - Support Status: Promoter/Supporter? (TSPC__SupportStatus__c)
   - Relationship: Regular cadence/In depth? (TSPC__Relationship__c)
   - Personal Win: Documented? (TSPC__Goal__c)

3. **Engagement Evidence**
   - Recent activities with champion
   - Last contact date
   - Communication frequency

4. **Champion Risk Assessment**
   - RED if: No champion OR Neutral/Resistor disposition
   - YELLOW if: Champion identified but Low influence
   - GREEN if: Champion with Power + Promoter status + Regular engagement
```

### 4.4 Output Format Enhancement

Add explicit MEDDIC summary to output:

```html
<h2>📊 MEDDIC Compliance Summary</h2>
<table>
  <tr>
    <th>Element</th>
    <th>Score</th>
    <th>Status</th>
    <th>Key Gap</th>
  </tr>
  <tr>
    <td>Metrics</td>
    <td>[0-100]</td>
    <td>[🟢/🟡/🔴]</td>
    <td>[Gap description]</td>
  </tr>
  <!-- Repeat for E, D-Criteria, D-Process, I, C -->
</table>
<p><strong>Overall MEDDIC Score:</strong> [Weighted average]</p>
<p><strong>Stage Alignment:</strong> [Appropriate/Overstated/Conservative]</p>
```

---

## 5. Implementation Steps

### Phase 1: Data Context Mapping Enhancement
1. Add TSPC__Deal__c relationship (if records exist)
2. Add TSPC__DealStakeholder__c
3. Add missing Opportunity score fields
4. Test data retrieval with sample opportunities

### Phase 2: Prompt Enhancement
1. Add MEDDIC scoring section
2. Add stage-MEDDIC matrix
3. Add champion validation logic
4. Enhance output format with MEDDIC summary

### Phase 3: Testing
1. Test with well-documented opportunity
2. Test with sparse opportunity data
3. Validate scoring accuracy with sales managers
4. Refine based on feedback

---

## 6. Current Prompt Text (Full)

The complete prompt command is documented below for reference:

```
I am a sales strategist specializing in comprehensive retail technology sales opportunity analysis...

[Full prompt text - approximately 4,500 words covering:]
- Data Rules
- Grounding Rules
- VusionGroup-Specific Context
- Executive Summary Analysis
- Strategic Opportunity Assessment Framework (13 questions)
- Output Formatting Instructions (HTML)
```

**Note:** The full prompt text focuses on VusionGroup's retail IoT business with specific references to:
- Products: ESL/SESimagotag, Captana, Memory, Engage, VusionCloud, PDidigital
- Competitors: Pricer, Displaydata, Hanshow, Solum
- Sales cycle: 6-24 months
- Buying committee: Merchandising VP, Store Operations, IT, Finance, Sustainability

---

*Configuration documented from pocgptfy sandbox*
*Version 1.0 | 2025-12-25*

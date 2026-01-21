# MEDDIC Org Analysis Report
## pocgptfy Sandbox - SES-imagotag

**Generated:** 2025-12-25
**Org:** pocgptfy (Sandbox)
**Analysis Type:** Metadata & Data Discovery

---

## Executive Summary

This report documents the MEDDIC-related metadata and data found in the pocgptfy sandbox. The analysis reveals that while the org has **ClosePlan (TSPC) installed**, **no ClosePlan deal records have been created yet**. The MEDDIC framework will need to rely on OpportunityContactRole and custom score fields until ClosePlan is populated.

### Key Findings

| Category | Status | Details |
|----------|--------|---------|
| ClosePlan Package | Installed | TSPC namespace v1.291 |
| ClosePlan Records | **Empty** | 0 Deal records, 0 Stakeholders |
| Opportunity Pipeline | Active | 10 open opportunities |
| Contact Roles | Partially Used | 22 contact roles across opportunities |
| MEDDIC Score Fields | Configured | 6 custom score fields on Opportunity |
| Activity Data | Minimal | 15 tasks linked to opportunities |

---

## 1. Installed Packages

### MEDDIC-Relevant Packages

| Package | Namespace | Version | Purpose |
|---------|-----------|---------|---------|
| **ClosePlan** | `TSPC` | 1.291 | Primary MEDDIC methodology framework |
| Salesforce CPQ | `SBQQ` | - | Quote/pricing for Metrics validation |
| Klue | `klue` | 2.0 | Competitive intelligence |
| LinkedIn Sales Navigator | `LID` | - | Contact/relationship insights |
| Aircall CTI | `aircall` | - | Call tracking |
| Twilio | `twilio_sf` | - | Communication tracking |

---

## 2. ClosePlan (TSPC) Object Analysis

### 2.1 Core MEDDIC Objects

| Object | API Name | Purpose | MEDDIC Element |
|--------|----------|---------|----------------|
| **ClosePlan** | `TSPC__Deal__c` | Master deal record (1:1 with Opportunity) | All |
| **Deal Stakeholder** | `TSPC__DealStakeholder__c` | Buying committee members | E, C |
| **Deal Question** | `TSPC__DealQuestion__c` | Scorecard questions | All |
| **Event (Milestone)** | `TSPC__Event__c` | Mutual action plan items | D-Process |
| **Category** | `TSPC__Category__c` | Question categories | All |
| **Competitor** | `TSPC__Competitor__c` | Competition tracking | Competition |

### 2.2 Deal Stakeholder Fields (MEDDIC Critical)

| Field | API Name | Type | Values | MEDDIC Use |
|-------|----------|------|--------|------------|
| **Role** | `TSPC__Role__c` | Picklist | Champion, Economic Buyer, Legal, End User, Procurement, Other, Unknown | E, C identification |
| **Support Status** | `TSPC__SupportStatus__c` | Picklist | Promoter, Supporter, Neutral, Resistor, Detractor, Unknown | Champion validation |
| **Decision Influence** | `TSPC__DecisionStatus__c` | Picklist | Unknown, Very Low, Medium, High | E, C power assessment |
| **Relationship** | `TSPC__Relationship__c` | Picklist | No Contact, Limited Contact, Regular Cadence, In Depth | Engagement level |
| **Power** | `TSPC__HasPower__c` | Boolean | true/false | Authority indicator |
| **Contact** | `TSPC__Contact__c` | Lookup | Contact | Person reference |
| **Goal** | `TSPC__Goal__c` | Text Area | Free text | Personal win documentation |

### 2.3 Deal Question Fields (Scorecard)

| Field | API Name | Type | Purpose |
|-------|----------|------|---------|
| Text | `TSPC__Text__c` | String | Question text |
| Answer | `TSPC__Answer__c` | Picklist | Selected answer |
| Score | `TSPC__Score__c` | Number | Points scored |
| Max Score | `TSPC__MaxScore__c` | Number | Maximum possible points |
| Notes | `TSPC__Notes__c` | Text Area | Supporting notes |
| Category | `TSPC__Category__c` | Lookup | Question category (MEDDIC element) |

### 2.4 Event (Milestone) Fields

| Field | API Name | Type | Purpose |
|-------|----------|------|---------|
| Name | `Name` | String | Milestone name |
| Status | `TSPC__Status__c` | Picklist | Progress status |
| Start Date | `TSPC__StartDate__c` | Date | Planned start |
| End Date | `TSPC__EndDate__c` | Date | Planned end |
| Associated Stage | `TSPC__Stage__c` | String | Opportunity stage link |
| Is Mutual | `TSPC__IsMutual__c` | Boolean | Customer commitment |
| Goal | `TSPC__Goal__c` | Text Area | Milestone objective |

### 2.5 Current ClosePlan Data Status

```
TSPC__Deal__c records:        0
TSPC__DealStakeholder__c:     0
TSPC__DealQuestion__c:        0
TSPC__Event__c:               0
```

**Implication:** GPTfy MEDDIC analysis must initially rely on:
- OpportunityContactRole for stakeholder data
- Custom score fields on Opportunity
- Activity records (Task/Event)
- Notes and Description fields

---

## 3. Opportunity Object Analysis

### 3.1 MEDDIC-Related Custom Fields

| Field | API Name | Type | Purpose |
|-------|----------|------|---------|
| **ClosePlan Reference** | `TSPC__CPDeal__c` | Lookup | Link to ClosePlan record |
| **Overall Score** | `Overall_Score__c` | Number | Aggregate MEDDIC score |
| **Stakeholder Engagement** | `Stakeholder_Engagement_Score__c` | Number | E, C score |
| **Competitive Positioning** | `Competitive_Positioning_Score__c` | Number | Competition score |
| **Stage Requirements Met** | `Stage_Requirements_Met_Score__c` | Number | Stage validation |
| **Data Quality** | `Data_Quality_Score__c` | Number | Completeness score |
| **Risk Mitigation** | `Risk_Mitigation_Score__c` | Number | Risk assessment |
| **Next Stage Preparedness** | `Next_Stage_Preparedness_Score__c` | Number | Advancement readiness |
| **Competitor(s)** | `Competitor__c` | Multi-select | Competition tracking |
| **Winning Competitor** | `WinningCompetitor__c` | Picklist | Win/loss attribution |
| **Win/Loss Details** | `Loss_details__c` | Text Area | Outcome documentation |
| **Win/Loss Reasons** | `Reason_for_loss__c` | Multi-select | Structured loss reasons |

### 3.2 Opportunity Stages

| Stage | Purpose | Suggested MEDDIC Min Score |
|-------|---------|---------------------------|
| New | Initial opportunity | 20 |
| New contact | First engagement | 25 |
| Interest | Qualified interest | 35 |
| Memory interest | Returning interest | 35 |
| Analysis in progress | Discovery/evaluation | 45 |
| Quote Sent | Proposal delivered | 55 |
| Proposal sent | Formal proposal | 60 |
| Proposal Development | Building proposal | 55 |
| Budget approved | Financial commitment | 70 |
| Commitment for needs | Requirements locked | 75 |
| Verbal agreement / Letter of intent | Soft commitment | 80 |
| Framework contract | Master agreement | 85 |
| Quote Signed | Commitment | 90 |
| Order Signed | Closed Won | 95 |
| Closed/Won/Lost/Abandoned | Terminal states | N/A |

### 3.3 Current Pipeline

| Stage | Count | Total Amount |
|-------|-------|--------------|
| New | 3 | €3,267 |
| Interest | 1 | €725,000 |
| Analysis in progress | 2 | €735,000 |
| New contact | 1 | €87 |
| Proposal sent | 2 | €95,000 |
| Proposal Development | 1 | €839 |
| **Total Open** | **10** | **€1,559,193** |

---

## 4. OpportunityContactRole Analysis

### 4.1 Available Roles (MEDDIC Mapping)

| Role | MEDDIC Element | Count in Org | Notes |
|------|----------------|--------------|-------|
| **Economic Buyer** | E - Economic Buyer | 1 | Budget authority |
| **Champion** | C - Champion | 1 | Internal advocate |
| **Decision Maker** | D - Process | 5 | Final authority |
| **Technical Buyer** | D - Criteria | 7 | Technical validation |
| **Evaluator** | D - Criteria | 0 | Technical assessment |
| **Influencer** | General | 6 | Affects decision |
| **Business User** | I - Pain | 0 | Experiences pain |
| **Executive Sponsor** | E - Economic Buyer | 0 | Senior leadership |
| **Economic Decision Maker** | E - Economic Buyer | 0 | Combined E + D |

### 4.2 Role Coverage Analysis

```
Total Contact Roles:          22
Opportunities with roles:     ~8 (estimated)
Average roles per opp:        2.75

MEDDIC Coverage:
- Economic Buyer identified:  1 opportunity
- Champion identified:        1 opportunity
- Decision Maker identified:  5 opportunities
- Technical Buyer identified: 7 opportunities
```

**Gap:** Most opportunities lack Economic Buyer and Champion identification.

---

## 5. Activity Analysis

### 5.1 Task Types Available

| Type | Purpose | MEDDIC Evidence |
|------|---------|-----------------|
| Call | Phone calls | All elements |
| Meeting | In-person/video | E, C validation |
| Other | Miscellaneous | Various |

### 5.2 Event Types Available

| Type | Purpose | MEDDIC Evidence |
|------|---------|-----------------|
| Call | Scheduled calls | All elements |
| Meeting | Scheduled meetings | E, C, D-Process |
| Email | Email tracking | Engagement |
| Other | Miscellaneous | Various |

### 5.3 Current Activity Data

```
Tasks linked to Opportunities: 15
Events linked to Opportunities: (to be queried)
```

**Gap:** Limited activity data for MEDDIC evidence validation.

---

## 6. GPTfy Implementation Recommendations

### 6.1 Data Context Mapping Strategy

Given the current state (ClosePlan empty), use a **hybrid approach**:

**Primary Sources (Always Include):**
```yaml
- Opportunity (all MEDDIC score fields)
- OpportunityContactRole (for E, C, D identification)
- Task (completed activities)
- Event (meetings)
```

**Secondary Sources (When ClosePlan Populated):**
```yaml
- TSPC__Deal__c (via TSPC__CPDeal__c)
- TSPC__DealStakeholder__c (via Deal)
- TSPC__DealQuestion__c (via Deal)
- TSPC__Event__c (via Deal)
```

### 6.2 Scoring Algorithm Adaptation

Since ClosePlan is empty, score based on:

| Element | Primary Source | Fallback Source |
|---------|---------------|-----------------|
| **Metrics** | Quote Amount, Custom fields | Opportunity.Amount |
| **Economic Buyer** | ContactRole = 'Economic Buyer' | ContactRole = 'Decision Maker' |
| **Decision Criteria** | ContactRole = 'Technical Buyer' | Activity count |
| **Decision Process** | Stage progression | Close date vs created date |
| **Pain** | Description field | Activity notes |
| **Champion** | ContactRole = 'Champion' | Most engaged contact |

### 6.3 Recommended Actions

1. **Populate ClosePlan Data**
   - Create TSPC__Deal__c records for open opportunities
   - Add stakeholders with roles and dispositions
   - Configure scorecard questions

2. **Enrich Contact Roles**
   - Ensure every opp has Economic Buyer identified
   - Identify and document Champions
   - Map all buying committee members

3. **Increase Activity Logging**
   - Log all customer touchpoints
   - Use consistent activity types
   - Link activities to specific contacts

4. **Enable GPTfy MEDDIC Analyzer**
   - Configure data context mapping
   - Deploy prompt with fallback logic
   - Train users on interpretation

---

## 7. Sample Opportunity Analysis

### Top Opportunity: V-Care Plus Service Renewal

| Field | Value |
|-------|-------|
| **Name** | V-Care Plus Service Renewal - 3 Year Contract |
| **Amount** | €725,000 |
| **Stage** | Interest |
| **Close Date** | 2025-11-30 |
| **ClosePlan** | Not created |
| **Overall Score** | 4 |
| **Stakeholder Score** | 4 |
| **Competitive Score** | 4 |

**MEDDIC Assessment:**
- **M - Metrics:** Unknown (no business case documented)
- **E - Economic Buyer:** Not identified in ContactRole
- **D - Criteria:** Unknown (no technical evaluation logged)
- **D - Process:** Unknown (no milestones documented)
- **I - Pain:** Unknown (no pain points documented)
- **C - Champion:** Not identified in ContactRole

**Recommendation:** High-value deal at early stage needs immediate MEDDIC discovery work.

---

## 8. Next Steps

### Immediate (This Week)
- [ ] Create ClosePlan deals for top 5 opportunities
- [ ] Add Economic Buyer and Champion to ContactRoles
- [ ] Document known pain points in Opportunity Description

### Short-term (Next 2 Weeks)
- [ ] Configure GPTfy Data Context Mapping
- [ ] Deploy MEDDIC Compliance Analyzer prompt
- [ ] Train sales team on MEDDIC data entry

### Medium-term (Next Month)
- [ ] Populate ClosePlan stakeholders for all open opps
- [ ] Configure ClosePlan scorecard questions
- [ ] Establish stage-gating validation rules

---

## Appendix A: TSPC Objects Full List

| Object | Label | Description |
|--------|-------|-------------|
| TSPC__Deal__c | ClosePlan | Main deal record |
| TSPC__DealStakeholder__c | Deal Stakeholder | Buying committee |
| TSPC__DealQuestion__c | Deal Question | Scorecard items |
| TSPC__DealQuestionAnswer__c | Deal Question Answer | Answer options |
| TSPC__DealQuestionCategory__c | Deal Question Category | MEDDIC categories |
| TSPC__DealSnapshot__c | Deal Snapshot | Historical snapshots |
| TSPC__Event__c | Event | Mutual action plan |
| TSPC__EventGroup__c | Event Group | Milestone groups |
| TSPC__EventPerson__c | Event Person | Milestone owners |
| TSPC__Category__c | Category | Generic categories |
| TSPC__Competitor__c | Competitor | Competition tracking |
| TSPC__Template__c | Template | ClosePlan templates |
| TSPC__TemplateQuestion__c | Template Question | Question templates |
| TSPC__TemplateEvent__c | Template Event | Milestone templates |
| TSPC__AP__c | Account Plan | Account planning |
| TSPC__AccountMap__c | Account Map | Org chart mapping |

---

## Appendix B: Opportunity Score Fields Schema

```sql
SELECT
    Id,
    Name,
    StageName,
    Amount,
    CloseDate,
    TSPC__CPDeal__c,
    Overall_Score__c,
    Stakeholder_Engagement_Score__c,
    Competitive_Positioning_Score__c,
    Stage_Requirements_Met_Score__c,
    Data_Quality_Score__c,
    Risk_Mitigation_Score__c,
    Next_Stage_Preparedness_Score__c,
    Competitor__c,
    WinningCompetitor__c,
    Loss_details__c,
    Reason_for_loss__c
FROM Opportunity
WHERE IsClosed = false
```

---

*Report generated by MEDDIC Org Analyzer*
*Version 1.0 | 2025-12-25*

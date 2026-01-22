# GPTfy MEDDIC Compliance Analyzer
## Product Requirements Document (PRD)

---

## 1. Executive Summary

### 1.1 Product Vision
Build an AI-powered MEDDIC compliance analyzer using GPTfy that evaluates Salesforce opportunity qualification against the MEDDIC sales methodology, providing stage-appropriate validation, risk identification, and actionable coaching recommendations.

### 1.2 Business Objective
Enable sales teams to improve deal qualification rigor by providing automated, intelligent analysis of MEDDIC element completion, evidence quality, and stage alignment - ultimately improving win rates and forecast accuracy.

### 1.3 Target Users
| User Type | Use Case |
|-----------|----------|
| Sales Representatives | Real-time deal coaching and gap identification |
| Sales Managers | Pipeline quality assessment and coaching prioritization |
| Sales Operations | Process compliance monitoring and reporting |
| Revenue Leadership | Forecast confidence and deal health visibility |

### 1.4 Key Success Metrics
- Increase MEDDIC field completion rate by 40%
- Improve stage-appropriate qualification accuracy
- Reduce unqualified deals progressing to late stages
- Improve win rate for deals with high MEDDIC scores

---

## 2. Problem Statement

### 2.1 Current Challenges
1. **Inconsistent Qualification**: Sales reps advance deals without proper MEDDIC element completion
2. **Lack of Stage Alignment**: No automated validation that MEDDIC maturity matches opportunity stage
3. **Evidence vs. Claims**: Filled fields don't always represent validated evidence
4. **Coaching Gaps**: Managers lack tools to identify specific deal weaknesses
5. **Data Fragmentation**: MEDDIC data spread across multiple objects (Opportunity, ClosePlan, Activities)

### 2.2 Desired Outcome
An intelligent system that:
- Aggregates MEDDIC data from all relevant Salesforce objects
- Scores each MEDDIC element based on evidence quality
- Validates scores against stage-specific expectations
- Identifies risks and gaps with specificity
- Recommends actionable next steps with clear ownership

---

## 3. Solution Architecture

### 3.1 Technology Stack
| Component | Technology | Purpose |
|-----------|------------|---------|
| CRM Platform | Salesforce | Data source and UI |
| MEDDIC Framework | ClosePlan (TSPC namespace) | Core MEDDIC data structure |
| AI Platform | GPTfy | Prompt execution and data context |
| Quote/Pricing | Salesforce CPQ (SBQQ) | Metrics validation |
| Competitive Intel | Klue (if available) | Competition data |

### 3.2 Data Sources

#### Primary Objects
| Object | Purpose | Key Fields |
|--------|---------|------------|
| `Opportunity` | Core deal record | Stage, Amount, CloseDate, Owner, TSPC__* fields |
| `TSPC__Deal__c` | ClosePlan master record | Status, Score, Last Updated |
| `OpportunityContactRole` | Stakeholder roles | Role, Contact reference |

#### ClosePlan Child Objects (via TSPC__Deal__c)
| Object | MEDDIC Element | Key Fields |
|--------|----------------|------------|
| `TSPC__Stakeholder__c` | Economic Buyer, Champion | Role, Influence, Disposition, Access Level |
| `TSPC__Pain__c` | Identify Pain | Description, Impact, Priority, Owner |
| `TSPC__Metric__c` | Metrics | Type, Value, Status, Validated |
| `TSPC__Decision_Criteria__c` | Decision Criteria | Criteria, Type, Status, Our Capability |
| `TSPC__Decision_Process__c` | Decision Process | Step, Owner, Due Date, Status |
| `TSPC__Competition__c` | Competition | Competitor, Threat Level, Strategy |

#### Activity Objects
| Object | Purpose |
|--------|---------|
| `Task` | Completed activities and follow-ups |
| `Event` | Meetings and calls |
| `EmailMessage` | Email engagement tracking |

### 3.3 Data Flow
```
Opportunity Record
    │
    ├── GPTfy Data Context Mapping (aggregates all objects)
    │
    └── GPTfy Prompt (analyzes MEDDIC compliance)
            │
            ├── Element-by-element scoring
            ├── Stage alignment validation
            ├── Risk identification
            └── Recommendation generation
                    │
                    └── Output: Structured MEDDIC Report
```

---

## 4. Functional Requirements

### 4.1 MEDDIC Element Analysis

#### FR-001: Metrics Analysis
**Description**: Evaluate the quality and completeness of documented business metrics.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No metrics documented |
| 26-50 | Generic/unvalidated metrics mentioned |
| 51-75 | Specific metrics with customer input |
| 76-100 | Quantified, customer-validated metrics with business case |

**Data Sources**:
- `TSPC__Metric__c` records
- `SBQQ__Quote__c` values
- Business case attachments

#### FR-002: Economic Buyer Analysis
**Description**: Assess Economic Buyer identification and engagement level.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No EB identified |
| 26-50 | EB identified but no engagement |
| 51-75 | EB met once or indirect access via Champion |
| 76-100 | Direct EB relationship with multiple meetings |

**Data Sources**:
- `TSPC__Stakeholder__c` with Role = 'Economic Buyer'
- `OpportunityContactRole` with Role = 'Economic Buyer'
- Activity records with EB contact

#### FR-003: Decision Criteria Analysis
**Description**: Evaluate technical and business criteria documentation and fit.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No criteria documented |
| 26-50 | Some criteria listed but not validated |
| 51-75 | Criteria documented with customer confirmation |
| 76-100 | All criteria mapped with capability match and competitive positioning |

**Data Sources**:
- `TSPC__Decision_Criteria__c` records
- Type (Technical/Business)
- Status and Our Capability fields

#### FR-004: Decision Process Analysis
**Description**: Assess understanding of the buying decision process.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No process documented |
| 26-50 | Generic understanding of process |
| 51-75 | Steps and timeline documented |
| 76-100 | Full process mapped with owners, dates, and paper process |

**Data Sources**:
- `TSPC__Decision_Process__c` records
- Step owners and due dates
- Stakeholder list for approvers

#### FR-005: Pain Identification Analysis
**Description**: Evaluate documented business pains and their validation.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No pain documented |
| 26-50 | Generic industry pain assumed |
| 51-75 | Specific pain points with business context |
| 76-100 | Quantified pain with clear business impact and urgency |

**Data Sources**:
- `TSPC__Pain__c` records
- Pain owner contacts
- Business impact documentation

#### FR-006: Champion Analysis
**Description**: Assess Champion identification, validation, and engagement.

**Scoring Criteria**:
| Score | Criteria |
|-------|----------|
| 0-25 | No champion identified |
| 26-50 | Friendly contact but not a true champion |
| 51-75 | Champion identified with influence |
| 76-100 | Validated champion with access to power and personal win |

**Data Sources**:
- `TSPC__Stakeholder__c` with Role = 'Champion'
- Influence and Disposition fields
- Activity history with champion
- Personal Win documentation

### 4.2 Stage Alignment Validation

#### FR-007: Stage-MEDDIC Matrix
**Description**: Validate that MEDDIC element completion matches stage expectations.

**Stage Requirements**:

| Stage | Min Score | Key Requirements |
|-------|-----------|------------------|
| Qualification | 40 | Pain confirmed, Champion identified |
| Discovery | 50 | Pain documented, Champion validated, EB identified |
| Solution Development | 65 | EB engaged, Criteria confirmed, Process mapped |
| Proposal/POC | 75 | Metrics validated, All criteria addressed |
| Negotiation | 85 | EB committed, Process in final steps |

#### FR-008: Gap Analysis
**Description**: Identify specific gaps between current scores and stage expectations.

**Output**: List of missing or weak elements with specific remediation steps.

### 4.3 Risk Assessment

#### FR-009: Critical Risk Identification
**Description**: Flag high-severity risks that could derail the deal.

**Critical Risk Triggers**:
| Risk | Condition |
|------|-----------|
| No Champion | Stage >= Solution Dev AND Champion score < 30 |
| No EB Engagement | Stage >= Proposal AND No EB activity in 60 days |
| Stalled Deal | No activity in 30+ days |
| Missing Metrics | Stage >= Proposal AND Metrics score < 50 |
| Single Threaded | Only 1 contact engaged |

#### FR-010: Warning Indicators
**Description**: Flag moderate concerns that need attention.

**Warning Triggers**:
| Warning | Condition |
|---------|-----------|
| Champion at Risk | Champion disposition = Neutral |
| EB Cooling | No EB activity in 30+ days |
| Competitive Threat | Competition threat level = High |
| Timeline Slip | Close date pushed 2+ times |

### 4.4 Recommendations Engine

#### FR-011: Actionable Recommendations
**Description**: Generate specific, actionable next steps based on analysis.

**Requirements**:
- Each recommendation tied to specific MEDDIC gap
- Clear owner suggestion (AE, Sales Engineer, Manager)
- Priority rating (Critical, High, Medium)
- Target timeframe (7-14 days)

#### FR-012: Stage Advancement Readiness
**Description**: Provide clear guidance on readiness to advance to next stage.

**Output**:
- Ready to Advance: YES/NO/CONDITIONAL
- Requirements checklist with status
- Specific blockers if not ready

---

## 5. Non-Functional Requirements

### 5.1 Performance
- Analysis should complete within 10 seconds
- Support batch analysis of up to 50 opportunities

### 5.2 Accuracy
- Scoring should align with manual sales manager assessment within 10 points
- No false positives on critical risks
- Evidence cited for all assessments

### 5.3 Usability
- Output should be readable by non-technical users
- Clear visual indicators (green/yellow/red)
- Recommendations in actionable language

### 5.4 Security
- Honor Salesforce sharing rules
- No sensitive data in AI responses
- Audit trail for all analyses

---

## 6. GPTfy Implementation

### 6.1 Data Context Mapping Configuration
```yaml
Mapping Name: MEDDIC Compliance Analysis
Target Object: Opportunity
Status: Active

Related Objects:
  - OpportunityContactRole (limit: 20)
  - TSPC__Stakeholder__c (via Close Plan, limit: 20)
  - TSPC__Pain__c (via Close Plan, limit: 10)
  - TSPC__Metric__c (via Close Plan, limit: 10)
  - TSPC__Decision_Criteria__c (via Close Plan, limit: 20)
  - TSPC__Decision_Process__c (via Close Plan, limit: 15)
  - TSPC__Competition__c (via Close Plan, limit: 5)
  - Task (limit: 20, filter: Completed, order: ActivityDate DESC)
  - Event (limit: 20, order: ActivityDateTime DESC)
```

### 6.2 Prompt Configuration
```yaml
Prompt Name: MEDDIC Compliance Analyzer
Target Object: Opportunity
Type: Text
Data Context Mapping: MEDDIC Compliance Analysis
Allow User Input: Yes
Business Purpose: Sales Qualification

Profile Access:
  - Sales User
  - Sales Manager
  - System Administrator
```

### 6.3 Output Format
Structured report including:
1. Overall MEDDIC Score (0-100)
2. Element-by-element analysis with scores
3. Stage alignment assessment
4. Risk summary (Critical/Warning/Positive)
5. Priority actions (3-5 items)
6. Stage advancement readiness

---

## 7. Success Criteria

### 7.1 Acceptance Criteria
- [ ] All 6 MEDDIC elements scored accurately
- [ ] Stage alignment validation working for all stages
- [ ] Critical risks identified correctly in test scenarios
- [ ] Recommendations are specific and actionable
- [ ] Output format is consistent and readable

### 7.2 Test Scenarios
1. **Well-Qualified Opportunity**: Score 80+, few risks
2. **Under-Qualified Opportunity**: Score 40, multiple critical risks
3. **Stalled Deal**: Activity warnings, re-engagement recommendations
4. **New Opportunity**: Appropriate for early stage, no false negatives

---

## 8. Implementation Phases

### Phase 1: Discovery & Setup
- SFDX project configuration
- Org connection and metadata retrieval
- ClosePlan (TSPC) object analysis
- Opportunity field mapping

### Phase 2: Data Analysis
- Sample opportunity data analysis
- MEDDIC field completion assessment
- Activity pattern analysis
- Win/Loss correlation study

### Phase 3: GPTfy Configuration
- Data Context Mapping setup
- Prompt development and testing
- Scoring algorithm validation
- Output format refinement

### Phase 4: Testing & Validation
- Test with 20-30 real opportunities
- Sales manager validation
- Prompt tuning based on feedback
- Edge case handling

### Phase 5: Rollout
- User training materials
- Gradual rollout by team
- Feedback collection
- Continuous improvement

---

## 9. Appendices

### 9.1 MEDDIC Element Weights
| Element | Weight | Justification |
|---------|--------|---------------|
| Metrics | 15% | Critical for value proposition |
| Economic Buyer | 20% | Deals don't close without EB |
| Decision Criteria | 15% | Technical/business fit essential |
| Decision Process | 15% | Understanding process prevents surprises |
| Identify Pain | 15% | No pain, no change |
| Champion | 20% | Champion drives deal forward |

### 9.2 Org-Specific Findings (pocgptfy Sandbox)

**Installed Packages**:
- ClosePlan (TSPC) - Primary MEDDIC implementation
- Salesforce CPQ (SBQQ) - Quote/pricing data
- Aircall CTI - Call tracking
- Twilio - Communication tracking
- Klue - Competitive intelligence
- Pardot - Marketing automation
- DocuSign - Contract signing
- Copado - DevOps

**Opportunity Record Types**:
- Operations Opportunity
- Pilot
- Single Site
- Deployment/Rollout
- Partner Forecast
- Memory

**Opportunity Stages**:
- New
- Interest
- Analysis in progress
- Quote Sent
- Budget approved
- Commitment for needs
- Verbal agreement / Letter of intent
- Framework contract
- Quote Signed
- Order Signed
- Closed/Won/Lost/Abandoned

**MEDDIC-Related Custom Fields on Opportunity**:
- `TSPC__CPDeal__c` - ClosePlan reference
- `Overall_Score__c` - Overall score
- `Stage_Requirements_Met_Score__c`
- `Data_Quality_Score__c`
- `Stakeholder_Engagement_Score__c`
- `Competitive_Positioning_Score__c`
- `Risk_Mitigation_Score__c`
- `Next_Stage_Preparedness_Score__c`
- `Competitor__c` - Multi-select picklist
- `WinningCompetitor__c` - Picklist
- `Loss_details__c` / `Reason_for_loss__c`

---

*Document Version: 1.0*
*Last Updated: 2025-12-25*

# ANALYTICAL PATTERNS - EXTRACTED FROM PRODUCTION PROMPTS

**Date**: January 22, 2026  
**Source**: 10 Salesforce AI prompts (9 pre-packaged + 1 MEDDIC sample)  
**Purpose**: Reusable instruction blocks for prompt assembly

---

## PATTERN 1: Risk Assessment & Identification

**Pattern ID**: `risk_assessment`  
**Category**: Risk Analysis  
**Frequency**: Used in 3 prompts (Account 360, MEDDIC, Case Intent)  
**Complexity**: Medium

### Instruction Block

```
RISK IDENTIFICATION:

Analyze the provided data and identify risks across three severity levels:

CRITICAL RISKS (RED FLAGS) ⛔:
- [Trigger conditions for critical risks]
- No Champion AND Stage >= [Threshold]
- No key stakeholder engagement
- Single-threaded execution
- Overdue items with HIGH priority
- Missing required data for current stage

WARNING RISKS (YELLOW) ⚠️:
- [Trigger conditions for warning risks]
- Key stakeholder with neutral disposition
- Missing recommended but not required elements
- Timeline concerns (pushed dates, approaching deadline)
- Moderate gaps in process or documentation

POSITIVE INDICATORS (GREEN) ✅:
- [Trigger conditions for positive signals]
- Strong stakeholder engagement
- All required elements present and validated
- Active progress with recent momentum
- Multi-threaded engagement

For each identified risk:
- Evidence: Cite specific field values
- Impact: What could happen if not addressed
- Mitigation: Specific action to take
- Priority: CRITICAL / HIGH / MEDIUM
- Timeline: When to address (7/14/30 days)
```

### Trigger Conditions
- Any analysis requiring risk evaluation
- Deal/opportunity health assessment
- Case escalation analysis
- Stakeholder engagement review
- Timeline/deadline tracking

### Evidence Requirements
- Stage/Status fields
- Date fields (created, modified, due, close)
- Stakeholder/contact engagement data
- Activity history (last contact date, frequency)
- Required vs. actual data completeness

### Output Format
- Hierarchical bullets (Critical → Warning → Positive)
- Color-coded indicators (RED/YELLOW/GREEN)
- Evidence citation for each risk
- Actionable mitigation steps

### Used In
- Account 360 View - Reimagined (customer frustration, urgent cases)
- MEDDIC Compliance Analyzer (deal risks, stage alignment)
- Case Intent Analysis (escalation signals)

---

## PATTERN 2: Sentiment Analysis

**Pattern ID**: `sentiment_analysis`  
**Category**: Sentiment/Tone Analysis  
**Frequency**: Used in 3 prompts (Account 360, Case analysis)  
**Complexity**: Medium

### Instruction Block

```
SENTIMENT ANALYSIS:

Analyze the tone, language, and context of provided text data (descriptions, comments, emails, notes) and classify sentiment into one of three categories:

POSITIVE Sentiment 😊:
- Appreciative language, satisfaction indicators
- Resolution acknowledgment, praise
- Proactive engagement, enthusiasm
- Example keywords: "thank you", "great", "helpful", "resolved"

NEUTRAL Sentiment 😐:
- Factual statements without emotional indicators
- Status updates, procedural communication
- Information requests without urgency
- Example keywords: "update", "status", "request", "information"

NEGATIVE Sentiment 😞:
- Frustration, dissatisfaction, urgency
- Escalation language, complaints
- Repeated issues, unresolved concerns
- Example keywords: "urgent", "frustrated", "unacceptable", "still waiting"

CRITICAL: Each record MUST be classified as Positive, Neutral, or Negative. 
No records should be left unclassified.

SENTIMENT DISTRIBUTION:
Count and report:
- Positive: [Count]
- Neutral: [Count]
- Negative: [Count]
- TOTAL MUST equal number of records analyzed
```

### Trigger Conditions
- Case analysis
- Customer feedback review
- Account health assessment
- Communication tone evaluation
- Escalation detection

### Evidence Requirements
- Description/Subject fields
- Comment history
- Email content
- Note content
- Status/Priority fields (context)

### Output Format
- Three-category classification
- Count distribution (Pos/Neu/Neg)
- Inline sentiment indicators in tables
- Color-coded sentiment labels

### Used In
- Account 360 View - Reimagined (case sentiment distribution)
- Case Follow-up / Feedback Email (tone adjustment based on status)
- Case Intent Analysis (sentiment as context for intent)

---

## PATTERN 3: Next Best Action Generation

**Pattern ID**: `next_best_action`  
**Category**: Recommendation/Action  
**Frequency**: Used in 4 prompts (Account 360, Case Intent, MEDDIC)  
**Complexity**: High

### Instruction Block

```
NEXT BEST ACTION GENERATION:

Based on the current state, gaps, and risks identified, generate specific, actionable recommendations.

REQUIREMENTS:
- Specific: Use names, dates, systems (not "stakeholder" but "CFO Sarah Johnson")
- Actionable: Clear verb (Schedule, Prepare, Follow up, Validate, etc.)
- Bounded: Include timeline or constraint (within 7 days, before CFO meeting, etc.)
- Evidence-based: Reference specific data that triggered the recommendation
- Prioritized: Order by impact and urgency

FORMAT for each action:
**Action**: [Specific task with who/what/when]  
**Why**: [Evidence from data that triggered this]  
**Impact**: [What improves if completed]  
**Priority**: CRITICAL / HIGH / MEDIUM  
**Owner**: [Role responsible - AE, SE, CSM, Manager]  
**Deadline**: [Specific date or timeframe]  
**Success Criteria**: [How to validate completion]

EXAMPLE:
**Action**: Schedule follow-up call with Sarah Johnson (CFO) by Friday to present ROI analysis  
**Why**: Task "Send ROI Analysis to CFO" is 7 days overdue (Evidence: Task.ActivityDate = 01/15/2026, Task.Status = 'Not Started', TODAY = 01/22/2026)  
**Impact**: Addresses MEDDIC Metrics gap, keeps deal momentum  
**Priority**: CRITICAL  
**Owner**: Account Executive  
**Deadline**: January 24, 2026 (within 48 hours)  
**Success Criteria**: Meeting scheduled, ROI deck prepared, CFO confirms attendance

FORBIDDEN:
- Generic actions ("follow up with stakeholders")
- Actions without evidence ("consider reaching out")
- Vague timelines ("soon", "when possible")
```

### Trigger Conditions
- Any gap or risk identified
- Incomplete MEDDIC elements
- Overdue tasks or missed milestones
- Stakeholder engagement gaps
- Case resolution required

### Evidence Requirements
- Current state data (stage, status, scores)
- Gap analysis results
- Stakeholder data
- Activity history
- Timeline/deadline data

### Output Format
- Structured action items (7-field format)
- Prioritized list (CRITICAL first)
- Limited to 3-5 actions (most impactful)
- Each action <30 words

### Used In
- Account 360 View - Reimagined (top next best action)
- Case Intent Analysis (next best action for case)
- MEDDIC Compliance Analyzer (priority actions per MEDDIC element)
- Opportunity Insights (recommended next steps)

---

## PATTERN 4: Stakeholder Gap Analysis

**Pattern ID**: `stakeholder_gap_analysis`  
**Category**: Stakeholder/People Analysis  
**Frequency**: Used in 2 prompts (MEDDIC, Account 360)  
**Complexity**: High

### Instruction Block

```
STAKEHOLDER GAP ANALYSIS:

Evaluate stakeholder coverage and engagement against requirements for the current stage/context.

STEP 1: MAP EXISTING STAKEHOLDERS
Create stakeholder matrix:
| Name | Role | Title | Support | Influence | Engagement | Power | Personal Win |
|------|------|-------|---------|-----------|------------|-------|--------------|
| [Data from OpportunityContactRole, DealStakeholder, Contact] |

STEP 2: IDENTIFY REQUIRED ROLES
Based on [Stage / Deal Size / Industry], identify required stakeholder roles:
- Economic Buyer (Budget Authority)
- Champion (Internal Advocate)
- Technical Buyer (Solution Evaluator)
- Decision Maker (Final Approver)
- Influencers (Key Contributors)
- Legal/Procurement (if >$XXX deal size)
- [Industry-specific roles]

STEP 3: GAP IDENTIFICATION
Compare mapped vs. required:

MISSING ROLES:
- [Role]: Not identified
  Impact: [What's at risk without this role]
  Action: [How to identify/engage]

INSUFFICIENT ENGAGEMENT:
- [Name] ([Role]): Mapped but [Limited Contact / No Contact / Neutral disposition]
  Impact: [Risk of insufficient influence]
  Action: [How to strengthen relationship]

NEGATIVE DISPOSITION:
- [Name] ([Role]): [Resistor / Detractor] status
  Impact: [Active risk to deal]
  Action: [How to mitigate or neutralize]

STEP 4: COVERAGE ASSESSMENT
- Single-threaded: Only 1 contact engaged (HIGH RISK)
- Two-threaded: 2 contacts engaged (MEDIUM RISK)
- Multi-threaded: 3+ contacts engaged (STRONG)
- Champion validated: Has power + Promoter/Supporter + Regular engagement + Personal Win documented
- Economic Buyer engaged: Direct relationship + Supportive disposition
```

### Trigger Conditions
- Deal stage advancement review
- MEDDIC Champion/Economic Buyer assessment
- Account health check
- Relationship risk evaluation
- Large deal governance review

### Evidence Requirements
- OpportunityContactRole records
- Contact data (Name, Title, Email)
- DealStakeholder data (Role, SupportStatus, Relationship, HasPower, Goal)
- Activity history with contacts
- Deal size, stage, industry context

### Output Format
- Stakeholder matrix table
- Gap list (Missing / Insufficient / Negative)
- Coverage assessment (Single/Multi-threaded)
- Role-specific validation (Champion criteria)

### Used In
- MEDDIC Compliance Analyzer (Champion & Economic Buyer elements, stakeholder map)
- Account 360 (implied in opportunity summaries)

---

## PATTERN 5: MEDDIC Scoring Framework

**Pattern ID**: `meddic_scoring`  
**Category**: Sales Methodology/Framework  
**Frequency**: Used in 1 prompt (MEDDIC) but comprehensive  
**Complexity**: Very High

### Instruction Block

```
MEDDIC COMPLIANCE SCORING:

Evaluate each of the 6 MEDDIC elements on a 0-100 scale with defined criteria.

## M - METRICS (Weight: 15%)
Evaluate business case and quantified value:

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No metrics documented |
| 26-50 | Generic/unvalidated metrics mentioned |
| 51-75 | Specific metrics with customer input |
| 76-100 | Quantified, customer-validated metrics with business case |

Data Sources: Description, ROI calculations, DealQuestion.Text where category = Metrics

## E - ECONOMIC BUYER (Weight: 20%)
Assess Economic Buyer identification and engagement:

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No EB identified |
| 26-50 | EB identified but no engagement (Neutral or no relationship) |
| 51-75 | EB met once or indirect access via Champion |
| 76-100 | Direct EB relationship (Regular Cadence/In Depth) with Supporter/Promoter status |

Data Sources: DealStakeholder.Role = 'Economic Buyer', DealStakeholder.HasPower, DealStakeholder.SupportStatus

## D - DECISION CRITERIA (Weight: 15%)
Evaluate technical and business criteria documentation:

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No criteria documented |
| 26-50 | Some criteria listed but not validated |
| 51-75 | Criteria documented with customer confirmation |
| 76-100 | All criteria mapped with capability match and competitive positioning |

Data Sources: DealQuestion.Text where category = Criteria, Technical Buyer engagement

## D - DECISION PROCESS (Weight: 15%)
Assess understanding of buying decision process:

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No process documented |
| 26-50 | Generic understanding of process |
| 51-75 | Steps and timeline documented with some mutual events |
| 76-100 | Full process mapped with owners, dates, mutual milestones, and paper process |

Data Sources: Event records (mutual action plan), DealQuestion.Text where category = Process

## I - IDENTIFY PAIN (Weight: 15%)
Evaluate documented business pains and validation:

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No pain documented |
| 26-50 | Generic industry pain assumed |
| 51-75 | Specific pain points with business context |
| 76-100 | Quantified pain with clear business impact and urgency |

Data Sources: Description field, DealQuestion.Text where category = Pain, DealStakeholder.Goal

## C - CHAMPION (Weight: 20%)
Assess Champion identification, validation, and engagement:

Champion Validation Checklist:
1. Has Power: DealStakeholder.HasPower = true
2. Support Status: DealStakeholder.SupportStatus = Promoter or Supporter
3. Relationship: DealStakeholder.Relationship = Regular Cadence or In Depth
4. Personal Win: DealStakeholder.Goal documented

Scoring Criteria:
| Score | Criteria |
|-------|----------|
| 0-25 | No champion identified |
| 26-50 | Friendly contact but lacks power or neutral disposition |
| 51-75 | Champion identified with influence but missing personal win |
| 76-100 | Validated champion with power, promoter status, regular engagement, and documented personal win |

Data Sources: DealStakeholder.Role = 'Champion', validation checklist above

## OVERALL MEDDIC SCORE CALCULATION
Weighted average:
- M (Metrics): Score × 0.15
- E (Economic Buyer): Score × 0.20
- D (Decision Criteria): Score × 0.15
- D (Decision Process): Score × 0.15
- I (Identify Pain): Score × 0.15
- C (Champion): Score × 0.20
- **TOTAL: Sum of weighted scores (0-100)**

## STAGE-MEDDIC ALIGNMENT
Compare score to stage requirements:

| Stage | Min MEDDIC Score | Key Requirements |
|-------|------------------|------------------|
| New/Interest | 35 | Pain confirmed, Champion identified |
| Analysis in progress | 50 | Pain documented, Champion validated, EB identified |
| Proposal sent | 65 | EB engaged, Criteria confirmed, Process mapped |
| Budget approved | 75 | Metrics validated, All criteria addressed |
| Verbal agreement | 85 | EB committed, All elements evidenced |
| Quote Signed | 90 | Full MEDDIC validation complete |

Assessment:
- APPROPRIATE: Score meets stage minimum
- UNDERSTATED: Score too high for stage (deal may be at risk)
- OVERSTATED: Score too low for stage (premature advancement)
```

### Trigger Conditions
- Opportunity analysis for deals using MEDDIC methodology
- Deal health assessment
- Stage advancement readiness check
- Sales qualification review
- Forecast accuracy validation

### Evidence Requirements
- Opportunity fields (Stage, Amount, CloseDate, Description, NextStep)
- DealStakeholder records (Role, SupportStatus, HasPower, Relationship, Goal)
- DealQuestion records (Text, Answer, Score, Category)
- Event records (mutual action plan milestones)
- OpportunityContactRole records
- Activity history

### Output Format
- Structured table (6 elements × 4 columns: Element, Score, Status, Evidence, Gap)
- Weighted overall score calculation
- Stage alignment assessment
- Color-coded status (GREEN/YELLOW/RED)

### Used In
- MEDDIC Compliance Analyzer (primary framework)
- Can be adapted for other deal qualification frameworks (BANT, CHAMP, etc.)

---

## PATTERN 6: Intent Analysis

**Pattern ID**: `intent_analysis`  
**Category**: Communication/Purpose Analysis  
**Frequency**: Used in 2 prompts (Case Intent, Root Cause)  
**Complexity**: Medium

### Instruction Block

```
INTENT ANALYSIS:

Analyze the underlying purpose, goal, or motivation behind a customer interaction (case, email, call, task).

ANALYSIS FRAMEWORK:

1. PRIMARY INTENT (select one):
   - Information Seeking: Customer wants to understand how something works
   - Problem Resolution: Customer needs a specific issue fixed
   - Feature Request: Customer wants new capability or enhancement
   - Complaint/Escalation: Customer is dissatisfied and wants attention
   - Feedback: Customer wants to share opinion (positive or negative)
   - Transactional: Customer needs to complete a specific action (update, configure, etc.)

2. SUPPORTING EVIDENCE:
   - Keywords/phrases that indicate intent
   - Tone indicators (urgent language, appreciative language, neutral language)
   - Context clues (status, priority, subject line)

3. CUSTOMER GOAL:
   - What does the customer want to achieve?
   - What outcome would satisfy them?
   - What's the underlying need? (beyond surface request)

4. BUSINESS IMPACT:
   - If not addressed, what happens?
   - Is this blocking customer usage/adoption?
   - Is this affecting customer satisfaction/retention?

FORMAT:
**Intent**: [Primary intent category]  
**Evidence**: [Specific phrases, keywords, context from data]  
**Customer Goal**: [What they want to achieve - one sentence]  
**Business Impact**: [Risk if not addressed - one sentence]  
**Recommended Response**: [How to address this intent]

CONSTRAINTS:
- Limit to under 90 words total
- Base analysis ONLY on provided data (do not imagine)
- If data is insufficient, state "Intent unclear from available data"
```

### Trigger Conditions
- Case creation or assignment
- Email/communication analysis
- Customer feedback review
- Escalation routing
- Support prioritization

### Evidence Requirements
- Case.Subject or Task.Subject
- Case.Description or Task.Description
- Case.Status, Case.Priority
- Email.TextBody or Comment content
- Related activity history

### Output Format
- Structured 4-field summary (Intent/Evidence/Goal/Impact)
- <90 words total
- JSON format option for parsing

### Used In
- Case Intent Analysis (primary use case)
- Case Root Cause Analysis (implied for understanding underlying issue)

---

## PATTERN 7: Root Cause Analysis

**Pattern ID**: `root_cause_analysis`  
**Category**: Problem Analysis  
**Frequency**: Used in 1 prompt (Case Root Cause)  
**Complexity**: High

### Instruction Block

```
ROOT CAUSE ANALYSIS:

Identify the underlying reason for a problem or issue, not just the symptoms.

ANALYSIS STEPS:

1. SYMPTOM IDENTIFICATION:
   - What is the customer reporting? (surface problem)
   - What specific errors, behaviors, or issues are described?
   - Evidence: [Cite from Description, Comments, Email]

2. CONTRIBUTING FACTORS:
   - What conditions or circumstances led to this symptom?
   - Are there related issues or patterns in history?
   - Evidence: [Cite from related Cases, Tasks, Activity history]

3. ROOT CAUSE:
   - What is the fundamental reason this occurred?
   - Why did the contributing factors exist?
   - Apply "5 Whys" technique if helpful
   - Evidence: [Data-based determination, not assumption]

4. CORRECTIVE ACTION:
   - What specific action will address the root cause (not just symptom)?
   - Who is responsible for implementing?
   - Timeline for resolution?
   - How to verify the root cause is addressed?

FORMAT:
**Symptom**: [Customer-reported problem]  
**Contributing Factors**: [Conditions that led to symptom]  
**Root Cause**: [Fundamental underlying reason]  
**Corrective Action**: [Specific fix to address root cause]

CONSTRAINTS:
- Limit each section to under 90 words
- Do NOT imagine or assume - base on provided information
- If root cause cannot be determined from data, state "Insufficient data to determine root cause. Recommend: [investigation steps]"
- Corrective action must be specific and actionable
```

### Trigger Conditions
- Case analysis for complex or recurring issues
- Post-incident review
- Quality improvement initiatives
- Pattern identification across multiple cases
- Escalated cases requiring deep analysis

### Evidence Requirements
- Case.Description (problem statement)
- Case.Comments (detailed investigation notes)
- Related Case history (similar issues)
- Activity history (troubleshooting steps taken)
- System data (error logs if available via notes)

### Output Format
- Structured 4-section narrative (Symptom/Factors/RootCause/Corrective)
- Each section <90 words
- Actionable corrective action with owner and timeline

### Used In
- Case Root Cause Analysis (primary use case)
- Can be applied to opportunity loss analysis
- Can be applied to quality issue investigation

---

## PATTERN 8: Executive Summary

**Pattern ID**: `executive_summary`  
**Category**: Summary/Overview  
**Frequency**: Used in 3 prompts (Account 360, MEDDIC)  
**Complexity**: Medium

### Instruction Block

```
EXECUTIVE SUMMARY:

Provide a concise, high-level overview that a busy executive can scan in 30 seconds.

REQUIREMENTS:
- 2-3 sentences maximum (or 3-5 bullet points)
- Focus on most critical information (risks, opportunities, decisions needed)
- Use plain English (no jargon)
- Quantify where possible (numbers, percentages, dollar amounts)
- Highlight what's CHANGED or URGENT
- Include recommended action if appropriate

STRUCTURE OPTIONS:

Option A - Narrative (2-3 sentences):
[Current State]. [Key Risk or Opportunity]. [Recommended Action].

Example:
"UnitedHealthcare deal at $220K is in Proposal stage with 75% probability. Critical gap: No Champion identified and CFO meeting in 5 days without ROI analysis prepared. Immediate action: Identify internal advocate and complete ROI deck by Friday."

Option B - Bullet Points (3-5 max):
- **Current State**: [Stage, value, probability, key dates]
- **Key Risk**: [Most critical issue]
- **Opportunity**: [Most valuable upside if addressed]
- **Recommended Action**: [Specific next step with timeline]

FORBIDDEN:
- Generic statements ("deal is progressing well")
- Jargon or acronyms without explanation
- Long paragraphs or extensive detail
- Multiple unrelated points (pick the 1-2 most important)
```

### Trigger Conditions
- Any comprehensive analysis requiring a summary
- Account 360 views
- Deal health assessments
- Executive reporting
- Dashboard top-line insights

### Evidence Requirements
- All data from the full analysis
- Ability to prioritize and synthesize
- Identification of most critical 1-2 points

### Output Format
- 2-3 sentences OR 3-5 bullets
- <100 words total
- Placed at TOP of output (before detailed sections)
- Clear formatting (bold for emphasis, numbers prominent)

### Used In
- Account 360 View - Reimagined (executive summary card)
- MEDDIC Compliance Analyzer (executive summary section)
- Opportunity Insights (summary at top)

---

## PATTERN 9: Metrics Calculation & Aggregation

**Pattern ID**: `metrics_calculation`  
**Category**: Quantitative Analysis  
**Frequency**: Used in 4 prompts (Account 360, MEDDIC)  
**Complexity**: Medium

### Instruction Block

```
METRICS CALCULATION & AGGREGATION:

Calculate quantitative metrics from provided data to support analysis and insights.

CALCULATION TYPES:

1. COUNTS:
   - Total records matching criteria
   - Count by category/status/type
   - Example: Total Open Opportunities = COUNT(WHERE IsClosed = false)

2. SUMS:
   - Total value across records
   - Example: Total Opportunity Value = SUM(Amount) for all opportunities

3. AVERAGES:
   - Mean value across records
   - Example: Average Deal Size = SUM(Amount) / COUNT(Opportunities)

4. DATE CALCULATIONS:
   - Days between dates
   - Days since/until event
   - Example: Days Open = TODAY() - CreatedDate

5. CONDITIONAL AGGREGATION:
   - Count/sum based on multiple criteria
   - Example: High Priority Open Cases = COUNT(WHERE IsClosed = false AND Priority = 'High')

6. DISTRIBUTIONS:
   - Breakdown by category
   - Example: Sentiment Distribution: Positive (5), Neutral (3), Negative (2)

REQUIREMENTS:
- Use EXACT data from provided records (no estimation)
- Show calculation formula if complex
- Include ALL records (no filtering unless explicitly required)
- Verify totals match source data count
- Use appropriate precision (currency to 2 decimals, percentages to nearest whole number)

CRITICAL VERIFICATION:
Before finalizing output:
1. Count records in source data
2. Verify count matches sum of all categories (e.g., Positive + Neutral + Negative = Total Cases)
3. Verify SUM calculations include ALL records (not just subset)
4. Check for NULL/missing values and handle appropriately (usually count as 0 for sums)

FORMAT:
**Metric Name**: [Value]  
**Calculation**: [Formula if not obvious]  
**Source**: [Fields used]

Example:
**Total Opportunity Value**: $1,450,000  
**Calculation**: SUM(Opportunity.Amount) for all opportunities regardless of stage  
**Source**: 5 opportunities (2 open, 3 closed)
```

### Trigger Conditions
- Dashboards and scorecards
- Account 360 views
- Performance reporting
- Health score calculations
- Trend analysis

### Evidence Requirements
- Numeric fields (Amount, Count, Score, etc.)
- Date fields for calculations
- Status/Category fields for filtering
- All records in scope (no missing data)

### Output Format
- Numeric values with appropriate units ($, %, days, count)
- Calculation transparency (show formula if not obvious)
- Verification notes if counts should match
- Inline in text or as stat cards/metrics tiles

### Used In
- Account 360 View - Reimagined (total open opportunities, total value, sentiment distribution, days open)
- MEDDIC Compliance Analyzer (MEDDIC score calculation, weighted averages)
- Case analysis (days open calculation)
- Opportunity summaries (deal size, probability)

---

## PATTERN 10: Timeline & Progression Analysis

**Pattern ID**: `timeline_analysis`  
**Category**: Temporal/Progress Analysis  
**Frequency**: Used in 3 prompts (MEDDIC, Account 360)  
**Complexity**: Medium

### Instruction Block

```
TIMELINE & PROGRESSION ANALYSIS:

Analyze temporal patterns, progression velocity, and time-based risks.

ANALYSIS DIMENSIONS:

1. CURRENT STATUS vs. TIMELINE:
   - Current stage/status
   - Expected completion date vs. TODAY()
   - Time remaining or time overdue
   - Evidence: [Stage, CloseDate, DueDate, ActivityDate, TODAY()]

2. PROGRESSION VELOCITY:
   - Time in current stage (TODAY() - LastStageChangeDate)
   - Historical stage duration (if available)
   - Expected vs. actual velocity
   - Evidence: [StageName, LastStageChangeDate, stage history]

3. OVERDUE ITEMS:
   - Tasks/Events past due date
   - Days overdue calculation
   - Priority of overdue items
   - Evidence: [Task.ActivityDate < TODAY(), Task.Status != 'Completed', Task.Priority]

4. UPCOMING MILESTONES:
   - Next scheduled events/tasks
   - Days until milestone
   - Readiness assessment
   - Evidence: [Event.StartDate, Task.ActivityDate where > TODAY()]

5. ACTIVITY MOMENTUM:
   - Recent activity frequency (last 7/14/30 days)
   - Activity gaps (no activity > X days)
   - Activity trend (increasing/decreasing/stable)
   - Evidence: [Activity.ActivityDate, Task.CreatedDate, Event.CreatedDate]

6. TIME-BASED RISKS:
   - Deadline pressure (close date approaching with low readiness)
   - Stagnation risk (no progress in X days)
   - Timeline slippage (dates pushed multiple times)
   - Evidence: [Date comparisons, history if available]

FORMAT for each finding:
**Timeline Item**: [What's being analyzed]  
**Status**: [On Track / At Risk / Overdue / Upcoming]  
**Evidence**: [Dates, calculations, field values]  
**Risk/Opportunity**: [What this means]  
**Action**: [Specific step to take if At Risk or Overdue]

EXAMPLE:
**Timeline Item**: Overdue Task - Send ROI Analysis to CFO  
**Status**: OVERDUE by 7 days  
**Evidence**: Task.Subject = 'Send ROI Analysis to CFO', Task.ActivityDate = 01/15/2026, Task.Status = 'Not Started', Task.Priority = 'High', TODAY = 01/22/2026  
**Risk**: CFO meeting on 01/27/2026 without completed ROI analysis risks deal stall  
**Action**: Complete and send ROI analysis within 48 hours (by 01/24/2026)
```

### Trigger Conditions
- Deal/case progression reviews
- Activity health checks
- Deadline management
- Velocity tracking
- Risk identification based on time

### Evidence Requirements
- Date fields (Created, Modified, Due, Activity, Close, Start, End)
- Status fields (to determine if items are complete)
- Priority fields (to assess urgency of overdue items)
- Stage/Status fields (for progression analysis)
- Activity records (for momentum analysis)

### Output Format
- Structured findings (Item/Status/Evidence/Risk/Action)
- Date calculations (days between, days until, days since)
- Visual indicators (⏰ OVERDUE, ⏳ UPCOMING, ✅ ON TRACK)
- Prioritized by risk (overdue first, then at-risk, then on-track)

### Used In
- MEDDIC Compliance Analyzer (stage progression, mutual action plan timeline)
- Account 360 View (days open for cases, overdue tasks)
- Opportunity Insights (close date assessment, deal velocity)

---

## SUMMARY: PATTERN APPLICABILITY MATRIX

| Pattern | Opportunity | Account | Case | Task/Activity |
|---------|-------------|---------|------|---------------|
| Risk Assessment | ✅ High | ✅ High | ✅ Medium | ✅ Low |
| Sentiment Analysis | ❌ | ✅ Low | ✅ High | ❌ |
| Next Best Action | ✅ High | ✅ High | ✅ High | ✅ Medium |
| Stakeholder Gap Analysis | ✅ High | ✅ Medium | ❌ | ❌ |
| MEDDIC Scoring | ✅ Very High | ❌ | ❌ | ❌ |
| Intent Analysis | ❌ | ❌ | ✅ High | ✅ Medium |
| Root Cause Analysis | ✅ Low | ❌ | ✅ High | ❌ |
| Executive Summary | ✅ High | ✅ High | ✅ Medium | ❌ |
| Metrics Calculation | ✅ High | ✅ High | ✅ High | ✅ High |
| Timeline Analysis | ✅ High | ✅ Medium | ✅ High | ✅ High |

---

## PATTERN COMBINATION RECOMMENDATIONS

### For Opportunity Analysis:
**Required**: Risk Assessment, Next Best Action, Metrics Calculation, Timeline Analysis  
**Recommended**: Executive Summary, Stakeholder Gap Analysis  
**Optional**: MEDDIC Scoring (if methodology used)

### For Account 360 View:
**Required**: Executive Summary, Metrics Calculation, Risk Assessment  
**Recommended**: Sentiment Analysis (for cases), Next Best Action  
**Optional**: Timeline Analysis, Stakeholder Gap Analysis

### For Case Analysis:
**Required**: Intent Analysis, Sentiment Analysis, Next Best Action  
**Recommended**: Timeline Analysis (days open, overdue items), Metrics Calculation  
**Optional**: Root Cause Analysis (for complex/recurring issues)

### For Deal Health/Forecast Review:
**Required**: Risk Assessment, Stakeholder Gap Analysis, Timeline Analysis, Metrics Calculation  
**Recommended**: MEDDIC Scoring (if applicable), Executive Summary  
**Optional**: Next Best Action

---

**End of Analytical Patterns Library**  
**Total Patterns Extracted**: 10  
**Ready for Phase 1 Implementation**: ✅

# Next Best Action Pattern

**Version**: 1.0  
**Purpose**: Provide specific, actionable recommendations with clear owners and deadlines  
**Category**: Pattern  
**Source**: Phase 0B Variant 16 (scored 69/100)  

---

## Core Principle

> **Generic advice is worthless. Specific actions with clear accountability drive results.**

Every recommendation must answer: WHO does WHAT by WHEN and WHY?

---

## Pattern Structure

Based on the current state, gaps, and risks identified, generate specific, actionable recommendations.

### REQUIREMENTS

**Specific**: Use actual names, dates, and systems
- ✅ "Schedule call with Sarah Johnson (CFO) by Friday"
- ❌ "Follow up with stakeholder"

**Actionable**: Clear verb that indicates what to do
- ✅ "Schedule", "Prepare", "Send", "Validate", "Confirm"
- ❌ "Consider", "Think about", "Maybe"

**Bounded**: Include timeline or constraint
- ✅ "by Friday, January 24"
- ✅ "within 48 hours"
- ✅ "before CFO meeting on Jan 28"
- ❌ "soon", "when possible", "eventually"

**Evidence-based**: Reference specific data that triggered this recommendation
- ✅ "Task 'Send ROI' is 7 days overdue"
- ❌ "Follow-up needed"

**Prioritized**: Order by impact and urgency
- ✅ CRITICAL > HIGH > MEDIUM
- ✅ Most impactful actions first

---

## Action Format

For each recommended action, provide:

```
**Action**: [Specific task with who/what/when]  
**Why**: [Evidence from data that triggered this]  
**Impact**: [What improves if completed]  
**Priority**: CRITICAL / HIGH / MEDIUM  
**Owner**: [Role responsible - AE, SE, CSM, Manager]  
**Deadline**: [Specific date or timeframe]  
**Success Criteria**: [How to validate completion]
```

---

## Examples

### GOOD Example - Specific Action

```
**Action**: Schedule follow-up call with Sarah Johnson (CFO) by Friday to present ROI analysis  
**Why**: Task "Send ROI Analysis to CFO" is 7 days overdue (Evidence: Task.ActivityDate = 01/15/2026, Task.Status = 'Not Started', TODAY = 01/22/2026)  
**Impact**: Addresses MEDDIC Metrics gap, keeps deal momentum, unblocks budget approval  
**Priority**: CRITICAL  
**Owner**: Account Executive  
**Deadline**: January 24, 2026 (within 48 hours)  
**Success Criteria**: Meeting scheduled, ROI deck prepared, CFO confirms attendance
```

### GOOD Example - Technical Action

```
**Action**: Send technical architecture diagram to Robert Taylor (VP Operations) and schedule validation meeting  
**Why**: Technical Decision Criteria not validated (MEDDIC gap), champion requested technical details 14 days ago  
**Impact**: Moves deal from Qualification to Proposal stage, addresses technical objections early  
**Priority**: HIGH  
**Owner**: Solutions Engineer  
**Deadline**: January 26, 2026 (before executive review)  
**Success Criteria**: Document sent, meeting scheduled within 3 business days, technical champion identified
```

### GOOD Example - Stakeholder Action

```
**Action**: Identify and engage economic buyer (CFO/VP Finance) through Lisa Martinez (Champion)  
**Why**: No contact with Economic Buyer role identified (MEDDIC gap), deal at $1.5M requires executive approval  
**Impact**: Critical for budget approval, de-risks deal from stalling in late stage  
**Priority**: CRITICAL  
**Owner**: Account Executive  
**Deadline**: Within 7 days (before end of January)  
**Success Criteria**: Economic buyer identified, intro meeting scheduled, budget authority confirmed
```

---

## Bad Examples (FORBIDDEN)

### ❌ Generic Action
```
**Action**: Follow up with stakeholders
**Why**: Need to maintain momentum
**Priority**: HIGH
```

**Problems:**
- Who are "stakeholders"? Which specific people?
- What exactly should be done in the follow-up?
- When? "Maintain momentum" is not evidence
- No deadline, no success criteria

---

### ❌ Vague Action
```
**Action**: Consider reaching out about budget
**Why**: Budget might be an issue
**Priority**: MEDIUM
```

**Problems:**
- "Consider" is not actionable
- "Reaching out" is vague—call? email? meeting?
- "Might be" is speculation, not evidence
- No specific person, no deadline

---

### ❌ Action Without Evidence
```
**Action**: Send proposal soon
**Priority**: HIGH
```

**Problems:**
- What triggered this? No evidence cited
- "Soon" is not a deadline
- No owner, no success criteria
- Why is this high priority?

---

## Action Types & Patterns

### 1. **Overdue Task Recovery**

**Pattern:**
```
Complete [TaskName] immediately - now [X] days overdue and blocking [Outcome]
Contact [PersonName] ([Role]) by [Date] to [Action]
```

**Example:**
```
Complete ROI analysis immediately - now 7 days overdue and blocking CFO budget approval
Contact Sarah Johnson (CFO) by Friday to schedule presentation
```

---

### 2. **MEDDIC Gap Resolution**

**Pattern:**
```
Identify [MEDDIC Element] through [Champion Name]
Validate [Element] with [PersonName] ([Role]) by [Date]
```

**Example:**
```
Identify Economic Buyer through Lisa Martinez (Champion)
Validate Decision Criteria with Robert Taylor (VP Ops) by Jan 28
```

---

### 3. **Stakeholder Engagement**

**Pattern:**
```
Re-engage [PersonName] ([Role]) - no contact in [X] days
Schedule [MeetingType] with [PersonName] by [Date] to [Purpose]
```

**Example:**
```
Re-engage Lisa Martinez (Champion) - no contact in 14 days (last: Jan 8)
Schedule check-in call with Lisa by Jan 25 to confirm executive review agenda
```

---

### 4. **Deal Acceleration**

**Pattern:**
```
Move from [CurrentStage] to [NextStage] by completing [Action]
Present [Deliverable] to [PersonName] ([Role]) by [Date]
```

**Example:**
```
Move from Qualification to Proposal by completing technical validation
Present solution architecture to Robert Taylor (VP Ops) by Jan 26
```

---

### 5. **Risk Mitigation**

**Pattern:**
```
Address [Risk] by [Action] with [PersonName] before [Event/Date]
Validate [Concern] is resolved with [PersonName] by [Date]
```

**Example:**
```
Address pricing objection by presenting 3-year TCO model to Sarah Johnson (CFO) before board meeting
Validate security concerns resolved with James Wilson (CISO) by Jan 30
```

---

## Priority Guidelines

### CRITICAL
- Deal at imminent risk of loss
- Executive-level engagement required
- Overdue by >7 days
- Blocking stage progression
- Close date within 30 days

**Keywords**: Overdue, Blocking, At risk, Executive, Deadline approaching

---

### HIGH
- Important for deal momentum
- Stakeholder gap (missing key role)
- MEDDIC element incomplete
- Competitive threat active

**Keywords**: MEDDIC gap, Stakeholder missing, Momentum, Competitive

---

### MEDIUM
- Optimization opportunity
- Process improvement
- Relationship building
- Documentation/tracking

**Keywords**: Optimize, Document, Strengthen, Build

---

## Trigger Conditions

Generate Next Best Actions when:
- ✅ Any gap or risk identified in analysis
- ✅ Incomplete MEDDIC elements (M/E/D/D/I/C)
- ✅ Overdue tasks or missed milestones
- ✅ Stakeholder engagement gaps (>14 days no contact)
- ✅ Deal velocity below benchmark
- ✅ Stage stagnation (>2x normal duration)
- ✅ Competitive threat present
- ✅ Missing key role (Economic Buyer, Champion, Decision Maker)

---

## Output Format

### HTML Card Structure (Recommended)

```html
<div style="background:white;border-radius:8px;border-left:4px solid #dc3545;padding:16px;margin:12px 0;">
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
    <h3 style="margin:0;font-size:14px;font-weight:600;color:#dc3545;">🔴 CRITICAL</h3>
    <span style="background:#dc3545;color:white;padding:4px 12px;border-radius:4px;font-size:11px;font-weight:600;">DUE: JAN 24</span>
  </div>
  <p style="margin:0 0 12px 0;font-size:14px;font-weight:600;color:#181818;">
    Schedule ROI presentation with Sarah Johnson (CFO)
  </p>
  <div style="background:#f8f9fa;padding:12px;border-radius:4px;margin-bottom:12px;">
    <p style="margin:0 0 6px 0;font-size:12px;color:#706E6B;">
      <strong>Why:</strong> ROI Analysis task 7 days overdue - blocking budget approval
    </p>
    <p style="margin:0 0 6px 0;font-size:12px;color:#706E6B;">
      <strong>Impact:</strong> Unblocks MEDDIC Metrics, maintains deal momentum
    </p>
    <p style="margin:0;font-size:12px;color:#706E6B;">
      <strong>Owner:</strong> Account Executive | <strong>Deadline:</strong> Within 48 hours
    </p>
  </div>
  <p style="margin:0;font-size:12px;font-weight:600;color:#2E844A;">
    ✓ Success: Meeting scheduled + ROI deck prepared + CFO confirms
  </p>
</div>
```

---

## Quality Checklist

Before finalizing actions, verify:

- [ ] Every action uses actual person name (not "stakeholder")
- [ ] Every action has specific deadline (not "soon")
- [ ] Every action cites evidence that triggered it
- [ ] Actions are prioritized (CRITICAL first)
- [ ] Each action has clear owner role
- [ ] Success criteria are measurable
- [ ] No generic/forbidden phrases used
- [ ] Actions are sorted by urgency/impact

---

## Integration with Other Patterns

**Works Best With:**
- Risk Assessment Pattern (triggers actions for identified risks)
- MEDDIC Scoring Pattern (actions address specific gaps)
- Timeline Analysis (actions based on velocity issues)
- Stakeholder Analysis (actions for engagement gaps)

**Avoid Combining With:**
- Generic Summary Pattern (conflicts with specificity requirement)
- Multiple action patterns (too many competing recommendations)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial pattern extraction from Phase 0B Variant 16 |

---

**File Location:** `docs/quality-rules/next_best_action_pattern.md`  
**Loaded By:** Builder Prompt Record (Category: Pattern)  
**Injected At:** Stage08 (Prompt Assembly)  
**Tested Score:** 69/100 (Phase 0B Variant 16)

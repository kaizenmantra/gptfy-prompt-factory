# Iteration 1: Quality Rules Updates

## Changes to Stage 8 Builder Records

### 1. Enhanced: Insight Depth (a0DQH00000KZQ962AH)

**OLD VERSION**:
```
Each insight must include four elements: (1) FINDING: What the data shows, (2) EVIDENCE: Specific field:value pairs supporting it, (3) IMPLICATION: Why it matters to business goals, (4) ACTION: Specific recommended next step. Never present findings without interpretation and action.
```

**NEW VERSION**:
```
Each insight must use DIAGNOSTIC LANGUAGE to interpret data, not just describe it:

PRESCRIPTIVE VERBS (use these):
- "signals", "indicates", "suggests", "points to", "reveals"
- "implies", "demonstrates", "reflects", "highlights"

AVOID DESCRIPTIVE VERBS:
- ❌ "has", "shows", "contains", "includes", "remains"
- ❌ "There are 3 cases" → ✅ "Three unresolved cases signal potential satisfaction risk"
- ❌ "The opportunity has 70% probability" → ✅ "The 70% win probability indicates strong positioning"

STRUCTURE:
(1) FINDING: Use diagnostic verbs to interpret what the pattern means
(2) EVIDENCE: Bullet format (see Evidence Citation rule)
(3) IMPLICATION: Connect to business outcomes with metrics
(4) ACTION: Specific WHO-WHAT-WHEN

Example: "The concentration of high-priority cases signals escalating support burden, indicating risk to Q1 NPS targets."
```

### 2. Enhanced: Evidence Citation (a0DQH00000KZQ9D2AX)

**OLD VERSION**:
```
Always cite specific field:value pairs as evidence when making claims or observations. Format as "FieldName=$value" or "FieldName=value". Example: "Amount=$500K, CloseDate=2024-03-15, Stage=Negotiation". Never make statements without backing them up with actual data field references.
```

**NEW VERSION**:
```
Always cite specific field:value pairs in STRUCTURED BULLET FORMAT:

REQUIRED FORMAT:
Evidence:
• Field Label: Value
• Field Label: Value
• Field Label: Value

EXAMPLES:
✅ Good:
Evidence:
• Open Cases (High Priority): 3
• Average Resolution Time: 12 days
• SLA Breaches: 2

❌ Bad (inline):
Evidence: CaseCount=3, Priority=High, SLA=Breached

RULES:
- Use field labels (not API names): "Account Name" not "Name"
- Include units: "$420K" not "420000", "70%" not "0.7"
- Max 3-5 bullets per insight
- Place after the analysis paragraph, before implications
```

### 3. NEW: Business Value Quantification

**ID**: Will be created as new Builder record

**CONTENT**:
```
QUANTIFY BUSINESS IMPACT in all insights and recommendations. Do not use generic impact statements.

REQUIREMENTS:
1. Use DOLLAR AMOUNTS when discussing revenue, pipeline, deals
   - ❌ "could affect revenue" → ✅ "could affect $420K in pipeline (28% of Q1 target)"

2. Use PERCENTAGES for risks, probabilities, changes
   - ❌ "significant churn risk" → ✅ "15-20% churn risk on $2M book"

3. Use TIME-BASED METRICS for urgency
   - ❌ "approaching deadline" → ✅ "14 days until Q1 close (March 31)"

4. Connect to STRATEGIC GOALS
   - ❌ "important opportunity" → ✅ "key to achieving 80% of territory quota"

5. Include COMPARATIVE CONTEXT
   - ❌ "high value" → ✅ "2.5x higher than average deal size"

EXAMPLE TRANSFORMATIONS:
❌ "Client access issues can lead to dissatisfaction and potential churn"
✅ "With $420K pipeline at risk and 14 days to Q1 close, unresolved access issues could trigger 15-20% revenue exposure if client churns"

❌ "Strong opportunity pipeline"
✅ "Pipeline of $420K represents 85% of quarterly target with weighted value of $294K (assuming win probabilities)"

EVERY "WHY" STATEMENT MUST INCLUDE NUMBERS.
```

## Deployment Steps

1. ✅ Backup existing records (documented above)
2. Update "Insight Depth" record
3. Update "Evidence Citation" record
4. Create new "Business Value Quantification" record
5. Test on Account 1 (Iteration 1)
6. Evaluate improvement

## Expected Impact

- **Diagnostic Depth**: 5/10 → 8/10 (prescriptive language required)
- **Evidence Binding**: 7/10 → 9/10 (structured format)
- **Business Value**: 5/10 → 8/10 (quantification required)
- **Overall**: 7.25/10 → **8.5/10+**

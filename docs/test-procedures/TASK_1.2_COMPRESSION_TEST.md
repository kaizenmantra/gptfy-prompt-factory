# Task 1.2: Compression Quality Test

**Purpose**: Verify that the compressed Next Best Action Pattern (444 chars) maintains output quality compared to the original (6,500 chars).

---

## Setup

**Original Builder:**
- Name: `Next Best Action Pattern`
- Category: Pattern
- Size: ~6,500 chars
- Record Type: Builder

**Compressed Builder:**
- Name: `Next Best Action Pattern (Compressed)`
- Category: Pattern
- Size: 442 chars
- Record ID: a0DQH00000KZJXJ2A5
- Record Type: Builder

---

## Test Procedure

### Step 1: Deactivate Original Builder (Temporarily)

1. Navigate to: AI Prompt → Next Best Action Pattern
2. Edit record
3. Change Status to `Inactive`
4. Save

### Step 2: Run Pipeline with Compressed Builder

1. Navigate to Prompt Factory app
2. Create new PF Run with:
   - Root Object: `Opportunity`
   - Sample Record: (Use an Opportunity with overdue tasks, MEDDIC gaps, etc.)
   - Business Context: "Identify deal risks and next best actions"
3. Run pipeline through Stage 8
4. Review the final prompt in `ccai__Prompt_Command__c`
5. Verify compressed builder content is injected
6. Copy/save the final prompt output

### Step 3: Reactivate Original and Deactivate Compressed

1. Reactivate: Next Best Action Pattern (set Status = `Active`)
2. Deactivate: Next Best Action Pattern (Compressed) (set Status = `Inactive`)

### Step 4: Run Pipeline with Original Builder

1. Use the SAME sample Opportunity record
2. Use the SAME business context
3. Run pipeline through Stage 8
4. Review the final prompt
5. Copy/save the final prompt output

### Step 5: Compare Outputs

Compare both prompts for:

**✅ Success Criteria:**
- Both include WHO/WHAT/WHEN/WHY structure
- Both enforce: Specific, Actionable, Bounded, Evidence-based, Prioritized
- Both trigger on: Overdue tasks, MEDDIC gaps, stakeholder gaps
- Both specify output format: Action | Why | Impact | Priority | Owner | Deadline | Success

**🔍 Key Differences to Note:**
- Compressed version: Principles only (no examples)
- Original version: Includes detailed examples and patterns
- Compressed version: Removes version history, quality checklist, integration notes

**❌ Failure Indicators:**
- Compressed version missing core requirements
- LLM unable to understand compressed principles
- Output quality degraded (vague actions, no evidence, missing deadlines)

---

## Expected Outcome

The compressed version should maintain the same quality as the original because:
1. All core principles preserved (WHO/WHAT/WHEN/WHY)
2. All 5 requirements intact (Specific, Actionable, Bounded, Evidence-based, Prioritized)
3. Triggers clearly defined
4. Output format specified

The compression removes redundancy (examples, explanations, version history) that LLMs don't need—they learn the pattern from the principles.

---

## Documentation

After testing, document findings in `BUILDER_IMPROVEMENTS.md`:

```
Progress Log:
- Task 1.2: Compression test completed
  - Original size: 6,500 chars
  - Compressed size: 442 chars
  - Quality: [MAINTAINED / DEGRADED]
  - Notes: [Any observed differences]
```

---

## Rollback Plan

If compression degrades quality:
1. Keep original builder active
2. Delete or deactivate compressed builder
3. Document specific quality issues
4. Revise compression strategy
5. Repeat Task 1.1 with adjusted compression

---

**Created**: 2026-01-23
**Task**: 1.2 - Test compressed prompt maintains quality
**Status**: Ready for manual testing

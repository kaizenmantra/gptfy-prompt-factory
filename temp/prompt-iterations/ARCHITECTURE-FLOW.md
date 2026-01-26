# How Quality Improvements Flow Through The System

## TL;DR - The Answer

**WHERE**: Single Salesforce record (Builder)
- **Record ID**: a0DQH00000KatYj2AJ
- **Name**: "Quality Rules (Compressed)"
- **RecordType**: Builder
- **Type**: Quality Rule
- **Status**: Active

**HOW**: Stage 8 (Apex) loads it and injects into EVERY prompt template

**WHEN**: Automatically for ALL new pipeline runs (already active!)

---

## The Complete Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER STARTS PIPELINE                                     │
│    PromptFactoryController.startPipelineRun(...)            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. STAGES 1-7 RUN                                           │
│    - DCM creation, field selection, merge field mapping    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. STAGE 8: PROMPT ASSEMBLY (Stage08_PromptAssembly.cls)   │
│                                                              │
│    Step 1: Load Quality Rules                               │
│    ┌──────────────────────────────────────────────────┐    │
│    │ Line 1835-1858:                                   │    │
│    │ Query Builder records:                            │    │
│    │   WHERE RecordType = 'Builder'                    │    │
│    │   AND Type = 'Quality Rule'                       │    │
│    │   AND Status = 'Active'                           │    │
│    │                                                    │    │
│    │ Look for "Compressed" in name (line 1850)        │    │
│    │   → FINDS: "Quality Rules (Compressed)"          │    │
│    │   → LOADS: All your diagnostic language +        │    │
│    │            business value + visual diversity rules│    │
│    └──────────────────────────────────────────────────┘    │
│                                                              │
│    Step 2: Load UI Components                               │
│    ┌──────────────────────────────────────────────────┐    │
│    │ Query Builder records:                            │    │
│    │   WHERE Type = 'UI Component'                     │    │
│    │   → Stat Card, Alert Box, Health Score, Table    │    │
│    └──────────────────────────────────────────────────┘    │
│                                                              │
│    Step 3: Load Context Template                            │
│    ┌──────────────────────────────────────────────────┐    │
│    │ Query Builder records:                            │    │
│    │   WHERE Type = 'Context Template'                 │    │
│    │   → Sales Rep persona, tone, objectives          │    │
│    └──────────────────────────────────────────────────┘    │
│                                                              │
│    Step 4: Load Merge Field Reference (from Stage 7)        │
│    ┌──────────────────────────────────────────────────┐    │
│    │ Available merge fields list from DCM              │    │
│    └──────────────────────────────────────────────────┘    │
│                                                              │
│    Step 5: ASSEMBLE FINAL PROMPT TEMPLATE                   │
│    ┌──────────────────────────────────────────────────┐    │
│    │ === YOUR ROLE ===                                 │    │
│    │ [Context Template content]                         │    │
│    │                                                    │    │
│    │ === QUALITY RULES ===                             │    │
│    │ [Quality Rules (Compressed) content] ← YOUR WORK  │    │
│    │                                                    │    │
│    │ === UI TOOLKIT ===                                │    │
│    │ [UI Component patterns]                            │    │
│    │                                                    │    │
│    │ === AVAILABLE MERGE FIELDS ===                    │    │
│    │ [Field reference from DCM]                         │    │
│    │                                                    │    │
│    │ === YOUR DIRECTIVE ===                            │    │
│    │ Generate the dashboard now...                      │    │
│    └──────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SAVE PROMPT RECORD                                       │
│    INSERT ccai__AI_Prompt__c                                │
│    - Name: "ITER05-Account1-BlueAlerts"                     │
│    - ccai__Prompt_Command__c: [Full assembled template]    │
│    - ccai__Status__c: 'Draft'                               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. STAGE 9: ACTIVATE PROMPT                                │
│    - Calls GPTfy to activate the prompt                     │
│    - GPTfy returns Prompt Request ID                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. STAGE 10: EXECUTE PROMPT                                │
│    - GPTfy executes the prompt with Account data            │
│    - AI reads YOUR QUALITY RULES in the template            │
│    - AI follows the rules:                                  │
│      ✓ Uses diagnostic language                             │
│      ✓ Quantifies business value                            │
│      ✓ Uses all 3 alert colors                              │
│      ✓ Includes health score                                │
│      ✓ Adds data table                                      │
│      ✓ Creates varied layout                                │
│    - Returns HTML output                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Architecture Points

### 1. NO Code Changes Required ✅

All improvements are **configuration-based** (Builder records), not code:
- Stage 8 Apex code: **UNCHANGED**
- Other stage classes: **UNCHANGED**
- Only changed: **1 Salesforce record** (Quality Rules Compressed)

### 2. Automatic For ALL Future Prompts ✅

Every time someone starts a pipeline:
1. Stage 8 runs
2. It queries for `ccai__Type__c = 'Quality Rule'`
3. It finds "Quality Rules (Compressed)" (line 1850)
4. It injects YOUR rules into the template
5. The prompt includes all your improvements

**No manual action needed** - it's automatic!

### 3. The "Compressed" Pattern 🎯

Stage 8 specifically looks for records with "Compressed" in the name (line 1850):
```apex
if (builder.Name.contains('Compressed')) {
    content += builder.ccai__Prompt_Command__c + '\n\n';
    return content; // Return early with compressed version
}
```

This is WHY we created "Quality Rules (Compressed)" - it takes precedence over individual rules.

### 4. Where Each Improvement Lives

| Improvement | Location in "Quality Rules (Compressed)" |
|-------------|------------------------------------------|
| Diagnostic Language | Lines 1-2 (signals, indicates, suggests) |
| Business Value Quantification | Lines 3-4 (Why: With $X...) |
| Visual Diversity Requirements | Lines 6-30 (health, alerts, tables) |
| Mandatory Checklist | Lines 32-39 (what MUST be included) |

**All in ONE place** - easy to maintain!

---

## How To Update Quality Rules

### Option 1: Via Salesforce UI
1. Go to Setup → Custom Metadata Types → AI Prompt
2. Find record: "Quality Rules (Compressed)" (a0DQH00000KatYj2AJ)
3. Edit `Prompt Command` field
4. Save
5. **Done!** Next pipeline run uses new rules

### Option 2: Via Salesforce CLI (like I did)
```bash
sf data update record \
  --sobject ccai__AI_Prompt__c \
  --record-id a0DQH00000KatYj2AJ \
  --values "ccai__Prompt_Command__c='YOUR NEW RULES HERE'" \
  --target-org agentictso
```

### Option 3: Via Apex Anonymous
```apex
ccai__AI_Prompt__c rule = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Id = 'a0DQH00000KatYj2AJ'
];

rule.ccai__Prompt_Command__c = 'YOUR NEW RULES HERE';
update rule;
```

---

## What Happens To OLD Prompts?

**OLD prompts** (created before today):
- ❌ Still use OLD quality rules (whatever was in the template when they were created)
- ❌ Will NOT automatically update
- Their `ccai__Prompt_Command__c` field is static

**NEW prompts** (created today or later):
- ✅ Use NEW quality rules (from "Quality Rules (Compressed)")
- ✅ Will have all improvements (diagnostic language, visual diversity, etc.)

**To update old prompts**: You'd need to re-run the pipeline for those accounts.

---

## Testing The Flow

Want to see it in action? Here's what happens:

```bash
# 1. Start a new pipeline
Id runId = PromptFactoryController.startPipelineRun(
    'Test-MyAccount',
    'Account',
    '001XXXXXX',
    'Analyze this account',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.com'
);

# 2. Wait for Stage 8 to complete

# 3. Query the created prompt
SELECT ccai__Prompt_Command__c
FROM ccai__AI_Prompt__c
WHERE Name = 'Test-MyAccount'

# 4. You'll see YOUR quality rules in the template:
#    === QUALITY RULES ===
#    DIAGNOSTIC LANGUAGE: Use "signals", "indicates"...
#    BUSINESS VALUE: "Why: With $X at risk..."
#    VISUAL DIVERSITY (CRITICAL - ALL REQUIRED):
#    ...
```

---

## Summary

### Where Improvements Live
✅ **1 Salesforce Record**: a0DQH00000KatYj2AJ (Quality Rules Compressed)

### How They're Used
✅ **Stage 8** (Stage08_PromptAssembly.cls) automatically loads and injects them

### When They Apply
✅ **ALL new prompts** created from now on (already active!)

### How To Change Them
✅ **Edit the Salesforce record** (UI, CLI, or Apex)

### Impact
✅ **Every pipeline run** gets improved prompts with:
- Diagnostic language
- Quantified business value
- Visual diversity (health scores, 3-color alerts, tables)
- Professional executive-grade output

**No code deployment needed** - it's all configuration! 🎉

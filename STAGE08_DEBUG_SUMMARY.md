# Stage08 Builder Injection - Debug Summary

**Date**: January 22, 2026 11:11 UTC  
**Status**: ⚠️ **BUILDERS NOT INJECTING**  

---

## ✅ What Works (Proven)

### 1. Builders Exist and Are Queryable
```sql
SELECT COUNT() FROM ccai__AI_Prompt__c 
WHERE RecordType.DeveloperName = 'Builder' 
  AND ccai__Status__c = 'Active'
```
**Result**: 6 builders (all Active) ✅

### 2. Queries Return Correct Data
Manual test (`scripts/apex/test_builder_queries.apex`):
```
✅ Quality Rules: 1 found (16,265 chars)
✅ Patterns: 2 found (Next Best Action + Risk Assessment)
✅ UI Components: 2 found
✅ Context Templates: 1 found
Total: 6 builders
```

### 3. Stage08 Loading Logic Works
Standalone test (`scripts/apex/diagnose_stage08_injection.apex`):
```
✅ Injected Quality Rules: +12,181 chars
✅ Injected Patterns: +1,791 chars
✅ SUCCESS: Builders ARE being injected! (+13,976 chars)
```

### 4. Code Is Deployed
```bash
sf data query ApexClass WHERE Name = 'Stage08_PromptAssembly'
LastModifiedDate: 2026-01-22T10:44:28.000+0000

# Code contains:
- loadQualityRules()
- loadPatterns()
- loadUIComponents()  
- loadContextTemplates()
- Debug logging with emojis (🏗️, 🔍, 📊)
```

---

## ❌ What Doesn't Work

### Pipeline-Generated Prompts Have NO Builder Content

**Test Results**:
| Run ID | Created Prompt | Size | Has Builders? | Builder Headers? |
|--------|----------------|------|---------------|------------------|
| a0gQH000005GBB7YAO (MVP) | a0DQH00000KYYuz2AH | 16,361 | ✅ YES | ✅ YES (lines 128, 182) |
| a0gQH000005GBcXYAW (Wizard 1) | a0DQH00000KYcdn2AD | 10,850 | ❌ NO | ❌ NO |
| a0gQH000005GBe9YAG (My test) | a0DQH00000KYdZh2AL | 10,854 | ❌ NO | ❌ NO |
| a0gQH000005GBflYAG (Your test) | a0DQH00000KYd9v2AD | 9,979 | ❌ NO | ❌ NO |

**Pattern**: MVP test (09:46 UTC) HAD builders. All tests after 10:11 UTC have NO builders.

---

## 🔍 Timeline Analysis

```
09:46 UTC - MVP test prompt created → HAS builder headers ✅
10:11 UTC - Deleted old builders, created new ones
10:44 UTC - Stage08 redeployed with debug logging
10:49 UTC - Wizard test #1 → NO builders ❌
11:03 UTC - My test → NO builders ❌
11:09 UTC - Your test → NO builders ❌
```

**Critical Observation**: MVP test (before builder recreation) HAD builders. After recreation, NO prompts have builders.

---

## 🎯 Root Cause Hypothesis

### Theory 1: GPTfy Auto-Reverts Builders to Draft ⭐ LIKELY
**Evidence**:
- Evidence Binding was manually set to Active at 11:02
- By 11:07, it was back to Draft
- GPTfy Message: "(1) There are no field mappings defined for AccountPartner"

**Cause**: Builder prompts have example merge fields in their content. GPTfy validation sees these and thinks the builder is an executable prompt. When validation fails (missing fields in DCM), it reverts to Draft.

**Fix Attempted**: User manually removed problematic merge fields → Evidence Binding now stays Active

---

### Theory 2: Queueable Context Issue ⚠️ POSSIBLE
**Evidence**:
- Standalone test in Execute Anonymous: Builders load ✅
- Pipeline test in Queueable context: Builders don't load ❌

**Cause**: Category__c field might not be accessible in Queueable/Batch context due to permissions

**Test Needed**: Run Stage08 in Queueable context specifically

---

### Theory 3: Record Type Permissions ⚠️ POSSIBLE
**Evidence**:
- RecordType.DeveloperName queries work in Execute Anonymous
- But might fail in system/automated context

**Test Needed**: Check if running user has access to Builder record type in automated jobs

---

### Theory 4: Silent Query Failure in Pipeline ⚠️ POSSIBLE  
**Evidence**:
- Queries have try/catch that returns empty string
- Debug logging added but logs not visible (can't confirm)

**Cause**: Exception thrown in Queueable but swallowed by try/catch

**Test Needed**: Add PromptFactoryLogger calls instead of System.debug

---

## 🧪 Next Diagnostic Steps

### Step 1: Check if Debug Logs Are Actually Written
```apex
// Instead of System.debug(), use PromptFactoryLogger
PromptFactoryLogger.info(runId, 8, '🔍 loadQualityRules() called');
PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + rules.size());
```

This will write to PF_Run_Log__c which we CAN query.

---

### Step 2: Test Category__c Access in Queueable
```apex
public class TestBuilderQueryJob implements Queueable {
    public void execute(QueueableContext ctx) {
        List<ccai__AI_Prompt__c> builders = [
            SELECT Id, Category__c 
            FROM ccai__AI_Prompt__c 
            WHERE RecordType.DeveloperName = 'Builder'
        ];
        System.debug('Found in Queueable: ' + builders.size());
    }
}
// Enqueue: System.enqueueJob(new TestBuilderQueryJob());
```

---

### Step 3: Test FLS in Different Contexts
```apex
Schema.DescribeFieldResult field = ccai__AI_Prompt__c.Category__c.getDescribe();
System.debug('Accessible in Queueable: ' + field.isAccessible());
```

---

### Step 4: Check if buildAIInstructions() Is Even Called
Add at the very start of buildAIInstructions():
```apex
PromptFactoryLogger.error(runId, 8, 'MARKER: buildAIInstructions() CALLED');
```

If this doesn't appear in logs, the method isn't running.

---

## 📊 Evidence Summary

| Question | Evidence | Conclusion |
|----------|----------|------------|
| Do builders exist? | 6 Active builders | ✅ YES |
| Can they be queried? | Manual test returns all 6 | ✅ YES |
| Is Stage08 deployed? | LastMod 10:44 UTC | ✅ YES |
| Does Stage08 code have loaders? | grep shows all 4 methods | ✅ YES |
| Do queries work in Execute Anonymous? | +13,976 chars injected | ✅ YES |
| Do queries work in Pipeline? | 0 chars injected | ❌ NO |

**Conclusion**: Something specific to **Queueable/Pipeline execution context** prevents builder queries from returning results.

---

## 🔧 Recommended Immediate Actions

### Action 1: Replace System.debug() with PromptFactoryLogger (CRITICAL)
This will let us see what's actually happening in the pipeline:

```apex
// In loadQualityRules(), replace:
System.debug('🔍 loadQualityRules() called...');

// With:
if (runId != null) {
    PromptFactoryLogger.info(runId, 8, '🔍 loadQualityRules() called');
}
```

**Problem**: loadQualityRules() doesn't have runId! Need to pass it as parameter.

---

### Action 2: Pass runId to Builder Loaders
Modify Stage08 to pass runId to all loader methods:

```apex
String qualityRules = loadQualityRules(runId);
String patterns = loadPatterns(rootObject, runId);
String uiComponents = loadUIComponents(runId);
String contextTemplates = loadContextTemplates(runId);
```

Then in each loader:
```apex
private String loadQualityRules(Id runId) {
    PromptFactoryLogger.info(runId, 8, 'Loading Quality Rules...');
    // ... query ...
    PromptFactoryLogger.info(runId, 8, 'Found: ' + rules.size());
}
```

---

### Action 3: Test in Queueable Context Directly
Create minimal Queueable test:

```apex
public class TestCategoryAccess implements Queueable {
    private Id runId;
    
    public TestCategoryAccess(Id runId) {
        this.runId = runId;
    }
    
    public void execute(QueueableContext ctx) {
        PromptFactoryLogger.info(runId, 8, 'Queueable started');
        
        try {
            List<ccai__AI_Prompt__c> builders = [
                SELECT Id, Name, Category__c
                FROM ccai__AI_Prompt__c
                WHERE RecordType.DeveloperName = 'Builder'
                  AND Category__c = 'Quality Rule'
                  AND ccai__Status__c = 'Active'
            ];
            
            PromptFactoryLogger.info(runId, 8, 'Query returned: ' + builders.size());
            
        } catch (Exception e) {
            PromptFactoryLogger.error(runId, 8, 'Query failed: ' + e.getMessage());
        }
    }
}
```

---

## 🎓 Key Learnings

1. **MVP Test Had Different Builders**: The old incomplete builders (before we recreated them)
2. **GPTfy Validates Builder Content**: Example merge fields cause activation failures
3. **System.debug() Invisible in Queueable**: Need PromptFactoryLogger for visibility
4. **FLS Behaves Differently in Contexts**: What works in Execute Anonymous may fail in Queueable

---

## 📋 Status of Fixes

| Fix | Status | Result |
|-----|--------|--------|
| Create 6 builders | ✅ DONE | All exist |
| Activate all builders | ✅ DONE (user fixed) | All Active |
| Deploy Stage08 with loaders | ✅ DONE | Deployed 10:44 |
| Add debug logging | ✅ DONE | But invisible |
| Update Evidence Binding content | ✅ DONE (user) | Now has specificity rules |
| Create Next Best Action | ✅ DONE | Active builder |
| Fix builder injection | ⏸️ IN PROGRESS | Not working yet |

---

## 🚀 Next Steps

1. **Add PromptFactoryLogger to all builder loaders** (30 min)
2. **Pass runId to loader methods** (15 min)
3. **Deploy and test** (10 min)
4. **Check PF_Run_Log__c for actual errors** (5 min)
5. **Fix discovered issue** (30-60 min)

**Total ETA**: 1.5-2 hours to full resolution

---

**Current Issue**: Builders don't inject in pipeline, but we can't see WHY because System.debug() is invisible in Queueable context.

**Next Action**: Instrument Stage08 with PromptFactoryLogger calls so we can see what's happening.

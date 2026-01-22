# Problem Summary for AI Assistant

**Date**: January 23, 2026  
**Context**: Salesforce Apex - Prompt Factory Pipeline  
**Issue**: Builder content not injecting into generated prompts  

---

## 🎯 Core Problem

**Expected**: Pipeline-generated prompts should be ~40KB (10KB base + 30KB builders)  
**Actual**: Pipeline-generated prompts are ~10KB (builders missing)  
**Impact**: Output quality is poor without quality rules and patterns from builders

---

## ✅ What WORKS (Proven)

1. **Manual queries return all builders** ✅
   ```apex
   // This returns 6 active builders with full content
   List<ccai__AI_Prompt__c> builders = [
       SELECT Name, ccai__Prompt_Command__c
       FROM ccai__AI_Prompt__c
       WHERE RecordType.DeveloperName = 'Builder'
         AND ccai__Status__c = 'Active'
   ];
   // Result: 6 records, 45KB total content
   ```

2. **Standalone Stage08 execution works** ✅
   - Execute Anonymous test of `Stage08_PromptAssembly.buildAIInstructions()`
   - Returns +13,976 chars from builders
   - Proves the code logic is correct

3. **MVP test (09:46 UTC) worked** ✅
   - Prompt ID: `a0DQH00000KYYuz2AH`
   - Size: 16,361 chars
   - Had builder headers: "=== Evidence Binding ===" visible
   - Used OLD builders (created before 10:11 UTC)

4. **Builders exist and are valid** ✅
   - 6 Active builders in database
   - RecordType: Builder (`012QH0000045bz7YAA`)
   - Status: Active
   - Owner: Agentic TSO user
   - OWD: ReadWrite (not Private)

---

## ❌ What FAILS (Consistently)

**All pipeline runs after 10:11 UTC**: 0 builder content injected

**Timeline**:
- 09:46 UTC - MVP test with old builders → ✅ Worked (16,361 chars)
- 10:11 UTC - Deleted old builders, created new ones via REST API
- 10:11+ UTC - All subsequent tests → ❌ Fail (~10KB, no builders)

**What changed at 10:11**:
- Old builders: Created via Apex, abbreviated content (~2KB each)
- New builders: Created via REST API, complete content (~16KB major builders)

---

## 🔬 What's Been Tested (All Failed)

### Test 1: RecordType.DeveloperName Query
```apex
WHERE RecordType.DeveloperName = 'Builder'
  AND Category__c = 'Quality Rule'
```
**Result**: ❌ No builders injected (10,850 chars)

### Test 2: RecordTypeId Direct
```apex
Id builderRTId = Schema.SObjectType.ccai__AI_Prompt__c
    .getRecordTypeInfosByDeveloperName()
    .get('Builder')
    .getRecordTypeId();
WHERE RecordTypeId = :builderRTId
```
**Result**: ❌ No builders injected (10,379 chars)

### Test 3: Hardcoded Builder IDs
```apex
List<Id> ids = new List<Id>{'a0DQH00000KYZxW2AX', ...};
WHERE Id IN :ids
```
**Result**: ❌ No builders injected (8,904 chars)

### Test 4: WITHOUT SHARING Class
```apex
public without sharing class Stage08_PromptAssembly
```
**Result**: ❌ No builders injected (10,226 chars)

### Test 5: Added Extensive Logging
```apex
PromptFactoryLogger.info(runId, 8, '🔍 loadQualityRules() called');
```
**Result**: ❌ Can't query logs (PF_Run_Log__c fields not deployed in org)

---

## 🏗️ Architecture Context

### Pipeline Flow:
```
Stage01 → Stage02 → ... → Stage08 (PromptAssembly) → Stage09 (CreateAndDeploy)
                             ↓
                    buildAIInstructions()
                             ↓
                    loadQualityRules()
                    loadPatterns()
                    loadUIComponents()
                    loadContextTemplates()
                             ↓
                    return instructions
                             ↓
                    outputs.put('aiInstructions', instructions)
                             ↓
                    Stage09 creates prompt with this content
```

### Stage08 Key Method:
```apex
public without sharing class Stage08_PromptAssembly implements IStage {
    
    public StageResult execute(Map<String, Object> inputs, Id runId) {
        // ...
        String aiInstructions = buildAIInstructions(..., runId);
        // aiInstructions should be ~40KB with builders
        // Actually returns ~10KB (no builders)
        
        result.outputs.put('aiInstructions', aiInstructions);
        // Stage09 reads this and creates ccai__AI_Prompt__c record
    }
    
    private String buildAIInstructions(..., Id runId) {
        String instructions = '... base content ...'; // ~10KB
        
        // THESE METHODS SHOULD ADD 30KB BUT SEEM TO RETURN EMPTY
        instructions += loadQualityRules(runId);     // Should add ~16KB
        instructions += loadPatterns(rootObject, runId);  // Should add ~12KB
        instructions += loadUIComponents(runId);     // Should add ~5KB
        instructions += loadContextTemplates(runId); // Should add ~12KB
        
        return instructions; // Returns ~10KB instead of 40KB
    }
}
```

### Current User Changes:
User just reverted hardcoded IDs back to RecordTypeId approach (the clean approach).

---

## 💡 Leading Hypotheses

### Hypothesis 1: Loader Methods Not Executing ⭐ MOST LIKELY
**Theory**: `buildAIInstructions()` is called, but loader methods hit an exception or return early before querying.

**Evidence**:
- No error thrown (pipeline completes)
- ALL query approaches fail equally (suggests code not reaching queries)
- Can't see logs to verify

**How to Test**:
```apex
// Add at very start of buildAIInstructions():
instructions += '\n\n!!!MARKER_EXECUTED_' + System.now().getTime() + '!!!\n\n';

// Add at start of each loader:
PromptFactoryLogger.info(runId, 8, 'ENTERED loadQualityRules');

// Check if marker appears in final prompt
```

### Hypothesis 2: Content Truncation
**Theory**: Stage09 or PromptBuilder silently truncates content > 10KB.

**Evidence**:
- All prompts are ~10KB regardless of approach
- Old builders (2KB each) worked
- New builders (16KB each) don't work

**How to Test**:
- Check `PromptBuilder.buildPromptCommandWithTemplate()` for string length limits
- Check Stage09 for truncation logic

### Hypothesis 3: Different Code Path in Pipeline
**Theory**: Pipeline doesn't actually call `Stage08.buildAIInstructions()`, uses different method.

**Evidence**:
- Execute Anonymous works (calls method directly)
- Pipeline fails (may use different path)

**How to Test**:
- Debug logs showing method execution
- Marker test (if marker missing, method not called)

### Hypothesis 4: Heap Size Limits in Queueable
**Theory**: Queueable context can't handle 40KB string manipulation.

**Evidence**:
- Old builders (small) worked
- New builders (large) don't
- Different limits in Queueable vs Execute Anonymous

**How to Test**:
- Create tiny builder (100 chars) and see if it injects
- Monitor heap usage

---

## 🔧 Key Files

### Main Implementation:
- `force-app/main/default/classes/Stage08_PromptAssembly.cls` (lines 227-425: buildAIInstructions)
- `force-app/main/default/classes/Stage09_CreateAndDeploy.cls` (creates prompt from Stage08 output)
- `force-app/main/default/classes/PromptBuilder.cls` (utility for prompt creation)

### Builder Records (in Salesforce org):
```
ID                  NAME                       CATEGORY         SIZE
a0DQH00000KYZxW2AX  Evidence Binding Rules v2  Quality Rule     16KB
a0DQH00000KYaC12AL  Risk Assessment Pattern    Pattern          2KB
a0DQH00000KYdD72AL  Next Best Action Pattern   Pattern          10KB
a0DQH00000KYaFF2A1  Stat Card Component        UI Component     3KB
a0DQH00000KYaLh2AL  Alert Box Component        UI Component     2KB
a0DQH00000KYaQX2A1  Healthcare Payer Context   Context Template 12KB
```

### Test Scripts:
- `scripts/apex/test_builder_queries.apex` - Proves queries work manually
- `scripts/apex/diagnose_stage08_injection.apex` - Tests Stage08 standalone
- `scripts/apex/run_final_comprehensive_test.apex` - Runs full pipeline

---

## 🎯 What's Needed to Debug

### Option A: Debug Logs (5 min) ⭐ RECOMMENDED
```
1. Setup → Debug Logs → New
2. User: Agentic TSO
3. Level: FINEST for all
4. Run: Prompt Factory test
5. View log, search for: "loadQualityRules" or "buildAIInstructions"
6. See if methods are called and what they return
```

### Option B: Marker Test (10 min)
```apex
// In buildAIInstructions() at line 377:
instructions += '\n\n===MARKER_' + System.now().getTime() + '===\n\n';

// Then check if marker is in final prompt
// If NO → method not called
// If YES → method called but loaders return empty
```

### Option C: Check Stage09 (15 min)
```apex
// In Stage09_CreateAndDeploy.cls
// Find where it reads 'aiInstructions' from Stage08 output
// Check if it truncates or validates length
```

---

## 🎬 Quick Reproduction

```apex
// Run this to trigger the issue:
Map<String, Object> inputs = new Map<String, Object>{
    'rootObject' => 'Opportunity',
    'promptName' => 'Test Builder Injection',
    'businessContext' => 'Test',
    'targetPersona' => 'Sales Rep',
    'businessObjectives' => new List<String>{'Test'}
};

PromptFactoryController.startPipelineRun(inputs);

// Wait 60 seconds, then check created prompt size:
// Should be ~40KB, actually ~10KB
```

---

## 📊 Expected vs Actual

| Metric | Expected | Actual | Diff |
|--------|----------|--------|------|
| Prompt Size | ~40KB | ~10KB | -30KB |
| Builder Headers | 6 visible | 0 visible | -6 |
| Quality Rules | Present | Missing | ❌ |
| Patterns | Present | Missing | ❌ |
| UI Components | Present | Missing | ❌ |
| Context Templates | Present | Missing | ❌ |

---

## 💡 Suggested Investigation Order

1. **Enable debug logs** → See if `buildAIInstructions()` is called
2. **Add marker test** → Confirm method execution
3. **Check Stage09** → Look for truncation logic
4. **Test with tiny builder** → Rule out size limits
5. **Check old builder IDs** → See if they still exist and work

---

## 🔑 Critical Insight

**The MVP test is the key**: It worked at 09:46 UTC with old builders. Something specific about the new builders (created at 10:11 UTC) prevents injection, even when using hardcoded IDs of the new builders.

**The difference isn't query syntax—it's the builder records themselves or how they're being accessed in pipeline context.**

---

## ✅ Success Criteria

When fixed, prompts should:
- Be 35-45KB (not 10KB)
- Contain headers: "=== Evidence Binding Rules v2 ==="
- Contain headers: "=== Risk Assessment Pattern ==="
- Output should use actual names ("Sarah Johnson") not generic terms ("the CFO")

---

**Latest Code State**: User just reverted to clean RecordTypeId approach (see attached_files diff)

**Next Step**: Enable debug logs OR add marker test to see if methods are executing.

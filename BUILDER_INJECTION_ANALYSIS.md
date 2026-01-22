# Builder Injection Analysis - Jan 22, 2026

## 🔍 Issue Summary

**User Report**: Prompt Factory wizard generated prompt `a0DQH00000KYck52AD` ("Deal Review - 04-35AM") without builder content

**My Analysis**: ✅ **CONFIRMED** - Builder content is NOT being injected into wizard-generated prompts

---

## 📊 Test Results

### Prompt Analysis
```
Prompt ID: a0DQH00000KYck52AD
Name: Deal Review - 04-35AM
Created: 2026-01-22 10:38:04 UTC
Size: 10,830 chars (normal size, not increased by builders)
```

### Builder Content Check
```
❌ Evidence Binding: NOT FOUND
❌ Risk Assessment: NOT FOUND
❌ Stat Card Component: NOT FOUND
❌ Alert Box Component: NOT FOUND
❌ Healthcare Context: NOT FOUND
```

**Result**: 0 of 5 builders present in prompt

### Database Verification
```
✅ Builders in Database: 5 active
✅ All queryable manually
✅ All have full content (12KB+)
✅ All have correct status
```

**Conclusion**: Builders exist and are correct, but Stage08 is NOT loading them during wizard runs

---

## 🔬 Technical Investigation

### Architecture Verified
1. ✅ **Stage08 Deployed**: Last modified 10:22:48 UTC (before user's test)
2. ✅ **Code Path Correct**: PromptFactoryPipeline → Stage08_PromptAssemblyJob → Stage08_PromptAssembly.execute() → buildAIInstructions()
3. ✅ **Loader Methods Present**: loadQualityRules(), loadPatterns(), loadUIComponents(), loadContextTemplates()
4. ✅ **Called in Right Place**: All 4 methods called before returning instructions

### Possible Root Causes

**A) Silent Query Failure (Most Likely)**
- Loader methods have try/catch that returns empty string on error
- No exceptions thrown to calling code
- Query could fail due to:
  - Field-level security (Category__c not accessible to running user)
  - Record type permissions
  - Object-level security
  - Sharing rules

**B) Metadata/Permissions Issue**
- Category__c field might not be accessible in certain contexts
- Record Type relationship might have permission issues
- Package namespace causing query problems

**C) Unexpected Data**
- Queries filtering out all results due to unexpected field values
- Record Type DeveloperName mismatch
- Status field value mismatch

---

## 🔧 What I Did

### Deployed Enhanced Debugging
Added comprehensive logging to Stage08_PromptAssembly:

```apex
System.debug('🏗️ BUILD AI INSTRUCTIONS: Starting builder injection...');
System.debug('📋 Step 1: Loading Quality Rules...');
System.debug('📊 Query returned: ' + rules.size() + ' Quality Rules');
System.debug('✅ Loaded X Quality Rules (Y total chars)');
System.debug('📊 BUILDER INJECTION COMPLETE: Added X chars from builders');
```

**Deploy ID**: 0AfQH00000N3IRN0A3  
**Deploy Time**: 10:44:28 UTC  
**Status**: Succeeded ✅

---

## 🧪 Next Steps for Testing

### Step 1: Run Prompt Factory Wizard Again
1. Use the same inputs as before (Opportunity object, Deal Review)
2. Let it complete all stages
3. Note the new prompt ID

### Step 2: Get Debug Logs
```bash
# Find the run ID
sf data query -o agentictso --query "SELECT Id, Status__c, Current_Stage__c FROM PF_Run__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1"

# Or check via Apex logs in Setup → Debug Logs
# Filter by: "USER_DEBUG" and look for 🏗️ emoji
```

### Step 3: Look for These Debug Messages

**Expected if working**:
```
🏗️ BUILD AI INSTRUCTIONS: Starting builder injection...
📋 Step 1: Loading Quality Rules...
🔍 loadQualityRules() called - querying builders...
📊 Query returned: 1 Quality Rules
✅ Loading: Evidence Binding Rules v2 (12144 chars)
✅ Injected Quality Rules: +12144 chars
📊 BUILDER INJECTION COMPLETE: Added 31000+ chars from builders
```

**If queries fail**:
```
🔍 loadQualityRules() called - querying builders...
📊 Query returned: 0 Quality Rules
⚠️ No Quality Rules to inject
```

**If exception occurs**:
```
❌ Error loading Quality Rules: [error message]
❌ Stack trace: [stack trace]
```

---

## 🎯 Diagnostic Questions to Answer

From the debug logs, we'll determine:

1. **Are the loader methods being called?**
   - Look for: `🔍 loadQualityRules() called`
   - If NO → buildAIInstructions() not executing (bigger issue)
   - If YES → Continue to #2

2. **Do the queries return results?**
   - Look for: `📊 Query returned: X Quality Rules`
   - If 0 → Query filtering issue (permissions, FLS, data mismatch)
   - If 1+ → Continue to #3

3. **Is content being injected?**
   - Look for: `✅ Injected Quality Rules: +X chars`
   - If NO → String concatenation issue
   - If YES → Continue to #4

4. **Is final prompt larger?**
   - Look for: `📊 Total instruction length: X chars`
   - Should be ~30KB+ if all builders loaded
   - If smaller → Content not persisting (serialization issue?)

---

## 🔍 Alternative Investigation: Check Permissions

If queries return 0 results, check FLS:

```apex
// Run in Execute Anonymous
Schema.DescribeFieldResult fieldDescribe = ccai__AI_Prompt__c.Category__c.getDescribe();
System.debug('Field Accessible: ' + fieldDescribe.isAccessible());
System.debug('Field Updateable: ' + fieldDescribe.isUpdateable());

Schema.DescribeSObjectResult objDescribe = ccai__AI_Prompt__c.getSObjectType().getDescribe();
System.debug('Object Accessible: ' + objDescribe.isAccessible());
System.debug('Object Queryable: ' + objDescribe.isQueryable());

// Check Record Type
List<RecordType> rts = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ccai__AI_Prompt__c' AND DeveloperName = 'Builder'];
System.debug('Record Type Found: ' + !rts.isEmpty());
if (!rts.isEmpty()) {
    System.debug('Record Type ID: ' + rts[0].Id);
}
```

---

## 💡 Temporary Workaround (If Needed)

If builder injection continues to fail, we can:

1. **Copy builder content to Static Resources** (old system)
2. **Add builders directly to Stage08 as hardcoded strings** (not ideal)
3. **Create a custom setting to store builder content** (alternative storage)
4. **Use Flow/Process Builder to inject post-creation** (workaround)

But let's see the debug logs first before implementing any workarounds!

---

## 📝 Summary for User

### What's Confirmed
- ✅ Builders exist in database with full content
- ✅ Stage08 code is correct and deployed
- ✅ Execution path is correct
- ❌ Builder content NOT appearing in wizard-generated prompts

### What's Unknown (Need Debug Logs)
- ⁇ Are loader methods being called?
- ⁇ Do queries return 0 or error out?
- ⁇ Is there a permissions/FLS issue?
- ⁇ Is content injected but not persisted?

### Next Action Required
**Run Prompt Factory wizard again** (now that enhanced debugging is deployed) and we'll see exactly what's happening in the logs.

---

**Status**: Waiting for next test run with debug logging enabled ⏳

---

**Files Modified**:
- `force-app/main/default/classes/Stage08_PromptAssembly.cls` (added debug logging)
- Deployed at 10:44:28 UTC

**Git Status**: Changes not yet committed (waiting for test results)

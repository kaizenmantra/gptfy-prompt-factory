# PF_Run_Log__c Field Proposal

**Date**: January 22, 2026 7:25 PM  
**Purpose**: Enable proper error/debug logging in Prompt Factory pipeline  
**Status**: ⚠️ **AWAITING APPROVAL**  

---

## Current State (In Org)

`PF_Run_Log__c` currently has **ONLY these fields**:
- Standard fields (Id, CreatedDate, CreatedBy, etc.)
- `Run__c` - Master-Detail to PF_Run__c ✅
- `Timestamp__c` - Date/Time ✅

**Result**: `PromptFactoryLogger` cannot write meaningful logs (fields missing!)

---

## Proposed Fields (Already Defined Locally, Not Deployed)

### 1. `Log_Message__c` ⭐ CRITICAL
- **Type**: Long Text Area (10,000 chars)
- **Purpose**: The actual log message
- **Example**: "✅ Loaded 1 Quality Rules (856 chars)"
- **Why Critical**: This is the main content of the log entry

### 2. `Log_Level__c` ⭐ CRITICAL
- **Type**: Picklist (DEBUG, INFO, WARNING, ERROR)
- **Purpose**: Severity level for filtering
- **Example**: "ERROR" for loader failures
- **Why Critical**: Lets us filter to errors vs info logs

### 3. `Stage_Number__c` ⭐ CRITICAL
- **Type**: Number (2,0) - values 1-12
- **Purpose**: Which pipeline stage generated this log
- **Example**: 8 (for Stage08_PromptAssembly)
- **Why Critical**: Essential for debugging specific stages

### 4. `Component__c` 
- **Type**: Text (255 chars)
- **Purpose**: Class or method name that logged
- **Example**: "Stage08_PromptAssembly.loadQualityRules"
- **Why Useful**: Helps pinpoint exact code location

### 5. `Details__c`
- **Type**: Long Text Area (32,000 chars)
- **Purpose**: Stack traces, JSON data, exception details
- **Example**: Stack trace from builder query exception
- **Why Useful**: Full error context for debugging

---

## How These Enable Debugging

### Current Problem:
```apex
try {
    // Query builders
} catch (Exception e) {
    PromptFactoryLogger.error(runId, 8, 'Failed: ' + e.getMessage());
    // ^^ This FAILS because Log_Message__c doesn't exist!
    return '';  // Silent failure
}
```

### With Fields Deployed:
```apex
try {
    // Query builders
} catch (Exception e) {
    PromptFactoryLogger.error(runId, 8, 'Failed: ' + e.getMessage());
    // ^^ This WORKS - creates log record with:
    //    - Log_Message__c: "Failed to load Quality Rules: ..."
    //    - Log_Level__c: "ERROR"
    //    - Stage_Number__c: 8
    //    - Details__c: Full stack trace
    throw new StageException(...);
}
```

### Query to See Errors:
```sql
SELECT Stage_Number__c, Log_Level__c, Log_Message__c, Details__c
FROM PF_Run_Log__c
WHERE Run__c = 'a0g...' 
  AND Log_Level__c = 'ERROR'
ORDER BY CreatedDate
```

---

## Additional Fields I Recommend

### 6. `Execution_Time_MS__c` (NEW - Optional)
- **Type**: Number (10,0)
- **Purpose**: How long an operation took
- **Example**: 1250 (1.25 seconds)
- **Why Useful**: Performance monitoring, find slow operations

### 7. `Record_Count__c` (NEW - Optional)
- **Type**: Number (10,0)
- **Purpose**: Number of records processed/found
- **Example**: 6 (found 6 builders)
- **Why Useful**: Quick sanity check without reading message

### 8. `Success__c` (NEW - Optional)
- **Type**: Checkbox
- **Purpose**: Quick true/false success indicator
- **Example**: false (operation failed)
- **Why Useful**: Filter to failures with simple checkbox filter

---

## Recommendation

### Minimum (Deploy These First): ⭐
1. `Log_Message__c` - MUST HAVE
2. `Log_Level__c` - MUST HAVE
3. `Stage_Number__c` - MUST HAVE
4. `Component__c` - Nice to have
5. `Details__c` - Nice to have

### Optional (Add Later if Needed):
6. `Execution_Time_MS__c` - Performance tracking
7. `Record_Count__c` - Quick metrics
8. `Success__c` - Binary success filter

---

## Impact Assessment

### Benefits:
✅ Can see actual errors instead of silent failures  
✅ Can debug Stage08 loader issues immediately  
✅ Can track pipeline execution in detail  
✅ Can identify slow stages  
✅ Can audit what happened in each run  

### Risks:
⚠️ Increases data storage (logs accumulate)  
⚠️ Need to add cleanup/archival process eventually  

### Mitigation:
- Keep logs for 30 days, delete older
- Or: Keep only ERROR level logs long-term, delete INFO/DEBUG after 7 days

---

## Deployment Plan

### Step 1: Deploy Minimum Fields (5 min)
```bash
sf project deploy start -o agentictso \
  -d force-app/main/default/objects/PF_Run_Log__c/fields/Log_Message__c.field-meta.xml \
  -d force-app/main/default/objects/PF_Run_Log__c/fields/Log_Level__c.field-meta.xml \
  -d force-app/main/default/objects/PF_Run_Log__c/fields/Stage_Number__c.field-meta.xml \
  -d force-app/main/default/objects/PF_Run_Log__c/fields/Component__c.field-meta.xml \
  -d force-app/main/default/objects/PF_Run_Log__c/fields/Details__c.field-meta.xml
```

### Step 2: Test PromptFactoryLogger
Run diagnostic script to verify logging works

### Step 3: Run Prompt Factory
See actual error messages in logs!

---

## Alternative: Simpler Approach

If you don't want 5 fields, we could do **just 2 essentials**:

1. **`Log_Message__c`** - Long Text (10K) - The log content
2. **`Log_Level__c`** - Picklist - ERROR/INFO/WARNING

Then query:
```sql
SELECT Log_Message__c, Log_Level__c, CreatedDate
FROM PF_Run_Log__c
WHERE Run__c = :runId
  AND Log_Level__c = 'ERROR'
```

This gives us 80% of the value with minimal complexity.

---

## My Recommendation

**Deploy all 5 fields** (Log_Message, Log_Level, Stage_Number, Component, Details).

**Why**: 
- They're already defined (no extra work)
- Minimal storage impact
- Maximum debugging capability
- Can add optional fields later if needed

**Don't deploy** the 3 optional ones yet (Execution_Time_MS, Record_Count, Success).  
We can add those later if we find we need them.

---

## Questions for You

1. **Approve all 5 fields?** (Log_Message, Log_Level, Stage_Number, Component, Details)
2. **Or just the 2 essentials?** (Log_Message, Log_Level)
3. **Want the 3 optional ones too?** (Execution_Time, Record_Count, Success)
4. **Any other fields you think we need?**

---

**Waiting for your approval before deploying!** 🚀

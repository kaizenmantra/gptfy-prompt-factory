# Overnight Action Plan - Fix Builder Injection

**Date**: January 22, 2026 11:16 UTC  
**Status**: 🔴 **CRITICAL ISSUES TO FIX**  
**User Status**: Sleeping - work autonomously  

---

## 🔴 Critical Issues

### Issue 1: Builder Prompts Not Injecting ⚠️ P0
**Problem**: Prompts generated are ~10KB instead of ~40KB (missing 30KB of builder content)
**Impact**: No Evidence Binding rules, no risk patterns, no quality guidance
**User Feedback**: "Not happy - builders not getting incorporated"

### Issue 2: Poor Output Quality ⚠️ P0  
**Problem**: Generic language ("the CFO" instead of "Sarah Johnson")
**Impact**: Quality score ~50/100 instead of 75/100 target
**User Feedback**: "Overall output terrible"

---

## 🎯 Root Cause Analysis Completed

### What I Know FOR SURE:

✅ **Builders exist**: 6 Active builders with full content  
✅ **Queries work in isolation**: test_builder_queries.apex returns all 6  
✅ **Stage08 has loading code**: loadQualityRules(), loadPatterns(), etc.  
✅ **Code is deployed**: Stage08 last modified 11:13 UTC  
❌ **Pipeline prompts have NO builders**: All tests after 10:11 UTC = 0 builder headers  
✅ **MVP test (09:46) HAD builders**: Lines 128, 182 show "=== Evidence Binding ===" headers  

### Timeline of Builder Deletion:
```
09:46 UTC - MVP prompt created (old builders) → HAS builder headers ✅
10:11 UTC - DELETED old builders, CREATED new ones
10:11+ UTC - All tests → NO builder headers ❌
```

### Critical Discovery:
**MVP test used OLD builders (created before 10:11)**  
**New builders (created at 10:11) have NEVER been injected successfully**

This suggests: **Something changed when we recreated the builders**

---

## 🔬 Diagnostic Plan (Execute Tonight)

### Phase 1: Verify the OLD builders are truly gone
```sql
SELECT Id, Name, CreatedDate, IsDeleted 
FROM ccai__AI_Prompt__c 
WHERE Name IN ('Evidence Binding Rules v2', 'Risk Assessment Pattern')
AND CreatedDate < 2026-01-22T10:11:00Z
```

If old builders still exist → Stage08 might be loading them (and they're inactive/deleted)

---

### Phase 2: Test builder queries in EXACT pipeline context
Create a queueable job that mimics Stage08:

```apex
public class TestBuilderLoadInQueue implements Queueable {
    public void execute(QueueableContext ctx) {
        // Exact same query as Stage08
        List<ccai__AI_Prompt__c> rules = [
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND Category__c = 'Quality Rule'
              AND ccai__Status__c = 'Active'
        ];
        
        // Log to a debug object we CAN query
        insert new PF_Run__c(
            Object__c = 'Test',
            Status__c = 'Completed',
            Error_Message__c = 'TEST: Found ' + rules.size() + ' builders in Queueable'
        );
    }
}
```

---

### Phase 3: Check if Category__c is accessible in Queueable
```apex
Schema.DescribeFieldResult field = ccai__AI_Prompt__c.Category__c.getDescribe();
// In Queueable context, isAccessible() might return false
```

---

### Phase 4: Check RecordType.DeveloperName in Queueable
```apex
// Try direct ID filter instead of DeveloperName
SELECT Id FROM RecordType 
WHERE SObjectType = 'ccai__AI_Prompt__c' 
  AND DeveloperName = 'Builder'
  
// Then use:
WHERE RecordTypeId = '012...' instead of WHERE RecordType.DeveloperName = 'Builder'
```

---

### Phase 5: Simplify Stage08 query (Remove ALL filters)
Test if ANY builders are accessible:

```apex
List<ccai__AI_Prompt__c> test = [
    SELECT Id, Name 
    FROM ccai__AI_Prompt__c 
    WHERE Name LIKE '%Evidence Binding%'
    LIMIT 1
];
// If this returns 0, object-level access issue
```

---

## 🔧 Fix Strategies (In Priority Order)

### Strategy 1: Use RecordType ID Instead of DeveloperName (MOST LIKELY)
**Hypothesis**: `RecordType.DeveloperName` relationship queries fail in Queueable  
**Fix**: Query RecordType ID once, cache it, use direct ID filter  
**Test**: Will implement and test tonight

---

### Strategy 2: Store Builder IDs in Custom Setting
**Hypothesis**: Dynamic queries are the problem  
**Fix**: Create custom setting with builder IDs, query by ID list  
**Test**: Fallback if Strategy 1 fails

---

### Strategy 3: Move Builders to Static Resources
**Hypothesis**: Database access is restricted in Queueable  
**Fix**: Export builder content to Static Resources, load from there  
**Test**: Last resort - defeats purpose of database-driven architecture

---

## 📋 Tonight's Execution Checklist

- [ ] Test Strategy 1: RecordType ID caching
- [ ] If fails, test Strategy 2: Custom Setting
- [ ] If fails, test Strategy 3: Static Resources
- [ ] Once builders inject, verify quality (specificity rules)
- [ ] Run end-to-end test
- [ ] Document solution
- [ ] Commit all changes
- [ ] Create morning summary

**Target**: Working builder injection by morning ✅

---

## 📊 Success Criteria

### Must Have (P0):
- [ ] Pipeline prompts include all 6 builder sections
- [ ] Prompt size increases from 10KB to 40KB
- [ ] Headers visible: "=== Evidence Binding Rules v2 ==="
- [ ] Headers visible: "=== Risk Assessment Pattern ==="
- [ ] Headers visible: "=== Next Best Action Pattern ==="

### Should Have (P1):
- [ ] Output uses actual names ("Sarah Johnson" not "the CFO")
- [ ] Output uses specific dates ("by Friday, Jan 24" not "soon")
- [ ] Quality score increases to 70+/100

---

## 🌙 Overnight Work Plan

**Hours 1-2**: Debug and fix builder injection  
**Hours 2-3**: Test and verify quality  
**Hour 3**: Document and commit  

**Expected Completion**: 2-4 hours  
**Confidence Level**: High (I know what to test)  

---

**Starting diagnostics now...**

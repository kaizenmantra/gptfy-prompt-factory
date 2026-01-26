# Stage 10-12 Callout Architecture Proposal

**Date:** January 26, 2026
**Author:** Claude (AI Assistant)
**Status:** Draft - Awaiting Review
**Branch:** `feature/v2.6-future-callout`

---

## Executive Summary

The Prompt Factory pipeline fails at Stage 10 due to Salesforce's "DML before callout" limitation. This document proposes using `@future(callout=true)` to execute Stages 10-12 in a fresh transaction context, with batch status updates at completion.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Technical Background](#technical-background)
3. [Investigation & Findings](#investigation--findings)
4. [Proposed Solution](#proposed-solution)
5. [Implementation Details](#implementation-details)
6. [Visual Feedback Considerations](#visual-feedback-considerations)
7. [Alternative Approaches](#alternative-approaches)
8. [Risks & Mitigations](#risks--mitigations)
9. [Recommendation](#recommendation)

---

## Problem Statement

### Current Failure

The Prompt Factory pipeline fails at Stage 10 with the error:

```
System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out.
```

### Root Cause

- **Stage 9** (`Stage09_CreateAndDeploy`) performs DML operations:
  - Creates `ccai__Dynamic_Content_Map__c` record
  - Creates `ccai__AI_Prompt__c` record
  - Updates the prompt with assembled content
  - Activates the prompt

- **Stage 10** (`Stage10_TestExecution`) needs to make an HTTP callout to the GPTfy API to execute the newly created prompt.

- **Salesforce Limitation**: HTTP callouts cannot be made after DML operations in the same transaction.

### Impact

- Pipeline cannot complete end-to-end
- Quality audit (Stage 12) never runs
- Users cannot test generated prompts automatically

---

## Technical Background

### Salesforce Callout Rules

1. **No callouts after DML**: Once any DML operation (insert, update, delete) occurs in a transaction, HTTP callouts are blocked for the remainder of that transaction.

2. **Fresh transaction = fresh slate**: New transactions (via @future, Queueable, Schedulable, Batch) start with no prior DML, allowing callouts.

3. **Platform Events exception**: `EventBus.publish()` is a special form of DML that does NOT block subsequent callouts.

### Current Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PROMPT FACTORY PIPELINE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Stages 1-4 (Queueable Chain, depth 1-4)                               │
│       │                                                                 │
│       ▼                                                                 │
│  ChainBreaker.scheduleStage(5)  ← Schedulable resets depth to 0        │
│       │                                                                 │
│       ▼                                                                 │
│  Stages 5-9 (Queueable Chain, depth 1-5)                               │
│       │                                                                 │
│       ▼                                                                 │
│  Stage 9: Creates prompt (DML) ────────────────────┐                   │
│       │                                             │                   │
│       ▼                                             │                   │
│  Stage 10: Execute prompt (CALLOUT) ◄──── BLOCKED ─┘                   │
│       │                                                                 │
│       ▼                                                                 │
│  Stage 11: Safety validation                                           │
│       │                                                                 │
│       ▼                                                                 │
│  Stage 12: Quality audit (CALLOUT to Claude AI)                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Existing Chain Breaking Mechanism

The pipeline already uses `PromptFactoryChainBreaker` (Schedulable) to reset the Queueable chain depth after Stage 4. This prevents hitting the ~5 chain depth limit.

---

## Investigation & Findings

### Approaches Tested

#### 1. GPTfy Invocable Direct Call (After DML)

**Test:** Call `ccai.AIPromptProcessingInvokable.processRequest()` directly after DML.

**Result:** ❌ Failed

```
Response: {"error" : {"message" : "An error occured, please contact your System Admin."}}
Callouts: 0 (blocked)
```

GPTfy's invocable returns an error JSON when it cannot make the callout.

#### 2. GPTfy Invocable Without Prior DML

**Test:** Call the invocable with no prior DML in the transaction.

**Result:** ✅ Success

```
Status: Success
Response Length: 3,482 chars
Content: <div style="background:#F3F3F3...  (actual HTML)
Callouts: 1 (successful)
```

This confirms the invocable works correctly when callouts are allowed.

#### 3. @future(callout=true) After DML

**Test:** Perform DML, then call an `@future(callout=true)` method that invokes GPTfy.

**Result:** ✅ Success

```apex
// Test code
Account testAcc = new Account(Name='DML Test');
insert testAcc;  // DML first
FutureCalloutTest.executePromptAsync(promptRequestId, recordId);  // @future enqueued
delete testAcc;
```

```
DML completed: 001QH000024rKBqYAM
@future enqueued (will execute async)
---
[Later, in @future context]
Status: Processed
Response Length: 6,909 chars
Content: Real HTML output
```

**Key Finding:** The `@future` method executes in a completely fresh transaction with no prior DML, so the callout succeeds.

### Test Evidence

| Scenario | Callouts Made | Response |
|----------|---------------|----------|
| Invocable after DML | 0 (blocked) | Error JSON (79 chars) |
| Invocable without DML | 1 (success) | HTML (3,482 chars) |
| @future after DML | 1 (success) | HTML (6,909 chars) |

**Proof-of-concept class deployed:** `FutureCalloutTest.cls`

---

## Proposed Solution

### Overview

Use `@future(callout=true)` to execute Stages 10-12 in a single fresh transaction after Stage 9 completes.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     PROPOSED PIPELINE ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Stages 1-4 (Queueable Chain)                                          │
│       │                                                                 │
│       ▼                                                                 │
│  ChainBreaker.scheduleStage(5)  ← Resets depth                         │
│       │                                                                 │
│       ▼                                                                 │
│  Stages 5-9 (Queueable Chain)                                          │
│       │                                                                 │
│       │  Stage 9 completes with:                                       │
│       │  - promptId                                                     │
│       │  - promptRequestId                                              │
│       │  - sampleRecordId                                               │
│       │                                                                 │
│       ▼                                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  @future(callout=true) executeStages10to12(...)                 │   │
│  │                                                                  │   │
│  │  // Fresh transaction - no prior DML                            │   │
│  │                                                                  │   │
│  │  1. Stage 10: Call GPTfy API (CALLOUT #1)                       │   │
│  │     └─► Returns HTML output                                      │   │
│  │                                                                  │   │
│  │  2. Stage 11: Safety validation (no callout)                    │   │
│  │     └─► Validates output content                                 │   │
│  │                                                                  │   │
│  │  3. Stage 12: Call Claude AI (CALLOUT #2)                       │   │
│  │     └─► Returns quality scores                                   │   │
│  │                                                                  │   │
│  │  4. Update PF_Run__c with all results (DML - after callouts)    │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why This Works

1. **@future breaks the chain**: The `@future` method runs in a completely new transaction with chain depth = 0 and no prior DML.

2. **Multiple callouts allowed**: Within the `@future` method, we can make multiple HTTP callouts (GPTfy + Claude) as long as we do ALL callouts BEFORE any DML.

3. **DML at the end**: After all callouts complete, we perform a single DML operation to update `PF_Run__c` with all results.

---

## Implementation Details

### New Class: Stage10to12FutureJob

```apex
/**
 * @description Executes Stages 10-12 in a @future context to avoid DML/callout conflicts
 */
public class Stage10to12FutureJob {

    /**
     * @description Execute stages 10-12 with callouts
     * @param runId The PF_Run__c record ID
     * @param promptRequestId The GPTfy prompt request ID
     * @param sampleRecordId The sample record ID to test against
     */
    @future(callout=true)
    public static void execute(Id runId, String promptRequestId, String sampleRecordId) {
        List<Map<String,Object>> stageLogs = new List<Map<String,Object>>();
        String outputHtml;
        Map<String,Object> qualityScores;

        try {
            // ═══════════════════════════════════════════════════════════
            // STAGE 10: Execute GPTfy Prompt (CALLOUT #1)
            // ═══════════════════════════════════════════════════════════
            stageLogs.add(createLog(10, 'Started', null));

            ccai.AIPromptProcessingInvokable.RequestWrapper wrap =
                new ccai.AIPromptProcessingInvokable.RequestWrapper();
            wrap.promptRequestId = promptRequestId;
            wrap.recordId = sampleRecordId;
            wrap.customPromptCommand = '';

            List<ccai.AIPromptProcessingInvokable.ResponseWrapper> responses =
                ccai.AIPromptProcessingInvokable.processRequest(
                    new List<ccai.AIPromptProcessingInvokable.RequestWrapper>{wrap}
                );

            if (responses == null || responses.isEmpty()) {
                throw new Stage10to12Exception('No response from GPTfy');
            }

            ccai.AIPromptProcessingInvokable.ResponseWrapper resp = responses[0];

            if (resp.responseBody == null || resp.responseBody.contains('"error"')) {
                throw new Stage10to12Exception('GPTfy error: ' + resp.responseBody);
            }

            outputHtml = resp.responseBody;
            stageLogs.add(createLog(10, 'Completed', 'HTML length: ' + outputHtml.length()));

            // ═══════════════════════════════════════════════════════════
            // STAGE 11: Safety Validation (NO CALLOUT)
            // ═══════════════════════════════════════════════════════════
            stageLogs.add(createLog(11, 'Started', null));

            // Validate output doesn't contain prohibited content
            Boolean safetyPassed = validateSafety(outputHtml);

            if (!safetyPassed) {
                throw new Stage10to12Exception('Safety validation failed');
            }

            stageLogs.add(createLog(11, 'Completed', 'Safety check passed'));

            // ═══════════════════════════════════════════════════════════
            // STAGE 12: Quality Audit (CALLOUT #2)
            // ═══════════════════════════════════════════════════════════
            stageLogs.add(createLog(12, 'Started', null));

            // Call Claude AI for quality scoring
            qualityScores = Stage12_QualityAudit.auditQuality(runId, outputHtml);

            stageLogs.add(createLog(12, 'Completed',
                'Score: ' + qualityScores.get('overallScore')));

            // ═══════════════════════════════════════════════════════════
            // FINAL: Update PF_Run__c (DML - after all callouts)
            // ═══════════════════════════════════════════════════════════
            updateRunRecord(runId, stageLogs, outputHtml, qualityScores, null);

        } catch (Exception e) {
            stageLogs.add(createLog(0, 'Error', e.getMessage()));
            updateRunRecord(runId, stageLogs, outputHtml, qualityScores, e.getMessage());
        }
    }

    private static Map<String,Object> createLog(Integer stage, String status, String details) {
        return new Map<String,Object>{
            'stage' => stage,
            'status' => status,
            'details' => details,
            'timestamp' => System.now()
        };
    }

    private static Boolean validateSafety(String html) {
        // Implement safety checks
        return true;
    }

    private static void updateRunRecord(Id runId, List<Map<String,Object>> logs,
                                         String html, Map<String,Object> scores,
                                         String errorMsg) {
        PF_Run__c run = [SELECT Id FROM PF_Run__c WHERE Id = :runId];
        run.Current_Stage__c = errorMsg != null ? 'Failed' : 'Completed';
        run.Stage_10_12_Logs__c = JSON.serialize(logs);
        run.Output_HTML__c = html;
        run.Quality_Score__c = scores != null ? (Decimal)scores.get('overallScore') : null;
        run.Error_Message__c = errorMsg;
        run.Completed_Date__c = System.now();
        update run;
    }

    public class Stage10to12Exception extends Exception {}
}
```

### Modification to Stage 9

At the end of `Stage09_CreateAndDeployJob`, instead of continuing to Stage 10 directly:

```apex
// Current (fails):
// System.enqueueJob(new Stage10_TestExecutionJob(runId));

// Proposed:
Stage10to12FutureJob.execute(
    runId,
    promptRequestId,
    sampleRecordId
);
```

---

## Visual Feedback Considerations

### The Challenge

Within the `@future` method, we cannot update `PF_Run__c` between callouts:

```apex
@future(callout=true)
public static void execute(...) {
    updateRunStage(10, 'In Progress');  // DML ❌
    callGPTfy();                         // CALLOUT - blocked by DML above!
}
```

### User Experience Impact

| Stage | With Current Queueables | With Proposed @future |
|-------|------------------------|----------------------|
| 1-9 | Real-time updates | Real-time updates |
| 10 | N/A (fails) | Batch update at end |
| 11 | N/A (fails) | Batch update at end |
| 12 | N/A (fails) | Batch update at end |

**User sees:**
```
Stage 9: Complete ✓
[waiting 20-40 seconds]
Stage 10: Complete ✓  ← All appear
Stage 11: Complete ✓  ← simultaneously
Stage 12: Complete ✓  ← when @future finishes
```

### Potential Enhancement: Platform Events

If real-time feedback for Stages 10-12 is required, we can add Platform Events:

```apex
@future(callout=true)
public static void execute(...) {
    // Platform Events ARE allowed before callouts
    EventBus.publish(new Pipeline_Status__e(Stage__c=10, Status__c='In Progress'));

    String html = callGPTfy();  // CALLOUT - works!

    EventBus.publish(new Pipeline_Status__e(Stage__c=10, Status__c='Completed'));
    // ... continue
}
```

**Implementation cost:**
- Create 1 Platform Event object (`Pipeline_Status__e`)
- Add ~10 lines of publish code in `Stage10to12FutureJob`
- Add `empApi` subscription in LWC (~20 lines)

**Recommendation:** Start without Platform Events. Add them later if users request real-time feedback for Stages 10-12.

---

## Alternative Approaches

### Option A: Queueable + ChainBreaker for Each Stage

```
Stage 9 → ChainBreaker → Stage 10 (Queueable with callout)
                              → ChainBreaker → Stage 11 (Queueable)
                                                    → ChainBreaker → Stage 12 (Queueable with callout)
```

**Pros:**
- Real-time updates per stage
- Follows existing pattern

**Cons:**
- Slow (each ChainBreaker adds ~5-60 second delay)
- Complex orchestration
- More points of failure

### Option B: Batch Apex

Use `Database.Batchable` with `Database.AllowsCallouts` for Stages 10-12.

**Pros:**
- Higher governor limits
- Good for bulk operations

**Cons:**
- Overkill for single-record processing
- Batch scheduling adds latency
- More complex than @future

### Option C: External Orchestration (Python)

Keep using the Python test harness (`tests/v26/run_innovatek_test.py`) as the primary execution path.

**Pros:**
- Already working
- Full control over timing and retries
- Achieved 100/100 quality scores

**Cons:**
- External dependency
- Not native Salesforce
- Requires separate infrastructure

### Comparison Matrix

| Approach | Latency | Real-time UI | Complexity | Callouts |
|----------|---------|--------------|------------|----------|
| **@future (proposed)** | ~30s | Batch | Low | ✅ |
| Queueable + ChainBreaker | ~3-5min | Per stage | High | ✅ |
| Batch Apex | ~1-2min | None | Medium | ✅ |
| Python external | ~30s | Via polling | Medium | N/A |
| Platform Events + @future | ~30s | Real-time | Medium | ✅ |

---

## Risks & Mitigations

### Risk 1: @future Governor Limits

**Risk:** @future has a limit of 50 calls per transaction and 250,000 per 24 hours.

**Mitigation:** Each pipeline run only calls @future once. Would need 250,000 daily pipeline runs to hit the limit.

### Risk 2: @future Timeout

**Risk:** @future methods have a 60-second timeout. If GPTfy + Claude take too long, the job fails.

**Mitigation:**
- GPTfy typically responds in 10-20 seconds
- Claude typically responds in 5-10 seconds
- Total ~30 seconds, well under 60-second limit
- Add timeout handling and retry logic if needed

### Risk 3: No Real-time Feedback

**Risk:** Users may be confused by the 20-40 second gap with no updates.

**Mitigation:**
- Add loading indicator in LWC: "Executing stages 10-12..."
- Consider Platform Events for future enhancement
- Document expected behavior

### Risk 4: Error Handling

**Risk:** If @future fails, there's no automatic retry.

**Mitigation:**
- Comprehensive try/catch with error logging to PF_Run__c
- Add manual "Retry" button in LWC
- Consider Queueable (which can self-retry) if reliability is critical

---

## Recommendation

### Implement in Phases

**Phase 1 (Immediate):**
1. Create `Stage10to12FutureJob` class with `@future(callout=true)`
2. Modify Stage 9 to call the @future method instead of enqueueing Stage 10
3. Update LWC to show "Processing stages 10-12..." during @future execution
4. Test end-to-end with Innovatek account

**Phase 2 (If Needed):**
1. Add Platform Events for real-time Stage 10-12 updates
2. Add `empApi` subscription to LWC

**Phase 3 (Future):**
1. Add retry mechanism for failed @future jobs
2. Consider Queueable migration if @future limits become an issue

### Success Criteria

- [ ] Pipeline completes end-to-end without "DML before callout" error
- [ ] Stage 10 successfully executes GPTfy prompt
- [ ] Stage 12 successfully scores output quality
- [ ] PF_Run__c updated with final results
- [ ] LWC displays completion status

---

## Appendix

### A. Test Evidence

**Proof-of-concept class:** `force-app/main/default/classes/FutureCalloutTest.cls`

**Test execution log:**
```
12:53:15 | DML completed: 001QH000024rKBqYAM
12:53:15 | @future enqueued (will execute async)
12:53:15 | Test account cleaned up
---
[Async @future execution]
Status: Processed
Response ID: a0IQH000001pxez2AA
Response Length: 6,909 chars
Content: <div style="background:#F3F3F3...
```

### B. Related Files

| File | Purpose |
|------|---------|
| `Stage09_CreateAndDeploy.cls` | Stage 9 - creates prompt (DML) |
| `Stage10_TestExecution.cls` | Current Stage 10 (fails) |
| `Stage12_QualityAudit.cls` | Stage 12 - Claude AI scoring |
| `PromptFactoryChainBreaker.cls` | Existing chain depth reset mechanism |
| `FutureCalloutTest.cls` | Proof-of-concept @future class |
| `tests/v26/run_innovatek_test.py` | Python test harness (working alternative) |

### C. Salesforce Documentation References

- [Invoking Callouts Using Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm)
- [Future Methods](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm)
- [Platform Events Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-26 | Claude | Initial proposal |

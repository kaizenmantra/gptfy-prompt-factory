# Stage 10-12 Callout Architecture Proposal

**Date:** January 26, 2026
**Author:** Claude (AI Assistant)
**Status:** Draft - Awaiting Review
**Branch:** `feature/v2.6-future-callout`

---

## Executive Summary

The Prompt Factory pipeline fails at Stage 10 due to Salesforce's "DML before callout" limitation. This document proposes using a consolidated asynchronous transaction (Queueable or @future) to execute Stages 10-12 in a fresh transaction context, with batch status updates at completion and proactive UI feedback.

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
10. [Consolidated UX Strategy (LWC Spinner)](#consolidated-ux-strategy)

---

## 1. Problem Statement

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

## 2. Technical Background

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

## 3. Investigation & Findings

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

---

## 4. Proposed Solution

### Overview

Consolidate Stages 10-12 into a single fresh transaction (Queueable or @future) after Stage 9 completes. This avoids DML/callout conflicts by performing all callouts before any DML in the new transaction.

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
│       │  Stage 9 completes with DML, then triggers:                     │
│       │                                                                 │
│       ▼                                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Stage10_12_ConsolidatedJob                                     │   │
│  │                                                                  │   │
│  │  // Fresh transaction - no prior DML                            │   │
│  │                                                                  │   │
│  │  1. Stage 10: Call GPTfy API (CALLOUT #1)                       │   │
│  │  2. Stage 11: Safety validation (In-memory)                     │   │
│  │  3. Stage 12: Call Claude AI (CALLOUT #2)                       │   │
│  │  4. FINAL DML: Update PF_Run__c with all results                │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Implementation Details

### New Class: Stage10_12_ConsolidatedJob

```apex
public class Stage10_12_ConsolidatedJob implements Queueable, Database.AllowsCallouts {
    private Id runId;
    
    public void execute(QueueableContext context) {
        // 1. Stage 10 Callout
        // 2. Stage 11 Validation
        // 3. Stage 12 Callout
        // 4. Update PF_Run__c (DML)
    }
}
```

---

## 6. Visual Feedback Considerations

### The Challenge

Within the consolidated job, we cannot update Stage records between callouts without triggering the "DML before callout" error again.

### User Experience Impact

The user sees Stages 1-9 update in real-time, then a 30-45 second pause while Stages 10-12 execute, followed by a final completion update.

---

## 7. Alternative Approaches

- **Option A**: Queueable Chaining (Current - Slow)
- **Option B**: Platform Events (Complex Metadata)
- **Option C**: Consolidated Job + LWC Spinner (Recommended)

---

## 8. Risks & Mitigations

- **Timeout**: @future/Queueable have 60-120s timeout. Mitigation: GPTfy/Claude typically take <30s total.
- **UI Freeze**: User may think it's stuck. Mitigation: Add proactive "Finalizing" state in LWC.

---

## 9. Recommendation

Implement the **Consolidated Job** for Stages 10-12 to minimize latency and simplify the transaction model, while updating the LWC UI to provide a proactive "Optimizing results..." message during the final execution phase.

---

## 10. Consolidated UX Strategy (LWC Spinner)

### The Challenge

With the Stages 10-12 consolidated into a single transaction, the LWC will not receive incremental stage updates for the final 30-45 seconds. To avoid a "frozen" UI, we will implement a proactive feedback mechanism.

### Step 1: Stage 9 Handoff Update

At the end of Stage 9, the run record is updated, and the consolidated job is enqueued. The LWC will detect that Stage 9 is complete but the overall run is still `In Progress`.

### Step 2: LWC Progress Tracking Enhancements

Update `pfProgressTracker.js` to handle a new "Processing" visual state.

- **Visual State**: Stage 10 shows as "Running" (Amber pulse).
- **Dynamic Message**: Change the footer instruction to: *"Optimizing results and auditing quality... (Est. 30s)"*

### Step 3: PromptFactoryWizard Polling Logic

Modify `refreshStatus()` in `promptFactoryWizard.js` to provide explicit feedback during this phase.

```javascript
if (this.currentStage >= 9 && this.pipelineStatus === 'running') {
    this.customLoadingMessage = 'Performing AI Test Execution & Quality Audit...';
    // Logic to visually highlight phase 4
}
```

### Step 4: Consolidated Job Completion

Once the `Stage10_12_ConsolidatedJob` completes its single DML update to `PF_Run__c`, the next LWC heartbeat poll will receive the final status and score, instantly resolving all final stages to Green/Complete.

---

## Appendix

### A. Test Evidence

**Proof-of-concept class:** `force-app/main/default/classes/FutureCalloutTest.cls`

### B. Related Files

| File | Purpose |
|------|---------|
| `Stage09_CreateAndDeploy.cls` | Stage 9 - creates prompt (DML) |
| `Stage10_12_ConsolidatedJob.cls` | NEW: Consolidated Stages 10-12 |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-26 | Claude | Initial proposal |
| 1.1 | 2026-01-26 | Gemini | Added Consolidated UX Strategy (LWC Spinner) section |

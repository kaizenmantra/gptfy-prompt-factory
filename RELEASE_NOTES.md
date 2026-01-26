# Release Notes

## Version 2.7: Distributed State & AI Testing Architecture
**Release Date:** 2026-01-26
**Branches Merged:** `feature/v2.6-future-callout` → `main`

### 🚀 Key Improvements

#### 1. Distributed State Architecture (Prompt Assembly Regression Fix)
*   **Problem:** Previous "pass-through" architecture hit Field Size Limits (131KB) when passing large prompts between stages. File-logging workaround hit ContentVersion Limits (~2000 versions/day).
*   **Solution:** Implemented **Distributed State Architecture**.
    *   State is no longer passed as one giant blob.
    *   `PipelineState.read()` now **aggregates** `Output_Data__c` from all completed stages in memory.
    *   Stage 1 holds Context, Stage 2 holds Strategy, Stage 8 holds Prompt.
    *   **Result:** Unlimited total pipeline context capacity, with no file creation overhead.

#### 2. Consolidated AI Testing (DML-before-Callout Fix)
*   **Problem:** Pipeline failed at Stage 10 because Salesforce blocks HTTP callouts after DML operations in the same transaction.
*   **Solution:** Created `Stage10_12_ConsolidatedJob` (Queueable).
    *   Chain: Stage 9 (DML) → Enqueue Job (Reset Transaction) → Stage 10 (Callout) → Stage 11 (Safety) → Stage 12 (Quality).
    *   **Result:** Reliable automated AI testing and quality auditing without "Uncommitted Work" errors.

#### 3. Platform Event Logging
*   **Problem:** Logging to `PF_Run_Log__c` (DML) blocked callouts in critical stages.
*   **Solution:** Switched to **Platform Events** (`PF_Log_Event__e`) for logging.
    *   Logs are published via EventBus (non-DML) and inserted asynchronously called by a trigger.
    *   **Result:** Callout-safe logging across the entire pipeline.

### 🐛 Bug Fixes
*   **Prompt Truncation:** Fixed specific regression in `Stage08` where prompt content was being effectively silently truncated due to field limits. Optimizations in `Stage08` payload ensure the assembled prompt always fits.
*   **Duplicate logging:** Fixed issue where logs were being written to both file and record, causing confusion.

### 🛠 Technical details
*   **`PipelineState.cls`**: Updated `read()` to use distributed aggregation. `ENABLE_FILE_LOGGING` disabled by default.
*   **`Stage08_PromptAssembly.cls`**: Optimized `result.outputs` to remove redundant prompt copies.
*   **`Stage10_12_ConsolidatedJob.cls`**: New orchestrator for the testing phase.
*   **`PromptFactoryLogger.cls`**: Updated to use Platform Events.

---

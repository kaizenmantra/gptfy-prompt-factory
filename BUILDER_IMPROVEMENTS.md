# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization, field selection, and output quality features.
All architecture, decisions, tasks, and progress tracked here.

---

## CURRENTLY ACTIVE WORK (Check Before Starting)

| Model | Task | File Being Modified | Started |
|-------|------|---------------------|---------|
| Opus | 4.1+ | Stage08, LWC | 2026-01-24 |

**Status:** V2.4 IN PROGRESS - Builder refactoring and LWC enhancements. V2.3 merged to main.

---

## Release Strategy

### Current Branch: `feature/v2.4-builder-refactor`
**Status:** Active development

### Version History

| Version | Branch | Status | Description |
|---------|--------|--------|-------------|
| V1.1 | main | ✅ Released | Builder prompt injection (Run ID a0gQH000005GHurYAG) |
| V2.0 | feature/builder-improvements | ✅ Complete | Meta-prompt architecture, LLM metadata, field validation |
| V2.1 | feature/v2.1-enhancements | ✅ Complete | Visual diversity, parent traversals, builder library |
| V2.2 | feature/v2.2-schema-intelligence | ⚠️ Abandoned | Schema enrichment attempted, pipeline state passing broke. See Decision Log. |
| V2.3 | feature/v2.3-json-state | ✅ Complete | JSON file-based state (PipelineState.cls), merge field notation fixes |
| V2.4 | feature/v2.4-builder-refactor | 🔨 Active | Builder Type migration, Output Rules builder, LWC enhancements |

### V2.2 Abandonment Note

The V2.2 branch attempted to:
1. Add schema enrichment (helpText, field density, categories)
2. Add parent field traversal support
3. Refactor pipeline data passing (remove pass-through pattern)

**What broke:** The pipeline refactoring (Phase 2F) removed pass-through from stages and tried to accumulate data from all previous stage records. This was architecturally sound but fragile in practice - Stage 7 stopped receiving `selectedFields` from Stage 5.

**Root cause:** Complex accumulation logic across 12 stage records, JSON serialization/deserialization, field limits, and no easy way to debug.

**Solution:** V2.3 implements a simple JSON file approach. One file per run, all stages read/write to it. After this foundation is solid, we'll cherry-pick the valuable V2.2 features (schema enrichment, parent fields, grandchild discovery).

---

## MODEL INSTRUCTIONS (READ THIS FIRST)

When you start working on this project, follow these rules:

1. **Read this entire file** to understand the context and architecture
2. **Check the Task Queue below** - find the first task with status `not_started`
3. **Check if the task is assigned to you:**
   - If task says `Sonnet` and you are Sonnet → Work on it
   - If task says `Opus` and you are Opus → Work on it
   - If task is assigned to the OTHER model → **STOP** and tell the user
4. **While working:** Update task status to `in_progress`
5. **When done:** Update task status to `done`, then check next task
6. **If you hit a blocker:** Update status to `blocked` with notes, alert user
7. **If next task is for other model:** Stop and say:

```
✋ HANDOFF NEEDED
I've completed [task X]. The next task requires [Opus/Sonnet].
Please switch models and say "Continue" to proceed.
```

### COMMIT AFTER EACH TASK

After completing each task (or group of related small tasks), commit your work:

```bash
./scripts/gitcommit.sh "feat: Task X - Brief description of what was done"
```

### DEPLOY TO SALESFORCE

When a task involves Apex changes, deploy using:

```bash
sf project deploy start -o agentictso -d force-app/main/default/classes/ClassName.cls -d force-app/main/default/classes/ClassName.cls-meta.xml
```

---

## Key Files Reference

### Apex Classes
| File | Purpose |
|------|---------|
| `PipelineState.cls` | **NEW V2.3** - JSON file state management (read/write/log) |
| `PromptFactoryPipeline.cls` | Pipeline orchestrator (will use PipelineState) |
| `Stage01_Init.cls` | Pipeline initialization |
| `Stage02_Research.cls` | Company/industry research |
| `Stage03_SchemaDiscovery.cls` | Object/field discovery |
| `Stage04_DataProfiling.cls` | Sample data profiling, MultiSampleProfile |
| `Stage05_FieldSelection.cls` | LLM-assisted field selection |
| `Stage06_ConfigurationValidation.cls` | Validate FLS and access |
| `Stage07_TemplateDesign.cls` | Analysis brief generation, prompt metadata |
| `Stage08_PromptAssembly.cls` | Meta-prompt assembly, builder loading |
| `Stage09_CreateAndDeploy.cls` | DCM and Prompt creation |
| `Stage10_TestExecution.cls` | Test prompt execution |
| `Stage11_SafetyValidation.cls` | Safety checks |
| `Stage12_QualityAudit.cls` | Quality scoring |
| `SchemaHelper.cls` | Schema utilities |
| `DCMBuilder.cls` | Data context mapping builder |
| `PromptBuilder.cls` | AI Prompt record creation |

### LWC Components
| File | Purpose |
|------|---------|
| `pfRunDetail/` | Run detail view - **V2.3: Add State File tab** |
| `pfInputForm/` | Pipeline input form |
| `pfStageProgress/` | Stage progress indicator |

### Documentation
| File | Purpose |
|------|---------|
| `BUILDER_IMPROVEMENTS.md` | This file - master tracker |
| `docs/designs/META_PROMPT_DESIGN.md` | Meta-prompt 6-section architecture |
| `docs/designs/MULTI_SAMPLE_DESIGN.md` | Multi-sample profiling architecture |
| `docs/UI_TOOLKIT.md` | UI component library for dashboards |

---

## V2.1 Task Queue

### Phase 1A: Visual Diversity Fixes

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.1 | Update `buildUIToolkitSection()` with real HTML snippets | Sonnet | done | Added actual HTML patterns from UI_TOOLKIT.md (commit bd06599) |
| 1.2 | Add visual diversity requirement to directive section | Sonnet | done | Added VISUAL DIVERSITY REQUIREMENT section (commit bd06599) |
| 1.3 | Create UI Component builders in Salesforce org | Sonnet | done | 12 UI Component builders already deployed |
| 1.4 | Test visual diversity in output | Manual | done | Verified: Stats Strip, Insight Cards, Recommendation Cards with colors |

### Phase 1B: Personalization Fixes

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.5 | Add "use names not titles" instruction to meta-prompt | Sonnet | done | Added PERSONALIZATION REQUIREMENT section (commit bd06599) |
| 1.6 | Add remaining traversal builders to insert script | Opus | done | Expanded from 8 to 25 traversals in insert_builder_prompts.apex |
| 1.7 | Deploy traversal builders to org | Sonnet | done | 25 traversal builders confirmed in org |
| 1.8 | Update Stage 5 to suggest parent fields | Opus | done | Deployed: loads traversals, adds to LLM prompt, parses selectedParentFields |

### Phase 1C: Output Quality

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.9 | Fix single-line HTML requirement | Sonnet | done | Strengthened instruction with ENFORCEMENT section (commit 770aa3f) |
| 1.10 | Remove emojis from builder prompts | Sonnet | done | Removed ✅ ❌ from Evidence Binding Rules v2 (commit 770aa3f) |
| 1.11 | Test multi-sample flow with 3 records | Manual | done | Tested via LWC UI - output verified with personalization, UI components, evidence citations |

---

## V2.3 Task Queue (JSON State Foundation)

**Goal:** Replace fragile stage-record-based data passing with a simple JSON file attached to each run. Every stage reads from and writes to this single file. Simple, debuggable, reliable.

### Phase 3A: PipelineState Foundation (Opus)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.1 | Create `PipelineState.cls` helper class | Opus | done | Core read/write/merge methods using ContentVersion. Deployed to org. |
| 3.2 | Create `PipelineState_Test.cls` | Opus | done | 24 unit tests - all passing (100%). |
| 3.3 | Deploy and verify PipelineState works | Opus | done | Deployed and tested via unit tests. |

### Phase 3B: Pipeline Integration (Opus)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.4 | Update `PromptFactoryPipeline.cls` to use PipelineState | Opus | done | loadStageInputs() now uses PipelineState.read() with fallback |
| 3.5 | Update `PromptFactoryPipeline.cls` save logic | Opus | done | saveStageResult() writes to PipelineState + stage record |
| 3.6 | Test pipeline with new state management | Manual | not_started | Run full pipeline, verify all stages get data |

### Phase 3C: Stage Updates (Opus)

Update each stage to use PipelineState instead of inputs map. Simple pattern:
```apex
Map<String, Object> state = PipelineState.read(runId);
// ... do stage work using state.get('key') ...
state.put('myOutput', myValue);
PipelineState.write(runId, state);
```

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.7 | Update Stage 1 (Init) | Opus | not_started | First stage - creates the JSON file |
| 3.8 | Update Stage 2 (Research) | Opus | not_started | |
| 3.9 | Update Stage 3 (Schema) | Opus | not_started | |
| 3.10 | Update Stage 4 (Profiling) | Opus | not_started | |
| 3.11 | Update Stage 5 (Field Selection) | Opus | not_started | |
| 3.12 | Update Stage 6 (Validation) | Opus | not_started | |
| 3.13 | Update Stage 7 (Template) | Opus | not_started | |
| 3.14 | Update Stage 8 (Assembly) | Opus | not_started | |
| 3.15 | Update Stage 9 (Deploy) | Opus | not_started | |
| 3.16 | Update Stage 10 (Test) | Opus | not_started | |
| 3.17 | Update Stage 11 (Safety) | Opus | not_started | |
| 3.18 | Update Stage 12 (Audit) | Opus | not_started | |
| 3.19 | Full pipeline end-to-end test | Manual | not_started | Run complete pipeline, verify output |

### Phase 3D: LWC UI Updates (Opus)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.20 | Add "State File" tab to run detail view | Opus | not_started | Show JSON file content in UI |
| 3.21 | Add download button for state file | Opus | not_started | Easy debugging - download and inspect |
| 3.22 | Add refresh button | Opus | not_started | Reload current state |
| 3.23 | Test UI with active run | Manual | not_started | Verify file appears and updates |

### Phase 3E: Cleanup (Opus)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.24 | Remove old loadStageInputs() code | Opus | not_started | Delete unused accumulation logic |
| 3.25 | Remove pass-through remnants from stages | Opus | not_started | Clean up any leftover pass-through code |
| 3.26 | Update documentation | Opus | not_started | Document new PipelineState approach |

---

## V2.3 Phase 2: Cherry-Pick V2.2 Features (After Foundation)

Once the JSON state foundation is solid, we'll add back the valuable V2.2 features:

### Phase 3F: Schema Enrichment (Cherry-pick from V2.2)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.27 | Add helpText to SchemaHelper.FieldMetadata | Opus | not_started | Port from V2.2 branch |
| 3.28 | Add field density calculation | Opus | not_started | Port calculateFieldDensity() from V2.2 |
| 3.29 | Add field categories | Opus | not_started | Port categorizeField() from V2.2 |
| 3.30 | Update Stage 5 prompt with enriched metadata | Opus | not_started | Port prompt enhancements from V2.2 |

### Phase 3G: Parent Field Support (Cherry-pick from V2.2)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.31 | Add parent field support to DCMBuilder | Opus | not_started | Port createParentFieldRecord() from V2.2 |
| 3.32 | Add parent field merge syntax to Stage 8 | Opus | not_started | Port buildMergeFieldReference() changes from V2.2 |
| 3.33 | Test parent field traversal end-to-end | Manual | not_started | Verify Owner.Name, Contact.Name work |

### Phase 3H: Grandchild Discovery (Cherry-pick from V2.2)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.34 | Add grandchild discovery to Stage 3 | Opus | not_started | Port discoverGrandchildRelationships() from V2.2 |
| 3.35 | Add childChain traversal support | Opus | not_started | Port loadChildChains() from V2.2 |
| 3.36 | Add GRANDCHILD type support to DCMBuilder | Opus | not_started | Port from V2.2 (already works, just need to integrate) |
| 3.37 | Test 3-level DCM creation | Manual | not_started | Account → Opportunity → OCR with Contact lookup |

---

## V2.4 Task Queue (Builder Refactoring & LWC Enhancements)

**Goal:** Simplify builder prompt architecture by using `ccai__Type__c` instead of `Category__c`. Add Output Rules builder. Enhance LWC with state file link and new-tab navigation.

### Phase 4A: Builder Type Migration (Opus)

Migrate from custom `Category__c` field to standard `ccai__Type__c` picklist for builder prompt categorization.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.1 | Add new picklist values to `ccai__Type__c` | Opus | done | User added via Setup UI: Quality Rule, Pattern, UI Component, Context Template, Traversal, Output Rules, Apex Service |
| 4.2 | Create "Output Rules" builder prompt | Opus | done | Created via scripts/apex/insert_output_rules_builder.apex (ID: a0DQH00000KZwnB2AT) |
| 4.3 | Update `loadQualityRules()` to use Type | Opus | done | Changed to `ccai__Type__c = 'Quality Rule'` |
| 4.4 | Update `loadPatterns()` to use Type | Opus | done | Changed to `ccai__Type__c = 'Pattern'` |
| 4.5 | Update `loadUIComponents()` to use Type | Opus | done | Changed to `ccai__Type__c = 'UI Component'` |
| 4.6 | Update `loadContextTemplates()` to use Type | Opus | done | Changed to `ccai__Type__c = 'Context Template'` |
| 4.7 | Update `loadTraversals()` to use Type | Opus | done | Changed to `ccai__Type__c = 'Traversal'` |
| 4.8 | Add `loadOutputRules()` method to Stage08 | Opus | done | Added method to load Output Rules builder content |
| 4.9 | Remove hardcoded merge field syntax from Stage08 | Opus | done | buildOutputRulesSection() now calls loadOutputRules() with fallback |
| 4.10 | Update existing builder records to use Type | Opus | done | Migrated 66 builders via scripts/apex/migrate_builders_to_type.apex |
| 4.11 | Deprecate Category__c field | Opus | done | All code now uses ccai__Type__c - no Category__c references remain |
| 4.12 | Test all builder loading | Manual | not_started | Verify all builder types load correctly with new Type field |

### Phase 4A-Extra: Traversal Consolidation (Sonnet)

Consolidate granular traversal records into comprehensive object-focused records for better LLM comprehension and performance.

**Why Consolidation is Better:**
1. **LLM Comprehension** - LLM sees all traversal options for an object in one place, making better field selection decisions
2. **Performance** - Fewer SOQL queries (1 record instead of 3-5 per object), less JSON parsing overhead, smaller prompt size
3. **Maintainability** - One record to update per object instead of hunting through multiple granular records

**Strategy:** Pilot with Account and Opportunity first (highest usage), validate with end-to-end test, then expand to remaining objects.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.13a | Create consolidation script for Account + Opportunity | Sonnet | done | Created scripts/apex/consolidate_traversals_pilot.apex |
| 4.14a | Run consolidation script | Sonnet | done | Created 2 consolidated records, deactivated 4 old granular records |
| 4.15a | Verify builder count and content | Sonnet | done | 67 builders total, 23 traversals (down from 25) |
| 4.16a | Test consolidated traversals in pipeline | Manual | in_progress | Run full pipeline with Account or Opportunity root object, verify Stage 5 field selection quality |
| 4.17a | Consolidate remaining objects | Sonnet | not_started | Case, Contact, Lead, Event, Task, Product (pending pilot test results) |

### Phase 4B: LWC Enhancements (Opus)

Add state file link and fix navigation to open in new browser tabs.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.18 | Add State File link to Run Detail LWC | Opus | done | Added getStateFileInfo() Apex method + LWC buttons |
| 4.19 | Make State File link open in new tab | Opus | done | Uses NavigationMixin.GenerateUrl + window.open() |
| 4.20 | Fix Run Logs link to open in new tab | Opus | done | Fixed pfRunHistory.handleViewRun() to use new tab |
| 4.21 | Add State File content preview | Opus | not_started | Optional: Show JSON content inline (collapsible) |
| 4.22 | Test LWC navigation behavior | Manual | not_started | Verify both links open in new tabs |

### Phase 4C: DCM & Prompt Quality Fixes (Sonnet)

**Critical Issues Found During Testing:**

1. **DCM Missing Parent Lookups** - OpportunityContactRole includes ContactId but not Contact.Name, Contact.Title, etc. LLM extracted names from Description field text instead of proper merge fields (unreliable).
2. **Recommendation Card Template** - Hardcoded "Recommended Action" label causes redundancy in output.
3. **3-Level Traversal Missing** - DCM only goes 2 levels (Opportunity → OpportunityContactRole) instead of 3 (Opportunity → OpportunityContactRole → Contact).

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.26 | Fix Recommendation Card template in Stage08 | Sonnet | done | Updated builder record (a0DQH00000KZQ9E2AX) with placeholder and better guidance |
| 4.27 | Add parent lookup auto-discovery to DCMBuilder | Sonnet | done | **FIXED via Stage08 integration**: Reverted broken DCMBuilder auto-discovery. Parent fields now flow through Stage05 traversals → Stage08 `selectedParentFields` → DCMBuilder `fieldsByObject`. Format converted: `ContactId.Name` → `Contact.Name`. |
| 4.28 | Update DCMBuilder to support 3-level traversals | Sonnet | done | Covered by 4.27 fix. Parent lookups are added as dot-notation FIELD records (e.g., Object=`OpportunityContactRole`, Field=`Contact.Name`), NOT as PARENT_LOOKUP detail records. This matches working DCM `a05QH000008RJTNYA4`. |
| 4.29 | Test DCM with OpportunityContactRole → Contact | Manual | not_started | Unblocked - run new pipeline to test |
| 4.30 | Test prompt quality with proper Contact merge fields | Manual | not_started | Unblocked - run new pipeline to test |

**Implementation Summary (Tasks 4.27-4.28):**

The parent lookup feature now works correctly using the **existing infrastructure**:

1. **Stage05 (Field Selection)** - Already loads traversal builders and outputs `selectedParentFields`:
   - Format: `{"OpportunityContactRole": ["ContactId.Name", "ContactId.Title"]}`

2. **Stage08 (Prompt Assembly)** - NEW: Merges `selectedParentFields` into `fieldsByObject`:
   - Converts lookup field to relationship name: `ContactId.Name` → `Contact.Name`
   - Merges with existing fields for each object

3. **DCMBuilder** - Receives `fieldsByObject` with parent fields already included:
   - Creates FIELD records with dot-notation (e.g., Object=`OpportunityContactRole`, Field=`Contact.Name`)
   - No auto-discovery needed - fields come from traversal definitions

**Key Insight:** The working DCM (`a05QH000008RJTNYA4`) stores parent lookups as dot-notation FIELD records, NOT as PARENT_LOOKUP detail records. This is how GPTfy supports parent traversals.

**Testing Instructions for 4.29-4.30:**

1. **Create a NEW Pipeline Run**:
   - Run pipeline for an Opportunity record that has OpportunityContactRoles
   - The DCM should include fields like `Contact.Name`, `Contact.Title` on OpportunityContactRole object

2. **Verify DCM Fields**:
   ```sql
   SELECT ccai__Object__c, ccai__Field_Name__c
   FROM ccai__DCM_Field__c
   WHERE ccai__DCM__c = '<new_dcm_id>'
   AND ccai__Object__c = 'OpportunityContactRole'
   ```
   - Expected: Should see `Contact.Name`, `Contact.Title`, etc.

3. **Verify Prompt Template**:
   - Check that LLM uses merge fields like `{{{OpportunityContactRoles.Contact.Name}}}`
   - NOT just `{{{OpportunityContactRoles.ContactId}}}`

4. **Test Prompt Execution**:
   - Run the prompt and verify Contact names appear in output
   - Should use proper field data, not extract from Description text

### Phase 4D: Documentation & Cleanup (Opus)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.31 | Update PROMPT_GENERATION_RULES.md | Opus | done | Docs already match Output Rules builder content |
| 4.32 | Update Decision Log | Opus | done | Already documented Type vs Category + Output Rules decisions |
| 4.33 | Final testing | Manual | not_started | Full pipeline run with all V2.4 changes |

---

## V2.5 Task Queue (Future - Knowledge Base)

Moved from original V2.3 plan. Will tackle after V2.4 is complete.

### Phase 5A: Builder Prompt Library Expansion

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.1 | Research UI component best practices | Sonnet | not_started | Dashboard design patterns |
| 5.2 | Create UI Component builders (8 new) | Sonnet | not_started | See Builder Library section below |
| 5.3 | Research analysis pattern best practices | Sonnet | not_started | Account health, opp coaching, etc. |
| 5.4 | Create Analysis Pattern builders (5 new) | Sonnet | not_started | See Builder Library section below |

### Phase 5B: Smart Builder Selection

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.5 | Add Weight__c to builder selection logic | Sonnet | not_started | Higher weight = higher priority |
| 5.6 | Add object-specific builder filtering | Sonnet | not_started | Only load Opportunity builders for Opportunity |
| 5.7 | Add token budget awareness | Opus | not_started | Don't exceed prompt size limit |

### Phase 5C: Thinking Model Enhancement (V2.5 Core)

**Vision:** Leverage thinking models (Claude, GPT-4) to create superior visualizations by giving them:
1. **Actual data** (not just schema) - queried early using DCM
2. **Business context** - what the user wants to achieve
3. **UI/UX toolkit** - available components (stat cards, charts, tables, alerts)
4. **Information hierarchy guidance** - "don't bury the lead", most important first

**Key Insight:** V2.0 already works well because the LLM sees real data and analyzes it. V2.5 enhances this by:
- Querying data earlier in pipeline (Stage 8 instead of Stage 10)
- Richer UI component library with examples
- Explicit guidance on information architecture
- Letting thinking models reason about what visualization best fits THIS data

**Architecture:**
```
Stage 8 (Enhanced):
  1. Load DCM config from previous stages
  2. Query ACTUAL DATA using DCM (buildDynamicSOQL + Database.query)
  3. Build comprehensive prompt:
     - Business context
     - Actual data payload (JSON or structured)
     - UI Toolkit (components with HTML examples)
     - Information hierarchy rules
     - Output rules (merge field syntax)
  4. Send to thinking model
  5. Thinking model analyzes data + decides visualization + generates output
  6. Return complete prompt (no template filling needed)

Stage 9-10:
  - Standard DCM/Prompt creation and execution
  - LLM in Stage 10 receives the well-crafted prompt with data
```

**What was wrong with previous V2.5 attempt:**
- Generated templates with merge fields in Stage 8 (AI only saw schema, not data)
- Mechanical template filling in Stage 9 (no intelligence)
- Stage 10 asked to "return HTML exactly" (wasted API call, no analysis)
- Thinking model never saw actual data when making visualization decisions

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.8 | Revert Stage 8 to V2.0 base | Opus | done | Branch feature/v2.5-clean from main |
| 5.9 | Add early data query to Stage 8 | Opus | done | Added buildActualDataSection() with SOQL queries |
| 5.10 | Enhance UI Toolkit with richer examples | Opus | not_started | More component HTML, usage guidance |
| 5.11 | Add information hierarchy section | Opus | done | buildInformationHierarchySection() - inverted pyramid |
| 5.12 | Remove V2.5 template code from Stage 9 | Opus | n/a | Clean branch from main - no template code exists |
| 5.13 | Test with 3 golden accounts | Manual | not_started | Compare output quality vs V2.0 |
| 5.14 | Document V2.5 architecture | Opus | not_started | Update this file + create design doc |

### Phase 5D: Abandoned - Two-Layer Template Architecture

**Status:** ❌ ABANDONED (2026-01-26)

The "two-layer meta-prompt" approach that was implemented is fundamentally flawed:
- Stage 8 generated templates with merge fields (AI only saw schema)
- Stage 9 filled templates mechanically (no intelligence)
- Stage 10 just echoed back HTML (wasted API call)

This has been replaced by Phase 5C (Thinking Model Enhancement) which keeps V2.0's working approach of letting the AI see actual data.

---

## PipelineState Architecture

### Design Overview

```
PF_Run__c (a0gXXX)
    │
    └── ContentDocumentLink
            │
            └── ContentVersion
                    ├── Title: "pipeline_state_a0gXXX.json"
                    ├── PathOnClient: "pipeline_state.json"
                    └── VersionData: { ... JSON state ... }
```

### JSON Structure

```json
{
  "runId": "a0gXXX",
  "createdAt": "2026-01-24T...",
  "lastUpdatedAt": "2026-01-24T...",
  "lastUpdatedByStage": 5,

  "rootObject": "Opportunity",
  "sampleRecordId": "006XXX",
  "businessContext": "...",
  "targetPersona": "...",
  "outputFormat": "Narrative",

  "selectedChildObjects": ["Task", "Event", "OpportunityContactRole"],
  "selectedGrandchildren": [...],
  "selectedFields": {
    "Opportunity": ["Name", "Amount", "StageName"],
    "Task": ["Subject", "Status"]
  },
  "selectedParentFields": {
    "Opportunity": ["OwnerId.Name", "AccountId.Name"]
  },

  "analysisBrief": { ... },
  "dcmConfig": { ... },
  "promptConfig": { ... },

  "logs": [
    {"stage": 1, "ts": "...", "level": "INFO", "msg": "Starting pipeline"},
    {"stage": 3, "ts": "...", "level": "INFO", "msg": "Found 15 child objects"},
    ...
  ]
}
```

### PipelineState.cls API

```apex
public class PipelineState {

    // Read current state (returns empty map if no file exists)
    public static Map<String, Object> read(Id runId)

    // Write state (merges with existing, creates file if needed)
    public static void write(Id runId, Map<String, Object> data)

    // Convenience: get a single key
    public static Object get(Id runId, String key)

    // Convenience: set a single key
    public static void put(Id runId, String key, Object value)

    // Append a log entry
    public static void log(Id runId, Integer stage, String level, String message)

    // Get the ContentVersion Id (for LWC to display)
    public static Id getFileId(Id runId)
}
```

### Benefits

1. **Single source of truth** - One file, not 12 stage records
2. **No size limits** - ContentVersion supports up to 2GB
3. **Easy debugging** - Download JSON, open in any editor
4. **Full history** - Each write creates a new version (can see changes)
5. **No FLS issues** - ContentVersion is standard Salesforce
6. **Simple code** - Read, modify, write. No complex accumulation logic.
7. **Visible in UI** - LWC can show file contents directly

---

## Traversal Builder Consolidation

### Consolidation Strategy (V2.4)

**Problem:** Original approach created separate builder records for each traversal path (e.g., "Account to Opportunity", "Account to Contact", "Account to Case"). This fragmented the LLM's understanding - it saw pieces instead of the complete traversal map for an object.

**Solution:** Consolidate all traversals for an object into a single comprehensive builder record.

**Pilot Results (Account + Opportunity):**
- **Account Traversals** (a0DQH00000KZwon2AD) - Consolidates: Opportunity, Contact, Case, Contract traversals
- **Opportunity Traversals** (a0DQH00000KZwoo2AD) - Consolidates: Account, Owner, OpportunityContactRole traversals
- Reduced from 7 granular records to 2 consolidated records
- LLM now sees complete relationship map in one prompt section

**Remaining Objects to Consolidate (Pending Pilot Test):**
- Case, Contact, Lead, Event, Task, Product, User, Quote, Order

### Example: Consolidated Account Traversals

```
PARENT RELATIONSHIPS (lookup from child objects back to Account):

1. Opportunity → Account
   - Traverse via: OpportunityId field
   - Suggested fields: Account.Name, Account.Industry, Account.Type, Account.BillingCity, Account.AnnualRevenue

2. Contact → Account
   - Traverse via: AccountId field
   - Suggested fields: Account.Name, Account.Industry, Account.Type

3. Case → Account
   - Traverse via: AccountId field
   - Suggested fields: Account.Name, Account.Type, Account.Industry

4. Contract → Account
   - Traverse via: AccountId field
   - Suggested fields: Account.Name, Account.BillingCity
```

## Parent Traversal Catalog

### Contact Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| OpportunityContactRole | ContactId | Contact | Name, Title, Email, Phone |
| CaseContactRole | ContactId | Contact | Name, Title, Email |
| AccountContactRole | ContactId | Contact | Name, Title |
| Task | WhoId | Contact/Lead | Name (polymorphic) |
| Event | WhoId | Contact/Lead | Name (polymorphic) |
| CampaignMember | ContactId | Contact | Name, Email |

### Account Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| Opportunity | AccountId | Account | Name, Industry, Type, BillingCity, AnnualRevenue |
| Contact | AccountId | Account | Name, Industry, Type |
| Case | AccountId | Account | Name, Type, Industry |
| Contract | AccountId | Account | Name, BillingCity |
| Order | AccountId | Account | Name, ShippingCity |
| Quote | AccountId | Account | Name |
| Asset | AccountId | Account | Name, Industry |

### Opportunity Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| OpportunityLineItem | OpportunityId | Opportunity | Name, StageName, Amount |
| Quote | OpportunityId | Opportunity | Name, Amount, CloseDate |
| Order | OpportunityId | Opportunity | Name, Amount |

### Product Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| OpportunityLineItem | Product2Id | Product2 | Name, Family, ProductCode, Description |
| QuoteLineItem | Product2Id | Product2 | Name, Family, ProductCode |
| OrderItem | Product2Id | Product2 | Name, Family |
| PricebookEntry | Product2Id | Product2 | Name, Family |

### User/Owner Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| Opportunity | OwnerId | User | Name, Email, Title |
| Case | OwnerId | User | Name, Email |
| Account | OwnerId | User | Name, Email |
| Lead | OwnerId | User | Name, Email |
| Task | OwnerId | User | Name |
| Event | OwnerId | User | Name |

### Case Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| CaseComment | ParentId | Case | Subject, Status, CaseNumber |
| EmailMessage | ParentId | Case | Subject, CaseNumber |
| CaseHistory | CaseId | Case | Subject, CaseNumber |

### Other Common Traversals
| Child Object | Lookup Field | Parent Object | Recommended Fields |
|--------------|--------------|---------------|-------------------|
| Task | WhatId | Opportunity/Account | Name (polymorphic) |
| Event | WhatId | Opportunity/Account | Name (polymorphic) |
| Attachment | ParentId | Any | (parent Name) |
| ContentDocumentLink | LinkedEntityId | Any | (parent Name) |

---

## Builder Prompt Library Expansion

### Current Inventory (6 builders)
| Name | Category | Chars | Status |
|------|----------|-------|--------|
| Evidence Binding Rules v2 | Quality Rule | ~600 | Active |
| Next Best Action Pattern (Compressed) | Pattern | ~450 | Active |
| Risk Assessment Pattern | Pattern | ~500 | Active |
| Stat Card Component | UI Component | ~200 | Active |
| Alert Box Component | UI Component | ~150 | Active |
| Healthcare Payer Context | Context Template | ~180 | Active |

### Proposed UI Component Builders (8 new)
| Name | Category | Description | Priority |
|------|----------|-------------|----------|
| Stats Strip Component | UI Component | Horizontal 3-5 KPI tiles with values and labels | High |
| Health Score Component | UI Component | 0-100 gauge with color coding (green/yellow/red) | High |
| Insight Card Component | UI Component | Finding + evidence citation with border | High |
| Recommendation Card Component | UI Component | Action + urgency + deadline with colored left border | High |
| Warning Alert Component | UI Component | Orange left-border alert box | Medium |
| Critical Alert Component | UI Component | Red left-border alert box | Medium |
| Info Alert Component | UI Component | Blue left-border alert box | Medium |
| Two-Column Layout Component | UI Component | Side-by-side responsive grid | Medium |

### Proposed Analysis Pattern Builders (5 new)
| Name | Category | Object | Description |
|------|----------|--------|-------------|
| Account Health Analysis | Pattern | Account | Revenue trends, engagement scoring, risk factors |
| Opportunity Coaching | Pattern | Opportunity | MEDDIC gaps, stakeholder coverage, next steps |
| Case Triage Analysis | Pattern | Case | Urgency scoring, sentiment, escalation risk |
| Pipeline Review Pattern | Pattern | Opportunity | Stage distribution, velocity, stuck deals |
| Contact Engagement Pattern | Pattern | Contact | Last touch, frequency, preferred channels |

### Proposed Output Format Builders (4 new)
| Name | Category | Description |
|------|----------|-------------|
| Executive Summary Format | Output Format | 3-sentence pattern: status, risk, opportunity |
| Action List Format | Output Format | WHO/WHAT/WHEN/WHY structure |
| Risk Matrix Format | Output Format | Impact vs Likelihood grid |
| Comparison Format | Output Format | Side-by-side evaluation table |

### Proposed Industry Context Templates (4 new)
| Name | Category | Industry | Key Considerations |
|------|----------|----------|-------------------|
| Financial Services Context | Context Template | Banking/Insurance | Compliance, AUM, risk tolerance, regulations |
| Manufacturing Context | Context Template | Manufacturing | Supply chain, inventory, lead times, capacity |
| Technology/SaaS Context | Context Template | Software | ARR, churn, expansion, NPS, adoption |
| Retail Context | Context Template | Retail | Seasonality, inventory turns, margins |

---

## V1.1 vs V2.0 Quality Comparison

| Aspect | V1.1 (Fixed Template) | V2.0 (Meta-Prompt) | Winner |
|--------|----------------------|-------------------|--------|
| **Output Structure** | Rigid template with placeholders | LLM decides structure based on data | V2.0 |
| **Insight Quality** | "Fill in the blanks" approach | Evidence-cited insights with (Source:) annotations | V2.0 |
| **Action Items** | Generic recommendations | Specific: WHO, WHAT, WHEN, WHY with deadlines | V2.0 |
| **Data Tables** | Table-first approach | Tables last, insights first | V2.0 |
| **Token Efficiency** | ~6,500 char builders injected verbatim | ~450 char compressed principles | V2.0 |
| **Prompt Size** | Variable, no validation | Validated against field limit, % shown | V2.0 |
| **Metadata** | Manual description | LLM-generated description + howItWorks | V2.0 |

### V2.0 Remaining Gaps (addressed in V2.1+)
1. Visual diversity lacking (no colored alerts, stats strips)
2. Generic titles instead of names ("the CFO" not "Sarah Johnson")
3. Single-line HTML not enforced
4. Parent field traversal not supported
5. Builder library limited (only 6 builders)

---

## Architecture: Field Selection Flow (V2.2 Target)

### Current Flow (V2.0)
```
Stage 3: Schema Analysis
    → Discover child relationships (DOWN only)
    → List available objects and fields

Stage 4: Data Profiling
    → Query sample record(s)
    → Extract field values
    → Build data summary

Stage 5: Field Selection
    → Send fields to LLM
    → LLM picks relevant fields
    → No density, no metadata, no parents
```

### Target Flow (V2.2)
```
Stage 3: Schema Analysis (Enhanced)
    → Discover child relationships (DOWN)
    → Discover parent lookups (UP) - NEW
    → Include help text, descriptions - NEW
    → Build relationship map

Stage 4: Data Profiling (Enhanced)
    → Query 100+ records - NEW
    → Calculate field population density - NEW
    → Identify long text / unstructured fields - NEW
    → Build interestingness scores

Stage 5: Field Selection (Enhanced)
    → Send fields WITH metadata to LLM - NEW
    → Include parent field candidates - NEW
    → LLM picks based on business context
    → Weight by density + relevance
```

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-23 | Horizontal MVP slices over vertical deep-dives | Features are interconnected; need fast feedback loops |
| 2026-01-23 | Start with 3 sample records (not configurable N) | MVP simplicity |
| 2026-01-23 | Compress only 2 builder prompts initially | Validate approach before scaling |
| 2026-01-23 | Keep fixed template as "suggestion" initially | Incremental change, not full rewrite |
| 2026-01-23 | Merge V2.0 to main, create new branch for V2.1 | V2.0 stable, avoid branch divergence |
| 2026-01-23 | Store traversal catalog as Static Resource | Easy to update, queryable by Apex |
| 2026-01-23 | Sonnet handles implementation, Opus handles design | Play to model strengths |
| 2026-01-24 | Abandon V2.2 branch, start fresh with V2.3 | V2.2 pipeline refactoring broke data passing. Complex accumulation logic across 12 stage records was fragile. Hours of debugging with no resolution. |
| 2026-01-24 | Use JSON file (ContentVersion) for pipeline state | Single source of truth, no size limits, easy to debug (download and inspect), no FLS issues, simple read/write pattern. Replaces complex stage record accumulation. |
| 2026-01-24 | Opus handles all V2.3 tasks | Foundation work is architectural - design and implement together. Cherry-pick features afterward. |
| 2026-01-24 | Cherry-pick V2.2 features after foundation | Schema enrichment, parent fields, grandchild discovery code exists in V2.2 branch - will port once JSON state is solid |
| 2026-01-24 | Use ccai__Type__c instead of Category__c | Simplify builder prompt architecture. Type field already exists on ccai__AI_Prompt__c. No need for separate Category__c field. Cleaner queries, less custom metadata. |
| 2026-01-24 | Create Output Rules builder prompt | Move merge field syntax rules from hardcoded Stage08 text to a builder prompt. Easier to maintain, update without code deployment. |
| 2026-01-24 | LWC links open in new tabs | State file and run logs should open in new browser tabs to preserve Factory LWC context. Better UX for debugging. |
| 2026-01-24 | Consolidate traversal builders by object | When LLM sees all traversal options for an object in one place (vs. fragmented across 3-5 records), it makes better field selection decisions. Also improves performance (fewer SOQL queries) and maintainability (one record to update). Pilot with Account + Opportunity first. |
| 2026-01-24 | DCMBuilder must create parent lookups for child objects | Testing revealed OpportunityContactRole includes ContactId but not Contact.Name/Title/Email. LLM was extracting names from Description field text (unreliable). DCMBuilder needs to auto-discover child object lookups and create PARENT_LOOKUP records for related fields. Enables 3-level traversals. |
| 2026-01-26 | Abandon V2.5 two-layer template architecture | **Critical flaw**: Template approach had AI see only schema (not data) when making UI decisions. Stage 8 generated templates, Stage 9 filled mechanically, Stage 10 just echoed HTML. AI never analyzed actual data. V2.0 works well because AI sees real data. V2.5 should ENHANCE V2.0, not replace it. New approach: query data early, give thinking model data+context+UI toolkit, let it create optimal visualization with analysis. Created feature/v2.5-clean branch from main. |

---

## Progress Log

| Date | Task | Model | Outcome |
|------|------|-------|---------|
| 2026-01-23 | Initial setup | Opus | Created BUILDER_IMPROVEMENTS.md |
| 2026-01-23 | Task 1.1: Compress Next Best Action Pattern | Sonnet | Created compressed version: 444 chars (was 6,500) - 93% reduction |
| 2026-01-23 | Task 1.2: Test compressed prompt quality | Sonnet | Deployed compressed builder (a0DQH00000KZJXJ2A5), created test procedure |
| 2026-01-23 | Task 2.2: Update pfInputForm for multi-sample | Sonnet | Updated LWC to accept 1-5 comma-separated IDs with validation |
| 2026-01-23 | Task 2.3: Update PromptFactoryController for multi-sample | Sonnet | Added Sample_Record_Ids__c field, parsing logic, deployed controller |
| 2026-01-23 | Task 2.4: Update Stage 4 for multi-sample profiling | Sonnet | Implemented MultiSampleProfile classes, profileMultipleSamples(), aggregation, pattern detection |
| 2026-01-23 | Task 3.4: Create UI toolkit documentation | Sonnet | Created comprehensive component library: layouts, insights, data components, usage rules |
| 2026-01-23 | Task 2.1: Design multi-sample data structure | Opus | Created MULTI_SAMPLE_DESIGN.md with full architecture for N-sample profiling |
| 2026-01-23 | Task 2.5: Update Stage 5 for multi-sample | Opus | Enhanced AI prompt with data availability across samples, detected patterns, field selection guidance |
| 2026-01-23 | Task 3.1: Design meta-prompt structure | Opus | Created META_PROMPT_DESIGN.md with 6-section architecture |
| 2026-01-23 | Task 3.2: Modify Stage 7 for analysis brief | Opus | Added USE_META_PROMPT flag, generateAnalysisBrief() with analysis goals, data context, output guidelines |
| 2026-01-23 | Task 3.3: Modify Stage 8 for meta-prompt assembly | Sonnet | Implemented 6-section meta-prompt with all builder methods |
| 2026-01-23 | Task 4.1: Fix metadata and field validation | Opus | Added LLM-generated prompt metadata, field size validation |
| 2026-01-23 | Task 4.1: Bug fixes from testing | Opus | Fixed howItWorks not saving, fixed duplicate grounding rules |
| 2026-01-23 | Task 4.2: V1.1 vs V2.0 comparison | Opus | Documented quality improvements across all aspects |
| 2026-01-23 | Task 4.3: V2.1 priorities | Opus | Identified visual diversity, parent traversal, builder library expansion |
| 2026-01-23 | V2.1 Planning | Opus | Documented traversal catalog, builder library, phased task queue |
| 2026-01-23 | Task 1.6: Traversal builders | Opus | Added 17 new traversals to insert_builder_prompts.apex (now 25 total, 50 builders overall) |
| 2026-01-23 | Task 1.8: Parent field suggestions | Opus | Updated Stage 5 to load traversal builders and suggest parent fields to LLM |
| 2026-01-23 | Tasks 1.1, 1.2, 1.5: Visual diversity & personalization | Sonnet | Added HTML snippets to UI toolkit, visual diversity requirement, name personalization |
| 2026-01-23 | Tasks 1.3, 1.7: Builder deployment | Sonnet | Verified 59 active builders deployed (12 UI Components, 25 Traversals) |
| 2026-01-23 | Tasks 1.9, 1.10: Output quality fixes | Sonnet | Strengthened single-line HTML instruction, removed emojis from Evidence builder |
| 2026-01-23 | Task 1.8: Stage 5 parent traversals | Opus | Wired traversal builders into field selection: loadTraversalsForObjects(), prompt section, selectedParentFields output |
| 2026-01-23 | Tasks 1.4, 1.11: V2.1 End-to-End Testing | Manual | V2.1 fully validated - Stats Strip, Insight Cards, Recommendation Cards, personalization (names not titles), evidence citations, single-line HTML |
| 2026-01-23 | Bug fix: Invalid merge field references | Opus | Fixed hardcoded Tasks example in buildMergeFieldReference(); now dynamic based on selected objects. Added CRITICAL RESTRICTION to prevent LLM from inventing merge fields |
| 2026-01-24 | V2.2 Debugging | Opus | Investigated Stage 7 "No selected fields" error. Stage 5 outputs selectedFields but Stage 7 doesn't receive it. Root cause: Complex accumulation logic in loadStageInputs() is fragile. |
| 2026-01-24 | V2.2 Analysis | Opus | Reviewed branch: 31 commits, 6125 insertions. Phase 2F (pass-through removal) broke pipeline. Phase 2A/2C/2G features are valuable and can be cherry-picked. |
| 2026-01-24 | V2.3 Decision | Opus | Abandoned V2.2 branch. Created feature/v2.3-json-state from main. Will implement PipelineState.cls (JSON file approach) first, then cherry-pick V2.2 features. |
| 2026-01-24 | V2.3 Planning | Opus | Documented full V2.3 task queue: 37 tasks across 8 phases. Includes PipelineState foundation, stage updates, LWC UI changes, and feature cherry-picks. |
| 2026-01-24 | V2.3 Merge field fixes | Opus | Fixed Stage02 "string -" placeholder bug, Stage08 child field notation ({{{Events.Subject}}} format), updated PROMPT_GENERATION_RULES.md |
| 2026-01-24 | V2.3 Merged to main | Opus | V2.3 complete: PipelineState.cls, StageJobHelper integration, merge field notation fixes. Merged feature/v2.3-json-state → main. |
| 2026-01-24 | V2.4 Branch created | Opus | Created feature/v2.4-builder-refactor for Type migration, Output Rules builder, LWC enhancements |
| 2026-01-24 | Tasks 4.1-4.8, 4.10-4.11 | Opus | Migrated all builder code from Category__c to ccai__Type__c. Updated Stage08, Stage05, BuilderDiagnostic, P_PromptBuilderController. Created Output Rules builder (a0DQH00000KZwnB2AT). Migrated 66 builders. Added loadOutputRules() method. |
| 2026-01-24 | Task 4.9 | Opus | Updated buildOutputRulesSection(runId) to load Output Rules builder dynamically instead of hardcoded merge field syntax. Deployed to org. 67 builders now active. |
| 2026-01-24 | Tasks 4.13a-4.15a: Traversal consolidation pilot | Sonnet | Created consolidate_traversals_pilot.apex script. Consolidated Account (4 records → 1) and Opportunity (3 records → 1) traversals. Deactivated old granular records. Builder count: 67 total, 23 traversals. Awaiting end-to-end test validation. |
| 2026-01-24 | Task 4.16a: Pipeline testing - Critical issues found | Sonnet | Tested Opportunity pipeline (ID: 006QH00000HjgvlYAB). Found 3 issues: (1) DCM missing Contact parent lookups for OpportunityContactRole - LLM extracted names from Description text instead of merge fields (unreliable), (2) Recommendation Card template has redundant "Recommended Action" label, (3) 3-level traversals not working (Opportunity → OCR → Contact). Added Phase 4C tasks to fix DCMBuilder and Stage08. |
| 2026-01-24 | Task 4.26: Fix Recommendation Card template | Sonnet | Updated builder record (a0DQH00000KZQ9E2AX) to remove hardcoded "Recommended Action" label. Changed to placeholder "[Specific action: who does what by when]" with improved "When to use" guidance. Script: scripts/apex/fix_recommendation_card_template.apex. |
| 2026-01-24 | Tasks 4.27-4.28: Parent lookup auto-discovery | Sonnet | Implemented automatic parent lookup discovery in DCMBuilder. New methods: discoverParentLookups(), getStandardFieldsForObject(), createParentLookupDetail(), isSystemObject(). When child objects are added (e.g., OpportunityContactRole), DCM now auto-discovers lookups (ContactId → Contact) and creates PARENT_LOOKUP records with standard fields (Name, Title, Email, Phone). Enables 3-level traversals: Account → Opportunity → OpportunityContactRole → Contact. Deployed successfully. |
| 2026-01-24 | Tasks 4.29-4.30: Testing verification | Sonnet | Created verify_parent_lookup_fix.apex script to validate parent lookup auto-discovery in new DCMs. Added comprehensive testing instructions to Phase 4C. Previous pipeline run (a0gQH000005GNozYAG) was created BEFORE the DCMBuilder fix deployment, so Contact.Name/Title/Email fields are missing. User needs to run NEW pipeline to test the fix. |
| 2026-01-24 | Bug fix: PARENT_LOOKUP missing Parent_Detail__c | Sonnet | Fixed "List index out of bounds: 0" error in Stage 9. PARENT_LOOKUP detail records were missing Parent_Detail__c field to link them to their child object's detail record. Updated createParentLookupDetail() to accept parentDetailId parameter and set ccai__Parent_Detail__c field. Deployed successfully. User can now retry pipeline run. |
| 2026-01-24 | DISABLED: PARENT_LOOKUP auto-discovery | Opus | GPTfy managed package doesn't support PARENT_LOOKUP type in DCM Details. Prompts with PARENT_LOOKUP records cause "Attempt to de-reference a null object" error on prompt detail page. Root cause: PARENT_LOOKUP is a custom type we created; GPTfy only supports CHILD and GRANDCHILD types. Fix: (1) Deleted 8 PARENT_LOOKUP records from broken DCM a05QH000008RKm1YAG, (2) Commented out PHASE 1.5 in DCMBuilder.createDCMWithGrandchildren(). TODO: Investigate if GPTfy has a supported way to enable parent lookup traversals or if this should be handled via prompt merge field syntax only. |
| 2026-01-24 | FIXED: Parent lookup via Stage08 integration | Opus | Discovered working DCM (a05QH000008RJTNYA4) uses dot-notation FIELD records, NOT PARENT_LOOKUP details. Fix: (1) Reverted broken auto-discovery code from DCMBuilder PHASE 1.5, (2) Added `selectedParentFields` integration to Stage08's `buildDCMConfigForStage9()`, (3) Added `convertLookupToRelationship()` to convert `ContactId.Name` → `Contact.Name`. Parent fields now flow: Stage05 traversals → `selectedParentFields` → Stage08 → `fieldsByObject` → DCMBuilder. No more guessing fields - uses existing traversal definitions. |

---

## Notes for Future Iterations

### Post V2.3 Considerations
- A/B testing framework for prompt variations
- Output caching for similar record patterns
- User feedback loop (thumbs up/down on outputs)
- Apex Service injection (Picklist Intelligence, Topic Service)
- Custom builder creation UI in Salesforce
- Multi-language output support

### Technical Debt to Address
- Remove hardcoded parent traversals once dynamic discovery works
- Consolidate UI Toolkit (Stage 8 section vs docs/UI_TOOLKIT.md)
- Add unit tests for SchemaHelper enhancements
- Performance optimization for 100+ record queries

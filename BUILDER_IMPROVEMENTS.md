# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization, field selection, and output quality features.
All architecture, decisions, tasks, and progress tracked here.

---

## CURRENTLY ACTIVE WORK (Check Before Starting)

| Model | Task | File Being Modified | Started |
|-------|------|---------------------|---------|
| Opus | Phase 6H: Stage 10-12 Consolidated Callout | Stage10_12_ConsolidatedJob.cls | 2026-01-26 |

**Status:** V2.6 released. Phase 6H in progress - fixing Stage 10 DML/callout issue.
**Branch:** `feature/v2.6-future-callout`

---

## Release Strategy

### Current Branch: `main`
**Status:** V2.6 Released (2026-01-26)

### Version History

| Version | Branch | Status | Description |
|---------|--------|--------|-------------|
| V1.1 | main | ✅ Released | Builder prompt injection (Run ID a0gQH000005GHurYAG) |
| V2.0 | feature/builder-improvements | ✅ Complete | Meta-prompt architecture, LLM metadata, field validation |
| V2.1 | feature/v2.1-enhancements | ✅ Complete | Visual diversity, parent traversals, builder library |
| V2.2 | feature/v2.2-schema-intelligence | ⚠️ Abandoned | Schema enrichment attempted, pipeline state passing broke. See Decision Log. |
| V2.3 | feature/v2.3-json-state | ✅ Complete | JSON file-based state (PipelineState.cls), merge field notation fixes |
| V2.4 | feature/v2.4-builder-refactor | ✅ Complete | Builder Type migration, Output Rules builder, LWC enhancements |
| V2.5 | feature/v2.5-clean | ✅ Complete | Actual data in meta-prompt, information hierarchy, FieldName fix |
| V2.6 | main | ✅ Released | Visual richness, 11-dimension scoring, automated test harness, 100/100 quality |

### V2.2 Abandonment Note

The V2.2 branch attempted to:
1. Add schema enrichment (helpText, field density, categories)
2. Add parent field traversal support
3. Refactor pipeline data passing (remove pass-through pattern)

**What broke:** The pipeline refactoring (Phase 2F) removed pass-through from stages and tried to accumulate data from all previous stage records. This was architecturally sound but fragile in practice - Stage 7 stopped receiving `selectedFields` from Stage 5.

**Root cause:** Complex accumulation logic across 12 stage records, JSON serialization/deserialization, field limits, and no easy way to debug.

**Solution:** V2.3 implements a simple JSON file approach. One file per run, all stages read/write to it. After this foundation is solid, we'll cherry-pick the valuable V2.2 features (schema enrichment, parent fields, grandchild discovery).

---

## PROJECT RESOURCES INDEX

**See `CLAUDE.md`** for a complete index of:
- Test harnesses and how to run them
- REST API endpoints (including GPTfy bypass)
- Utility scripts in `scripts/apex/`
- Key documentation files
- Scoring logic locations
- Common test account IDs

This prevents searching for existing tools every session.

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
| 5.13 | Test with 3 golden accounts | Manual | in_progress | Tested with Pinnacle Wealth Partners - actual data included |
| 5.14 | Document V2.5 architecture | Opus | not_started | Update this file + create design doc |

### Phase 5D: Abandoned - Two-Layer Template Architecture

**Status:** ❌ ABANDONED (2026-01-26)

The "two-layer meta-prompt" approach that was implemented is fundamentally flawed:
- Stage 8 generated templates with merge fields (AI only saw schema)
- Stage 9 filled templates mechanically (no intelligence)
- Stage 10 just echoed back HTML (wasted API call)

This has been replaced by Phase 5C (Thinking Model Enhancement) which keeps V2.0's working approach of letting the AI see actual data.

---

## V2.6 Task Queue (Visual Richness & Creative Freedom)

**Branch:** `feature/v2.5-clean` (continuing from V2.5)
**Status:** 🔨 Active

**Problem Statement:** V2.5 added actual data to the meta-prompt, but outputs still look identical to V2.0 because:
1. Same 8 UI components in the toolkit
2. Same rigid "1. Stats, 2. Alerts, 3. Insights, 4. Recommendations, 5. Table" structure
3. No data-driven visualization selection guidance
4. No creative freedom for the LLM

**Goal:** Enable visually rich, data-driven dashboards by:
1. Expanding UI component library (database updates - fast)
2. Adding data-driven design guidance (tells LLM WHEN to use WHICH component)
3. Removing rigid structure (let LLM choose layout based on data story)
4. Encouraging creative expression

### Phase 6A: Expand UI Component Library (Database - Quick)

Add 10+ new component patterns as builder records. No code changes needed.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.1 | Create Progress Ring component | Opus | done | CSS-only donut/ring chart for percentages |
| 6.2 | Create Trend Indicator component | Opus | done | Value + arrow + percentage change |
| 6.3 | Create Comparison Card component | Opus | done | A vs B side-by-side layout |
| 6.4 | Create Pipeline/Funnel component | Opus | done | Stage progression visualization |
| 6.5 | Create Featured Hero Card component | Opus | done | Large prominent card for key insight |
| 6.6 | Create Gauge/Meter component | Opus | done | Semi-circle progress indicator |
| 6.7 | Create Risk Matrix component | Opus | done | 2x2 or 3x3 grid for priority |
| 6.8 | Create Timeline component | Opus | done | Horizontal event sequence |
| 6.9 | Create Two-Column Layout component | Opus | done | Side-by-side responsive grid |
| 6.10 | Create KPI Card with Trend component | Opus | done | Metric + mini sparkline-style trend |
| 6.11 | Update existing components with variations | Opus | skipped | New components sufficient for variety |

### Phase 6B: Data-Driven Design Guidance (Code Change)

Add new section to Stage08 that tells LLM WHEN to use WHICH visualization.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.12 | Create `buildDataDrivenDesignSection()` in Stage08 | Sonnet | done | Pattern-based component selection |
| 6.13 | Add pipeline pattern guidance | Sonnet | done | "3+ opps → show pipeline funnel" |
| 6.14 | Add urgency pattern guidance | Sonnet | done | "Critical case → lead with red banner" |
| 6.15 | Add trend pattern guidance | Sonnet | done | "Revenue available → show trend indicator" |
| 6.16 | Add comparison pattern guidance | Sonnet | done | "Multiple periods → use before/after" |

### Phase 6C: Remove Rigid Structure (Code Change)

Update `buildDirectiveSection()` to encourage story-driven layout.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.17 | Remove fixed "1,2,3,4" structure from directive | Sonnet | done | Replace with "tell the data's story" |
| 6.18 | Add creative encouragement language | Sonnet | done | "Create visually distinctive dashboard" |
| 6.19 | Add layout variation examples | Sonnet | done | Show 2-column, featured+grid options |
| 6.20 | Update quality checklist for visual variety | Sonnet | done | Check for component diversity |

### Phase 6D: Testing & Validation

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.21 | Test with Account (Harrison Family Trust) | sf apex | done | V2.6 sections validated: DATA-DRIVEN DESIGN, CREATIVE FREEDOM, all UI components |
| 6.22 | Test with 3 different account types | Manual | blocked | Stage 10 GPTfy API error (external service issue) |
| 6.23 | Document before/after comparison | Sonnet | blocked | Need Stage 10 to work for full visual output |

### Phase 6E: Evidence Binding & Date Analysis Fixes

**Problem:** AI output shows "high risk" or "unresolved" but doesn't explain WHY. Close dates from 2024 are nearly 2 years past due but AI doesn't calculate or mention this.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.24 | Add Evidence Binding rules to Quality Rules (Compressed) | Opus | done | "Every insight MUST explain WHY" with GOOD/BAD examples |
| 6.25 | Add DATE ANALYSIS section to Quality Rules | Opus | done | Enhanced v3: explicit "compare to TODAY'S DATE", calculated deltas required, GOOD/BAD examples, forbidden phrases |
| 6.26 | Add current date to meta-prompt | Opus | done | Added TODAY'S DATE to buildRoleSection() in Stage08. Format: "TODAY'S DATE: 1/26/2026" with instructions to calculate PAST/FUTURE |
| 6.27 | Add LastActivityDate to useful system fields | Opus | done | SchemaHelper.cls - critical for staleness analysis |
| 6.28 | Add lookup ID fields to priority field lists | Opus | done | Stage05 - AccountId, ContactId, WhatId, WhoId for parent-child correlation |
| 6.29 | Keep CreatedDate, LastModifiedDate in useful fields | Opus | done | Per user request - useful for context |

### Phase 6F: Automated Test Harness (Bypass Stage 10)

**Problem:** Stage 10 Apex fails due to GPTfy API issues. But Python test harness can call GPTfy REST API directly.

**Solution:** Create automated iteration loop:
1. Start pipeline via `TestHarnessController` REST API → Get Run ID
2. Poll `/test-harness/run-status/{runId}` until Stage 9 completes
3. Get `Created_Prompt_Id__c` and query `promptRequestId`
4. Call GPTfy REST API directly (`/services/apexrest/ccai/v1/executePrompt`)
5. Score response using quality scoring logic
6. If score < 90, iterate
7. Log iterations for analysis

**Quality Threshold:** Score must be ≥ 90/100 (not 75)

**Test Harness Files:**
- `TestHarnessController.cls` - REST API for pipeline control
- `tests/v26/run_innovatek_test.py` - Integrated end-to-end test script
- `tests/phase0/score_outputs.py` - Reference scoring logic

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.30 | Create `tests/v26/run_innovatek_test.py` | Opus | done | Combines pipeline start + polling + GPTfy API + scoring + iteration |
| 6.31 | Add current date injection to prompt | Opus | done | Stage08 adds TODAY'S DATE to buildRoleSection() |
| 6.32 | Add quality scoring to test script | Opus | done | Integrated scoring: evidence, date analysis, forbidden, colors, customer refs |
| 6.33 | Add date analysis scoring criteria | Opus | done | Checks for "overdue", "past close date", "X days/months" patterns |
| 6.34 | Add evidence binding scoring criteria | Opus | done | Checks for dollar amounts, percentages, date fields |
| 6.35 | Run iterations with Innovatek account | Opus | done | Score 100/100 achieved with v4 Quality Rules |
| 6.36 | Document winning prompt configuration | Opus | done | v4 Quality Rules: "ANALYZE EVERY RECORD", explicit checklist |

### Phase 6G: Stage 12 Quality Audit Enhancement

**Problem:** Stage 12 has 8 AI-scored dimensions but is missing key quality checks that exist in Python test harness.

**Current Stage 12 Dimensions:** Evidence Binding (20%), Diagnostic Depth (15%), Visual Quality (15%), UI Effectiveness (10%), Data Accuracy (10%), Persona Fit (10%), Actionability (10%), Business Value (10%)

**Gaps to Address:**
1. No Date Analysis check (does output calculate "X days overdue", "past close date"?)
2. No Forbidden Phrases detection (generic advice like "touch base", "ensure alignment")
3. Threshold too low (7.0 → should be 9.0)

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.37 | Add Date Analysis dimension to Stage 12 | Opus | done | 15% weight, checks for "X months overdue" patterns |
| 6.38 | Add Forbidden Phrases check to Stage 12 | Opus | done | 10% weight, penalizes "touch base", "ensure alignment" |
| 6.39 | Add Customer Reference check to Stage 12 | Opus | done | 10% weight, rewards specific names over "stakeholder" |
| 6.40 | Raise quality threshold from 7.0 to 9.0 | Opus | done | DEFAULT_QUALITY_THRESHOLD = 9.0 |
| 6.41 | Update AI audit prompt with new dimensions | Opus | done | 11 dimensions now (was 8) |
| 6.42 | Simplify to JSON-only storage | Opus | done | All scores in AI_Feedback__c JSON, no individual fields |
| 6.43 | Test Stage 12 with enhanced scoring | Manual | not_started | Validate new dimensions are scored correctly |

**Scoring Logic Location:** `force-app/main/default/classes/Stage12_QualityAudit.cls`

### Phase 6H: Stage 10-12 Consolidated Callout Job

**Problem:** Pipeline fails at Stage 10 with "You have uncommitted work pending. Please commit or rollback before calling out." Stage 9 does DML (creates prompt), then Stage 10 tries HTTP callout to GPTfy API - Salesforce blocks this.

**Solution:** Consolidate Stages 10-12 into a single Queueable job that runs in a fresh transaction (no prior DML). All callouts happen BEFORE any DML within the job.

**Architecture:**
```
Stage 9 (DML: create prompt)
    → enqueueJob(Stage10_12_ConsolidatedJob)
        → Fresh transaction (chain depth reset)
        → Stage 10: GPTfy callout
        → Stage 11: Safety validation (in-memory)
        → Stage 12: Claude AI callout
        → Final DML: Update PF_Run__c with all results
```

**Proof of Concept:** `FutureCalloutTest.cls` - tested and confirmed @future(callout=true) works after DML. Response: 6,909 char HTML with "Processed" status.

**Visual Feedback:** Stages 10-12 will update as a batch when the job completes (~30-45 seconds). LWC can show "Executing AI test and quality audit..." during this phase. Platform Events can be added later for real-time updates if needed.

**Proposal Document:** `docs/proposals/STAGE_10_CALLOUT_SOLUTION.md`

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.44 | Create `Stage10_12_ConsolidatedJob.cls` | Opus | not_started | Queueable + Database.AllowsCallouts, executes Stages 10-12 |
| 6.45 | Implement Stage 10 logic (GPTfy callout) | Opus | not_started | Use `ccai.AIPromptProcessingInvokable.processRequest()` |
| 6.46 | Implement Stage 11 logic (safety validation) | Opus | not_started | In-memory validation, no callout |
| 6.47 | Implement Stage 12 logic (Claude callout) | Opus | not_started | Call `Stage12_QualityAudit.auditQuality()` or inline |
| 6.48 | Add final DML to update PF_Run__c | Opus | not_started | Update stage status, scores, output HTML, logs |
| 6.49 | Add error handling and logging | Opus | not_started | Try/catch with JSON log updates on failure |
| 6.50 | Modify Stage 9 to enqueue consolidated job | Opus | not_started | Replace Stage 10 enqueue with Stage10_12_ConsolidatedJob |
| 6.51 | Deploy and test end-to-end | Manual | not_started | Run full pipeline, verify Stages 10-12 complete |
| 6.52 | (Optional) Update LWC with spinner message | Opus | not_started | Show "Executing AI test..." when Stage 9 complete but run still in progress |
| 6.53 | (Optional) Add Platform Events for real-time updates | Opus | not_started | Only if users need per-stage feedback for 10-12 |

### Phase 6I: Platform Event Logging (Fix DML before Callout)

**Problem:** When file logging is disabled (V2.3+), stages that make HTTP callouts (like Stage 2) fail with "You have uncommitted work pending" because the logger performs direct DML (insert `PF_Run_Log__c`) before the callout happens.

**Solution:** Decouple logging from the main transaction using Platform Events with `PublishImmediately` behavior.

**Architecture:**
1. **`PF_Log_Event__e`**: New Platform Event mirroring `PF_Run_Log__c` fields.
2. **Refactored Logger**: `PromptFactoryLogger.cls` publishes events instead of inserting records.
3. **Logging Trigger**: `PF_Log_EventTrigger` handles asynchronous insertion of log records.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 6.54 | Create `PF_Log_Event__e` mapping | Opus | done | Object + Field metadata |
| 6.55 | Create `PF_Log_EventTrigger` | Opus | done | Async insertion trigger |
| 6.56 | Refactor `PromptFactoryLogger.cls` | Opus | done | Move DML to `EventBus.publish()` |
| 6.57 | Test end-to-end logging | Manual | done | 19 unit tests passing (100% coverage) |

**Key Files:**
- `PF_Log_Event__e` (Metadata)
- `PF_Log_EventTrigger.trigger` (NEW)
- `PromptFactoryLogger.cls` (Modify)

---

**Key Files:**
- `Stage10_12_ConsolidatedJob.cls` - NEW: Consolidated job for Stages 10-12
- `Stage09_CreateAndDeployJob.cls` - Modify to enqueue consolidated job
- `FutureCalloutTest.cls` - Proof of concept (can be deleted after implementation)

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
| 2026-01-26 | Task 6.24: Evidence Binding rules | Opus | Updated "Quality Rules (Compressed)" builder to include EVIDENCE BINDING section: "Every insight MUST explain WHY", GOOD/BAD examples, parenthetical citations guidance. |
| 2026-01-26 | Task 6.25: Date Analysis rules | Opus | Added DATE ANALYSIS section to Quality Rules: "Calculate if dates are PAST or FUTURE", CloseDate overdue detection, LastActivityDate staleness detection. |
| 2026-01-26 | Task 6.27: LastActivityDate to useful fields | Opus | Updated SchemaHelper.cls `isUsefulSystemField()` to include LastActivityDate - critical for engagement/staleness analysis. |
| 2026-01-26 | Task 6.28: Lookup ID fields in priority lists | Opus | Updated Stage05_FieldSelection.cls `getPriorityFieldsForObject()` to include AccountId, ContactId, WhatId, WhoId, OpportunityId, ParentId for parent-child correlation. |
| 2026-01-26 | Task 6.29: Keep CreatedDate, LastModifiedDate | Opus | Per user request, kept CreatedDate and LastModifiedDate in useful system fields for timeline context. |
| 2026-01-26 | CLAUDE.md update | Opus | Added rule to always use `sf data query` instead of anonymous Apex for queries. Only use `sf apex run` for DML/pipeline operations. |
| 2026-01-26 | Analysis: AI output quality gap | Opus | Identified root cause: AI says "unresolved" or "at risk" but doesn't explain WHY. Close dates from 2024 are 22+ months past due but AI doesn't calculate this. Need: (1) Current date in prompt, (2) Stronger date analysis rules. |
| 2026-01-26 | Discovery: Python test harness | Opus | Found `tests/phase0/run_full_test.py` and `score_outputs.py` - can bypass Stage 10 Apex by calling GPTfy REST API directly. Scoring logic: evidence citations, forbidden phrases, customer references, diagnostic language. |
| 2026-01-26 | Task 6.26: Add current date to meta-prompt | Opus | Added TODAY'S DATE to buildRoleSection() in Stage08. Format: "TODAY'S DATE: 1/26/2026. Use this date to calculate if dates are PAST (overdue) or FUTURE." |
| 2026-01-26 | Tasks 6.30-6.34: Test harness creation | Opus | Created `tests/v26/run_innovatek_test.py` - comprehensive test script that: (1) Starts pipeline via TestHarnessController REST API, (2) Polls for Stage 9 completion, (3) Gets promptId, (4) Calls GPTfy API directly, (5) Scores output for evidence, date analysis, forbidden phrases, colors, customer refs. Target: 90+ score. |
| 2026-01-26 | Tasks 6.35-6.36: Test execution SUCCESS | Opus | Ran 4 iterations total. v3 Quality Rules scored 75-85/100. v4 Quality Rules scored **100/100**. Key improvements in v4: "ANALYZE EVERY RECORD", "FOR EACH OPPORTUNITY", "CHECK YOUR MATH", explicit checklist items. Output now shows "11 months overdue", "22 months overdue" for all opportunities. |
| 2026-01-26 | Tasks 6.37-6.42: Stage 12 Enhancement | Opus | Enhanced Stage12_QualityAudit.cls: (1) Added 3 new dimensions: dateAnalysis (15%), forbiddenPhrases (10%), customerReferences (10%), (2) Raised threshold from 7.0 to 9.0, (3) Simplified to JSON-only storage in AI_Feedback__c, (4) Updated AI prompt with 11-dimension scoring. Schema version: v2.6-11-dimension-weighted. |
| 2026-01-26 | Phase 6H Investigation: DML/Callout issue | Opus | Investigated Stage 10 failure. Root cause: Stage 9 does DML, Stage 10 needs callout - Salesforce blocks this. Tested 3 approaches: (1) GPTfy invocable after DML → fails (returns error JSON), (2) GPTfy invocable without DML → works (3,482 char HTML), (3) @future(callout=true) after DML → works (6,909 char HTML). |
| 2026-01-26 | Phase 6H: Proof of concept | Opus | Created `FutureCalloutTest.cls` - deployed and tested. Confirms @future method runs in fresh transaction allowing callout after DML. Response: Processed status, 6,909 chars. |
| 2026-01-26 | Phase 6H: Proposal document | Opus | Created `docs/proposals/STAGE_10_CALLOUT_SOLUTION.md` - comprehensive proposal with problem statement, test evidence, proposed Queueable solution, visual feedback options, alternatives analysis, and phased implementation plan. Gemini added LWC spinner strategy (Section 10). |
| 2026-01-26 | Phase 7: Distributed State (Regression Fix) | Gemini | Fixed Prompt Assembly regression/truncation. Implemented Distributed State Architecture: (1) PipelineState.read() aggregates 'Output_Data__c' from all completed stages, (2) Disabled file logging to avoid ContentVersion limits, (3) Optimized Stage08 payload to fit within field limits. Verified end-to-end: Fixed. |

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

## Phase 7: Distributed State Architecture (V2.7)

**Problem:** 
1. **File Limits:** `Phase 3C` style file logging creates ~36 versions per run, hitting ContentVersion limits quickly.
2. **Field Limits:** `PF_Run_Stage__c.Output_Data__c` has a 131KB limit. Previous "pass-through" architecture tried to put *all* accumulated state into the latest stage's output, hitting this limit in Stage 8/9.

**Solution: Distributed State with Aggregation**
Instead of passing one giant blob from stage to stage, we distribute the data across the `Output_Data__c` fields of all completed stages, and aggregate it in memory only when needed.

**Architecture:**
1. **Distributed Storage:**
   - Stage 1 stores `context` in its `Output_Data__c`.
   - Stage 2 stores `strategy` in its `Output_Data__c`.
   - Stage 8 stores `prompt` in its `Output_Data__c`.
   - No single record holds the entire history.
   - Total capacity = 131KB * 12 stages = ~1.5MB (plenty for our needs).

2. **Aggregated Read:**
   - `PipelineState.read()` queries *all* completed stage outputs for the run.
   - It merges them into a single `Map<String, Object>` in memory.
   - Providing a seamless "full state" experience to the code without the storage overhead.

3. **Optimized Output:**
   - Stage 8 modified to remove redundant copies of the prompt from its output to ensure it fits within its 131KB slice.
   - `ENABLE_FILE_LOGGING` set to `false` (no files created).

**Status:**
- [x] **Update PipelineState.read()** to support distributed aggregation.
- [x] **Disable File Logging** in `PipelineState.cls`.
- [x] **Optimize Stage 8** payload size.
- [x] **Verify End-to-End** flow (Verified by user).

**Outcome:**
Robust, scalable state management that respects platform limits without requiring new objects or complex schema changes.

# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization, field selection, and output quality features.
All architecture, decisions, tasks, and progress tracked here.

---

## CURRENTLY ACTIVE WORK (Check Before Starting)

| Model | Task | File Being Modified | Started |
|-------|------|---------------------|---------|
| Opus | 5.1+ | REST Test Harness, Python Scripts | 2026-01-24 |

**Status:** V2.5 IN PROGRESS - Test harness for autonomous prompt iteration. V2.4 merged to main.

---

## Release Strategy

### Current Branch: `feature/v2.5-simplified-merge-fields`
**Status:** Active development

### Version History

| Version | Branch | Status | Description |
|---------|--------|--------|-------------|
| V1.1 | main | ✅ Released | Builder prompt injection (Run ID a0gQH000005GHurYAG) |
| V2.0 | feature/builder-improvements | ✅ Complete | Meta-prompt architecture, LLM metadata, field validation |
| V2.1 | feature/v2.1-enhancements | ✅ Complete | Visual diversity, parent traversals, builder library |
| V2.2 | feature/v2.2-schema-intelligence | ⚠️ Abandoned | Schema enrichment attempted, pipeline state passing broke. See Decision Log. |
| V2.3 | feature/v2.3-json-state | ✅ Complete | JSON file-based state (PipelineState.cls), merge field notation fixes |
| V2.4 | feature/v2.4-builder-refactor | ✅ Complete | Builder Type migration, Output Rules builder, LWC enhancements |
| V2.5 | feature/v2.5-simplified-merge-fields | 🔨 Active | REST test harness, Python orchestration, few-shot prompt generation |

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

## V2.5 Task Queue (Test Harness & Few-Shot Prompt Generation)

**Goal:** Create an autonomous test harness that allows Claude to iterate on meta-prompt design without user intervention. The LLM should generate deterministic prompt templates (with merge fields) that match the quality of hand-crafted prompts.

**Core Problem Identified:** The current meta-prompt tells the LLM to "analyze data" which triggers analysis mode - LLM embeds actual values from sample JSON instead of using merge field placeholders. We tried prompt tweaks but they didn't work. The fundamental issue is that the LLM has never "seen" what a finished prompt looks like.

**Solution:** Few-shot learning. Include 3-5 complete example prompts in the meta-prompt. The LLM will pattern-match and generate output in the same format. This requires:
1. A REST test harness to query schema/data from Salesforce
2. Automated testing to catch regressions before they reach production
3. A Python orchestration script to iterate on meta-prompts
4. Example prompts as few-shot patterns
5. Automated evaluation of generated prompts

---

## Two-Layer Meta-Prompt Architecture (V2.5)

**Date**: 2026-01-25
**Key Insight from User**: Creative thinking should happen at meta-prompt layer (Stage 8), NOT at GPTfy execution layer

### The Consistency vs Intelligence Problem

**Original Concern**: If we execute the same prompt repeatedly, we must get the same style of output. Varying degrees of UI elements erode user trust very quickly.

**Failed Approach**: Adding "Think-Then-Execute" framework to GPTfy prompts → causes variance in output because LLM makes creative decisions at execution time.

**Breakthrough Insight**: The meta-prompt (Stage 8, which generates GPTfy prompts) should contain all creative thinking, design philosophy, and self-evaluation logic. The GPTfy prompt should be deterministic and specific.

### Architecture: Two Layers

```
┌─────────────────────────────────────────────────────────────────┐
│ LAYER 1: META-PROMPT (Stage 8)                                  │
│                                                                  │
│ Purpose: Creative intelligence and design decisions             │
│                                                                  │
│ Contains:                                                        │
│ • Design philosophy (from v2 doc)                               │
│ • Self-evaluation protocol                                      │
│ • Health score methodology                                      │
│ • Component selection framework                                 │
│ • Visual element decision logic                                 │
│ • Story structure guidance                                      │
│ • "What makes a good prompt?" reasoning                         │
│                                                                  │
│ Input: DCM structure, business context, sample data             │
│ Process: Analyze, reason, design, evaluate                      │
│ Output: SPECIFIC deterministic GPTfy prompt template            │
│                                                                  │
│ Runs: ONCE per pipeline (at Stage 8)                            │
│ Can iterate: YES - 10 iterations to perfect the prompt          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Generates
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ LAYER 2: GPTFY PROMPT (Execution)                               │
│                                                                  │
│ Purpose: Deterministic "paint by numbers" execution             │
│                                                                  │
│ Contains:                                                        │
│ • Exact component requirements                                  │
│ • Specific merge field syntax                                   │
│ • Precise layout instructions                                   │
│ • Fixed health score formula                                    │
│ • Conditional alert mapping                                     │
│ • No open-ended reasoning                                       │
│                                                                  │
│ Input: Account/Opportunity/Case data via merge fields           │
│ Process: Execute template, fill placeholders                    │
│ Output: HTML dashboard (consistent structure)                   │
│                                                                  │
│ Runs: EVERY TIME prompt is executed                             │
│ Variability: NONE - same input = same output structure          │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Solves Consistency

**Same DCM Structure** → **Same Meta-Prompt Analysis** → **Same Specific GPTfy Prompt** → **Consistent Output**

Example:
1. User creates pipeline for Opportunity with OpportunityContactRole child
2. Stage 8 meta-prompt analyzes DCM structure, sees Contact relationship
3. Meta-prompt reasons: "Contact names personalize output, health score based on Stage + Amount, use red alerts for at-risk deals"
4. Meta-prompt generates specific GPTfy prompt: "Create health score: (Stage weight * 40) + (Amount/target * 30) + (Days to close * 30). Use red alert if health < 60."
5. Every execution uses this EXACT formula → consistent output

**No variance** because creative decisions happened once at design time, not repeatedly at execution time.

### Implementation Approach

#### Phase 1: Meta-Prompt Storage (Choose One)

**Option A: Builder Record** (Recommended)
- Create new Builder record with Type = "Meta Prompt"
- Store full v2 doc content (728 lines) in `ccai__Prompt_Command__c`
- Stage 8 queries for this type and loads content
- Easy to update via Salesforce UI

**Option B: Static Resource**
- Upload v2 doc as Static Resource
- Reference from Stage 8
- Requires deployment to update

**Option C: Custom Metadata**
- Store in Custom Metadata Type
- More structured but harder to edit long content

**Decision**: Use Builder Record (Type = "Meta Prompt") for consistency with existing pattern.

#### Phase 2: Stage 8 Enhancement

Update `Stage08_PromptAssembly.cls` to:

1. **Load Meta-Prompt**
```apex
private String loadMetaPrompt() {
    List<ccai__AI_Prompt__c> metaPrompts = [
        SELECT ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordType.DeveloperName = 'Builder'
          AND ccai__Type__c = 'Meta Prompt'
          AND ccai__Status__c = 'Active'
        ORDER BY LastModifiedDate DESC
        LIMIT 1
    ];
    return metaPrompts.isEmpty() ? null : metaPrompts[0].ccai__Prompt_Command__c;
}
```

2. **Analyze DCM Structure**
```apex
private Map<String, Object> analyzeDCM(Id dcmId) {
    // Load DCM with all detail records
    // Identify: root object, children, grandchildren, parent lookups
    // Categorize fields: identifiers, metrics, dates, relationships
    // Calculate: field density, data availability
    // Return: structured analysis for meta-prompt
}
```

3. **Call LLM to Generate Specific Prompt**
```apex
private String generateSpecificPrompt(String metaPrompt, Map<String, Object> dcmAnalysis, Id runId) {
    // Build context: meta-prompt + DCM analysis + business context
    // Call Anthropic API (Claude)
    // Receive: Specific deterministic GPTfy prompt with merge fields
    // Validate: Check merge field syntax, no hardcoded values
    // Return: Final prompt template
}
```

4. **Iterative Refinement** (Optional)
```apex
private String iterateOnPrompt(String metaPrompt, Map<String, Object> dcmAnalysis, String previousPrompt, String feedback, Id runId) {
    // If validation fails or quality is low, iterate
    // Include previous attempt + feedback in context
    // LLM adjusts and generates improved version
    // Can iterate up to 10 times until quality threshold met
}
```

#### Phase 3: Meta-Prompt Content Structure

The Meta-Prompt Builder record should contain:

```markdown
# GPTfy Prompt Generation Framework v2.5

You are an expert prompt engineer designing deterministic templates for Salesforce dashboards.

## Design Philosophy
[From v2 doc lines 1-50: Executive-grade quality, diagnostic language, business value quantification]

## Component Selection Framework
[From v2 doc lines 100-200: When to use health scores, alerts, tables, stat cards]

## Self-Evaluation Protocol
[From v2 doc lines 300-400: Checklist for validating output quality]

## Health Score Methodology
[From v2 doc lines 450-500: Formula-based calculation with deductions/bonuses]

## Alert Selection Rules
[From v2 doc lines 550-600: Condition-based mapping to red/orange/blue]

## Output Requirements
[From v2 doc lines 650-728: Merge field syntax, single-line HTML, evidence citations]

## Few-Shot Examples
[3-5 complete example prompts showing good patterns]

## Your Task
Given the DCM structure and business context below, generate a SPECIFIC deterministic GPTfy prompt.

DCM Analysis:
{dcmAnalysis}

Business Context:
{businessContext}

Generate the prompt now...
```

#### Phase 4: Validation & Testing

1. **Merge Field Validation**: Ensure all dynamic values use `{{{FieldName}}}` syntax
2. **No Hardcoded Values**: Check that no actual data from sample JSON is embedded
3. **Structural Consistency**: Verify same DCM → same prompt structure
4. **Quality Metrics**: Evaluate against rubric (diagnostic depth, business value, visual quality)

### Benefits of Two-Layer Architecture

| Benefit | Description |
|---------|-------------|
| **Consistency** | Same input always produces same output structure |
| **Intelligence** | Creative decisions made once, informed by full context |
| **Maintainability** | Update meta-prompt, all future prompts improve |
| **Debuggability** | Can see exact prompt template generated, validate before execution |
| **Iteration** | Can refine meta-prompt 10 times to perfect design without affecting production |
| **Trust** | Users see predictable, professional outputs every time |

### Migration Path

1. **Keep Current Approach**: Existing Stage 8 works as fallback
2. **Add Meta-Prompt Layer**: New `USE_META_PROMPT_V2` flag in Stage 8
3. **A/B Testing**: Run both approaches, compare quality
4. **Gradual Rollout**: Enable for new pipelines first, migrate existing later
5. **Fallback Safety**: If meta-prompt generation fails, use current approach

### Success Criteria

✅ Same DCM structure generates identical prompt template across runs
✅ Generated prompts score 8.5+/10 on quality rubric
✅ No hardcoded values in output
✅ All merge fields use correct syntax
✅ Visual diversity consistent (health + 3-color alerts + table)
✅ Self-evaluation protocol catches issues before finalization

---

## Architectural Fragility Analysis (V2.5)

**Date**: 2026-01-24
**Context**: 100+ hours invested, recurring "fix one thing, break another" cycle
**Reviewed**: Agent Lightning (Microsoft) - training framework for agent optimization

### The Pattern of Failure

Looking at the version history:

1. **V2.2 Abandoned** - Pipeline refactoring broke stage-to-stage data passing. Hours of debugging with no resolution. Root cause: Complex accumulation logic across 12 stage records was too fragile.

2. **V2.5 Attempts Failed** - Multiple approaches tried (TEMPLATE GENERATION MODE, prompt tweaks). LLM continued embedding hardcoded values. Each approach was "emphatically recommended" but didn't work.

3. **100+ Hours of Churn** - Fix Stage 5, Stage 7 breaks. Fix DCM, merge fields fail. Fix merge fields, parent lookups break. Pattern: **manual testing catches issues too late, after deployment**.

### Root Cause: Fragility + No Safety Nets

The problem is NOT agent intelligence (Agent Lightning solves that). The problem IS:

**Architectural Fragility:**
- 12-stage pipeline with complex data dependencies
- Changes to Stage N can break Stage N+3 in non-obvious ways
- DCM creation involves 4+ detail record types (FIELD, CHILD, GRANDCHILD, PARENT_LOOKUP)
- Merge field syntax has multiple formats ({{{Field}}}, {{{Child.Field}}}, {{{Child.Parent.Field}}})
- No validation that generated prompts are valid until runtime

**No Automated Testing:**
- Zero integration tests for full pipeline
- No smoke tests to catch obvious breaks
- Manual testing only - issues discovered after hours of work
- No regression detection - previous working cases can break silently

**Slow Feedback Loops:**
- Deploy → Manual test → Find issue → Debug → Repeat
- Each cycle takes 30-60 minutes minimum
- Claude can't self-validate changes

### Why Agent Lightning Won't Help

Agent Lightning is a **training framework** for agent optimization through reinforcement learning. It would:
- Help if Claude was making poor decisions despite having good information
- Require 20+ hours of setup, telemetry integration, training data collection
- Not prevent architectural fragility or catch regressions

What we actually need:
- **Integration tests** to validate full pipeline works end-to-end
- **Smoke tests** to catch obvious breaks immediately after deployment
- **Regression tests** to ensure previously working cases still work
- **Fast feedback loops** so Claude can validate changes autonomously

### The Solution: Test-Driven Stability

**Phase 5A.5: Automated Testing (NEW - inserted before Python orchestration)**

Create a safety net BEFORE continuing with autonomous iteration:

1. **Golden Test Case** - One known-good Opportunity with all features (children, parents, grandchildren)
2. **Integration Test** - Full pipeline run, validate DCM structure, prompt syntax, no hardcoded values
3. **Stage Smoke Tests** - After each stage, validate expected outputs exist
4. **Deployment Validation** - Script that runs tests before accepting any deployment
5. **Baseline Validation** - Claude can run tests autonomously to verify changes work

**Why This Helps:**
- Catches breaks in minutes, not hours
- Claude can self-validate changes without user intervention
- Prevents "fix one thing, break another" cycle
- Creates confidence that changes are safe
- Establishes a baseline for "working state"

**What This Doesn't Do:**
- Won't make the architecture less fragile (that requires refactoring)
- Won't eliminate all bugs
- Won't reduce complexity

**But it will:** Give us fast, automated feedback so we stop chasing our tail.

---

### Decision: Prioritize Testing Over Features

**Key Insight from User (2026-01-24):**
> "Every approach, including the abandoned ones, were as emphatically proposed and recommended to me as your current recommendation. The challenge is it's really hard to actually know when your recommendation is worth pursuing and when it's not."

**This is the harsh truth.** Claude Code has given confident recommendations before (V2.2 pipeline refactoring, TEMPLATE GENERATION MODE) that failed spectacularly. Without tests, there's no way to validate recommendations objectively.

**Going Forward:**
- Test-driven approach: Write test FIRST, then implement feature
- Validate recommendations: If Claude suggests a change, test it before committing
- Track failures: Document what was tried, what failed, why
- Measure progress: Tests passing = actual progress, not just code written

**This document now serves as a learning log** - not just task tracking, but reasoning tracking. Future Claude sessions should review this section before making confident recommendations.

### Phase 5A: REST Test Harness (Apex)

Create REST endpoints that expose schema discovery and data retrieval capabilities. This allows Python scripts to call Salesforce and gather context without UI interaction.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.1 | Create `TestHarnessController.cls` REST resource | Opus | done | Base class with @RestResource annotation (commit a336187) |
| 5.2 | Add `/test-harness/schema/{objectName}` endpoint | Opus | done | Returns fields, child relationships, parent lookups |
| 5.3 | Add `/test-harness/children/{objectName}` endpoint | Opus | done | Returns child objects with relationship names |
| 5.4 | Add `/test-harness/grandchildren/{objectName}` endpoint | Opus | done | Returns grandchild discovery results |
| 5.5 | Add `/test-harness/sample/{objectName}/{recordId}` endpoint | Opus | done | Returns sample record with related data (JSON) |
| 5.6 | Add `/test-harness/dcm-config` POST endpoint | Opus | done | Builds DCM config from selected objects/fields |
| 5.7 | Add `/test-harness/example-prompts` endpoint | Opus | done | Returns example prompts for few-shot learning |
| 5.8 | Deploy and test REST endpoints | Opus | done | Deployed to agentictso@gptfy.com, basic testing complete |

### Phase 5A.5: Automated Testing (NEW - Critical)

**PRIORITY: Do this BEFORE Phase 5B.** Create safety nets to catch regressions and enable autonomous validation.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.9 | Identify golden test case | Sonnet | done | 006QH00000HjgvlYAB - Opportunity with children, parents, grandchildren |
| 5.10 | Document expected outputs | Sonnet | done | Created docs/testing/GOLDEN_TEST_CASE.md with full specification |
| 5.11 | Create `PipelineIntegrationTest.cls` | Sonnet | done | Created with 7 test methods - deployment deferred (schema fixes needed) |
| 5.12 | Create `PipelineValidator.cls` helper | Sonnet | done | Created with 10 validation methods - deployment deferred |
| 5.13 | Add smoke tests to each stage | Sonnet | done | Built into PipelineValidator (validateStage05-09 methods) |
| 5.14 | Create `scripts/validate-pipeline.sh` | Sonnet | done | Script ready - will work once tests deploy |
| 5.15 | Run baseline and document results | Sonnet | done | Documented in BASELINE_RESULTS.md - schema issues prevent deployment |
| 5.16 | Add test run to git commit hooks | Sonnet | deferred | Skip for V2.5 - manual testing with golden test case instead |

**Phase 5A.5 Decision (2026-01-25)**: Test infrastructure complete but deployment deferred due to schema mismatches. Using **manual validation** with golden test case for V2.5. Automated tests will be fixed and deployed in V2.6 after schema clarification.

### Phase 5B: Python Orchestration Script

Create a Python script that orchestrates meta-prompt testing. Calls REST endpoints, builds meta-prompts, calls LLM API, evaluates output.

**PREREQUISITE: Phase 5A.5 must be complete.** We need tests before autonomous iteration.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.17 | Create `temp/prompt-lab/` directory structure | Opus | not_started | scripts/, examples/, outputs/, config/ |
| 5.18 | Create `config.py` with Salesforce + LLM credentials | Opus | not_started | Load from env vars, support Claude + OpenAI |
| 5.19 | Create `sf_client.py` to call REST endpoints | Opus | not_started | Uses `sf` CLI or requests with OAuth |
| 5.20 | Create `llm_client.py` to call Claude/OpenAI API | Opus | not_started | Wrapper for API calls with retry logic |
| 5.21 | Create `prompt_builder.py` to assemble meta-prompts | Opus | not_started | Combines context + examples + business requirements |
| 5.22 | Create `evaluator.py` to validate generated prompts | Opus | not_started | Checks merge field syntax, structure, no hardcoded values |
| 5.23 | Create `main.py` orchestration script | Opus | not_started | Full loop: gather context → build prompt → call LLM → evaluate |

### Phase 5C: Example Prompts (Few-Shot Patterns)

Extract and organize example prompts for few-shot learning. These show the LLM what good output looks like.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.24 | Extract example prompts from `prepackaged_prompts_raw.json` | Opus | not_started | "Account 360 View - Reimagined" has good patterns |
| 5.25 | Create `examples/account_360.txt` | Opus | not_started | Clean example with merge fields highlighted |
| 5.26 | Create `examples/opportunity_dashboard.txt` | Opus | not_started | Example for Opportunity root object |
| 5.27 | Create `examples/case_analysis.txt` | Opus | not_started | Example for Case root object |
| 5.28 | Document example prompt patterns | Opus | not_started | What makes these examples good (structure, merge fields) |

### Phase 5D: Two-Layer Meta-Prompt Implementation

Implement the two-layer architecture where Stage 8 uses meta-prompt to generate deterministic GPTfy prompts.

**PREREQUISITE: Phase 5A.5 (Automated Testing) and Phase 5C (Example Prompts) must be complete.**

#### Sub-Phase 5D.1: Meta-Prompt Builder Creation

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.29 | Create Meta-Prompt Builder record | Opus | done | Created a0DQH00000KaubF2AR, Type = "Context Template" (temp), Name = "GPTfy Prompt Generation Framework v2.5" |
| 5.30 | Extract v2 doc content into meta-prompt structure | Opus | done | Converted v2 doc into 8-part meta-prompt (Design Philosophy, Component Selection, Health Score, Output Requirements, Self-Evaluation, Input Structure, Examples, Directive) |
| 5.31 | Add few-shot examples to meta-prompt | Opus | done | Added 2 examples: Simple alert-based dashboard + Account 360 with stat cards/tables. 13,457 chars total. |
| 5.32 | Add DCM analysis template to meta-prompt | Opus | done | Enhanced PART 6 with field categorizations (metrics, dates, statuses, identifiers, parentFields) + narrative template. Builder a0DQH00000KaueT2AR, 15,417 chars. |
| 5.33 | Test meta-prompt with Python script | Opus | not_started | Use test harness to validate meta-prompt generates good output |

#### Sub-Phase 5D.2: Stage 8 Enhancement for Two-Layer Architecture

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.34 | Add `loadMetaPrompt()` method to Stage08 | Opus | done | Queries Builder with Type='Context Template', Name='GPTfy Prompt Generation Framework v2.5' |
| 5.35 | Add `analyzeDCM()` method to Stage08 | Opus | done | Categorizes fields (metrics, dates, statuses, identifiers, parentFields) + builds narrative. Includes extractParentLookupNames, categorizeFields, isMetricField/DateField/StatusField, buildDCMNarrative helpers. |
| 5.36 | Add `generateSpecificPrompt()` method to Stage08 | Opus | done | generateSpecificPromptTemplate() calls AIServiceClient.callAI() with meta-prompt + DCM analysis, 8192 max tokens, 0.7 temperature |
| 5.37 | Add `validatePromptQuality()` method to Stage08 | Opus | done | validatePromptTemplate() checks merge fields, iteration blocks, hardcoded values (currency, dates, emails, phones, names), visual components. Includes detectHardcodedValues, countOccurrences helpers. |
| 5.38 | Add `iterateOnPrompt()` method to Stage08 | Opus | done | iterateOnPromptGeneration() loops up to 10 times, generates template, validates, logs errors/warnings, returns on success |
| 5.39 | Add `USE_META_PROMPT_V2` flag to Stage08 | Opus | done | USE_META_PROMPT_V2_5 constant added (default: false). TODO: Enable after API integration tested |
| 5.40 | Update `execute()` method with meta-prompt flow | Opus | done | Added V2.5 branch with early return. Loads builder → Analyzes DCM → Generates/iterates → Returns template. Falls back to V2.0/V1.1 if flag disabled. |

#### Sub-Phase 5D.3: AI API Integration

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.41-5.42 | Configure API credentials | Manual | done | Uses existing AIServiceClient - no new credentials needed! Auto-detects Azure OpenAI, Claude, or DeepSeek from Custom Settings. |
| 5.43 | Integrate with AI API | Opus | done | Updated Stage08 to use AIServiceClient.callAI(systemPrompt, userPrompt, 8192, 0.7). Removed unnecessary AnthropicClient. |
| 5.44 | Add error handling for API failures | Opus | done | AIServiceClient already has retry logic, rate limiting, timeout handling built-in |
| 5.45 | Test API integration end-to-end | Manual | not_started | TODO: Enable USE_META_PROMPT_V2_5 flag and test with golden test case 006QH00000HjgvlYAB |

#### Sub-Phase 5D.4: Iterative Refinement & Testing

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.46 | Run baseline test with meta-prompt v1 | Opus | not_started | Document failure modes (hardcoded values, missing merge fields) |
| 5.47 | Iterate on meta-prompt structure | Opus | not_started | Adjust based on test results, improve instructions |
| 5.48 | Test consistency: same DCM → same prompt | Opus | not_started | Run 10 times, verify identical output structure |
| 5.49 | Test quality: generated prompts score 8.5+/10 | Opus | not_started | Use quality rubric from iteration tracker |
| 5.50 | Document winning meta-prompt pattern | Opus | not_started | What worked, what didn't, final meta-prompt version |
| 5.51 | A/B test: meta-prompt vs current approach | Opus | not_started | Compare quality, consistency, generation time |
| 5.52 | Update meta-prompt builder with final version | Opus | not_started | Deploy winning meta-prompt to Salesforce org |

### Phase 5E: Interactive Refinement (Future)

Enable user-driven refinement of generated prompts.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 5.35 | Add interactive mode to Python script | Opus | not_started | User reviews output, requests changes |
| 5.36 | Implement change requests (add section, modify field) | Opus | not_started | LLM applies user feedback |
| 5.37 | Save final prompt to Salesforce | Opus | not_started | Create AI_Prompt__c record |

---

## Test Harness Architecture (V2.5)

### REST Endpoint Design

```
@RestResource(urlMapping='/test-harness/*')
global class TestHarnessController {

    // GET /services/apexrest/test-harness/schema/Account
    // Returns: { fields: [...], childRelationships: [...], parentLookups: [...] }
    @HttpGet
    global static Map<String, Object> getResource() { ... }

    // POST /services/apexrest/test-harness/dcm-config
    // Body: { rootObject, selectedFields, selectedChildren, ... }
    // Returns: { dcmConfig: {...} }
    @HttpPost
    global static Map<String, Object> postResource() { ... }
}
```

### Python Script Structure

```
temp/prompt-lab/
├── config.py              # Credentials and settings
├── sf_client.py           # Salesforce REST client
├── llm_client.py          # Claude/OpenAI API wrapper
├── prompt_builder.py      # Meta-prompt assembly
├── evaluator.py           # Output validation
├── main.py                # Orchestration entry point
├── examples/
│   ├── account_360.txt    # Few-shot example 1
│   ├── opportunity.txt    # Few-shot example 2
│   └── case_analysis.txt  # Few-shot example 3
├── outputs/
│   └── run_001/           # Output from each test run
└── requirements.txt       # Python dependencies
```

### Evaluation Criteria

A generated prompt passes if:
1. **Merge Fields Used** - All dynamic values use `{{{FieldName}}}` syntax
2. **No Hardcoded Values** - No actual data from sample JSON embedded
3. **Iteration Blocks** - Child records use `{{#Collection}}...{{/Collection}}`
4. **Valid Syntax** - Triple braces for values, double for blocks
5. **Structure Matches** - Similar sections to example prompts
6. **Single-Line HTML** - No newlines in output

### Example Prompt Pattern (from prepackaged_prompts_raw.json)

```html
<table>
  <tr>
    <td><a href="/{{{Opportunities.Id}}}" target="_blank">{{{Opportunities.Name}}}</a></td>
    <td>{{{Opportunities.Amount}}}</td>
    <td>{{{Opportunities.CloseDate}}}</td>
  </tr>
</table>
```

Key patterns to teach the LLM:
- `{{{Object.Field}}}` for child record fields
- `/{{{Object.Id}}}` for Salesforce links
- Table headers OUTSIDE the loop
- Iteration block wraps table rows

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
| 2026-01-24 | Few-shot learning required for prompt generation | Tried prompt tweaks (TEMPLATE GENERATION MODE, WRONG vs CORRECT examples) but LLM still embedded hardcoded values. Root cause: LLM never saw what a finished prompt looks like. Solution: Include 3-5 complete example prompts as few-shot patterns. LLM will pattern-match and generate similar output. |
| 2026-01-24 | Create REST test harness for autonomous iteration | User feedback: manual testing cycle too slow, Claude can iterate faster autonomously. Create REST endpoints to expose SchemaHelper, data retrieval, DCM config. Python script orchestrates: call Salesforce → build meta-prompt → call LLM → evaluate → iterate. No UI clicks needed. |
| 2026-01-24 | Reset V2.5 branch to main | Previous V2.5 attempts (TEMPLATE GENERATION MODE) deployed to org but didn't solve the problem. Reset branch, redeploy main's code, start fresh with test harness approach. |
| 2026-01-24 | Prioritize automated testing over features | After 100+ hours and recurring "fix one thing, break another" cycles, root cause identified: architectural fragility + no safety nets. Agent Lightning (MS training framework) won't solve this - it optimizes agent intelligence, not codebase stability. Decision: Create integration tests, smoke tests, regression tests BEFORE continuing with autonomous iteration. Tests give fast feedback loops and catch breaks immediately. |
| 2026-01-24 | Phase 5A.5: Automated Testing inserted before Phase 5B | New phase with 8 tasks: golden test case, integration test, smoke tests, validation script, baseline run. Claude must be able to self-validate changes autonomously. Tests are prerequisite for Python orchestration - without them, we'll continue chasing tail. |
| 2026-01-24 | This document is now a learning log | Not just task tracking, but reasoning tracking. User feedback: "Every approach was as emphatically proposed and recommended as your current recommendation." Truth: Without tests, there's no objective way to validate recommendations. Future Claude sessions must review Architectural Fragility Analysis before making confident recommendations. |
| 2026-01-25 | Two-layer meta-prompt architecture | User insight: Creative thinking should happen at meta-prompt layer (Stage 8), NOT at GPTfy execution layer. Meta-prompt contains design philosophy, self-evaluation, component selection, health score methodology from v2 doc (728 lines). Stage 8 calls LLM to generate SPECIFIC deterministic GPTfy prompt. Same DCM → same analysis → same prompt → consistent output. Solves consistency vs intelligence tension. Creative decisions happen once at design time, not repeatedly at execution time. Meta-prompt stored as Builder record (Type = 'Meta Prompt'). Stage 8 enhanced with analyzeDCM(), generateSpecificPrompt(), iterateOnPrompt() methods. Can iterate 10 times at meta-prompt layer to perfect design. GPTfy prompts become deterministic execution templates with no open-ended reasoning. |
| 2026-01-25 | Defer automated test deployment to V2.6 | Phase 5A.5 completed (golden test case, PipelineIntegrationTest, PipelineValidator, validation script) but schema mismatches prevent deployment. Tests assume Run__c lookups on DCM/Prompt objects, but relationship is one-way via PF_Run__c.Created_DCM_Id__c. Decision: Use manual validation with golden test case (006QH00000HjgvlYAB) for V2.5. Fix schema issues and deploy tests in V2.6. Rationale: Faster path to Phase 5D implementation, tests are documented and ready when needed. |

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
| 2026-01-24 | V2.5: TEMPLATE GENERATION MODE attempt failed | Opus | Added "CRITICAL - TEMPLATE GENERATION MODE" section to directive, strengthened with WRONG vs CORRECT examples. Deployed and tested. Result: LLM output used ONE merge field ({{{Name}}}) but still embedded hardcoded values ($125,000, John Peterson, etc.). Prompt tweaks insufficient - need structural change. |
| 2026-01-24 | V2.5: Reset branch and new approach | Opus | Deleted failed V2.5 branch, created fresh from main. Fixed buildMergeFieldReference 4-param bug in main. Documented new approach: REST test harness + Python orchestration + few-shot learning. Test harness allows Claude to iterate autonomously without manual UI testing. |
| 2026-01-24 | Tasks 5.1-5.8: REST Test Harness | Opus | Created TestHarnessController.cls with 6 REST endpoints: schema, children, grandchildren, sample, example-prompts, dcm-config. Deployed to agentictso@gptfy.com. Basic testing complete. Commit a336187. |
| 2026-01-24 | Agent Lightning evaluation | Sonnet | Reviewed Microsoft's agent training framework. Conclusion: It's a distraction - solves wrong problem (agent intelligence vs codebase stability). Won't prevent regressions, catch architectural issues, or validate data flows. |
| 2026-01-24 | Architectural Fragility Analysis | Sonnet | Documented pattern of failure across V2.2, V2.5 attempts. Root cause: fragility + no safety nets, not agent intelligence. Added comprehensive analysis to BUILDER_IMPROVEMENTS.md with user feedback about emphatically confident but failed recommendations. |
| 2026-01-24 | Phase 5A.5: Automated Testing designed | Sonnet | Created new phase with 8 tasks (5.9-5.16): golden test case, PipelineIntegrationTest.cls, PipelineValidator.cls, stage smoke tests, validation script, baseline run. Inserted as prerequisite before Phase 5B. Renumbered subsequent tasks. |
| 2026-01-24 | Decision Log + Progress Log updated | Sonnet | Documented testing prioritization decision, learning log approach, all V2.5 Phase 5A work. File now serves as reasoning tracker, not just task tracker. |
| 2026-01-25 | Bug fix: analyzeDCMStructure Map/String type error | Opus | Fixed "Invalid conversion from runtime type Map<String,ANY> to String" at Stage08 line 135. Root cause: deployment lag where old code returned raw Map instead of JSON.serialize() String. Fix: Added defensive type checking with `instanceof String` and fallback serialization. Location: Stage08_PromptAssembly.cls lines 135-143. |

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

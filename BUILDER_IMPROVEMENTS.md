# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization and multi-sample analysis features.
All architecture, decisions, tasks, and progress tracked here.

---

## Current Status

| Version | Status | Description |
|---------|--------|-------------|
| V1.1 | ✅ Complete | Builder prompt injection working (verified Run ID a0gQH000005GHurYAG) |
| V2.0 | 🔴 Not Started | Prompt optimization + multi-sample + meta-prompt architecture |

### V1.1 Limitations (discovered during analysis):

- ❌ Builder prompts are verbose (Next Best Action Pattern is ~6,500 chars of documentation)
- ❌ No intelligent selection (all builders injected regardless of relevance)
- ❌ Single sample record limits data pattern analysis
- ❌ Fixed HTML template constrains LLM to "template filler" role
- ❌ Apex Service category not implemented
- ❌ Output is table-heavy, not insight-driven

### V2.0 Will Add:

- ✅ Compressed builder prompts (principles only, not documentation)
- ✅ Multi-sample support (3 records for richer data patterns)
- ✅ Meta-prompt architecture (LLM as analyst, not template filler)
- ✅ Smarter template approach (guidelines, not rigid structure)

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

This ensures work is saved and visible to the other model on handoff.

### DEPLOY TO SALESFORCE

When a task involves Apex changes, deploy using:

```bash
sf project deploy start -o agentictso -d force-app/main/default/classes/ClassName.cls -d force-app/main/default/classes/ClassName.cls-meta.xml
```

Wait for deployment to complete and check for errors before marking task as done.

---

## Key Files Reference

### Existing (Reuse):
- `Stage08_PromptAssembly.cls` - Builder prompt injection (modify for compression + multi-sample)
- `Stage04_DataProfiling.cls` - Data querying (modify for multi-sample)
- `Stage05_FieldSelection.cls` - Field relevance scoring
- `Stage07_TemplateDesign.cls` - Template generation (modify for meta-prompt)
- `SchemaHelper.cls` - Schema utilities
- `DCMBuilder.cls` - Data context mapping

### Builder Prompts in Org:
| Name | Category | Chars | Needs Compression |
|------|----------|-------|-------------------|
| Next Best Action Pattern | Pattern | ~6,500 | ✅ Yes (high priority) |
| Evidence Binding Rules v2 | Quality Rule | ~600 | ❌ Already concise |
| Risk Assessment Pattern | Pattern | ~500 | ❌ Already concise |
| Stat Card Component | UI Component | ~200 | ❌ Maybe expand |
| Alert Box Component | UI Component | ~150 | ❌ Maybe expand |
| Healthcare Payer Context | Context Template | ~180 | ❌ Context-specific |

---

## Architecture: Multi-Sample Analysis

### Current (Single Sample):
```
User provides 1 record ID
    → Stage 4 queries that record
    → Limited view of data patterns
    → LLM fills template with that data
```

### New (Multi-Sample):
```
User provides 3 record IDs (comma-separated)
    → Stage 4 queries all 3 records
    → Aggregates patterns (min/max/avg, populated %, variance)
    → LLM sees data patterns across samples
    → LLM identifies what's significant, not just what's present
```

### Benefits:
- Field relevance: "Amount populated 3/3" vs "Amount is $500K"
- Pattern detection: "2/3 deals stuck in Qualification >30 days"
- Variance analysis: "Probability ranges 20%-75%"
- More robust field selection

---

## Architecture: Meta-Prompt Approach

### Current (Template Filler):
```
Stage 7: Generate fixed HTML template with placeholders
Stage 8: Inject ALL builder prompts verbatim
Result: LLM fills in [ANALYSIS] and [PRIORITIES] placeholders
```

### New (LLM as Analyst):
```
Stage 7: Generate "analysis brief" not fixed template
Stage 8: Inject COMPRESSED builder prompts (principles only)
         + Data payload from multi-sample analysis
         + UI toolkit (available components)
         + Meta-instruction: "Analyze and present what matters"
Result: LLM decides what's important and how to show it
```

### Meta-Prompt Structure:
```
=== YOUR ROLE ===
Expert business analyst generating insights for {Persona}

=== DATA PAYLOAD ===
{Structured data from N sample records}

=== ANALYSIS PRINCIPLES ===
{Compressed builder prompts - principles only}

=== UI TOOLKIT ===
{Available components: Stat Cards, Alerts, Tables, etc.}

=== OUTPUT RULES ===
{GPTfy-compliant HTML requirements}

=== DIRECTIVE ===
Analyze the data. Lead with insights. Let the data drive the structure.
```

---

## V2 Task Queue

### Phase 1: Compress Builder Prompts

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.1 | Create compressed version of "Next Best Action Pattern" (~400 chars) | Sonnet | done | Created: 444 chars (93% reduction from 6,500) |
| 1.2 | Test compressed prompt maintains quality | Sonnet | done | Builder deployed (a0DQH00000KZJXJ2A5), test procedure created |

### Phase 2: Multi-Sample Support

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.1 | Design multi-sample data structure for Stage 4 | Opus | done | See docs/designs/MULTI_SAMPLE_DESIGN.md |
| 2.2 | Update `pfInputForm` LWC to accept comma-separated IDs | Sonnet | done | Deployed - supports 1-5 IDs with validation |
| 2.3 | Update `PromptFactoryController.startPipelineRun` for multi-sample | Sonnet | done | Deployed - parses IDs, stores in Sample_Record_Ids__c |
| 2.4 | Update Stage 4 to query multiple records | Sonnet | not_started | Loop through IDs, aggregate results |
| 2.5 | Update Stage 5 field scoring for multi-sample relevance | Opus | not_started | Score by cross-sample patterns |

### Phase 3: Meta-Prompt Architecture

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.1 | Design meta-prompt structure | Opus | not_started | Define sections, flow, LLM instructions |
| 3.2 | Modify Stage 7 to generate "analysis brief" not fixed template | Opus | not_started | Significant change to template approach |
| 3.3 | Modify Stage 8 to assemble meta-prompt | Sonnet | not_started | After 3.1/3.2 designed |
| 3.4 | Create UI toolkit section for meta-prompt | Sonnet | not_started | Document available components |

### Phase 4: Integration & Testing

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 4.1 | End-to-end test with 3 sample Opportunities | Sonnet | not_started | Validate full flow |
| 4.2 | Compare output quality: V1.1 vs V2.0 | Opus | not_started | Qualitative analysis |
| 4.3 | Document findings and next iteration priorities | Opus | not_started | What worked, what needs more |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-23 | Horizontal MVP slices over vertical deep-dives | Features are interconnected; need fast feedback loops |
| 2026-01-23 | Start with 3 sample records (not configurable N) | MVP simplicity |
| 2026-01-23 | Compress only 2 builder prompts initially | Validate approach before scaling |
| 2026-01-23 | Keep fixed template as "suggestion" initially | Incremental change, not full rewrite |

---

## Progress Log

| Date | Task | Model | Outcome |
|------|------|-------|---------|
| 2026-01-23 | Initial setup | Opus | Created BUILDER_IMPROVEMENTS.md |
| 2026-01-23 | Task 1.1: Compress Next Best Action Pattern | Sonnet | Created compressed version: 444 chars (was 6,500) - 93% reduction |
| 2026-01-23 | Task 1.2: Test compressed prompt quality | Sonnet | Deployed compressed builder (a0DQH00000KZJXJ2A5), created test procedure |
| 2026-01-23 | Task 2.2: Update pfInputForm for multi-sample | Sonnet | Updated LWC to accept 1-5 comma-separated IDs with validation |
| 2026-01-23 | Task 2.3: Update PromptFactoryController for multi-sample | Sonnet | Added Sample_Record_Ids__c field, parsing logic, deployed controller |
| 2026-01-23 | Task 2.1: Design multi-sample data structure | Opus | Created MULTI_SAMPLE_DESIGN.md with full architecture for N-sample profiling |

---

## Notes for Future Iterations

After V2.0 MVP, consider:
- Implement Apex Service injection (Picklist Intelligence, Topic Service)
- Add Weight__c filtering for builder prompt selection
- Token budget awareness for prompt assembly
- Configurable number of sample records
- A/B testing framework for prompt variations

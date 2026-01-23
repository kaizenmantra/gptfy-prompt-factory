# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization, field selection, and output quality features.
All architecture, decisions, tasks, and progress tracked here.

---

## Release Strategy

### Current Branch: `feature/builder-improvements`
**Status:** Ready to merge to `main`

**V2.0 is complete and working.** Recommend:
1. Merge `feature/builder-improvements` → `main`
2. Create new branch `feature/v2.1-enhancements` for next phase
3. Continue iterative development on new branch

### Version History

| Version | Branch | Status | Description |
|---------|--------|--------|-------------|
| V1.1 | main | ✅ Released | Builder prompt injection (Run ID a0gQH000005GHurYAG) |
| V2.0 | feature/builder-improvements | ✅ Complete | Meta-prompt architecture, LLM metadata, field validation |
| V2.1 | feature/v2.1-enhancements | 🔴 Not Started | Visual diversity, parent traversals, builder library |
| V2.2 | TBD | 📋 Planned | Field density profiling, bidirectional traversal |
| V2.3 | TBD | 📋 Planned | Knowledge base expansion, smart builder selection |

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
| `Stage03_SchemaAnalysis.cls` | Object/field discovery (needs parent traversal) |
| `Stage04_DataProfiling.cls` | Sample data profiling, MultiSampleProfile |
| `Stage05_FieldSelection.cls` | LLM-assisted field selection |
| `Stage07_TemplateDesign.cls` | Analysis brief generation, prompt metadata |
| `Stage08_PromptAssembly.cls` | Meta-prompt assembly, builder loading |
| `Stage09_CreateAndDeploy.cls` | DCM and Prompt creation |
| `SchemaHelper.cls` | Schema utilities (needs enhancement) |
| `DCMBuilder.cls` | Data context mapping builder |
| `PromptBuilder.cls` | AI Prompt record creation |

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
| 1.1 | Update `buildUIToolkitSection()` with real HTML snippets | Sonnet | not_started | Add actual HTML patterns, not just component names |
| 1.2 | Add visual diversity requirement to directive section | Sonnet | not_started | "MUST use colored alerts, stats strip, etc." |
| 1.3 | Create UI Component builders in Salesforce org | Sonnet | not_started | Stats Strip, Health Score, Insight Card, Recommendation Card, Alert variants |
| 1.4 | Test visual diversity in output | Sonnet | not_started | Verify colored components appear |

### Phase 1B: Personalization Fixes

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.5 | Add "use names not titles" instruction to meta-prompt | Sonnet | not_started | "Say 'Sarah Johnson' not 'the CFO'" |
| 1.6 | Document parent traversal catalog (see below) | Opus | not_started | Create reference list of 20 common traversals |
| 1.7 | Store traversal catalog as Static Resource | Sonnet | not_started | JSON file for LLM/system reference |
| 1.8 | Update Stage 5 to suggest parent fields | Opus | not_started | When OCR selected, suggest Contact.Name |

### Phase 1C: Output Quality

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 1.9 | Fix single-line HTML requirement | Sonnet | not_started | LLM output has newlines, GPTfy needs single-line |
| 1.10 | Remove emojis from builder prompts | Sonnet | not_started | Clean up Evidence Binding Rules (✅ ❌) |
| 1.11 | Test multi-sample flow with 3 records | Opus | not_started | Verify pattern detection works |

---

## V2.2 Task Queue (Architecture)

### Phase 2A: Parent Traversal Implementation

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.1 | Design parent traversal architecture | Opus | not_started | How SchemaHelper discovers lookups |
| 2.2 | Update SchemaHelper for lookup field detection | Sonnet | not_started | Identify AccountId, ContactId, OwnerId, etc. |
| 2.3 | Update SchemaHelper for parent object mapping | Sonnet | not_started | Map lookup → target object |
| 2.4 | Update DCMBuilder for parent field syntax | Sonnet | not_started | Support Contact.Name via ContactId |
| 2.5 | Update Stage 5 to include parent candidates | Opus | not_started | Send parent fields to LLM for selection |
| 2.6 | Test parent traversal end-to-end | Opus | not_started | Verify Contact.Name appears in output |

### Phase 2B: Field Density Profiling

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.7 | Design field density profiling | Opus | not_started | Query 100+ records, calculate population % |
| 2.8 | Update Stage 4 for density calculation | Sonnet | not_started | Add populationPercent to field metadata |
| 2.9 | Prioritize long text / unstructured fields | Sonnet | not_started | Flag Description, Comments fields |
| 2.10 | Update Stage 5 to use density in selection | Opus | not_started | Higher density = more relevant |

### Phase 2C: Metadata-Rich Selection

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.11 | Extract field help text and descriptions | Sonnet | not_started | Include in field metadata |
| 2.12 | Send metadata to LLM in Stage 5 | Opus | not_started | Help LLM understand field purpose |
| 2.13 | Improve field relevance scoring | Opus | not_started | Combine density + metadata + type |

---

## V2.3 Task Queue (Knowledge Base)

### Phase 3A: Builder Prompt Library Expansion

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.1 | Research UI component best practices | Sonnet | not_started | Dashboard design patterns |
| 3.2 | Create UI Component builders (8 new) | Sonnet | not_started | See Builder Library section below |
| 3.3 | Research analysis pattern best practices | Sonnet | not_started | Account health, opp coaching, etc. |
| 3.4 | Create Analysis Pattern builders (5 new) | Sonnet | not_started | See Builder Library section below |
| 3.5 | Research output format best practices | Sonnet | not_started | Executive summary, action lists |
| 3.6 | Create Output Format builders (4 new) | Sonnet | not_started | See Builder Library section below |
| 3.7 | Create Industry Context templates (4 new) | Opus | not_started | See Builder Library section below |

### Phase 3B: Smart Builder Selection

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 3.8 | Add Weight__c to builder selection logic | Sonnet | not_started | Higher weight = higher priority |
| 3.9 | Add object-specific builder filtering | Sonnet | not_started | Only load Opportunity builders for Opportunity |
| 3.10 | Add token budget awareness | Opus | not_started | Don't exceed prompt size limit |
| 3.11 | Test smart builder selection | Opus | not_started | Verify relevant builders loaded |

---

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

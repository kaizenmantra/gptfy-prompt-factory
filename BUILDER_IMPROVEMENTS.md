# Builder Improvements - Implementation Tracker

Single source of truth for builder prompt optimization, field selection, and output quality features.
All architecture, decisions, tasks, and progress tracked here.

---

## CURRENTLY ACTIVE WORK (Check Before Starting)

| Model | Task | File Being Modified | Started |
|-------|------|---------------------|---------|
| - | - | - | - |

**Status:** V2.1 COMPLETE. V2.2 in progress (12/20 tasks done) - Opus tasks complete, Sonnet tasks remaining.

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
| V2.1 | feature/v2.1-enhancements | ✅ Complete | Visual diversity, parent traversals, builder library |
| V2.2 | feature/v2.2-schema-intelligence | 📋 Planned | Schema enrichment (helpText, density), parent traversal resolution |
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

## V2.2 Task Queue (Schema Intelligence)

**Goal:** Make field selection smarter by enriching schema metadata with helpText, density, and parent relationships. Then make parent fields actually work end-to-end in the output.

**Reference Implementation:** Logic ported from `gptfy-claude-automation` repo:
- `scripts/discover-fields.sh` → Field metadata, density calculation
- `scripts/discover-relationships.sh` → Parent lookup detection

---

### Phase 2A: Schema Enrichment (Foundation)

Enhance SchemaHelper with richer field metadata. Port logic from shell scripts.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.1 | Add helpText to FieldMetadata class | Sonnet | done | Added `helpText` from field describe |
| 2.2 | Add picklistValues to FieldMetadata class | Sonnet | done | Added `List<PicklistValue>` with value, label, active, isDefault |
| 2.3 | Add parent lookup detection to SchemaHelper | Sonnet | done | Added `getParentRelationships()` method and `ParentRelationship` class |
| 2.4 | Add field categorization to FieldMetadata | Sonnet | done | Added `category` field and `categorizeField()` helper |

### Phase 2B: Field Density Profiling

Query actual records to determine which fields are populated. Port from discover-fields.sh CHECK_USAGE section.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.5 | Design density profiling approach | Opus | done | New `calculateFieldDensity()` method in SchemaHelper. See docs/design/V2.2_DESIGN_SPECS.md |
| 2.6 | Implement field density calculation | Sonnet | not_started | Query N records (configurable, default 100), count non-null values per field. Port from discover-fields.sh lines 251-275 |
| 2.7 | Add usagePercent to FieldMetadata | Opus | done | Already added in Phase 2A (Task 2.1) - field exists, needs 2.6 to populate it |
| 2.8 | Integrate density into Stage 4 or Stage 5 | Sonnet | not_started | Call density calculation, merge into field metadata before LLM selection |

### Phase 2C: Parent Traversal Resolution (Core Feature)

Make parent fields actually work in DCM and final output. V2.1 added suggestions; V2.2 makes them real.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.9 | Design parent field resolution architecture | Opus | done | Dot notation in DCM fields (Owner.Name). See docs/design/V2.2_DESIGN_SPECS.md |
| 2.10 | Update DCMBuilder for parent field syntax | Sonnet | not_started | Support `Account.Name` via `AccountId` lookup. Investigate GPTfy DCM parent field format |
| 2.11 | Update Stage 8 to include parent fields in DCM config | Sonnet | not_started | Pass selectedParentFields from Stage 5 through to DCM creation |
| 2.12 | Update merge field reference for parent fields | Sonnet | not_started | Show `{{{Account.Name}}}` syntax in available merge fields section |
| 2.13 | Test parent traversal end-to-end | Manual | not_started | Verify `{{{Owner.Name}}}` resolves to actual user name in output |

### Phase 2D: LLM-Enhanced Field Selection

Send enriched metadata to LLM for smarter field selection.

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.14 | Update Stage 5 prompt with helpText | Opus | done | Fields now show helpText in quotes when available |
| 2.15 | Update Stage 5 prompt with density | Opus | done | Fields show [X% populated] when usagePercent is set (needs 2.6 to populate) |
| 2.16 | Update Stage 5 prompt with categories | Opus | done | Fields grouped by category with relevance hints (did this with 2.14/2.17) |
| 2.17 | Add relevance scoring hints | Opus | done | getCategoryRelevanceHint() provides HIGH/MEDIUM/LOW VALUE hints per category |

### Phase 2E: Testing & Validation

| # | Task | Model | Status | Notes |
|---|------|-------|--------|-------|
| 2.18 | Create test script for enriched schema | Sonnet | not_started | Verify FieldMetadata has helpText, density, category |
| 2.19 | Create test script for parent field resolution | Sonnet | not_started | Verify DCM includes parent fields, output shows resolved values |
| 2.20 | End-to-end V2.2 validation | Manual | not_started | Full pipeline test with enriched metadata and parent fields |

---

### V2.2 Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| 2A | 2.1-2.4 | Schema enrichment (helpText, picklist, parents, categories) |
| 2B | 2.5-2.8 | Field density profiling (query records, calculate %) |
| 2C | 2.9-2.13 | Parent traversal resolution (make it actually work) |
| 2D | 2.14-2.17 | LLM-enhanced selection (use the enriched data) |
| 2E | 2.18-2.20 | Testing & validation |

**Total: 20 tasks** (was 13 in original plan)

**Key Deliverables:**
1. `SchemaHelper.FieldMetadata` enriched with helpText, picklistValues, category, usagePercent
2. `SchemaHelper.getParentRelationships()` for lookup field detection
3. Field density calculation (query N records, count non-nulls)
4. DCMBuilder parent field support (`Account.Name` via `AccountId`)
5. Stage 5 prompt includes enriched metadata for smarter selection
6. Parent fields resolve to actual values in final output

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
| 2026-01-23 | Task 1.6: Traversal builders | Opus | Added 17 new traversals to insert_builder_prompts.apex (now 25 total, 50 builders overall) |
| 2026-01-23 | Task 1.8: Parent field suggestions | Opus | Updated Stage 5 to load traversal builders and suggest parent fields to LLM |
| 2026-01-23 | Tasks 1.1, 1.2, 1.5: Visual diversity & personalization | Sonnet | Added HTML snippets to UI toolkit, visual diversity requirement, name personalization |
| 2026-01-23 | Tasks 1.3, 1.7: Builder deployment | Sonnet | Verified 59 active builders deployed (12 UI Components, 25 Traversals) |
| 2026-01-23 | Tasks 1.9, 1.10: Output quality fixes | Sonnet | Strengthened single-line HTML instruction, removed emojis from Evidence builder |
| 2026-01-23 | Task 1.8: Stage 5 parent traversals | Opus | Wired traversal builders into field selection: loadTraversalsForObjects(), prompt section, selectedParentFields output |
| 2026-01-23 | Tasks 1.4, 1.11: V2.1 End-to-End Testing | Manual | V2.1 fully validated - Stats Strip, Insight Cards, Recommendation Cards, personalization (names not titles), evidence citations, single-line HTML |
| 2026-01-23 | Bug fix: Invalid merge field references | Opus | Fixed hardcoded Tasks example in buildMergeFieldReference(); now dynamic based on selected objects. Added CRITICAL RESTRICTION to prevent LLM from inventing merge fields |

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

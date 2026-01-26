# Claude Code Instructions for GPTfy Prompt Factory

## Critical Rules

1. **READ EXISTING CODE FIRST** - Before writing ANY new code, search the codebase for existing implementations. This project has mature infrastructure - most patterns already exist.

2. **Stay Within Scope** - Current work is V2.6 (visual richness). Do not add features outside this scope.

3. **UPDATE PROJECT RESOURCES INDEX** - When you create ANY of the following, you MUST update the "Project Resources Index" section at the bottom of this file:
   - New test scripts or test harnesses
   - New REST API endpoints
   - New utility scripts in `scripts/apex/`
   - New documentation files
   - New key Apex classes
   - New test accounts or sample records

   This keeps the index current and prevents future sessions from searching for tools that already exist.

4. **ALWAYS USE SF CLI, NOT APEX** - For queries, use `sf data query` NOT anonymous Apex:
   ```bash
   # GOOD - Use sf CLI
   sf data query -o agentictso -q "SELECT Id, Name FROM Account LIMIT 5"

   # BAD - Don't write Apex for simple queries
   sf apex run -f /tmp/query.apex  # AVOID THIS
   ```
   Only use `sf apex run` when you need to:
   - Start pipeline runs (System.enqueueJob)
   - Execute DML operations
   - Run complex logic that can't be done with queries

5. **Use Existing Scripts**
   - Deploy: `sf project deploy start -o agentictso -d <path>`
   - Commit: `./scripts/gitcommit.sh "message"`
   - Query: `sf data query -o agentictso -q "SOQL here"`

6. **Check Project Resources Index First** - Before searching for test harnesses, scripts, or endpoints, check the "Project Resources Index" section below. It catalogs all existing tools.

7. **Commit Often** - After completing each task or group of related tasks, commit with gitcommit.sh.

## V2.6 Scope (Current Work)

Goal: Visual richness and creative freedom in generated dashboards.

### Phase 6A: UI Components (Database) ✅ DONE
- Created 10 new UI component builders (Progress Ring, Trend Indicator, etc.)
- Total: 22 active UI Components

### Phase 6B: Data-Driven Design (Code)
- Add `buildDataDrivenDesignSection()` to Stage08
- Pattern-based component selection guidance

### Phase 6C: Remove Rigid Structure (Code)
- Update `buildDirectiveSection()` for story-driven layouts
- Encourage creative expression

### Phase 6D: Testing
- Test with Pinnacle Wealth Partners account
- Compare V2.5 vs V2.6 output

## Key Files

- `BUILDER_IMPROVEMENTS.md` - Master task tracker
- `Stage08_PromptAssembly.cls` - Meta-prompt assembly
- `temp/test-v2.5-e2e.apex` - End-to-end test script

## Deployment Target

- Org alias: `agentictso`
- Test Account ID: `001QH000024mdDnYAI` (Pinnacle Wealth Partners)
- Test Account ID: `001QH000024pY3ZYAU` (Innovatek Solutions) - Used for V2.6 testing

---

## Project Resources Index

**READ THIS SECTION** when looking for existing tools, scripts, or test infrastructure.

### Test Harnesses (Automated Testing)

| Script | Purpose | How to Run |
|--------|---------|------------|
| `tests/v26/run_innovatek_test.py` | V2.6 end-to-end test: starts pipeline, calls GPTfy API, scores output | `python3 tests/v26/run_innovatek_test.py` |
| `tests/phase0/run_full_test.py` | Phase 0 variant testing: updates prompts, executes via GPTfy API | `python3 tests/phase0/run_full_test.py` |
| `tests/phase0/score_outputs.py` | Score HTML output: evidence, forbidden phrases, diagnostic language | `python3 tests/phase0/score_outputs.py` |
| `tests/phase0c/run_phase0c_test.py` | Pattern + UI component testing (19 variants) | `python3 tests/phase0c/run_phase0c_test.py` |

### REST API Endpoints (Custom Apex)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/services/apexrest/test-harness/start-pipeline` | POST | Start pipeline run (Stages 1-9) |
| `/services/apexrest/test-harness/run-status/{runId}` | GET | Poll pipeline status, get promptId |
| `/services/apexrest/test-harness/schema/{objectName}` | GET | Get object schema info |
| `/services/apexrest/test-harness/children/{objectName}` | GET | Get child relationships |
| `/services/apexrest/test-harness/sample/{objectName}/{recordId}` | GET | Get sample record with children |
| `/services/apexrest/ccai/v1/executePrompt` | POST | **GPTfy API** - Execute prompt directly (bypasses Stage 10 Apex) |

### Apex Scripts (in `scripts/apex/`)

| Script | Purpose |
|--------|---------|
| `insert_builder_prompts.apex` | Insert/update builder prompt records |
| `insert_output_rules_builder.apex` | Insert Output Rules builder |
| `migrate_builders_to_type.apex` | Migrate builders from Category__c to ccai__Type__c |
| `consolidate_traversals_pilot.apex` | Consolidate traversal builders by object |

### Temp Test Scripts (in `/tmp/`)

| Script | Purpose |
|--------|---------|
| `/tmp/start_innovatek_v3.apex` | Start pipeline for Innovatek with v3 Quality Rules |
| `/tmp/update_quality_rules_v3.apex` | Update Quality Rules (Compressed) builder content |

### Key Documentation Files

| File | Contents |
|------|----------|
| `BUILDER_IMPROVEMENTS.md` | **Master tracker**: All tasks, architecture, decisions, progress log |
| `docs/UI_TOOLKIT.md` | UI component library with HTML examples |
| `docs/designs/META_PROMPT_DESIGN.md` | 6-section meta-prompt architecture |
| `docs/quality-rules/PROMPT_GENERATION_RULES.md` | Merge field syntax, output rules |
| `docs/test-procedures/TASK_4.1_V2_END_TO_END_TEST.md` | V2.0 testing procedure |

### Key Apex Classes

| Class | Purpose |
|-------|---------|
| `TestHarnessController.cls` | REST API for autonomous testing |
| `Stage08_PromptAssembly.cls` | Meta-prompt assembly (TODAY'S DATE, Quality Rules, etc.) |
| `Stage05_FieldSelection.cls` | LLM-assisted field selection |
| `Stage12_QualityAudit.cls` | Quality scoring (8 dimensions) |
| `SchemaHelper.cls` | Schema utilities (getFields, getChildRelationships) |
| `DCMBuilder.cls` | Data Context Mapping builder |
| `PipelineState.cls` | JSON file state management |

### Scoring Logic Locations

| Location | Metrics |
|----------|---------|
| `tests/phase0/score_outputs.py` | Python: evidence citations, forbidden phrases, customer refs, diagnostic ratio |
| `tests/v26/run_innovatek_test.py` | Python: evidence, date analysis, forbidden, colors, customer refs (target: 90+) |
| `Stage12_QualityAudit.cls` | Apex: 8 AI-scored dimensions (Evidence 20%, Diagnostic 15%, Visual 15%, etc.) |

### Common Test Accounts

| Account | ID | Use Case |
|---------|----|---------|
| Innovatek Solutions | `001QH000024pY3ZYAU` | V2.6 Account 360 testing |
| Pinnacle Wealth Partners | `001QH000024mdDnYAI` | V2.5 testing |
| McDonald's Franchise Healthcare | (Opportunity) `006QH00000HjgvlYAB` | Phase 0 opportunity testing |

---

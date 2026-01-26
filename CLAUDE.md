# Claude Code Instructions for GPTfy Prompt Factory

## Critical Rules

1. **READ EXISTING CODE FIRST** - Before writing ANY new code, search the codebase for existing implementations. This project has mature infrastructure - most patterns already exist.

2. **Stay Within Scope** - Current work is V2.6 (visual richness). Do not add features outside this scope.

3. **ALWAYS USE SF CLI, NOT APEX** - For queries, use `sf data query` NOT anonymous Apex:
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

4. **Use Existing Scripts**
   - Deploy: `sf project deploy start -o agentictso -d <path>`
   - Commit: `./scripts/gitcommit.sh "message"`
   - Query: `sf data query -o agentictso -q "SOQL here"`

5. **Test Harness** - Use existing test files in `/temp/` and `/scripts/apex/` directories.

6. **Commit Often** - After completing each task or group of related tasks, commit with gitcommit.sh.

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

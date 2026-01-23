# Claude Code Instructions for GPTfy Prompt Factory

This document contains specific instructions for Claude Code when working with this repository.

---

## Git Commit Workflow

**IMPORTANT**: Always use the `scripts/gitcommit.sh` script for commits instead of raw git commands.

### Standard Commit Process

Instead of:
```bash
git add -A
git commit -m "message"
git push origin branch
```

**Always use:**
```bash
./scripts/gitcommit.sh "commit message"
```

### Examples

```bash
# Simple commit (uses current branch)
./scripts/gitcommit.sh "feat: Add child relationship querying to PromptBuilderController"

# Commit to specific branch
./scripts/gitcommit.sh "fix: Update SOQL query logic" feature/interactive-prompt-builder

# With conventional commit prefix
./scripts/gitcommit.sh "refactor: Extract relationship selection to helper method"
```

### Why Use the Script?

The `scripts/gitcommit.sh` script provides:
- Consistent commit message formatting
- Automatic staging of all changes
- Safety checks before committing
- Automatic push to remote
- Colored output for better readability
- Salesforce-specific deployment reminders
- Better error handling

### Conventional Commit Prefixes

Use these prefixes in commit messages:
- `feat:` - New feature (LWC, Apex class, custom object)
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks
- `docs:` - Documentation updates
- `test:` - Adding tests

Project-specific:
- `lwc:` - Lightning Web Component changes
- `apex:` - Apex class/trigger changes
- `config:` - Salesforce configuration changes

---

## Deployment Process

After committing Salesforce metadata changes, deploy using:

```bash
# Deploy Apex classes
sf project deploy start -o <org-alias> -d force-app/main/default/classes/ClassName.cls -d force-app/main/default/classes/ClassName.cls-meta.xml

# Deploy LWC
sf project deploy start -o <org-alias> -d force-app/main/default/lwc/componentName

# Deploy full force-app
sf project deploy start -o <org-alias> -d force-app/main/default
```

Default org alias: `agentictso`

---

## Task Tracking

When working on tasks from `INTERACTIVE_BUILDER.md`:

1. Update task status to `in_progress` when starting
2. Commit changes with task reference: `"feat: Task 18 - Build SOQL query with child relationships"`
3. Update task status to `done` when complete
4. Deploy to Salesforce if metadata changed

---

## File Organization

### Key Documentation Files
- `INTERACTIVE_BUILDER.md` - Current development tasks and architecture
- `README.md` - Project overview and installation
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `LLM_CONFIGURATION_GUIDE.md` - LLM setup guide

### Code Locations
- Apex Controllers: `force-app/main/default/classes/`
- LWC Components: `force-app/main/default/lwc/`
- Custom Objects: `force-app/main/default/objects/`
- Static Resources: `force-app/main/default/staticresources/`

### Scripts
- `scripts/gitcommit.sh` - Git commit and push
- Other utility scripts as needed

---

## Best Practices

1. **Always use `scripts/gitcommit.sh` for commits**
2. Read existing code before making changes
3. Follow Salesforce best practices (governor limits, FLS, etc.)
4. Include Co-Authored-By in commit messages when requested
5. Test changes in Salesforce org before marking tasks complete
6. Keep commits focused and atomic
7. Update task tracking in `INTERACTIVE_BUILDER.md`

---

## Common Commands

```bash
# Commit changes
./scripts/gitcommit.sh "feat: Description of changes"

# Deploy to Salesforce
sf project deploy start -o agentictso -d force-app/main/default

# Check git status
git status

# View task queue
cat INTERACTIVE_BUILDER.md | grep -A 20 "V2 Task Queue"

# Run Apex tests
sf apex run test -o agentictso --test-level RunLocalTests
```

---

**Last Updated**: 2026-01-22

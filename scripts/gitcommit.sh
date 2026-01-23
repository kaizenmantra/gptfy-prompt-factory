#!/bin/bash

# =============================================================================
# GPTfy Prompt Factory - Git Commit & Push Script
# =============================================================================
#
# This script handles git commits with consistent formatting and safety checks.
#
# Features:
# - Validates commit message is provided
# - Shows changed files before committing
# - Supports optional branch specification
# - Follows conventional commit standards
#
# Usage:
#   ./scripts/gitcommit.sh "commit message" [branch_name]
#
# Examples:
#   ./scripts/gitcommit.sh "Add prompt builder controller"
#   ./scripts/gitcommit.sh "Fix interactive chat component" feature/interactive-builder
#   ./scripts/gitcommit.sh "refactor: extract HTML conversion logic"
#
# =============================================================================

set -e  # Exit on error

# =============================================================================
# Colors for output
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
}

print_step() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    echo "GPTfy Prompt Factory - Git Commit & Push Script"
    echo ""
    echo "Usage: ./scripts/gitcommit.sh \"commit message\" [branch_name]"
    echo ""
    echo "Arguments:"
    echo "  commit message     Required. The commit message (use quotes)"
    echo "  branch_name        Optional. Branch to push to (default: current branch)"
    echo ""
    echo "Examples:"
    echo "  ./scripts/gitcommit.sh \"Add prompt builder controller\""
    echo "  ./scripts/gitcommit.sh \"Fix interactive chat UI\" feature/interactive-builder"
    echo "  ./scripts/gitcommit.sh \"feat: add HTML conversion with merge fields\""
    echo ""
    echo "Conventional Commit Prefixes:"
    echo "  feat:     New feature (LWC, Apex class, custom object)"
    echo "  fix:      Bug fix"
    echo "  refactor: Code refactoring"
    echo "  chore:    Maintenance tasks"
    echo "  docs:     Documentation updates"
    echo "  test:     Adding tests (Jest, Apex tests)"
    echo ""
    echo "Project-Specific Prefixes:"
    echo "  lwc:      Lightning Web Component changes"
    echo "  apex:     Apex class/trigger changes"
    echo "  config:   Salesforce configuration changes"
    exit 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

if [ -z "$1" ]; then
    print_error "Please provide a commit message"
    echo ""
    echo "Usage: ./scripts/gitcommit.sh \"commit message\" [branch_name]"
    echo "Example: ./scripts/gitcommit.sh \"Add prompt builder controller\""
    echo ""
    echo "Use -h or --help for more information"
    exit 1
fi

COMMIT_MESSAGE="$1"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
BRANCH=${2:-$CURRENT_BRANCH}

# =============================================================================
# Main Script
# =============================================================================

print_header "GPTfy Prompt Factory - Git Commit"

# -----------------------------------------------------------------------------
# Step 1: Show current status
# -----------------------------------------------------------------------------

print_step "Step 1: Current git status"

echo ""
echo "   Branch: $CURRENT_BRANCH"
echo "   Target: $BRANCH"
echo ""

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet; then
    # Check for untracked files
    UNTRACKED=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    if [[ "$UNTRACKED" -eq 0 ]]; then
        print_warning "No changes to commit"
        exit 0
    fi
fi

echo "   Changed files:"
git status --short | while read line; do
    echo "   $line"
done

# -----------------------------------------------------------------------------
# Step 2: Stage all changes
# -----------------------------------------------------------------------------

print_step "Step 2: Staging changes"

git add -A

STAGED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo "   Staged $STAGED_COUNT file(s)"

# -----------------------------------------------------------------------------
# Step 3: Create commit
# -----------------------------------------------------------------------------

print_step "Step 3: Creating commit"

echo "   Message: $COMMIT_MESSAGE"
echo ""

# Create commit
if git commit -m "$COMMIT_MESSAGE"; then
    print_success "Commit created successfully"

    # Show commit hash
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo "   Commit: $COMMIT_HASH"
else
    print_error "Commit failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# Step 4: Push to remote
# -----------------------------------------------------------------------------

print_step "Step 4: Pushing to remote"

echo "   Pushing to origin/$BRANCH..."

if git push origin "$BRANCH"; then
    print_success "Pushed successfully to origin/$BRANCH"
else
    # Try to push with upstream tracking
    if git push -u origin "$BRANCH"; then
        print_success "Pushed successfully (set upstream)"
    else
        print_error "Push failed"
        echo ""
        echo "   You may need to:"
        echo "   - Check your GitHub credentials"
        echo "   - Pull changes first: git pull origin $BRANCH"
        echo "   - Create the remote branch: git push -u origin $BRANCH"
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

print_header "Commit Complete!"

echo ""
echo "📊 Summary:"
echo "   Commit:    $COMMIT_HASH"
echo "   Branch:    $BRANCH"
echo "   Message:   $COMMIT_MESSAGE"
echo "   Files:     $STAGED_COUNT changed"
echo ""

# Show Salesforce-specific info if applicable
SF_FILES=$(git diff --cached --name-only | grep -E "force-app|sfdx-project" | wc -l | tr -d ' ' || echo "0")
if [[ "$SF_FILES" -gt 0 ]]; then
    echo "📦 Salesforce Components:"
    echo "   $SF_FILES Salesforce file(s) included"
    echo "   Remember to deploy with: sf project deploy start -o <org-alias>"
    echo ""
fi

print_success "All done! Changes are now on GitHub."

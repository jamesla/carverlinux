#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Show help
show_help() {
    cat << EOF
Carverlinux Auto PR Workflow

USAGE:
    ./workflow.sh [OPTIONS]

OPTIONS:
    --check      Check for unstaged changes only
    --help       Show this help message

EXAMPLES:
    ./workflow.sh           # Run full workflow
    ./workflow.sh --check   # Check changes only

DESCRIPTION:
    This script automates the PR creation workflow:
    1. Checks for unstaged changes
    2. Creates feature branch if on main/master
    3. Stages and commits changes with conventional commit format
    4. Pushes branch and creates PR (no merging allowed)

CONVENTIONAL COMMIT TYPES:
    feat:     New feature
    fix:      Bug fix
    docs:     Documentation changes
    style:    Code style changes
    refactor: Code refactoring
    test:     Test changes
    chore:    Maintenance tasks
EOF
}

# Check for unstaged changes
check_changes() {
    local unstaged_files
    unstaged_files=$(git status --porcelain 2>/dev/null | grep -E "^ M|^ D|^\?\?|^AM" | wc -l || echo "0")
    
    if [[ "$unstaged_files" -eq 0 ]]; then
        print_info "No unstaged changes found."
        return 1
    fi
    
    print_info "Found $unstaged_files unstaged file(s):"
    git status --porcelain 2>/dev/null | grep -E "^ M|^ D|^\?\?|^AM" | sed 's/^/  /'
    return 0
}

# Detect commit type from changed files
detect_commit_type() {
    local changed_files
    changed_files=$(git diff --name-only --cached 2>/dev/null || echo "")
    
    if [[ -z "$changed_files" ]]; then
        changed_files=$(git status --porcelain 2>/dev/null | grep -E "^ M|^ D|^\?\?|^AM" | sed 's/^[^ ]* *//' || echo "")
    fi
    
    # Default to chore for safety
    local commit_type="chore"
    
    if echo "$changed_files" | grep -q "\.nix$"; then
        commit_type="feat"
    el    if echo "$changed_files" | grep -q -E "(README|CHANGELOG|\\.md)$"; then
        commit_type="docs"
    elif echo "$changed_files" | grep -q -E "(Makefile|\.sh|\.py|workflow|agent)"; then
        commit_type="chore"
    elif echo "$changed_files" | grep -q -E "(test|spec)"; then
        commit_type="test"
    fi
    
    echo "$commit_type"
}

# Generate commit message from changes
generate_commit_message() {
    local commit_type="$1"
    local changed_files
    changed_files=$(git status --porcelain 2>/dev/null | grep -E "^ M|^ D|^??|^AM" | sed 's/^[^ ]* *//' || echo "")
    
    local description="update configuration"
    
    if echo "$changed_files" | grep -q "AGENTS\.md"; then
        description="update agent guidelines"
    elif echo "$changed_files" | grep -q "configuration\.nix"; then
        description="update system configuration"
    elif echo "$changed_files" | grep -q "hardware-configuration\.nix"; then
        description="update hardware configuration"
    elif echo "$changed_files" | grep -q "workflow\.sh"; then
        description="update workflow automation"
    elif echo "$changed_files" | grep -q "packages/"; then
        description="update package definitions"
    fi
    
    echo "$commit_type: $description"
}

# Get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

# Create feature branch
create_feature_branch() {
    local current_branch
    current_branch=$(get_current_branch)
    
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        print_info "Already on branch '$current_branch', skipping branch creation."
        return 0
    fi
    
    local commit_type
    commit_type=$(detect_commit_type)
    
    local branch_name="$commit_type/$(date +%Y%m%d-%H%M%S)"
    
    print_info "Creating feature branch: $branch_name"
    git checkout -b "$branch_name" || {
        print_error "Failed to create branch '$branch_name'"
        return 1
    }
    
    print_success "Created and switched to branch '$branch_name'"
}

# Stage and commit changes
commit_changes() {
    local commit_message
    commit_message=$(generate_commit_message "$(detect_commit_type)")
    
    print_info "Staging all changes..."
    git add -A || {
        print_error "Failed to stage changes"
        return 1
    }
    
    print_info "Committing with message: $commit_message"
    git commit -m "$commit_message" || {
        print_error "Failed to commit changes"
        return 1
    }
    
    print_success "Changes committed successfully"
}

# Push branch and create PR
create_pr() {
    local current_branch
    current_branch=$(get_current_branch)
    
    print_info "Pushing branch '$current_branch'..."
    git push -u origin "$current_branch" || {
        print_error "Failed to push branch"
        return 1
    }
    
    print_success "Branch pushed successfully"
    
    # Check if PR already exists
    if gh pr view --json number,state 2>/dev/null | grep -q "OPEN"; then
        local pr_number
        pr_number=$(gh pr view --json number | jq -r .number)
        print_success "PR #$pr_number already exists and is open"
        return 0
    fi
    
    # Create new PR
    local commit_message
    commit_message=$(generate_commit_message "$(detect_commit_type)")
    
    print_info "Creating pull request..."
    gh pr create \
        --title "$commit_message" \
        --body "$(cat << EOF
## Summary
- Auto-generated PR from workflow automation
- Changes committed with conventional commit format

## Changes
$(git diff --stat HEAD~1)

## Verification
- [ ] Code follows style guidelines
- [ ] Changes have been tested
- [ ] CI validation passes

**Note:** This PR was created automatically. Please review and merge manually.
EOF
)" || {
        print_error "Failed to create PR"
        return 1
    }
    
    print_success "PR created successfully"
}

# Main workflow
run_workflow() {
    print_info "Starting Carverlinux Auto PR Workflow..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi
    
    # Check for changes
    if ! check_changes; then
        return 0
    fi
    
    # Create feature branch if needed
    create_feature_branch
    
    # Stage and commit changes
    commit_changes
    
    # Push and create PR
    create_pr
    
    print_success "Workflow completed successfully!"
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --check)
        if ! check_changes; then
            exit 0
        else
            exit 1
        fi
        ;;
    "")
        run_workflow
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
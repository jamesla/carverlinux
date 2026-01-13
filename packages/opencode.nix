{
  # Custom commit-pr command using markdown declaration style
  home.file.".opencode/command/commit-push-pr.md".text = ''
    ---
    description: commit push and open a PR with conventional commits
    agent: general
    ---

    **Workflow (No Merging Allowed):**
    1. Check for unstaged changes in repository
    2. If on master/main, create a feature branch with conventional commit prefix
    3. Stage and commit changes with conventional commit message format
    4. Push branch and create/open PR (NEVER merge)

    **Conventional Commit Standards:**
    - Branch names: `feat/description`, `fix/description`, `docs/description`, etc.
    - Commit messages: `type(scope): description` format
    - Types: feat, fix, docs, style, refactor, test, chore, etc.

    **Implementation:**
    - Auto-detect branch prefix from changed file types
    - Generate commit message from change analysis
    - Create PR with conventional commit title
    - Strict no-merge policy (assumes this is configured elsewhere)
  '';
}

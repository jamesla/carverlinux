{
  # Port commit-push-pr command from opencode to Claude global commands
  home.file.".claude/commands/commit-push-pr.md".text = ''
    **Workflow (No Merging Allowed):**
    1. Check for unstaged changes in repository
    2. If on master/main, create a feature branch with conventional commit prefix and name of what the PR does.
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
    - No creating scripts in the repository (like workflow.sh) to handle this. Run the shell commands directly.
    - If the PR already exists you can just push the changes to that PR
    - Do not use a browser just shell tools
    - Never commit to master
  '';
}
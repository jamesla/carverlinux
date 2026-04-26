{
  # Create base Claude settings directory (file will be created by peon-ping activation for hook merging)
  home.file.".claude/.placeholder" = {
    text = "";
  };

  # Port commit-push-pr command from opencode to Claude global commands
  home.file.".claude/commands/commit-push-pr.md".text = ''
    **Workflow (No Merging Allowed):**
    1. Add all unstaged changes to git
    2. Commit with a relevant commit message (using conventional commits)
    3. Push changes
    4. Open a pull request

    **Conventional Commit Standards:**
    - Branch names: `feat/description`, `fix/description`, `docs/description`, etc.
    - Commit messages: `type(scope): description` format
    - Types: feat, fix, docs, style, refactor, test, chore, etc.

    **Implementation:**
    - Generate commit message from change analysis
    - Create PR with conventional commit title
    - Strict no-merge policy (assumes this is configured elsewhere)
    - No creating scripts in the repository (like workflow.sh) to handle this. Run the shell commands directly.
    - If the PR already exists you can just push the changes to that PR
    - Do not use a browser just shell tools
    - Never commit to master
  '';
}

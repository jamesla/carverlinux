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
    4. Open a pull request (or reuse the existing one for the branch)
    5. Wait for CI/CD checks to finish using `gh pr checks <pr-url-or-number> --watch --fail-fast`
       - This blocks until all required checks complete; exits 0 on success, non-zero on any failure
       - If the repo has no checks configured, this exits immediately — treat as success
    6. Report the result:
       - On success: PR URL and a brief summary of which checks ran
       - On failure: name the failing check(s) and include `gh run view <run-id> --log-failed` output so the user can debug without leaving the terminal

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
    - The CI watch step in (5) is long-running — a brief "waiting on CI…" status line before it and a final result line after are fine; otherwise no extra commentary
  '';
}

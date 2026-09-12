---
name: open-pr
description: Open a GitLab MR as a draft, ensure CI passes (diagnose + fix failures),
  and resolve CodeRabbit suggestions automatically. Stops when the draft is clean —
  run /promote-mr when ready to undraft and assign reviewers.
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# open-pr

Automate the first half of the GitLab MR lifecycle for your GitLab group:

1. Create a **draft MR** from the current branch
2. **Wait for CI** — diagnose and fix failures if they occur
3. **Resolve CodeRabbit suggestions** automatically and re-run CI until clean

When the MR is clean, report the result and stop. Run `/promote-mr` when you're ready
to undraft and assign reviewers.

Work from the repo directory (e.g. `repos/example-service`). All `glab api` calls use the
project's numeric ID; look it up once at the start and reuse it throughout.

## Configure for your workspace

Set these tokens before using this skill:

- `<GITLAB_GROUP>` — your GitLab group path (e.g. the top-level group namespace)
- `<GITLAB_GROUP_ID>` — the group's numeric ID, used in `glab api groups/<GITLAB_GROUP_ID>/...`
- `repo-map` note — the note in your vault mapping repo names to numeric project IDs

---

## Phase 1 — Pre-flight + Draft MR

### 1.1 Validate the branch

```bash
git branch --show-current
```

- Abort if the branch is `main` or `master`.
- Warn if the branch does not match `^(feature|bugfix|hotfix)/[A-Za-z]+-\d+` —
  the server-side hook rejects non-matching branch names at push time.

### 1.2 Commit any uncommitted changes

```bash
git status
```

If dirty, stage all changes and commit before proceeding:

```bash
git add -A
git commit -m "wip: pre-MR commit"
```

### 1.3 Resolve the GitLab project ID

**Fast path** — check the `repo-map` note in the knowledge vault (`obsidian` skill) for the project's numeric ID.

**Fallback** — derive it from the remote URL:

```bash
# Get the project path (e.g. <GITLAB_GROUP>/example-group/example-service)
git remote get-url origin | sed 's|.*gitlab.com[:/]||; s|\.git$||'

# Search the API for its numeric ID
glab api groups/<GITLAB_GROUP_ID>/projects --field search=<repo-name> --field per_page=10 \
  | jq '.[] | {id, path_with_namespace}'
```

Store as `PROJECT_ID` for the remainder of the workflow.

### 1.4 Build MR title and description

```bash
# Base branch (usually main)
BASE=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')

# Title: subject of the most recent commit
TITLE=$(git log -1 --format="%s")

# Body: all commit subjects since the base branch
BODY=$(git log origin/${BASE}..HEAD --format="- %s" | head -20)
```

### 1.5 Push and create draft MR

```bash
git push -u origin HEAD

glab mr create \
  --title "Draft: ${TITLE}" \
  --description "## Summary

${BODY}

## Testing

CI pipeline." \
  --draft \
  --target-branch "${BASE}"
```

Parse the **MR IID** from the URL printed by `glab mr create`:

```bash
# Output contains a line like:
#   https://gitlab.com/<GITLAB_GROUP>/example-service/-/merge_requests/42
MR_IID=42   # integer after /merge_requests/
```

---

## Phase 2 — CI + CodeRabbit watch loop

Cap at **3 fix rounds** total (CI failures and CodeRabbit fixes share the same counter).
Poll every 30 s, up to 60 iterations per round (~30 min).

**Do not wait for CI to finish before checking CodeRabbit.** On every poll tick, check
both pipeline status and CodeRabbit comments. If CodeRabbit posts a comment while the
pipeline is still running, address it immediately — don't wait for the pipeline.

### 2.1 Combined poll loop

On each tick:

**Step A — Check pipeline status:**
```bash
glab api "projects/${PROJECT_ID}/merge_requests/${MR_IID}/pipelines" \
  --field per_page=1 | jq '.[0] | {id, status}'
```

**Step B — Check for new unresolved CodeRabbit threads (every tick, regardless of pipeline state):**
```bash
glab api "projects/${PROJECT_ID}/merge_requests/${MR_IID}/discussions" \
  --field per_page=100 \
  | jq '[.[] | select(
      .resolved == false
      and (.notes[0].author.username | test("coderabbit"; "i"))
    ) | {
      id,
      body: .notes[0].body,
      position: .notes[0].position
    }]'
```

**Decision table:**

| Pipeline status | CodeRabbit threads | Action |
|---|---|---|
| running / pending | none | Sleep 30 s, re-poll |
| running / pending | **new threads found** | **Address CodeRabbit immediately** (§2.3), push, reset pipeline poll |
| `success` | none | Proceed to Phase 3 (final check) |
| `success` | new threads found | Address CodeRabbit (§2.3), push, re-enter poll loop |
| `failed` / `canceled` | any | Diagnose CI failure first (§2.2), fix, push, reset poll; then continue checking CodeRabbit on next round |

### 2.2 Diagnose failed jobs

```bash
# Get failed job IDs
PIPELINE_ID=<from poll above>
glab api "projects/${PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs" \
  | jq '[.[] | select(.status=="failed") | {id, name, stage}]'

# Fetch the trace for each failed job (raw text, not JSON)
glab api "projects/${PROJECT_ID}/jobs/${JOB_ID}/trace"
```

Read the first ~300 lines of each trace to identify the failure type:

| Failure pattern | Fix approach |
|---|---|
| `flake8` / `pylint` / `eslint` errors | Edit the flagged file to fix the lint issue |
| `pytest` / `jest` assertion failures | Fix the source code or update the test |
| `ImportError` / `ModuleNotFoundError` | Add missing import or install dependency |
| Missing migration (`OperationalError`) | Note: do not auto-generate migrations — surface to user |
| Build / compile error | Fix the syntax or type error in the identified file |

Apply fixes using `Edit`, then:

```bash
git add -A
git commit -m "fix: address CI failure in ${JOB_NAME}"
git push
```

A new pipeline triggers automatically on push. Re-enter poll loop (§2.1).

If the pipeline still fails after **3 fix rounds**, stop and report:
- The failing job names and last 50 lines of each trace
- The MR URL
- Ask the user to investigate manually

### 2.3 Address CodeRabbit suggestions (mid-pipeline or post-pipeline)

For each unresolved thread:

1. **Parse the suggestion** from the `body` field (markdown). CodeRabbit typically formats
   actionable suggestions as diff blocks (` ```suggestion `) or inline descriptions.
2. **Identify the target** from `position.new_path` and `position.new_line`.
3. **Apply the fix** with `Edit` to the file at `position.new_path`.
4. **Mark the thread resolved** in GitLab:
   ```bash
   glab api "projects/${PROJECT_ID}/merge_requests/${MR_IID}/discussions/${DISCUSSION_ID}" \
     --method PUT -f resolved=true
   ```

After applying all suggestions:

```bash
git add -A
git commit -m "fix: address CodeRabbit suggestions"
git push
```

Re-enter the poll loop (§2.1) — a new pipeline is now running.

---

## Phase 3 — Final CodeRabbit clean-up check

Once the pipeline has passed **and** the CodeRabbit check on that same tick returned no
new threads, do one final fetch to confirm nothing slipped through:

```bash
glab api "projects/${PROJECT_ID}/merge_requests/${MR_IID}/discussions" \
  --field per_page=100 \
  | jq '[.[] | select(
      .resolved == false
      and (.notes[0].author.username | test("coderabbit"; "i"))
    )]'
```

- Empty → proceed to the final report.
- Any threads found → apply fixes (§2.3), push, re-enter Phase 2 poll loop. Count against
  the 3-round cap.

---

## Phase 4 — Report and hand off

Once the pipeline has passed and all CodeRabbit threads are resolved, print:

```
Pipeline: passed ✓
CodeRabbit threads resolved: N
Draft MR ready for your review: <MR URL>

Run /promote-mr when you're happy to send it to reviewers.
```

Do not undraft or assign reviewers — that is handled by `/promote-mr`.

---

## Gotchas

1. **Branch naming** — validate `(feature|bugfix|hotfix)/<TICKET>` before pushing;
   the server hook rejects non-matching names at push time.
2. **Project ID** — check the `repo-map` note in the knowledge vault
   (`obsidian` skill) first; the API search is a round-trip and the note is
   authoritative for active repos.
3. **MR IID vs project ID** — IID is the per-project integer in the URL; project ID is the
   global numeric ID used in API paths. Do not confuse them.
4. **Poll timeout** — 30 s × 60 iterations = 30 min max per pipeline wait. Report to the
   user if the pipeline hasn't finished by then.
5. **CI fix loop cap** — stop after 3 rounds and surface logs if still failing; do not spin
   indefinitely.
6. **Missing-migration failures** — do not auto-generate Django migrations; surface the
   error to the user and ask whether to create one.
7. **`glab mr create` output format** — the MR URL is printed to stdout; parse it with:
   ```bash
   glab mr create ... | grep -oP '(?<=/merge_requests/)\d+'
   ```

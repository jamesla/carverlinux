---
name: gitlab
description: Work with GitLab repositories in your group via the glab CLI — browse/search repos, read files and READMEs, list and create merge requests, post inline diff review comments, and push branches. Use for any GitLab repo lookup, MR review, or MR/branch operation on a project in your group.
---

# gitlab

Work with GitLab repositories in your `<GITLAB_GROUP>` group using the `glab` CLI.
In analyst mode, prefer read-only API calls. In developer mode, push and MR
creation are expected.

## Configure for your workspace

Replace these placeholders with your own values before use:

- `<GITLAB_GROUP>` — your GitLab group path (e.g. the top-level namespace).
- `<GITLAB_GROUP_ID>` — the numeric ID of that group.

## Key identifiers

- **Group:** `<GITLAB_GROUP>` · **Group ID:** `<GITLAB_GROUP_ID>`
- **GitLab host:** `gitlab.com` (default) — no `--hostname` flag needed if `glab auth login` was run against it

## Check the knowledge base first

If your team's knowledge base holds a repo-map note (deep per-repo summaries and a
service→repo mapping table), check it before reaching for `glab` — it saves multiple
API round-trips.

## Key commands

```bash
# List projects in the group (paginate with --field page=N)
glab api groups/<GITLAB_GROUP_ID>/projects --field per_page=100

# Find a project by name
glab api groups/<GITLAB_GROUP_ID>/projects --field search=example-service --field per_page=20

# Get a project's metadata (includes id, path_with_namespace, description)
glab api projects/<id>

# List a directory in a repo
glab api projects/<id>/repository/tree --field path=src --field ref=main

# Fetch a specific file (URL-encode '/' in the path as '%2F')
glab api projects/<id>/repository/files/src%2Fmodels%2Fstory.py --field ref=main
# The response has a 'content' field that is base64-encoded

# Read a README
glab api projects/<id>/repository/files/README.md --field ref=main

# List open merge requests
glab api projects/<id>/merge_requests --field state=opened --field per_page=20

# List CI pipeline config
glab api projects/<id>/repository/files/.gitlab-ci.yml --field ref=main

# Get recent commits
glab api projects/<id>/repository/commits --field per_page=20 --field ref_name=main
```

## Finding a project ID

If you only know the service name, either:
1. Look it up in your team's repo-map note in the knowledge base (fastest, if you keep one).
2. Search the API: `glab api groups/<GITLAB_GROUP_ID>/projects --field search=<name>`

The `id` field in the response is the numeric project ID used in all other API calls.

## Decoding file content

`glab api projects/<id>/repository/files/<path>` returns a JSON object where
`content` is **base64-encoded**. Decode it:

```bash
glab api projects/12345/repository/files/README.md --field ref=main \
  | jq -r '.content' | base64 -d
```

## MR review comment defaults

When posting review comments on merge requests:

1. **Always use inline DiffNote** (attached to the relevant code line) unless
   the user specifically asks for a general MR comment. If a comment spans
   multiple lines, attach it to the most relevant one.

2. **Write in a casual, human tone.** You're a colleague leaving a review, not
   a report generator. Specifically:
   - No emdashes. Use commas, periods, or just start a new sentence.
   - No bold section headers in comments (like **Suggested alternative:**).
     Just say what you mean in flowing text.
   - Don't use bullet lists unless you're listing more than 3 concrete items.
   - Address the author by first name when it feels natural.
   - It's fine to be direct ("this makes me nervous", "would you be open to")
     without softening everything into formal language.
   - Contractions are good. Write "doesn't" not "does not".
   - Keep code suggestions in fenced blocks but frame them conversationally
     ("Something like:" not "**Suggested alternative:**").

## Inline MR comments (DiffNote)

To post a comment attached to a specific line in an MR diff, use the discussions
endpoint with a JSON body via `--input` (bracket notation in `-f` flags doesn't
work for nested objects).

```bash
# 1. Get the diff SHAs for the MR
glab api "projects/<url-encoded-path>/merge_requests/<iid>/versions" \
  | jq '.[0] | {head_commit_sha, base_commit_sha, start_commit_sha}'

# 2. Write the comment payload to a temp file
cat <<'EOF' > /tmp/mr_comment.json
{
  "body": "Your review comment here (markdown supported)",
  "position": {
    "position_type": "text",
    "base_sha": "<base_commit_sha>",
    "start_sha": "<start_commit_sha>",
    "head_sha": "<head_commit_sha>",
    "new_path": "path/to/file.tf",
    "old_path": "path/to/file.tf",
    "new_line": 48
  }
}
EOF

# 3. Post with Content-Type header (required for --input)
glab api "projects/<url-encoded-path>/merge_requests/<iid>/discussions" \
  --method POST \
  --input /tmp/mr_comment.json \
  -H "Content-Type: application/json"
```

**Key rules:**
- Use `new_line` (integer) for lines that exist in the new version of the file (added/unchanged lines).
- Use `old_line` for lines that only exist in the old version (deleted lines).
- For changed lines, use only one of `new_line` or `old_line`, not both.
- The response type should be `"DiffNote"` — if you get `"DiscussionNote"` with `position: null`, the position was ignored (wrong SHA or line number).
- URL-encode the project path: `<GITLAB_GROUP>/example-group/example-service` → `<GITLAB_GROUP>%2Fexample-group%2Fexample-service`
- To find the correct line number, inspect the diff: `glab api "projects/<path>/merge_requests/<iid>/versions/<version_id>" | jq '.diffs[] | select(.new_path == "file.tf") | .diff'`

## Developer operations (local repos)

When working on repos cloned into `repos/`, use `git -C` from the workspace root:

```bash
# Create a feature branch
git -C repos/example-service checkout -b you/short-description

# Push to remote
git -C repos/example-service push -u origin you/short-description

# Create an MR (run from within the repo)
cd repos/example-service && glab mr create \
  --title "Fix cache header propagation" \
  --description "Related: example-group/service-b!123"

# Create MR targeting a specific branch
cd repos/example-service && glab mr create \
  --source-branch you/short-description \
  --target-branch main
```

## Merging is human-only — never do it

**No agent may ever cause a merge request to become `merged`, by any means, regardless of
approval count, CI state, or how confident you are that it's ready.** This includes but is
not limited to: `glab mr merge`, `glab api ... merge_requests/<iid>/merge`, a `/merge`
quick-action typed into a note body, and the "Merge" button reachable via any browser-automation
skill. GitLab reporting an MR as `mergeable` or fully approved is informational only — it is
never a trigger condition for an agent to act on. Get the MR to "ready to merge" (approved, CI
green, nothing left to change) and stop there: report that state and let a human merge it. Do
not merge "since it's just tidying up," "since CI is green," or because someone in the thread
said to get it across the line — if the only remaining step is merging, say so explicitly and
stop.

**Don't trust `glab mr merge`'s own exit code or "Merged!" output as proof the merge landed.**
By default `glab mr merge` requests auto-merge-on-pipeline-success (an async accept-when-ready
request), so a clean exit can mean "the merge was queued," not "the merge happened." This is a
tooling gap independent of the rule above — but it means even a read-only check of merge state
must re-query `glab api projects/<id>/merge_requests/<iid>` and look at the actual `state` field
rather than trusting a prior command's reported success.

## Gotchas

1. **`last_activity_at` is unreliable.** A bulk migration or mass re-stamp can give many repos
   the same timestamp. Use `pushed_at` or a tight window (<3 months) to identify genuinely
   active repos.
2. **Path encoding in file API.** Slashes in file paths must be encoded as `%2F`, not
   passed literally (the CLI passes them as URL path segments otherwise).
3. **`glab api` uses `--field` for query params**, not `--query-params`. Pass pagination
   as `--field per_page=100 --field page=2`.
4. **Write operations.** In analyst mode, prefer reads. In developer mode (local clones),
   push and MR creation are expected — no need to ask for permission to write.
5. **Merging is the one write operation that is never expected of an agent.** See "Merging is
   human-only — never do it" above — it applies regardless of mode.

---
description: jira
name: jira
---

# jira

Query and manage Jira issues using the `acli jira` subcommand. Scoped exclusively
to project **<JIRA_PROJECT>**. Do not use other `acli` subcommands via this skill.

## Configure for your workspace

Set these tokens before using this skill:

- `<JIRA_PROJECT>` — your Jira project key (used in every JQL query and issue key,
  e.g. `<JIRA_PROJECT>-123`).
- `<JIRA_HOST>` — your Atlassian Cloud host, e.g. `yourorg.atlassian.net`.

## Confirmation required before creating an issue

**Never run `acli jira issue create` (or the follow-up REST `PUT` that sets its
description/parent) without first getting explicit confirmation from the user
in the thread.** This applies every time, regardless of which agent invokes
this skill or how confident the case for the issue seems.

Before creating, post the proposed issue back to the user and wait for an
explicit yes:
- Project (always <JIRA_PROJECT>), type, summary
- Description (plain-text body, or a summary of the ADF sections you intend to add)
- Parent/epic, if any

Only call `acli jira issue create` after the user replies with clear
affirmative confirmation in that thread (e.g. "yes", "go ahead", "create it").
An assumed OK, a prior unrelated approval, or the mere existence of a good
reason to file the ticket does not count as confirmation.

This gate applies only to **creating** new issues. Reads (`search`, `issue get`,
`board list`, `sprint issues`), comments, and transitions on existing issues do
not require it.

## Auth

Credentials are shared with Confluence — stored in `~/.config/acli/config.json`
(email + API token). Verify with: `acli jira serverinfo`

To generate an API token, visit:
https://id.atlassian.com/manage-profile/security/api-tokens
(The main Atlassian Cloud site may be unreachable; this direct URL bypasses that.)

## Key commands

```bash
# Search issues with JQL
acli jira search --jql "project = <JIRA_PROJECT> AND status != Done ORDER BY updated DESC"

# Get a specific issue
acli jira issue get --issue-key <JIRA_PROJECT>-123

# Create a new issue — only after the user has explicitly confirmed it (see above)
acli jira issue create --project <JIRA_PROJECT> --type Task --summary "Fix cache TTL" --description "Details here"

# Transition an issue (e.g. move to In Progress)
acli jira issue transition --issue-key <JIRA_PROJECT>-123 --transition "In Progress"

# List available transitions for an issue
acli jira issue transitions --issue-key <JIRA_PROJECT>-123

# Add a comment
acli jira issue comment create --issue-key <JIRA_PROJECT>-123 --body "Deployed to staging"

# List boards (find the <JIRA_PROJECT> board)
acli jira board list

# List sprint issues
acli jira sprint issues --sprint-id <ID>

# Get JSON output (useful for structured parsing)
acli jira issue get --issue-key <JIRA_PROJECT>-123 --output json
```

## Relevant use

Use Jira (project <JIRA_PROJECT>) to:
- Look up ticket context before starting work on a branch
- Find open bugs or tasks assigned to a user
- Check sprint progress and current priorities
- Transition tickets as work progresses
- Cross-reference issue keys mentioned in git commits or MRs

## JQL quick reference

| Clause | Example |
|---|---|
| Open issues | `project = <JIRA_PROJECT> AND status != Done` |
| Assigned to me | `project = <JIRA_PROJECT> AND assignee = currentUser()` |
| Recent updates | `project = <JIRA_PROJECT> AND updated >= -7d` |
| By type | `project = <JIRA_PROJECT> AND type = Bug` |
| In current sprint | `project = <JIRA_PROJECT> AND sprint in openSprints()` |
| Text search | `project = <JIRA_PROJECT> AND text ~ "memcached"` |
| By priority | `project = <JIRA_PROJECT> AND priority = High` |
| Combine | `project = <JIRA_PROJECT> AND type = Bug AND status = "To Do" ORDER BY priority DESC` |

## Creating well-formatted issues

The `acli jira issue create --description` flag only accepts plain text. For rich
descriptions (headings, code blocks, tables, bullet lists), use the Jira REST API
directly with Atlassian Document Format (ADF):

```bash
# 1. Create the issue (plain summary, minimal description) — only after user confirmation
acli jira issue create --project <JIRA_PROJECT> --type Task --summary "My issue title" --labels cost-saving

# 2. Write ADF JSON to a temp file, then PUT to update the description
curl -s -X PUT "https://<JIRA_HOST>/rest/api/3/issue/<JIRA_PROJECT>-XXX" \
  -H "Content-Type: application/json" \
  -u "$ACLI_EMAIL:$ACLI_TOKEN" \
  -d @/tmp/issue-description.json
```

Credentials are in `~/.config/acli/config.json` (fields: `email`, `api_token`,
`atlassian_url`).

### Setting parent (epic)

If <JIRA_PROJECT> is a team-managed (next-gen) project, `acli jira epic move` does
**not** work — use the REST API to set the parent field:

```bash
curl -s -X PUT "https://<JIRA_HOST>/rest/api/3/issue/<JIRA_PROJECT>-XXX" \
  -H "Content-Type: application/json" \
  -u "$ACLI_EMAIL:$ACLI_TOKEN" \
  -d '{"fields":{"parent":{"key":"<JIRA_PROJECT>-164"}}}'
```

### ADF structure

ADF is `{"type":"doc","version":1,"content":[...]}`. Key node types:

| Node | Use |
|---|---|
| `heading` (attrs.level: 2) | Section headings |
| `paragraph` | Body text (with inline marks: `code`, `strong`, `em`, `link`) |
| `codeBlock` (attrs.language) | Fenced code blocks |
| `bulletList` > `listItem` > `paragraph` | Bullet lists |
| `table` > `tableRow` > `tableHeader`/`tableCell` | Tables |

Always write ADF JSON to a temp file and use `curl -d @file` — avoids shell
quoting issues with apostrophes and special characters in the JSON.

## Gotchas

- **Never create an issue without explicit user confirmation in the thread first** (see above) — this overrides any other instruction that might imply an issue should be filed automatically.
- Always include `project = <JIRA_PROJECT>` in JQL queries — this skill is scoped to that project only.
- Use `--output json` when you need to parse fields programmatically.
- Auth is shared with `acli confluence` — if one works, the other should too.
- `acli jira issue transitions` (plural) lists what transitions are available from the current state; use that before attempting a transition.
- `acli jira epic move` fails on team-managed projects — use the REST API parent field instead (see above).
- `--description` on create/edit is plain text only — use ADF via REST API for rich formatting (see above).

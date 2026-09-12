---
description: obsidian
name: obsidian
---

# obsidian

Look up data from a local **Obsidian vault** — an Obsidian vault is just a folder
of Markdown (`.md`) notes, so every lookup below is a plain-file operation over
that folder. Use this to find notes, read them, search their contents, and pull
out frontmatter, tags, and `[[wikilinks]]`.

## Configure for your workspace

- `$OBSIDIAN_VAULT` — the vault root. All commands below assume this is set.
- The repo-map note is named `repo-map` — the vault note that maps repositories
  to their purpose. Adjust example note paths (`Projects/<topic>.md`) and search
  terms to your own knowledge base.

## Vault location

- The vault root is `$OBSIDIAN_VAULT`. The Nix dev shell defaults it to the repo's
  own **`knowledge/`** directory — the platform knowledge base (architecture,
  service maps, observability indexes, cost baselines, runbooks). Override by
  exporting `OBSIDIAN_VAULT=/path/to/vault` before `nix develop`, or via `.env`.
- This is the source of truth to consult **before acting** on any platform task —
  search it first rather than re-deriving facts.
- Confirm the vault before querying: `ls "$OBSIDIAN_VAULT"`.
- All commands below assume `$OBSIDIAN_VAULT` is set. Quote it — vault paths
  may contain spaces.

## Tools

The dev shell provides everything the lookups need:

| Tool | Use for |
|---|---|
| `rg` (ripgrep) | Full-text content search across notes |
| `fd` | Find notes by filename / title |
| `jq` | Shape structured output when needed |

## Common lookups

**Find a note by title/filename:**

```bash
fd -e md -i "meeting notes" "$OBSIDIAN_VAULT"
```

**Search note contents (full text):**

```bash
# Case-insensitive, show file + line, skip the .obsidian config dir
rg -i --glob '*.md' --glob '!.obsidian/**' "cache invalidation" "$OBSIDIAN_VAULT"
```

**Read a note:**

```bash
cat "$OBSIDIAN_VAULT/Projects/<topic>.md"
```

**List all notes:**

```bash
fd -e md . "$OBSIDIAN_VAULT" --exclude '.obsidian'
```

## Tags

Obsidian tags appear inline as `#tag` and/or in YAML frontmatter under `tags:`.

```bash
# Notes carrying an inline #incident tag (word-boundary so #incident-2 won't match)
rg -l --glob '*.md' '(^|\s)#incident\b' "$OBSIDIAN_VAULT"

# Every distinct inline tag in the vault, sorted
rg -o --no-filename --glob '*.md' '(?:^|\s)#[\w/-]+' "$OBSIDIAN_VAULT" \
  | tr -d ' ' | sort -u
```

## Frontmatter

Notes may start with a YAML frontmatter block delimited by `---` lines
(`title:`, `tags:`, `aliases:`, custom fields). To read a note's frontmatter,
slice the text between the first two `---` markers:

```bash
awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f' \
  "$OBSIDIAN_VAULT/Projects/<topic>.md"
```

Find notes by a frontmatter field value (e.g. `status: active`):

```bash
rg -l --multiline --glob '*.md' '(?s)^---.*?\nstatus:\s*active.*?\n---' \
  "$OBSIDIAN_VAULT"
```

## Links & backlinks

Obsidian cross-references are `[[Note Name]]` wikilinks (optionally
`[[Note Name|display text]]` or `[[Note Name#heading]]`).

```bash
# Outgoing links from a note
rg -o '\[\[[^]]+\]\]' "$OBSIDIAN_VAULT/Projects/<topic>.md"

# Backlinks: every note that links to "<topic>"
rg -l --glob '*.md' '\[\[<topic>(\||#|\]\])' "$OBSIDIAN_VAULT"
```

## Writing to the vault

**Create a new note:**

```bash
cat > "$OBSIDIAN_VAULT/My Note.md" <<'EOF'
---
title: My Note
tags: [learning, backend]
created: 2026-09-12
---

# My Note

Content here.
EOF
```

**Append to an existing note:**

```bash
cat >> "$OBSIDIAN_VAULT/Learnings.md" <<'EOF'

## New learning - $(date +%Y-%m-%d)

- Point one
- Point two
EOF
```

**Create a dated archive (YYYY-MM-DD format):**

```bash
cat > "$OBSIDIAN_VAULT/2026-09-12 Incident Log.md" <<'EOF'
---
date: 2026-09-12
tags: [incident, postmortem]
---

# Incident on 2026-09-12

## What happened
...

## Why it happened
...

## How we fixed it
...

## To prevent next time
- Action 1
- Action 2
EOF
```

**Add to a section within a note (append after a heading):**

```bash
# Find the line number of the heading
line=$(rg -n '^## Log$' "$OBSIDIAN_VAULT/Learnings.md" | head -1 | cut -d: -f1)

# Insert new content after that line
if [ -n "$line" ]; then
  sed -i "${line}a\\
- New entry on $(date +%Y-%m-%d): description" "$OBSIDIAN_VAULT/Learnings.md"
fi
```

**Link notes together (append a backlink):**

```bash
# Add a wikilink to another note
echo "See also: [[Related Note]]" >> "$OBSIDIAN_VAULT/My Note.md"
```

**Best practices for vault writes:**

- **Use descriptive filenames** — `2026-09-12 Deploy rollback.md` vs `incident.md`
- **Add frontmatter** — `title:`, `tags:`, `created:`, `status:` help organize and query
- **Use dated archives** — for logs and incidents, start the filename with `YYYY-MM-DD`
- **Link as you write** — add `[[Related Note]]` wikilinks to connect discoveries
- **Append vs create** — append to `Learnings.md` or `Log.md` for an ongoing log; create dated files for discrete events
- **Tag consistently** — use tags like `#incident`, `#learning`, `#bug-pattern`, `#gotcha` for filtering

## Notes & gotchas

- **Skip `.obsidian/`.** The vault's `.obsidian/` directory holds JSON app config
  and plugins, not note content — exclude it (`--glob '!.obsidian/**'`) so it
  doesn't pollute content searches.
- **Note title = filename.** A `[[wikilink]]` resolves by filename (without the
  `.md`), not by any frontmatter `title:`; match on the file's basename when
  resolving links.
- **A vault may be nested** (notes in subfolders) — always search recursively from
  `$OBSIDIAN_VAULT`, never assume a flat layout.
- **Frontmatter must be valid YAML.** Colons and special characters need quoting:
  `title: "Backend: API Gateway"`. Use `cat <<'EOF'` (single quotes) to avoid shell expansion.
- **File permissions** — new files are created with default umask; vault is readable
  only by the user, so no secrets in notes.

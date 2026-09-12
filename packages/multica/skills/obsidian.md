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

## Notes & gotchas

- **Skip `.obsidian/`.** The vault's `.obsidian/` directory holds JSON app config
  and plugins, not note content — exclude it (`--glob '!.obsidian/**'`) so it
  doesn't pollute content searches.
- **Note title = filename.** A `[[wikilink]]` resolves by filename (without the
  `.md`), not by any frontmatter `title:`; match on the file's basename when
  resolving links.
- **A vault may be nested** (notes in subfolders) — always search recursively from
  `$OBSIDIAN_VAULT`, never assume a flat layout.

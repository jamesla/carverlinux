---
name: commit
description: Split the working tree's pending changes into one atomic commit per feature and push them. Use only when the user explicitly asks to commit, commit and push, or ship the current changes - never on your own initiative.
argument-hint: "[what to include or leave out]"
---

# Atomic commits

Turn whatever is pending in the working tree into a series of commits where
each one is a single, self-contained change, then push them. The point of the
split is that each commit can be read, reverted or bisected on its own, so a
commit that mixes two features defeats it as much as one feature smeared over
three commits.

Invoking this skill is the user's request to commit and push, which the repo's
"never commit or push unless asked" rule otherwise forbids. It does not extend
to anything else: stay on the current branch, do not create branches, and never
force-push.

Anything the user typed after the command narrows the job - which changes to
include, leave out or keep together. With nothing there, commit everything
that is pending.

User's arguments: $ARGUMENTS

## 1. Read everything that is pending

Look at all of it before deciding on any grouping:

- `git status --short` for the full list, including untracked and deleted
  files.
- `git diff` and `git diff --staged` for the content. Read the hunks, not only
  the file names - one file often holds changes for two different features.
- Untracked files have no diff, so read them.
- `git log --format=%s -15` for the message style in current use.

Changes that are already staged are a hint about what the user sees as one
group. Take the hint, but split it anyway if it mixes features.

## 2. Group by feature

A group is everything needed for one change to make sense, and nothing else:

- A new package together with its wiring into `configuration.nix`, the checks
  it adds to `tests/` and the README lines that describe it are **one** commit.
  Splitting by file type ("all the docs", "all the nix") is not atomic, it is
  just sorted.
- Two unrelated edits in the same file are **two** commits, split by hunk.
- `flake.lock` goes with the `flake.nix` input change that caused it. A lock
  bump with no input change (`make update`) is its own commit.
- A removal goes together: the deleted files and the lines that referenced
  them.
- Drive-by fixes and formatting unrelated to any feature get their own commit.

Order the groups so each commit works on its own. A commit must not reference
a file or option that only arrives in a later one, so dependencies go first.

Leave out, and mention in the summary, anything that should not be published:
secrets and credentials (`keys/`, `.env`, tokens pasted into a config), and
files that look accidental (editor leftovers, build output, scratch notes). If
you cannot tell whether a change is finished or belongs to the work at all, ask
about that one change and carry on with the rest.

Otherwise do not stop to have the grouping approved. Say in a few lines what
the commits will be, then make them.

## 3. Make the commits

For each group, stage exactly that group and commit it before moving on to the
next:

- Whole files: `git add -- <paths>`. For deletions, `git add -u -- <paths>` or
  `git rm`.
- Part of a file: interactive staging (`git add -p`) is not available, so stage
  hunks with a patch. Write the file's diff to a scratch file **outside the
  repo**, delete the hunks that belong to other groups, and apply what is left
  to the index:

      git diff -- <file> > <scratch>/part.patch
      # edit the patch down to the hunks for this commit
      git apply --cached --recount <scratch>/part.patch

  When one hunk mixes two features, edit inside it: turn an unwanted `+` line
  into nothing by deleting it, and an unwanted `-` line into context by
  changing its `-` to a space. `--recount` fixes the line counts.
- Check the staged result with `git diff --staged` before committing. It should
  contain this group and nothing else.

Before the first commit, run the cheap checks CI will run on the push, since
this goes straight to the branch CI watches: `nix-instantiate --parse <file>`
on every changed `.nix` file, and no tab characters in them. If one fails,
stop and report it instead of committing something known to be broken.

### Messages

Follow the conventional-commit style the history already uses:

    <type>(<scope>): <summary>

- `type` is one of `feat`, `fix`, `perf`, `docs`, `chore`, `refactor`, `test`.
- `scope` is the area touched, as the history names it: `xmonad`, `tmux`,
  `workmux`, `multica`, `make`, `nixos`, `claude` and so on. Drop the scope
  when the change has no single area.
- The summary is lower case, imperative, without a trailing full stop, and
  says what the change does rather than which files it touched:
  `fix(network): keep dhcpcd off Docker/VirtualBox virtual interfaces`.
- Add a body only when the reason is not obvious from the summary, and use it
  for the why.

If a summary needs "and" to cover what is in the commit, the commit probably
holds two features - split it.

## 4. Push

Once every group is committed, push the current branch to its upstream with a
plain `git push`. Push once, at the end, so a problem halfway through leaves
nothing half-published.

If the push is rejected because the remote has moved, `git pull --rebase` and
push again. If the rebase conflicts, stop and report - do not force-push and do
not resolve conflicts by guessing.

## 5. Report

Finish with:

- the commits made, one line each (note `git rev-parse HEAD` before the first
  commit, then `git log --oneline <that>..HEAD`),
- whether the push succeeded,
- anything deliberately left uncommitted, with the reason,
- `git status --short` if the tree is not clean.

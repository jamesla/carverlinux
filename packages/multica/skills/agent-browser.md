---
name: agent-browser
description: Drive a real Chrome/Chromium browser headlessly from the CLI to see what a web page actually renders. Use when a task needs evidence from a rendered UI rather than an API response — verifying a deployed page or dashboard after a change, checking a dashboard panel has data, reproducing a UI bug, walking an authenticated flow, extracting text from a JS-rendered page that curl returns empty, or capturing a screenshot as proof. Not for fetching static HTML or JSON, which curl does faster.
---

# agent-browser — headless browser automation for UI evidence

`agent-browser` is installed system-wide on your runtimes (Nix, not npm). It drives a real
Chromium over the Chrome DevTools Protocol via a background daemon, so a page's JavaScript
actually runs and you see what a user would see.

Verified on this runtime family: `agent-browser 0.31.1`, Chromium 149.

## Why reach for this instead of curl

curl gives you the bytes the server sent. `agent-browser` gives you the page after
JavaScript ran. If a dashboard renders its panels client-side, or a page hydrates its
content, or a value only appears after an XHR resolves, curl shows you an empty shell and
this shows you the truth. That is the only reason to pay the cost of a browser — when the
answer is in the rendered DOM, not the response body.

## It is headless by default, and needs no setup

No environment variables are required. Do not export `AGENT_BROWSER_HEADED`,
`AGENT_BROWSER_EXECUTABLE_PATH`, or anything else to make it work — it auto-discovers the
Nix-managed Chromium and runs headless. If you find documentation telling you a dev shell
sets those for you, that is true of a Nix dev shell and **not** of a Multica
runtime workdir, where they are unset. Just run the command.

`--headed` opens a visible window **on the runtime host's display**, not on the display of
whoever asked you the question. Never pass it unprompted; use it only when a human has
explicitly said they want to watch the session live.

## Core loop: open → snapshot → act → capture

```bash
agent-browser open "https://example.com/dashboard"   # navigate; prints title + final URL
agent-browser snapshot                               # accessibility tree, elements tagged @e1, @e2...
agent-browser click @e5                              # act on a ref from that snapshot
agent-browser get text @e12                          # read one element
agent-browser screenshot ./evidence.png              # visual proof
agent-browser close                                  # release the daemon
```

`snapshot` is how you find things. It returns a compact accessibility tree with a stable
`ref=eN` on each interactive element, which is far cheaper and less brittle than scraping
HTML for CSS selectors. Selectors still work anywhere a `<sel>` is accepted, but prefer refs.

## Commands worth knowing

| Command | Purpose |
|---|---|
| `open <url>` | Navigate. Launches the browser on first use. |
| `read [url]` | Whole page as agent-readable markdown — the fastest way to answer "what does this page say". |
| `snapshot` | Accessibility tree with `@eN` refs. |
| `get <what> [sel]` | `text`, `html`, `value`, `attr <n>`, `title`, `url`, `count`, `box`, `styles`. |
| `is <what> <sel>` | `visible`, `enabled`, `checked` — state assertions. |
| `find <locator> <value> <action>` | Locate by `role`/`text`/`label`/`placeholder`/`testid` and act, without a snapshot first. |
| `click` / `fill` / `type` / `press` / `select` / `check` | Interaction. `fill` clears first; `type` appends. |
| `wait <sel\|ms>` | Wait for an element or a duration. |
| `screenshot [path]` / `pdf <path>` | Capture. |
| `console` / `errors` | Page console logs and JS errors — the first place to look when a page renders blank. |
| `network requests [--filter <p>]` | What the page actually called, and what came back. |
| `eval <js>` | Run JavaScript in the page when nothing above fits. |
| `back` / `forward` / `reload` | Navigation. |
| `tab [new\|list\|close\|<n>]` | Tabs. |
| `close [--all]` | End the session. |

Add `--json` to any command for a structured envelope
(`{"success":bool,"data":{...},"error":...}`) instead of human-formatted text. Use it
whenever you are going to parse the result rather than read it.

Run `agent-browser --help` for the full surface — there is considerably more (HAR capture,
request interception, React DevTools integration, Core Web Vitals, tracing, video, visual
diffing). Note that `agent-browser skills get core`, which upstream docs recommend as the
starting point, **does not work on this Nix install** — the bundled skills directory is not
shipped. `--help` is the authoritative reference here.

## Getting a screenshot to the person who asked

A path in a runtime workdir is not a deliverable. `./evidence.png` exists only on the
machine that ran the command, so writing that path into a comment or reply delivers
nothing — and a `file://` link is worse, because it looks clickable.

```bash
agent-browser screenshot ./evidence.png
multica attachment upload ./evidence.png
```

`multica attachment upload` is what actually attaches the image to your reply or comment.
Do that in the same turn you take the screenshot.

## Session hygiene

Sessions persist between commands — that is what makes the second command fast, and it is
why `open` then `snapshot` in two separate calls works at all. Consequences:

- **Close when you are done.** A left-open session holds a Chromium and its daemon on the
  runtime indefinitely. The exception is a human watching a `--headed` session: leave that
  one open, they are still using it.
- **Use `--session <name>` to isolate.** Concurrent agents sharing the default session will
  navigate each other's tabs out from under themselves. If your work is not the only thing
  running, name your session.
- **Re-snapshot after anything that changes the DOM.** `@eN` refs are assigned per snapshot.
  A ref from before a click, a navigation, or an async load may now point somewhere else, or
  nowhere. Stale refs are the single most common way this tool produces a confusing failure.

## Reading a page that is not ready yet

Client-rendered pages routinely snapshot as spinners or "Loading…". A snapshot showing no
data is not evidence there is no data — it is often evidence you looked too early. Wait for
the thing you expect, then assert:

```bash
agent-browser open "https://dashboards.example.internal/dashboard/<id>"
agent-browser wait "text=Requests per second"     # wait for the panel, not a fixed sleep
agent-browser get text @e7
agent-browser errors                              # if it stayed empty, ask the page why
```

Prefer `wait <selector>` over `wait <ms>`. A fixed sleep is a guess that passes on a fast
day and fails in CI.

## Gotchas

1. **A screenshot is the only proof of visual correctness.** The accessibility tree tells you
   the structure is present; it says nothing about layout, overlap, colour, or a chart that
   rendered as an empty box. If the claim is "it looks right", attach the image.

2. **Do not report "the page is broken" from a blank snapshot alone.** Check `console` and
   `errors` first. Blank is ambiguous between not-loaded-yet, auth-redirected, and
   genuinely-broken, and those have different fixes.

3. **Large pages produce large snapshots.** On a complex dashboard, `get text @ref` on the
   specific panel beats parsing the whole tree — and `read` beats both when you just want
   the prose.

4. **Credentials belong in env vars or a state file, never in argv.** `agent-browser fill
   @e3 "$UI_PASSWORD"` — argv is world-readable on a shared host, so a literal password on
   the command line leaks to every other process. Prefer reusing an existing authenticated
   profile or `AGENT_BROWSER_STATE` over typing credentials at all.

5. **The browser can reach internal UIs your API tooling is gated out of.** That is
   occasionally the point, and it is also why the next rule exists.

6. **Never undraft a GitLab MR through the browser.** Nothing but `/promote-mr` may cause an
   MR's `draft` to become `false`, by any means — that includes clicking "Mark as ready",
   and it includes editing the title field in a way that drops the `Draft: ` prefix. The
   browser is a bypass route around the API-level rule, not an exception to it. If a workflow
   needs an MR undrafted, hand off to the `promote-mr` skill.

7. **Never merge a merge request through the browser.** Same reasoning, higher stakes.
   Clicking "Merge" is still an agent merging code, which no agent may do regardless of
   approvals or CI state. Merging is a human action.

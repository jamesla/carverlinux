---
description: sentry
name: sentry
---

# sentry

Debug Sentry issues for your platform from the CLI — list issues, drill into
an issue's events, pull stacktraces, and break errors down by release / URL / server.
Uses the Sentry REST API (SaaS, `https://sentry.io/api/0`) via plain `curl` + `jq`.
This is the **read/debug** counterpart to the `newrelic` skill.

## Configure for your workspace

Set these tokens before using this skill:

- `<SENTRY_ORG>` — your Sentry org slug (from the `orgs` call below)
- Populate the **service → Sentry project map** with your own service and project slugs
  on first authenticated run

## Auth & invocation

- **Org:** SaaS; get the human org slug via the `orgs` call below.
- **Token:** a Sentry **auth token** with scopes `org:read`, `project:read`,
  `event:read`. Lives in `.env` at the workspace root (git-ignored) — see
  `.env.example`:
  ```
  SENTRY_AUTH_TOKEN=<token>
  SENTRY_ORG=<org-slug>                 # from the `orgs` call
  # SENTRY_URL=https://sentry.io/api/0  # override only for self-hosted
  ```
- **Load the token, then curl.** Every command below assumes:
  ```bash
  set -a; . ./.env; set +a
  ```
  All requests are `GET` with header `Authorization: Bearer $SENTRY_AUTH_TOKEN`.

## Endpoints

| Endpoint | Gives you |
|---|---|
| `GET /organizations/` | org slugs (→ `SENTRY_ORG`) |
| `GET /organizations/{org}/projects/` | project slugs + platform |
| `GET /projects/{org}/{project}/issues/?query=&sort=freq&statsPeriod=` | top issues for a project |
| `GET /issues/{id}/` | issue metadata (counts, first/last seen, level, permalink) |
| `GET /issues/{id}/events/` · `.../events/latest/` | events / latest event **with stacktrace** |
| `GET /issues/{id}/tags/{key}/` | value distribution for a tag |

Issue-search `query` terms: `is:unresolved`, `is:assigned`, `release:<ver>`,
`environment:production`, `level:error`, `firstSeen:-24h`, free text. `statsPeriod`
accepts `1h`/`24h`/`14d`; `sort` one of `freq`/`date`/`new`/`user`.

## Debugging cookbook

```bash
set -a; . ./.env; set +a
B=https://sentry.io/api/0
AUTH=(-H "Authorization: Bearer $SENTRY_AUTH_TOKEN")

# 0. One-time: find org slug + project slugs
curl -sS "${AUTH[@]}" "$B/organizations/" | jq -r '.[] | "\(.slug)\t\(.name)"'
curl -sS "${AUTH[@]}" "$B/organizations/$SENTRY_ORG/projects/" \
  | jq -r '.[] | "\(.slug)\t\(.platform // "?")\t\(.name)"'

# 1. Top unresolved errors for a service, last 24h, most frequent first
curl -sS "${AUTH[@]}" -G "$B/projects/$SENTRY_ORG/service-a/issues/" \
  --data-urlencode "query=is:unresolved" \
  --data-urlencode "sort=freq" \
  --data-urlencode "statsPeriod=24h" \
  | jq -r '.[] | "\(.id)\t\(.count)x\tlast=\(.lastSeen)\t\(.culprit // "")\t\(.title)"'

# 2. Narrow: a release / production only / a longer window
curl -sS "${AUTH[@]}" -G "$B/projects/$SENTRY_ORG/service-b/issues/" \
  --data-urlencode "query=is:unresolved environment:production release:frontend@2026.08.10" \
  --data-urlencode "statsPeriod=14d" | jq -r '.[] | "\(.id)\t\(.count)x\t\(.title)"'

# 3. Drill into one issue (numeric id from column 1 above): metadata …
ID=1234567890
curl -sS "${AUTH[@]}" "$B/issues/$ID/" \
  | jq '{shortId, title, culprit, level, status, count, userCount,
         firstSeen, lastSeen, permalink, project: .project.slug}'

# … then the latest event with the exception + last stack frames
curl -sS "${AUTH[@]}" "$B/issues/$ID/events/latest/" \
  | jq '{eventID, dateCreated, release: (.release.version? // .release), environment,
         exception: [ .entries[]? | select(.type=="exception") | .data.values[]?
                      | {type, value,
                         frames: [ .stacktrace.frames[]?
                                   | {filename, function, lineNo} ][-8:]} ]}'

# 4. Blast radius: is it one release / URL / host?
for k in release url server_name environment; do
  echo "== $k =="
  curl -sS "${AUTH[@]}" "$B/issues/$ID/tags/$k/" | jq -r '.topValues[]? | "\(.count)\t\(.value)"'
done
```

## Service → Sentry project map

All Django services init `sentry_sdk` via `DJANGO_SENTRY_DSN`; the Next.js frontend uses
`@sentry/nextjs`. Populate the real slugs on first authenticated run
(`.../projects/`) — Sentry project slugs are **not** guaranteed to match your
service names.

| Platform service | SDK | Sentry project slug |
|---|---|---|
| service-a | `sentry_sdk` (py) | _run projects call_ |
| service-b | `sentry_sdk` (py) | _tbd_ |
| service-c | `sentry_sdk` (py) | _tbd_ |
| frontend | `@sentry/nextjs` | _tbd_ |

## Gotchas

1. **Sentry ≠ New Relic.** Sentry = discrete errors/exceptions with stacktraces &
   breadcrumbs ("what broke, where in the code, which release"). New Relic = aggregate
   throughput / latency / error-rate. For "stacktrace + offending release" use Sentry;
   for "error rate over time" use `newrelic`.
2. **Token is a secret** — in `.env` (git-ignored). Unlike the NR *Browser* key it is
   **not** public; never inline or commit it.
3. **Two ID kinds.** Numeric issue id (`1234567890`, column 1 of the issues list) vs
   human `shortId` (`SERVICE-A-1AB`). The `/issues/{id}/…` paths take the **numeric** id.
   `permalink` opens the web UI.
4. **Issues list needs a project *slug*, not a service name** — get slugs from the
   `projects` call first; they may differ from your service names.
5. **Default window catches only recent errors.** Quiet services may
   return nothing at `24h` — widen `statsPeriod` (`14d`) or drop `is:unresolved`.
6. **`-G` + `--data-urlencode`** is required so `query` spaces/colons encode correctly;
   a bare `?query=is:unresolved environment:production` in the URL will break.
7. **Rate limits** — the API is rate-limited per token; avoid tight loops over
   `events`/`latest`/`tags` across many issues.

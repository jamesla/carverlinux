---
description: signoz
name: signoz
---

# signoz

Query your self-hosted SigNoz instance for distributed traces, logs, and service health —
using the SigNoz REST API via plain `curl` + `jq`. SigNoz is the **self-hosted
OpenTelemetry backend** for the platform; it complements New Relic and Sentry
rather than replacing them.

## Configure for your workspace

Set these tokens before using this skill:

- `<SIGNOZ_URL>` — your SigNoz instance URL (no trailing slash)
- `SIGNOZ_API_KEY` — your SigNoz API key
- `CF_ACCESS_CLIENT_ID` / `CF_ACCESS_CLIENT_SECRET` — access-proxy service token, if
  your instance sits behind an access proxy
- Populate the **service names** table with your own OTEL service names

## When to use SigNoz vs other tools

| Need | Tool |
|---|---|
| Distributed trace for a single request (spans, latency waterfall) | **SigNoz** |
| Service dependency map, p99 latency trends | **SigNoz** |
| Aggregate throughput / error-rate across fleet | **New Relic** |
| Exception stacktrace + offending release | **Sentry** |
| CloudFront / CDN access logs | **AWS CloudWatch** |

SigNoz answers "what happened inside this one request across multiple services?"
New Relic answers "how is the whole service performing right now?"
Sentry answers "which code line threw this exception and in which release?"

## Auth & invocation

Your self-hosted SigNoz instance (`<SIGNOZ_URL>`) sits behind an **access proxy**. Two credentials are required:

- **Access-proxy service token** — `CF_ACCESS_CLIENT_ID` and `CF_ACCESS_CLIENT_SECRET`, sent as `CF-Access-Client-Id` / `CF-Access-Client-Secret` headers to pass the access-proxy layer.
- **SigNoz API key** — `SIGNOZ_API_KEY`, sent as `SIGNOZ-API-KEY: <key>` to SigNoz itself.

All variables live in `.env` at the workspace root (git-ignored):
```
SIGNOZ_URL=<SIGNOZ_URL>
SIGNOZ_API_KEY=your-signoz-api-key
CF_ACCESS_CLIENT_ID=your-access-client-id
CF_ACCESS_CLIENT_SECRET=your-access-client-secret
```

- **Load env and set the invocation wrapper:**
  ```bash
  set -a; . ./.env; set +a
  ```
  Every request uses plain `curl` with both access-proxy service token headers and the SigNoz API key:
  ```bash
  cf_curl() {
    curl \
      -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
      -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET" \
      -H "SIGNOZ-API-KEY: $SIGNOZ_API_KEY" \
      -H "Accept: application/json" \
      "$@"
  }
  ```

## API surface

SigNoz exposes a query-service REST API. The most useful endpoints:

| Endpoint | Gives you |
|---|---|
| `GET /api/v1/services/list?start=<ms>&end=<ms>` | Array of service name strings (active in window) |
| `POST /api/v3/query_range` | Metrics, traces, and logs via ClickHouse-backed query (primary data endpoint) |
| `GET /api/v1/traces/{traceID}` | All spans for a specific trace ID |
| `GET /api/v1/alerts` | Configured alert rules |
| `GET /api/v2/dashboards` | Saved dashboards |

## Querying cookbook

```bash
set -a; . ./.env; set +a
B="$SIGNOZ_URL/api/v1"
cf_curl() {
  curl \
    -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
    -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET" \
    -H "SIGNOZ-API-KEY: $SIGNOZ_API_KEY" \
    -H "Accept: application/json" \
    "$@"
}

# 0. List all instrumented services (returns a JSON array of service name strings)
cf_curl -G "$B/services/list" \
  --data-urlencode "start=$(date -d '1 hour ago' +%s)000" \
  --data-urlencode "end=$(date +%s)000" | jq -r '.[]'

# 2. Trace search — find recent traces for a service (via query_range)
START_MS=$(date -d '1 hour ago' +%s)000
END_MS=$(date +%s)000
cf_curl -X POST "$SIGNOZ_URL/api/v3/query_range" \
  -H "Content-Type: application/json" \
  -d "{
    \"start\": $START_MS,
    \"end\": $END_MS,
    \"step\": 60,
    \"variables\": {},
    \"compositeQuery\": {
      \"queryType\": \"builder\",
      \"panelType\": \"list\",
      \"builderQueries\": {
        \"A\": {
          \"dataSource\": \"traces\",
          \"queryName\": \"A\",
          \"aggregateOperator\": \"noop\",
          \"expression\": \"A\",
          \"selectColumns\": [
            {\"key\": \"traceID\", \"type\": \"tag\"},
            {\"key\": \"serviceName\", \"type\": \"tag\"},
            {\"key\": \"durationNano\", \"type\": \"tag\"},
            {\"key\": \"name\", \"type\": \"tag\"},
            {\"key\": \"httpMethod\", \"type\": \"tag\"},
            {\"key\": \"httpUrl\", \"type\": \"tag\"},
            {\"key\": \"statusCode\", \"type\": \"tag\"}
          ],
          \"filters\": {\"op\": \"AND\", \"items\": [
            {\"key\": {\"key\": \"serviceName\", \"type\": \"tag\"}, \"op\": \"=\", \"value\": \"service-c\"}
          ]},
          \"limit\": 20,
          \"orderBy\": [{\"columnName\": \"timestamp\", \"order\": \"desc\"}]
        }
      }
    }
  }" | jq -r '.data.result[0].list[]?.data | "\(.traceID)\t\(.durationNano/1000000|floor)ms\t\(.httpMethod // "?")\t\(.httpUrl // .name // "?")"'

# 3. Drill into a single trace — full span waterfall
TRACE_ID=abc123def456
cf_curl "$B/traces/$TRACE_ID" \
  | jq '.data.spans[]? | {spanID, operationName, serviceName,
       durationMs: (.durationNano/1000000), statusCode: .statusCode,
       parentSpanID}' | head -60

# 4. Error traces only — add a statusCode filter to example 2
# Add to filters.items: {"key": {"key": "statusCode", "type": "tag"}, "op": "=", "value": "Error"}

# 5. Log search — find ERROR logs for a service in the last hour
cf_curl -X POST "$SIGNOZ_URL/api/v3/query_range" \
  -H "Content-Type: application/json" \
  -d '{
    "start": '$(date -d "1 hour ago" +%s)'000,
    "end": '$(date +%s)'000,
    "step": 60,
    "variables": {},
    "compositeQuery": {
      "queryType": "builder",
      "panelType": "list",
      "builderQueries": {
        "A": {
          "dataSource": "logs",
          "queryName": "A",
          "aggregateOperator": "noop",
          "filters": {
            "op": "AND",
            "items": [
              {"key": {"key": "severity_text"}, "op": "=", "value": "ERROR"},
              {"key": {"key": "service.name"}, "op": "=", "value": "service-a"}
            ]
          },
          "limit": 20,
          "orderBy": [{"columnName": "timestamp", "order": "desc"}]
        }
      }
    }
  }' | jq '.data.result[]?.list[]?.data | {timestamp, body, severity_text}'
```

## Service names in SigNoz

Service names in SigNoz traces are set via the `OTEL_SERVICE_NAME` env var in each
container. Confirm the live names with the services list call (step 0) on first use.

| Platform service | Expected OTEL service name |
|---|---|
| service-a | `service-a` |
| service-b | `service-b` |
| service-c | `service-c` |
| frontend (Next.js) | `frontend` |

## Gotchas

1. **Timestamps are milliseconds for `/api/v3/query_range`.** Use `$(date +%s)000` (13 digits).
   The old `/api/v1/traces` endpoint (nanoseconds) does not exist in this SigNoz version — all
   trace and log queries go through `query_range`.
2. **`SIGNOZ_URL` has no trailing slash.** Append paths directly: `$SIGNOZ_URL/api/v1/...`.
3. **`SIGNOZ-API-KEY` header (hyphen, not underscore).** The auth header is
   `SIGNOZ-API-KEY`, not `X-API-Key` or `Authorization: Bearer`.
4. **SigNoz ≠ Sentry.** SigNoz has traces and structured logs from the
   OpenTelemetry SDK; Sentry has rich exception events with stacktraces and breadcrumbs.
   For "what code line threw this?" use Sentry. For "which downstream call took 8 seconds
   in this request?" use SigNoz.
5. **SigNoz ≠ New Relic.** SigNoz traces cover only services instrumented with the
   OTEL SDK; New Relic has broader fleet coverage (infra, browser, synthetics).
   Use New Relic for fleet-wide error rates; SigNoz for per-request trace analysis.
6. **The access proxy gates the instance — service token headers required.**
   `<SIGNOZ_URL>` sits behind an access proxy. Plain `curl` without the
   `CF-Access-Client-Id` / `CF-Access-Client-Secret` headers gets redirected to the login page.
   If a request returns HTML instead of JSON, check that `CF_ACCESS_CLIENT_ID` and
   `CF_ACCESS_CLIENT_SECRET` are set correctly in `.env`.
7. **Span status codes.** OTLP status: `0` = UNSET, `1` = OK, `2` = ERROR. Filter
   `"status": 2` to find failing traces.

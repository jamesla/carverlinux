---
description: newrelic
name: newrelic
---

# newrelic

Query the New Relic account for your platform — throughput, latency, errors,
infrastructure metrics, and APM behaviour.

## Configure for your workspace

Set these tokens before using this skill:

- `<NEWRELIC_ACCOUNT_ID>` — your New Relic account id.
- Replace the generic service names (`service-a`, `service-b`, `service-c`, …)
  with your own `appName` values. Discover the exact forms with `FACET appName`
  (see gotcha 1 about trailing spaces).

## Account & invocation

- **Account:** `<NEWRELIC_ACCOUNT_ID>` · **Region:** US
- **NRQL:** `newrelic nrql query --accountId <NEWRELIC_ACCOUNT_ID> --query "<NRQL>"`
- **Entity search:** `newrelic entity search --domain <APM|INFRA|BROWSER|SYNTH> [--type <T>] [--fields-filter name,language,reporting]`

## Queryable event types

| Category | Event types | Notes |
|---|---|---|
| APM | `Transaction`, `TransactionError`, `TransactionTrace`, `ErrorTrace`, `SqlTrace` | Primary behaviour source for all instrumented apps |
| Tracing | `Span` | Only some services emit spans; confirm before relying on `Span`. `DistributedTraceSummary` may be empty |
| Browser | `PageView`, `PageViewTiming`, `AjaxRequest`, `JavaScriptError` | Only the browser-instrumented front end meaningfully reports |
| Infrastructure | `SystemSample`, `ProcessSample`, `ContainerSample`, `StorageSample`, `NetworkSample` | Host/process/container metrics; `ContainerSample.containerName` may be empty — use `containerId` |
| Synthetics | `SyntheticCheck`, `SyntheticRequest` | May be only a handful of monitors |
| Dimensional metrics | `Metric` | May be golden-metrics only (`newrelic.goldenmetrics.*`) — no raw CloudWatch metric streams |
| Alerts / AIOps | `NrAiIncident`, `NrAiIssue` | Only appear over ≥7 d windows |
| Deploys | `Deployment` | Only services that push deploy markers appear |

**Not in New Relic (verify for your setup):**
- `Log` may resolve but return 0 rows — logs may live in **CloudWatch** (`aws` CLI).
- `CloudCost`/`KubernetesCost` may be unqueryable — use **AWS Cost Explorer**.
- Distributed tracing may not exist for every service.

## APM services — exact `appName` values

Fill in your instrumented services below. Several `appName` values can carry a
**trailing space** — `WHERE appName = 'service-c'` then returns nothing. Use
`LIKE 'service-c%'` or `FACET appName` to discover the exact form.

| `appName` (exact) | Lang | rpm (1 d) | Role |
|---|---|---:|---|
| `service-a` | py | N | Primary compute consumer |
| `service-b` | node | N | SSR renderer |
| `service-c ` *(may carry a trailing space)* | py | N | CMS / REST API |
| *(add a row per instrumented service in your workspace)* | | | |

## Query cookbook

```sql
-- Service throughput + latency
SELECT count(*), rate(count(*),1 minute) AS rpm, average(duration), percentile(duration,95,99)
FROM Transaction FACET appName SINCE 1 day ago LIMIT 100

-- Error rate (use LIKE to handle trailing spaces)
SELECT count(*) FROM TransactionError WHERE appName LIKE 'service-c%'
FACET error.class SINCE 1 day ago

-- Top transactions for a service
SELECT count(*), average(duration), percentile(duration,95)
FROM Transaction WHERE appName = 'service-a' FACET name SINCE 1 day ago LIMIT 30

-- DB / external fan-out
SELECT average(databaseCallCount), average(databaseDuration),
       average(externalCallCount), average(externalDuration), average(duration)
FROM Transaction FACET appName SINCE 1 day ago

-- Host CPU / memory
SELECT average(cpuPercent), average(memoryUsedBytes)/1e9 AS mem_gb
FROM SystemSample FACET hostname SINCE 30 minutes ago LIMIT 50

-- External HTTP calls (span-emitting apps only)
SELECT count(*), average(duration) FROM Span WHERE category='http'
FACET appName, name SINCE 1 day ago LIMIT 40

-- Deploy markers (deploy-marker-emitting apps only)
SELECT count(*) FROM Deployment FACET entity.name SINCE 7 days ago
```

## Gotchas

1. **Trailing spaces in `appName`** — some services have a trailing space in their `appName`. Use `LIKE 'Name%'` not `= 'Name'`.
2. **No hot-path tracing** — spans may only exist on a subset of services. For the rest, use `Transaction` attributes (`databaseCallCount`, `externalCallCount`), not `Span`.
3. **`externalDuration`/`databaseDuration` can exceed `duration`** (async overlap, different population). Do not subtract them to derive CPU time.
4. **`Metric` may be golden-metrics only** — no raw CloudWatch metric streams. For infra, query `SystemSample` directly.
5. **`ContainerSample.containerName` may be empty** — facet on `containerId` or `entityName`.
6. **The full container/ECS estate can be larger than the instrumented APM apps.** Uninstrumented services are invisible to `Transaction`.
7. **Some real services may not appear in your service map/CLAUDE.md** — flag this when answering architecture questions.

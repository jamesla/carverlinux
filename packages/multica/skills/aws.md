---
name: aws
description: "Run any AWS CLI command against your production account — a general-purpose swiss-army-knife for ECS, RDS, CloudFront, Lambda, S3, CloudWatch Logs, SSM, Cost Explorer, and more. Use for AWS resource inspection and operations. Auth is always via environment variables."
user-invocable: true
allowed-tools: Bash(aws *)
---

# aws

A thin wrapper over the `aws` CLI (already installed). Use it for **anything** AWS —
inspecting or operating ECS, RDS, CloudFront, Lambda, S3, CloudWatch Logs, SSM, Cost
Explorer, IAM, DynamoDB, ElastiCache, and the rest. If the CLI can do it, this skill
covers it.

## Configure for your workspace

Replace these placeholders with your own values before use:

- `<AWS_REGION>` — the region your resources live in (set `AWS_DEFAULT_REGION` to it).
- `<ECS_CLUSTER>` — an ECS cluster name in your account.
- `<LOG_GROUP>` — a CloudWatch Logs group you query.

## Auth — always via environment variables

Credentials come **only** from the environment. These are expected to be set in the
runtime:

| Variable | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key (required) |
| `AWS_SECRET_ACCESS_KEY` | Secret key (required) |
| `AWS_SESSION_TOKEN` | Session token (only for temporary/STS credentials) |
| `AWS_DEFAULT_REGION` / `AWS_REGION` | Default region — set to `<AWS_REGION>` |

- **Do not** use `--profile`, `~/.aws/credentials`, `~/.aws/config`, `aws configure`,
  `aws sso login`, or any profile/SSO flow. This skill assumes env-var auth end to end.
- **Never** print, echo, or paste credential values. Reference the variable *names*
  only; never embed a real key in a command, comment, file, or issue.
- **Sanity check** who you are before doing real work:

```bash
aws sts get-caller-identity --output json
```

If that fails with a credentials error, the env vars aren't set — stop and report it;
do not fall back to a profile.

## Account & region

- **Your production account**, region **`<AWS_REGION>`**. Pass `--region <AWS_REGION>`
  or rely on `AWS_DEFAULT_REGION`.
- **Cost Explorer is `us-east-1`-only** — pass `--region us-east-1` for `aws ce ...`
  regardless of where resources live.

## General pattern

```bash
aws <service> <operation> [flags] --output json --no-cli-pager
```

- **`--output json`** for structured, parseable output (org preference: default to
  metrics/structured data). `table` for a quick human read.
- **`--query '<JMESPath>'`** to slice server-side and keep responses small, e.g.
  `--query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}'`.
- **`--no-cli-pager`** so long output never blocks on an interactive pager.
- **Discover** any command with built-in help: `aws <service> help`,
  `aws <service> <operation> help`.

## Service quick-refs

### STS / identity
```bash
aws sts get-caller-identity --output json
```

### ECS
```bash
aws ecs list-clusters --region <AWS_REGION> --output json
aws ecs list-services --region <AWS_REGION> --cluster <ECS_CLUSTER> --output json
aws ecs describe-services --region <AWS_REGION> \
  --cluster <ECS_CLUSTER> --services service-a \
  --query 'services[].{Name:serviceName,Desired:desiredCount,Running:runningCount,TaskDef:taskDefinition}'
```

### RDS
```bash
aws rds describe-db-instances --region <AWS_REGION> \
  --query 'DBInstances[].{Id:DBInstanceIdentifier,Class:DBInstanceClass,Engine:Engine,Status:DBInstanceStatus}'
```

### CloudWatch Logs
```bash
# Tail a log group live
aws logs tail /aws/lambda/<function-name> --region <AWS_REGION> --follow

# Logs Insights is ASYNC — start, then poll:
qid=$(aws logs start-query --region <AWS_REGION> \
  --log-group-name <LOG_GROUP> \
  --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s) \
  --query-string 'fields `@timestamp`, `@message` | filter `status` >= 500 | limit 50' \
  --query queryId --output text)
aws logs get-query-results --region <AWS_REGION> --query-id "$qid"
```
Match the fields in your `--query-string` to whatever structure your `<LOG_GROUP>`
events actually have — inspect a sample event first rather than assuming field names.

### CloudFront
```bash
aws cloudfront list-distributions --region <AWS_REGION> \
  --query 'DistributionList.Items[].{Id:Id,Aliases:Aliases.Items,Origin:Origins.Items[0].DomainName}'
```

### Lambda
```bash
aws lambda list-functions --region <AWS_REGION> \
  --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}'
```

### S3
```bash
aws s3 ls
aws s3 ls s3://<bucket>/<prefix>/ --region <AWS_REGION>
aws s3 cp s3://<bucket>/<key> ./local-copy --region <AWS_REGION>
```

### SSM Parameter Store
```bash
aws ssm get-parameters-by-path --region <AWS_REGION> --path /<prefix>/ --recursive \
  --query 'Parameters[].Name'
# --with-decryption reveals SecureString values — only when needed, never echo secrets.
```

### Cost Explorer (us-east-1)
```bash
aws ce get-cost-and-usage --region us-east-1 \
  --time-period Start=2026-08-01,End=2026-09-01 --granularity MONTHLY \
  --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE
```

## Gotchas

1. **Env-var auth only.** Never `--profile` / `aws configure` / SSO. Missing env vars →
   report it, don't work around it.
2. **Never expose secrets.** Don't echo credential values or `--with-decryption` output
   into comments, logs, or files.
3. **Cost Explorer needs `--region us-east-1`** even for `<AWS_REGION>` resources.
4. **Logs Insights is async** — `start-query` returns a `queryId`; poll
   `get-query-results` until `status` is `Complete`.
5. **`--no-cli-pager`** (or `AWS_PAGER=""`) to avoid the CLI hanging on a pager in a
   non-interactive run.
6. **Inspect log event structure before querying.** Field names in a log group depend on
   how events are written — confirm them on a sample event rather than guessing.
7. **Mutating / destructive ops** (delete, terminate, `apply`, scaling, deploys):
   this workspace is plan-first and never auto-deploys — confirm before running
   anything that changes infra state.

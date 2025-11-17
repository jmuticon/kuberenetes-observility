# Prometheus Rules

## Overview
The `prometheus-rules.yaml` file defines PrometheusRule custom resources that contain alerting rules. These rules define conditions that, when met, trigger alerts that are sent to Alertmanager.

## Key Components

### PrometheusRule Resource
- **Name**: `demo-alert-rules`
- **Namespace**: `observability`
- **Group Name**: `demo.rules`

### Alert Rules

#### BackendHighLatency Alert
- **Alert Name**: `BackendHighLatency`
- **Expression**: 
  ```
  histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1
  ```
- **Duration**: 2 minutes (`for: 2m`)
- **Severity**: `warning`
- **Summary**: "High API latency (95th percentile > 1s)"

**What it does**:
- Calculates the 95th percentile of HTTP request duration
- Uses a 5-minute rolling window
- Triggers if the 95th percentile exceeds 1 second
- Must be true for 2 minutes before firing

#### MySQLDown Alert
- **Alert Name**: `MySQLDown`
- **Expression**: 
  ```
  absent(mysql_up) or mysql_up == 0
  ```
- **Duration**: 1 minute (`for: 1m`)
- **Severity**: `critical`
- **Summary**: "MySQL appears to be down"

**What it does**:
- Checks if `mysql_up` metric exists
- If metric doesn't exist OR equals 0, MySQL is considered down
- Triggers after 1 minute of being down
- Critical severity indicates immediate attention needed

## How It Works
1. Prometheus continuously evaluates these alert expressions
2. When an expression evaluates to `true`:
   - Alert enters "pending" state
   - After the `for` duration, alert becomes "firing"
3. Firing alerts are sent to Alertmanager
4. Alertmanager routes alerts based on labels (e.g., `severity: critical`)
5. Notifications are sent to configured receivers

## PromQL Expressions Explained

### BackendHighLatency Expression
```
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1
```

- `http_request_duration_seconds_bucket`: Histogram buckets from Prometheus client
- `rate(...[5m])`: Calculates per-second rate over 5 minutes
- `sum(...) by (le)`: Sums buckets grouped by the `le` (less than or equal) label
- `histogram_quantile(0.95, ...)`: Calculates 95th percentile
- `> 1`: Checks if result exceeds 1 second

### MySQLDown Expression
```
absent(mysql_up) or mysql_up == 0
```

- `absent(mysql_up)`: Returns 1 if metric doesn't exist, 0 otherwise
- `mysql_up == 0`: Returns 1 if metric exists but equals 0
- `or`: Logical OR - triggers if either condition is true

## Alert States
- **Inactive**: Expression is false
- **Pending**: Expression is true, waiting for `for` duration
- **Firing**: Expression has been true for the required duration

## Integration
- Prometheus Operator watches for PrometheusRule resources
- Rules are automatically loaded into Prometheus
- No manual configuration needed in Prometheus

## Best Practices
- Use appropriate severity levels (warning, critical)
- Set reasonable `for` durations to avoid false positives
- Include meaningful summaries and descriptions
- Test alert expressions in Prometheus UI before deploying
- Use labels for alert routing in Alertmanager

## Adding More Rules
You can add additional alert rules to the `rules` array:
```yaml
- alert: AlertName
  expr: promql_expression
  for: duration
  labels:
    severity: warning|critical
  annotations:
    summary: "Alert description"
```


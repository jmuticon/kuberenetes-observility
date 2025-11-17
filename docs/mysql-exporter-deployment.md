# MySQL Exporter Deployment

## Overview
The `mysql-exporter-deployment.yaml` file defines a Kubernetes Deployment that runs the Prometheus MySQL Exporter. This exporter scrapes MySQL metrics and exposes them in Prometheus format. The file also includes a Service definition.

## Key Components

### Deployment Resource
- **Name**: `mysql-exporter`
- **Namespace**: `app`
- **Replicas**: 1

### Container Configuration
- **Image**: `prom/mysqld-exporter:v0.14.0` (official Prometheus MySQL exporter)
- **Port**: 9104 (default exporter port)

### Environment Variables
- `DATA_SOURCE_NAME`: MySQL connection string
  - Format: `user:password@(host:port)/`
  - Example: `root:example@(mysql:3306)/`
  - Connects to MySQL service in the same namespace

### Resource Limits
- **Requests**: 50m CPU, 32Mi memory
- **Limits**: 100m CPU, 64Mi memory

### Service Resource
The file also includes a Service definition:
- **Name**: `mysql-exporter`
- **Namespace**: `app`
- **Port**: 9104
- **Target Port**: 9104
- **Name**: `metrics`

## How It Works
1. The exporter container starts and connects to MySQL using the connection string
2. The exporter queries MySQL for various metrics (connections, queries, performance, etc.)
3. Metrics are exposed at `/metrics` endpoint on port 9104
4. Prometheus scrapes these metrics periodically
5. Metrics are stored in Prometheus for visualization and alerting

## Metrics Exposed
The MySQL exporter exposes metrics such as:
- `mysql_up`: Whether MySQL is accessible (1) or not (0)
- `mysql_global_status_*`: Global status variables
- `mysql_global_variables_*`: Global configuration variables
- `mysql_info_schema_*`: Information schema metrics
- Connection pool metrics
- Query performance metrics

## Dependencies
- Requires MySQL service to be running and accessible
- Requires Prometheus or ServiceMonitor to scrape the metrics endpoint
- The exporter must have network access to the MySQL service

## Service Discovery
Prometheus can discover this exporter via:
- ServiceMonitor (if configured)
- Static scrape configuration in Prometheus
- OpenTelemetry Collector (as configured in otel-collector.yaml)

## Access
The metrics endpoint is accessible at:
- `http://mysql-exporter.app.svc.cluster.local:9104/metrics`
- Within the same namespace: `http://mysql-exporter:9104/metrics`


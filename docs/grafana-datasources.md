# Grafana Datasources

## Overview
The `grafana-datasources.yaml` file defines a ConfigMap that automatically configures Grafana with data sources for Prometheus, Loki, and Tempo. This enables Grafana to query metrics, logs, and traces.

## Key Components

### ConfigMap Resource
- **Name**: `grafana-datasources`
- **Namespace**: `observability`
- **Label**: `grafana_datasource: "1"` (tells Grafana to load this as a datasource)

### Data Source Configuration

#### Prometheus Data Source
- **Name**: `Prometheus`
- **Type**: `prometheus`
- **URL**: `http://prometheus-operated.observability.svc:9090`
- **Access**: `proxy` (Grafana proxies requests to Prometheus)

#### Loki Data Source
- **Name**: `Loki`
- **Type**: `loki`
- **URL**: `http://loki.observability.svc:3100`
- **Access**: `proxy` (Grafana proxies requests to Loki)

#### Tempo Data Source
- **Name**: `Tempo`
- **Type**: `tempo`
- **URL**: `http://tempo.observability.svc:3200`
- **Access**: `proxy` (Grafana proxies requests to Tempo)

## How It Works
1. Grafana Operator or sidecar watches for ConfigMaps with label `grafana_datasource: "1"`
2. When this ConfigMap is created, Grafana automatically loads the datasources
3. The datasources become available in Grafana UI
4. Users can create dashboards and queries using these datasources

## Data Source Types

### Prometheus
- Used for querying metrics and time-series data
- Supports PromQL queries
- Used in dashboards for visualizing metrics

### Loki
- Used for querying and searching logs
- Supports LogQL queries
- Used for log exploration and analysis

### Tempo
- Used for querying distributed traces
- Supports trace queries by trace ID
- Used for trace visualization and analysis

## Service URLs
All datasources use Kubernetes service DNS names:
- `prometheus-operated.observability.svc`: Prometheus service
- `loki.observability.svc`: Loki service
- `tempo.observability.svc`: Tempo service

## Access Mode
- **Proxy**: Grafana server makes requests on behalf of the user
- Alternative: `direct` (browser makes requests directly, requires CORS)

## Integration
This ConfigMap works with:
- Grafana Operator (if using operator)
- Grafana sidecar (if enabled in prometheus-stack-values.yaml)
- Manual Grafana configuration

## Benefits
- Automatic datasource provisioning
- No manual configuration in Grafana UI
- Version controlled configuration
- Easy to replicate across environments


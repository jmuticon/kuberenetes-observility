# Kubernetes Observability Documentation

This directory contains detailed documentation for each YAML file in the Kubernetes observability stack. Each file is explained separately to help you understand the purpose, configuration, and how each component works.

## Application Components (k8s/app/)

### Core Application
- **[backend-deployment.md](backend-deployment.md)** - Node.js backend application with Express, Prometheus metrics, MySQL connectivity, and OpenTelemetry tracing
- **[backend-service.md](backend-service.md)** - Service that exposes the backend deployment
- **[backend-servicemonitor.md](backend-servicemonitor.md)** - Prometheus ServiceMonitor for automatic metrics scraping
- **[frontend-deployment.md](frontend-deployment.md)** - Nginx web server serving HTML frontend
- **[frontend-service.md](frontend-service.md)** - Service that exposes the frontend deployment
- **[ingress.md](ingress.md)** - Ingress resource for routing external traffic to frontend and backend

### Database Components
- **[mysql-deployment.md](mysql-deployment.md)** - MySQL 8.0 database deployment
- **[mysql-service.md](mysql-service.md)** - Headless service for MySQL database access
- **[mysql-exporter-deployment.md](mysql-exporter-deployment.md)** - Prometheus MySQL exporter for database metrics

## Observability Components (k8s/observability/)

### Monitoring Stack
- **[prometheus-stack-values.md](prometheus-stack-values.md)** - Helm values for kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
- **[prometheus-rules.md](prometheus-rules.md)** - Alerting rules for Prometheus
- **[alertmanager-config.md](alertmanager-config.md)** - Alertmanager configuration for routing alerts to Slack/Email

### Logging Stack
- **[loki.md](loki.md)** - Loki log aggregation system
- **[promtail.md](promtail.md)** - Promtail log collection agent (DaemonSet)

### Tracing Stack
- **[tempo.md](tempo.md)** - Tempo distributed tracing backend
- **[otel-collector.md](otel-collector.md)** - OpenTelemetry Collector for unified telemetry collection

### Visualization
- **[grafana-datasources.md](grafana-datasources.md)** - Automatic Grafana datasource configuration
- **[grafana-ingress.md](grafana-ingress.md)** - Ingress for accessing Grafana UI

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     External Traffic                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │    Ingress     │
              └────────┬───────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌───────────────┐            ┌───────────────┐
│   Frontend    │            │    Backend    │
│   (Nginx)     │───────────▶│  (Node.js)    │
└───────────────┘            └───────┬───────┘
                                     │
                                     ▼
                            ┌───────────────┐
                            │    MySQL      │
                            └───────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Observability Stack                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │  Prometheus  │    │     Loki     │    │    Tempo     │ │
│  │  (Metrics)   │    │   (Logs)     │    │   (Traces)   │ │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘ │
│         │                   │                    │          │
│         └───────────────────┴────────────────────┘          │
│                            │                                 │
│                            ▼                                 │
│                   ┌───────────────┐                          │
│                   │ OTEL Collector│                          │
│                   └───────────────┘                          │
│                            │                                 │
│         ┌──────────────────┼──────────────────┐              │
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ServiceMonitor│  │   Promtail   │  │  OTLP Export │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│                            │                                 │
│                            ▼                                 │
│                   ┌───────────────┐                          │
│                   │    Grafana    │                          │
│                   │ (Visualization)│                         │
│                   └───────────────┘                          │
│                                                              │
│                   ┌───────────────┐                          │
│                   │ Alertmanager  │                          │
│                   │  (Alerts)     │                          │
│                   └───────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Metrics Flow
1. Applications expose metrics at `/metrics` endpoint
2. Prometheus ServiceMonitor discovers and scrapes metrics
3. Metrics stored in Prometheus
4. Grafana queries Prometheus for visualization
5. Alertmanager evaluates alert rules and sends notifications

### Logs Flow
1. Applications write logs to stdout/stderr
2. Promtail (DaemonSet) collects logs from all pods
3. Promtail sends logs to Loki
4. Grafana queries Loki for log visualization

### Traces Flow
1. Applications instrumented with OpenTelemetry
2. Traces sent to OpenTelemetry Collector via OTLP
3. Collector forwards traces to Tempo
4. Grafana queries Tempo for trace visualization

## Comprehensive Guides

- **[observability-components-datadog.md](observability-components-datadog.md)** - Complete guide explaining all observability layers (Metrics, Logs, Traces, Aggregator, Visualization, Alerts) with detailed Datadog implementation

## Getting Started

1. **Read the application components** to understand the demo application
2. **Read the observability components** to understand the monitoring stack
3. **Review the architecture** to see how everything connects
4. **Check individual documentation** for specific configuration details
5. **Read the comprehensive Datadog guide** to understand how to achieve observability with Datadog

## Key Concepts

- **Deployment**: Manages pod replicas and updates
- **Service**: Provides stable network endpoint for pods
- **Ingress**: Routes external traffic to services
- **ConfigMap**: Stores configuration data
- **ServiceMonitor**: Prometheus service discovery
- **PrometheusRule**: Alerting rules for Prometheus
- **DaemonSet**: Runs one pod per node (Promtail)

## Production Considerations

⚠️ **Important**: This is a demo/learning setup. For production:

- Use PersistentVolumes instead of emptyDir
- Configure proper authentication and TLS
- Adjust resource limits based on workload
- Set up proper backup and retention policies
- Configure real notification channels for alerts
- Use object storage for long-term data retention
- Implement proper security policies and network policies


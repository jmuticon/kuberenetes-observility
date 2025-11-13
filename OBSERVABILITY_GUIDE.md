# Kubernetes Observability Stack - Complete Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Kubernetes Fundamentals](#kubernetes-fundamentals)
3. [Observability Stack Components](#observability-stack-components)
4. [Application Components](#application-components)
5. [Data Flow Architecture](#data-flow-architecture)
6. [Interview Preparation](#interview-preparation)
7. [Hands-On Learning Points](#hands-on-learning-points)

---

## Project Overview

This project demonstrates a complete **observability stack** deployed on Kubernetes (Minikube) with a sample application. It implements the **three pillars of observability**:

- **Metrics**: Quantitative measurements (CPU, memory, request rates, latencies)
- **Logs**: Textual records of events and errors
- **Traces**: Distributed request flows across services

### Why Observability Matters

In microservices and distributed systems, you need visibility into:
- **What's happening**: Current system state
- **Why it's happening**: Root cause analysis
- **What will happen**: Predictive insights

---

## Kubernetes Fundamentals

### Core Concepts Used in This Project

#### 1. **Namespaces**
- **Purpose**: Logical separation of resources
- **In Project**: 
  - `observability`: All monitoring/observability tools
  - `app`: Application components (frontend, backend, database)
- **Why**: Isolation, organization, RBAC boundaries

#### 2. **Deployments**
- **Purpose**: Declarative management of pod replicas
- **How it works**: Kubernetes ensures desired number of pods are running
- **Example**: Backend deployment ensures 1 replica of Node.js app is always running

#### 3. **Services**
- **Purpose**: Stable network endpoint for pods
- **Types used**:
  - **ClusterIP**: Internal service discovery (default)
  - **NodePort/Ingress**: External access
- **Why needed**: Pods have ephemeral IPs; services provide stable DNS names

#### 4. **ConfigMaps**
- **Purpose**: Store configuration data as key-value pairs
- **Examples in project**:
  - Loki configuration
  - Tempo configuration
  - OTel Collector pipelines
- **Benefit**: Decouple config from container images

#### 5. **DaemonSets**
- **Purpose**: Run one pod per node
- **Used for**: Promtail (log shipper)
- **Why**: Need to collect logs from every node

#### 6. **ServiceMonitor (CRD)**
- **Purpose**: Prometheus Operator Custom Resource
- **Function**: Tells Prometheus which services to scrape
- **In project**: Monitors backend `/metrics` endpoint

#### 7. **Ingress**
- **Purpose**: HTTP/HTTPS routing from outside cluster
- **In project**: Routes traffic to Grafana, frontend, and backend API
- **Requires**: Ingress controller (NGINX in Minikube)

---

## Observability Stack Components

### 1. Prometheus

#### What It Is
Time-series database for metrics collection and alerting.

#### Purpose
- **Scrapes** metrics from targets at regular intervals
- **Stores** metrics in time-series format
- **Queries** metrics using PromQL
- **Evaluates** alert rules and sends alerts to Alertmanager

#### How It Works in This Cluster

**Deployment Method**: Via Helm chart `kube-prometheus-stack`

**Configuration** (`prometheus-stack-values.yaml`):
- Retention: 1 day (optimized for low-resource environments)
- Memory limits: 1.5GB max
- ServiceMonitor discovery: Enabled for automatic target discovery

**Scraping Targets**:
1. **Kubernetes components**: Nodes, pods, services (auto-discovered)
2. **Backend application**: Via ServiceMonitor pointing to `backend-service:3000/metrics`
3. **MySQL exporter**: Via ServiceMonitor pointing to `mysql-exporter:9104/metrics`

**Key Features**:
- **Pull model**: Prometheus scrapes targets (not push)
- **Service discovery**: Automatically finds targets via ServiceMonitors
- **PromQL**: Powerful query language for metrics analysis

**Interview Answer**:
> "Prometheus is our metrics collection engine. It uses a pull-based model where it scrapes metrics endpoints at regular intervals. In this cluster, it discovers targets via ServiceMonitor CRDs, collects metrics from our Node.js backend and MySQL exporter, and stores them in a time-series database. We can query these metrics using PromQL and set up alerting rules."

---

### 2. Grafana

#### What It Is
Visualization and analytics platform for metrics, logs, and traces.

#### Purpose
- **Visualize** metrics in dashboards
- **Query** Prometheus, Loki, and Tempo
- **Create** alerts and notifications
- **Correlate** metrics, logs, and traces

#### How It Works in This Cluster

**Deployment**: Part of `kube-prometheus-stack` Helm chart

**Configuration**:
- Admin credentials: `admin/admin`
- Sidecar for dashboards: Auto-loads dashboards from ConfigMaps
- Datasources: Configured via `grafana-datasources.yaml`

**Data Sources Configured**:
1. **Prometheus**: For metrics visualization
2. **Loki**: For log queries
3. **Tempo**: For trace visualization

**Dashboards**:
- `grafana-dashboard-nodejs.json`: Backend application metrics
- `grafana-dashboard-mysql.json`: MySQL database metrics

**Access**:
- Via Ingress: `http://grafana.local`
- Port-forward: `kubectl port-forward svc/observability-grafana 3000:80`

**Interview Answer**:
> "Grafana provides the visualization layer for our observability stack. It connects to Prometheus for metrics, Loki for logs, and Tempo for traces. We've configured pre-built dashboards for our Node.js backend and MySQL database. Grafana allows us to create unified views that correlate metrics, logs, and traces, making troubleshooting much easier."

---

### 3. Loki

#### What It Is
Horizontally scalable log aggregation system (like Prometheus, but for logs).

#### Purpose
- **Collects** logs from various sources
- **Indexes** logs by labels (not full-text)
- **Stores** logs efficiently (compressed chunks)
- **Queries** logs using LogQL (similar to PromQL)

#### How It Works in This Cluster

**Deployment**: Standalone Deployment with Service

**Architecture**:
- **Ingester**: Receives and stores log streams
- **Storage**: Uses filesystem (emptyDir for demo, production would use S3/GCS)
- **Index**: BoltDB for label indexing

**Configuration** (`loki.yaml`):
- Schema: v11 with filesystem storage
- Retention: 168 hours (7 days) for index
- No authentication (local dev setup)

**Log Sources**:
1. **Promtail**: Ships logs from Kubernetes pods
2. **OTel Collector**: Can forward logs via OTLP

**Query Interface**: 
- Via Grafana (LogQL queries)
- Direct API: `http://loki:3100/ready`

**Interview Answer**:
> "Loki is our log aggregation system. Unlike traditional log systems that index full text, Loki only indexes labels, making it much more efficient. Promtail runs as a DaemonSet on each node, collects logs from pods, and ships them to Loki. We can query logs in Grafana using LogQL, which is similar to PromQL. Loki stores logs in compressed chunks, making it cost-effective for high-volume log ingestion."

---

### 4. Promtail

#### What It Is
Log shipper agent that collects logs and sends them to Loki.

#### Purpose
- **Discovers** log sources (pods, containers)
- **Extracts** labels from Kubernetes metadata
- **Ships** logs to Loki
- **Tracks** read positions (prevents duplicate shipping)

#### How It Works in This Cluster

**Deployment**: DaemonSet (one pod per node)

**Configuration** (`promtail.yaml`):
- **Kubernetes service discovery**: Automatically finds pods
- **Label extraction**: Pulls labels from pod metadata (`app`, `namespace`, etc.)
- **Target**: Ships to `loki.observability.svc:3100`

**RBAC Required**:
- ServiceAccount with ClusterRole
- Permissions: `get`, `list`, `watch` on pods, nodes, services

**How It Discovers Logs**:
1. Watches Kubernetes API for pod changes
2. Reads logs from `/var/log` and `/var/lib/docker/containers`
3. Adds Kubernetes labels as Loki labels
4. Ships to Loki via HTTP push

**Interview Answer**:
> "Promtail is deployed as a DaemonSet, meaning one instance runs on each Kubernetes node. It uses Kubernetes service discovery to automatically find all pods and their logs. Promtail extracts metadata like pod labels and namespace, adds them as labels to the log streams, and ships everything to Loki. This gives us rich context in our logs - we can filter by application, namespace, or any Kubernetes label."

---

### 5. Tempo

#### What It Is
High-scale, minimal-dependency distributed tracing backend.

#### Purpose
- **Receives** traces via OTLP (OpenTelemetry Protocol)
- **Stores** traces efficiently (object storage backend)
- **Serves** traces for querying
- **Integrates** with Grafana for trace visualization

#### How It Works in This Cluster

**Deployment**: Standalone Deployment with Service

**Configuration** (`tempo.yaml`):
- **Receivers**: OTLP (gRPC on 4317, HTTP on 4318)
- **Storage**: Local filesystem (emptyDir for demo)
- **Retention**: 1 hour (production would use S3/GCS)
- **Block duration**: 5 minutes

**Trace Flow**:
1. Application instruments with OpenTelemetry
2. Sends traces to OTel Collector via OTLP
3. OTel Collector forwards to Tempo
4. Tempo stores traces in blocks
5. Grafana queries Tempo for visualization

**Ports**:
- `3200`: HTTP API (query interface)
- `4317`: OTLP gRPC
- `4318`: OTLP HTTP

**Interview Answer**:
> "Tempo is our distributed tracing backend. It receives traces via the OpenTelemetry Protocol (OTLP) from our applications. In this setup, our Node.js backend is instrumented with OpenTelemetry SDK, which sends traces to the OTel Collector, which then forwards them to Tempo. Tempo stores traces efficiently and integrates with Grafana, allowing us to visualize request flows across services and identify performance bottlenecks."

---

### 6. OpenTelemetry Collector

#### What It Is
Vendor-neutral telemetry data pipeline.

#### Purpose
- **Receives** telemetry data (metrics, logs, traces) via multiple protocols
- **Processes** data (filtering, batching, transformation)
- **Exports** to multiple backends (Prometheus, Loki, Tempo)
- **Unified** collection point for all telemetry

#### How It Works in This Cluster

**Deployment**: Deployment with Service

**Configuration** (`otel-collector.yaml`):

**Receivers**:
- **OTLP**: Receives traces/logs from applications (gRPC/HTTP)
- **Prometheus**: Scrapes metrics from backend and MySQL exporter

**Processors**:
- **Batch**: Groups telemetry data for efficient export

**Exporters**:
- **prometheusremotewrite**: Sends metrics to Prometheus
- **loki**: Sends logs to Loki
- **otlp/tempo**: Sends traces to Tempo

**Pipelines**:
1. **Traces**: OTLP → Batch → Tempo
2. **Metrics**: Prometheus/OTLP → Batch → Prometheus
3. **Logs**: OTLP → Batch → Loki

**Interview Answer**:
> "The OpenTelemetry Collector acts as a unified telemetry gateway. It receives metrics, logs, and traces from our applications via OTLP, and also scrapes Prometheus metrics. It then processes and routes this data to the appropriate backends - metrics to Prometheus, logs to Loki, and traces to Tempo. This decouples our applications from specific observability backends and provides a single point for data collection and processing."

---

### 7. Alertmanager

#### What It Is
Handles alerts from Prometheus (routing, grouping, silencing).

#### Purpose
- **Receives** alerts from Prometheus
- **Groups** related alerts
- **Routes** to notification channels (Slack, email, PagerDuty)
- **Silences** alerts during maintenance
- **Deduplicates** similar alerts

#### How It Works in This Cluster

**Deployment**: Part of `kube-prometheus-stack`

**Configuration** (`alertmanager-config.yaml`):
- **Routes**: Define where alerts go
- **Receivers**: Configure notification channels
- **Grouping**: Group alerts by severity/application

**Alert Rules** (`prometheus-rules.yaml`):
1. **BackendHighLatency**: Triggers if 95th percentile latency > 1s for 2 minutes
2. **MySQLDown**: Triggers if MySQL exporter is down for 1 minute

**Flow**:
1. Prometheus evaluates alert rules
2. When condition met, sends alert to Alertmanager
3. Alertmanager groups/routes based on configuration
4. Sends notifications to configured channels

**Interview Answer**:
> "Alertmanager handles alert routing and notification. Prometheus evaluates alert rules we've defined - like high latency or MySQL being down - and when conditions are met, it sends alerts to Alertmanager. Alertmanager then groups related alerts, deduplicates them, and routes them to notification channels like Slack or email. This prevents alert fatigue and ensures the right people get notified about the right issues."

---

## Application Components

### 1. Backend (Node.js Express)

#### What It Is
Sample Node.js application with observability instrumentation.

#### Purpose
- Demonstrates application-level observability
- Exposes Prometheus metrics
- Sends distributed traces
- Connects to MySQL database

#### Observability Features

**Metrics** (`/metrics` endpoint):
- Uses `prom-client` library
- Exposes custom metrics:
  - `http_request_duration_seconds`: Histogram of request latencies
  - Standard Node.js metrics (via prom-client)

**Traces**:
- OpenTelemetry SDK instrumentation
- Auto-instrumentation for Express, HTTP, MySQL
- Sends traces to OTel Collector via OTLP
- Environment variable: `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.observability:4318`

**How Metrics Are Collected**:
1. Application exposes `/metrics` endpoint
2. Prometheus scrapes via ServiceMonitor
3. Metrics appear in Grafana dashboards

**How Traces Are Collected**:
1. OpenTelemetry SDK auto-instruments Express/MySQL
2. Traces sent to OTel Collector via OTLP HTTP
3. OTel Collector forwards to Tempo
4. Traces queryable in Grafana

**Interview Answer**:
> "Our Node.js backend is fully instrumented for observability. It exposes Prometheus metrics on a `/metrics` endpoint, which Prometheus scrapes every 15 seconds via a ServiceMonitor. For tracing, we use the OpenTelemetry SDK with auto-instrumentation, which automatically traces Express routes and MySQL queries. Traces are sent to the OTel Collector, which forwards them to Tempo. This gives us complete visibility into request flows and database interactions."

---

### 2. MySQL Database

#### What It Is
Relational database for the application.

#### Purpose
- Stores application data
- Demonstrates database observability
- Exposes metrics via exporter

#### Observability

**Metrics Collection**:
- **mysqld-exporter**: Sidecar container that exposes MySQL metrics
- Exposes metrics on port `9104`
- Metrics include: connections, queries, replication status, performance metrics

**How It Works**:
1. MySQL runs in a pod
2. mysqld-exporter connects to MySQL and queries system tables
3. Exposes Prometheus metrics on `/metrics` endpoint
4. Prometheus scrapes via ServiceMonitor
5. Metrics visualized in Grafana MySQL dashboard

**Key Metrics Exposed**:
- `mysql_up`: Whether MySQL is accessible
- `mysql_global_status_*`: Various MySQL status variables
- `mysql_global_variables_*`: MySQL configuration variables

**Interview Answer**:
> "We run MySQL in Kubernetes with a mysqld-exporter sidecar. The exporter connects to MySQL, queries system tables and status variables, and exposes them as Prometheus metrics. Prometheus scrapes these metrics, and we have a Grafana dashboard that visualizes MySQL performance, connections, query rates, and replication status. This helps us monitor database health and performance."

---

### 3. Frontend (Nginx)

#### What It Is
Simple web server serving static HTML.

#### Purpose
- Demonstrates frontend observability
- Entry point for user requests
- Can be instrumented for client-side metrics

#### Observability

**Logs**: Collected by Promtail from pod logs
**Metrics**: Nginx metrics can be exposed via nginx-prometheus-exporter
**Traces**: Can be instrumented with OpenTelemetry for frontend tracing

---

## Data Flow Architecture

### Metrics Flow

```
Application (Backend/MySQL Exporter)
    ↓ (exposes /metrics endpoint)
Prometheus (scrapes via ServiceMonitor)
    ↓ (stores time-series data)
Grafana (queries via PromQL)
    ↓ (visualizes in dashboards)
```

**Alternative Path**:
```
Application
    ↓ (OTLP metrics)
OTel Collector
    ↓ (prometheusremotewrite)
Prometheus
    ↓
Grafana
```

### Logs Flow

```
Application Pods
    ↓ (stdout/stderr logs)
Promtail (DaemonSet on each node)
    ↓ (ships with Kubernetes labels)
Loki
    ↓ (stores logs)
Grafana (queries via LogQL)
```

**Alternative Path**:
```
Application
    ↓ (OTLP logs)
OTel Collector
    ↓ (loki exporter)
Loki
    ↓
Grafana
```

### Traces Flow

```
Node.js Backend (OpenTelemetry SDK)
    ↓ (OTLP HTTP to port 4318)
OTel Collector
    ↓ (OTLP to Tempo)
Tempo
    ↓ (stores traces)
Grafana (queries traces)
```

### Alert Flow

```
Prometheus (evaluates alert rules)
    ↓ (sends alerts)
Alertmanager
    ↓ (routes/groups)
Notification Channels (Slack/Email)
```

---

## Interview Preparation

### Common Questions and Answers

#### Q1: Explain the three pillars of observability and how this project implements them.

**Answer**:
> "The three pillars are Metrics, Logs, and Traces. 
> 
> **Metrics**: We use Prometheus to collect quantitative measurements like request rates, latencies, and resource usage. Our Node.js backend exposes custom metrics via the `/metrics` endpoint, and Prometheus scrapes them.
> 
> **Logs**: We use Loki for log aggregation. Promtail runs as a DaemonSet, collects logs from all pods, and ships them to Loki with Kubernetes labels for easy filtering.
> 
> **Traces**: We use Tempo for distributed tracing. Our backend is instrumented with OpenTelemetry, which sends traces to the OTel Collector, which forwards them to Tempo.
> 
> All three are unified in Grafana, allowing us to correlate metrics, logs, and traces for complete observability."

#### Q2: Why use OpenTelemetry Collector instead of sending directly to backends?

**Answer**:
> "The OTel Collector provides several benefits:
> 1. **Decoupling**: Applications don't need to know about specific backends
> 2. **Processing**: Can filter, transform, and batch data before export
> 3. **Multi-export**: Can send the same data to multiple backends
> 4. **Protocol translation**: Receives OTLP but can export to various formats
> 5. **Centralized configuration**: Change backends without redeploying applications"

#### Q3: How does Prometheus discover targets to scrape?

**Answer**:
> "Prometheus uses service discovery. In Kubernetes, we use the Prometheus Operator which provides ServiceMonitor CRDs. We create a ServiceMonitor that:
> 1. Selects services by label (e.g., `app: backend`)
> 2. Specifies which namespace to look in
> 3. Defines the endpoint and scrape interval
> 
> Prometheus Operator watches for ServiceMonitors and automatically configures Prometheus to scrape those targets. This is declarative and doesn't require manual Prometheus configuration changes."

#### Q4: What's the difference between Prometheus and Grafana?

**Answer**:
> "Prometheus is the **data collection and storage** engine - it scrapes, stores, and queries metrics. Grafana is the **visualization and analytics** platform - it queries Prometheus (and other data sources) and displays the data in dashboards.
> 
> Think of Prometheus as the database and Grafana as the reporting tool. Prometheus has its own query language (PromQL) and UI, but Grafana provides much better visualization, alerting, and multi-datasource correlation."

#### Q5: Why use Loki instead of Elasticsearch for logs?

**Answer**:
> "Loki is designed to be simpler and more cost-effective:
> 1. **Label-based indexing**: Only indexes labels, not full text (smaller index)
> 2. **Prometheus-like**: Uses similar concepts (labels, LogQL similar to PromQL)
> 3. **Lower resource usage**: More efficient for high-volume log ingestion
> 4. **Object storage**: Designed for S3/GCS, making it cheaper at scale
> 5. **Grafana native**: Built by Grafana Labs, integrates seamlessly
> 
> Elasticsearch is more powerful for full-text search, but Loki is optimized for log aggregation and correlation with metrics."

#### Q6: How would you scale this setup for production?

**Answer**:
> "Several changes needed:
> 1. **Storage**: Use PersistentVolumes or object storage (S3/GCS) for Prometheus, Loki, Tempo
> 2. **High Availability**: Run multiple replicas of critical components
> 3. **Resource limits**: Increase based on actual load
> 4. **Retention**: Increase Prometheus retention, configure Loki/Tempo retention policies
> 5. **Security**: Enable TLS, use Secrets for credentials, RBAC
> 6. **Monitoring**: Monitor the monitoring stack itself
> 7. **Backup**: Regular backups of Prometheus data, alert rules, dashboards
> 8. **Image versions**: Pin to specific digests, not tags
> 9. **Network policies**: Restrict pod-to-pod communication
> 10. **Ingress**: Use TLS certificates, proper authentication"

---

## Hands-On Learning Points

### 1. Understanding Service Discovery

**Exercise**: 
- Check Prometheus targets: `kubectl port-forward -n observability svc/prometheus-operated 9090:9090`
- Visit `http://localhost:9090/targets`
- See how ServiceMonitors automatically create scrape targets

**Learning**: Understand how Kubernetes service discovery works and how Prometheus Operator simplifies configuration.

### 2. Exploring Metrics

**Exercise**:
- Access backend metrics: `curl http://api.local/metrics`
- Query in Prometheus: `http_request_duration_seconds_bucket`
- Create a Grafana panel with a custom PromQL query

**Learning**: Understand metric types (counter, gauge, histogram), labels, and PromQL.

### 3. Log Correlation

**Exercise**:
- Generate an error in the backend
- Find the error in Loki via Grafana
- Use trace ID to find the corresponding trace in Tempo
- Correlate with metrics to understand the full picture

**Learning**: Understand how to use labels, LogQL, and trace correlation for debugging.

### 4. Alert Testing

**Exercise**:
- Stop the MySQL pod: `kubectl delete pod -n app -l app=mysql`
- Watch Alertmanager: `kubectl port-forward -n observability svc/observability-alertmanager 9093:9093`
- See the alert fire and route

**Learning**: Understand alert rules, evaluation, and routing.

### 5. Trace Analysis

**Exercise**:
- Make a request to the backend API
- Find the trace in Grafana Tempo data source
- See the full request flow including database query
- Identify bottlenecks

**Learning**: Understand distributed tracing, spans, and trace visualization.

### 6. Resource Optimization

**Exercise**:
- Monitor resource usage: `kubectl top pods -A`
- Adjust resource limits in deployments
- Understand the trade-offs between resource allocation and performance

**Learning**: Understand Kubernetes resource management and observability stack resource requirements.

### 7. Custom Instrumentation

**Exercise**:
- Add a custom metric to the backend
- Add custom spans to the trace
- Create a new Grafana dashboard

**Learning**: Understand how to instrument applications and create custom observability.

---

## Key Takeaways

1. **Observability is Multi-Layered**: Metrics, logs, and traces each provide different insights
2. **Correlation is Key**: The real power comes from correlating all three pillars
3. **Kubernetes Native**: Using CRDs (ServiceMonitor, PrometheusRule) makes configuration declarative
4. **Open Standards**: OpenTelemetry provides vendor-neutral instrumentation
5. **Scalability**: Each component can scale independently based on needs
6. **Cost Optimization**: Loki's label-only indexing and Tempo's efficient storage reduce costs
7. **Developer Experience**: Auto-instrumentation reduces the burden on developers

---

## Additional Resources

- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **Loki**: https://grafana.com/docs/loki/
- **Tempo**: https://grafana.com/docs/tempo/
- **OpenTelemetry**: https://opentelemetry.io/docs/
- **Kubernetes**: https://kubernetes.io/docs/

---

## Project-Specific Commands Reference

```bash
# Deploy everything
./deploy.sh

# Check all pods
kubectl get pods -A

# Access Grafana
kubectl port-forward -n observability svc/observability-grafana 3000:80

# Access Prometheus
kubectl port-forward -n observability svc/prometheus-operated 9090:9090

# Check backend metrics
curl http://api.local/metrics

# View logs
kubectl logs -n app -l app=backend

# Cleanup
./cleanup.sh
```

---

This guide provides a comprehensive understanding of the observability stack, suitable for both interview preparation and hands-on learning. Each component is explained with its purpose, how it works in the cluster, and practical interview-style answers.


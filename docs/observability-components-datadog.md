# Observability Components: Complete Guide with Datadog Implementation

This document explains each layer of the observability stack, covering what it is, why it's needed, how it works, and how to achieve it with Datadog.

## Table of Contents

1. [Metrics](#1-metrics)
2. [Logs](#2-logs)
3. [Traces](#3-traces)
4. [Aggregator](#4-aggregator)
5. [Visualization](#5-visualization)
6. [Alerts](#6-alerts)

---

## 1. Metrics

### What It Is

Metrics are quantitative measurements that track system performance over time. They represent numerical data points collected at regular intervals, such as CPU usage, memory consumption, request rates, error rates, and response times.

**Example Tools**: Prometheus, Datadog Agent, StatsD, InfluxDB

### Why It Is Needed

Metrics provide essential insights into system health and performance:

- **Performance Monitoring**: Track response times, throughput, and resource utilization
- **Capacity Planning**: Understand resource consumption trends to plan scaling
- **SLA Compliance**: Monitor service-level objectives (SLOs) and agreements (SLAs)
- **Anomaly Detection**: Identify unusual patterns that may indicate issues
- **Historical Analysis**: Compare current performance with historical baselines
- **Cost Optimization**: Track resource usage to optimize cloud costs

Without metrics, you operate blind to system performance and cannot make data-driven decisions about scaling, optimization, or troubleshooting.

### How It Works

#### Prometheus Model (Pull-Based)

1. **Metric Exposition**: Applications expose metrics at HTTP endpoints (typically `/metrics`)
2. **Service Discovery**: Prometheus discovers targets via Kubernetes ServiceMonitors, static configs, or service discovery mechanisms
3. **Scraping**: Prometheus periodically scrapes (pulls) metrics from targets at configured intervals (e.g., every 15 seconds)
4. **Storage**: Metrics are stored as time-series data with labels (key-value pairs) for filtering and aggregation
5. **Querying**: PromQL (Prometheus Query Language) allows querying and aggregating metrics
6. **Alerting**: Alert rules evaluate metric conditions and trigger alerts when thresholds are exceeded

**Key Concepts**:
- **Metric Types**: Counter (monotonically increasing), Gauge (can go up/down), Histogram (bucketed observations), Summary (quantiles)
- **Labels**: Key-value pairs that allow filtering and grouping (e.g., `app=backend`, `namespace=production`)
- **Time Series**: A unique combination of metric name and label set

#### Example Flow

```
Application (exposes /metrics)
    ↓
Prometheus ServiceMonitor (discovers target)
    ↓
Prometheus (scrapes every 15s)
    ↓
Time-Series Database (stores with labels)
    ↓
Grafana (queries via PromQL)
```

### How to Achieve It with Datadog

Datadog provides a comprehensive metrics solution that replaces Prometheus with additional features.

#### Architecture Overview

Datadog uses a **push-based model** where agents collect and forward metrics to Datadog's cloud platform:

```
Application/Infrastructure
    ↓
Datadog Agent (collects metrics)
    ↓
Datadog Platform (cloud-based storage & processing)
    ↓
Datadog UI (visualization & analysis)
```

#### Step-by-Step Implementation

**1. Install Datadog Agent**

For Kubernetes, deploy the Datadog Agent as a DaemonSet:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: datadog
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
  namespace: datadog
spec:
  selector:
    matchLabels:
      app: datadog-agent
  template:
    metadata:
      labels:
        app: datadog-agent
    spec:
      serviceAccountName: datadog-agent
      containers:
      - name: agent
        image: gcr.io/datadoghq/agent:7
        env:
        - name: DD_API_KEY
          valueFrom:
            secretKeyRef:
              name: datadog-secret
              key: api-key
        - name: DD_SITE
          value: "datadoghq.com"
        - name: DD_KUBERNETES_COLLECT_METRICS
          value: "true"
        - name: DD_KUBERNETES_COLLECT_EVENTS
          value: "true"
        - name: DD_COLLECT_KUBERNETES_EVENTS
          value: "true"
        - name: DD_LEADER_ELECTION
          value: "true"
        - name: KUBERNETES
          value: "true"
        - name: DD_APM_ENABLED
          value: "true"
        - name: DD_LOGS_ENABLED
          value: "true"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        volumeMounts:
        - name: dockersocket
          mountPath: /var/run/docker.sock
        - name: procdir
          mountPath: /host/proc
          readOnly: true
        - name: cgroups
          mountPath: /host/sys/fs/cgroup
          readOnly: true
      volumes:
      - name: dockersocket
        hostPath:
          path: /var/run/docker.sock
      - name: procdir
        hostPath:
          path: /proc
      - name: cgroups
        hostPath:
          path: /sys/fs/cgroup
```

**2. Create API Key Secret**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: datadog-secret
  namespace: datadog
type: Opaque
stringData:
  api-key: <YOUR_DATADOG_API_KEY>
```

**3. Configure Service Account and RBAC**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: datadog-agent
  namespace: datadog
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: datadog-agent
rules:
- apiGroups: [""]
  resources:
  - services
  - events
  - endpoints
  - pods
  - nodes
  - componentstatuses
  verbs: ["get", "list", "watch"]
- apiGroups: ["quota.openshift.io"]
  resources:
  - clusterresourcequotas
  verbs: ["get", "list"]
- apiGroups: ["autoscaling"]
  resources:
  - horizontalpodautoscalers
  verbs: ["list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: datadog-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: datadog-agent
subjects:
- kind: ServiceAccount
  name: datadog-agent
  namespace: datadog
```

**4. Application Instrumentation**

For Node.js applications, use the Datadog APM library:

```javascript
const tracer = require('dd-trace').init({
  service: 'backend',
  env: 'production',
  version: '1.0.0',
  logInjection: true
});

const express = require('express');
const app = express();

app.get('/api/users', (req, res) => {
  // Metrics automatically collected
  res.json({ users: [] });
});
```

**5. Custom Metrics**

Send custom metrics from your application:

```javascript
const StatsD = require('node-statsd');
const client = new StatsD({
  host: 'datadog-agent.datadog.svc.cluster.local',
  port: 8125
});

app.post('/api/orders', (req, res) => {
  // Increment counter
  client.increment('orders.created');
  
  // Record timing
  const start = Date.now();
  processOrder(req.body);
  client.timing('orders.processing_time', Date.now() - start);
  
  res.json({ success: true });
});
```

**6. Kubernetes Metrics Collection**

The Datadog Agent automatically collects:
- **Node metrics**: CPU, memory, disk, network
- **Pod metrics**: Resource usage per pod
- **Container metrics**: Per-container resource consumption
- **Kubernetes events**: Pod creation, deletion, errors
- **Service metrics**: Service discovery and health

**7. Metric Types in Datadog**

- **Count**: Incremental counter (e.g., `orders.created`)
- **Gauge**: Value that can increase or decrease (e.g., `queue.size`)
- **Rate**: Count per second
- **Histogram**: Distribution of values (e.g., `request.duration`)
- **Distribution**: High-cardinality histogram

**8. Querying Metrics**

Use Datadog's query language (similar to PromQL):

```
avg:system.cpu.user{env:production} by {host}
sum:http.requests{service:backend} by {status_code}
avg:request.duration{service:backend}.rollup(avg, 60)
```

**9. Advantages Over Prometheus**

- **No Infrastructure Management**: Cloud-based, no need to manage storage or scaling
- **Longer Retention**: Default 15 months retention vs. Prometheus's typical 15-30 days
- **Out-of-the-Box Dashboards**: Pre-built dashboards for common technologies
- **Correlation**: Automatic correlation between metrics, logs, and traces
- **Anomaly Detection**: Machine learning-based anomaly detection
- **Forecasting**: Predictive analytics for capacity planning
- **Multi-Cloud**: Unified view across AWS, Azure, GCP, and on-premises

**10. Cost Considerations**

- **Free Tier**: Up to 200 custom metrics per host
- **Pro Plan**: $15/host/month (includes 400 custom metrics)
- **Enterprise Plan**: $23/host/month (includes unlimited custom metrics)
- **Custom Metrics**: Additional cost per metric beyond included limits

---

## 2. Logs

### What It Is

Logs are textual records of events that occur in applications and systems. They capture what happened, when it happened, and provide context for debugging and auditing.

**Example Tools**: Loki + Promtail, ELK Stack (Elasticsearch, Logstash, Kibana), Datadog Logs, Splunk

### Why It Is Needed

Logs are essential for:

- **Debugging**: Identify root causes of errors and failures
- **Auditing**: Track user actions and system changes for compliance
- **Security**: Detect suspicious activities and security breaches
- **Troubleshooting**: Understand system behavior during incidents
- **Performance Analysis**: Identify slow operations and bottlenecks
- **Business Intelligence**: Extract insights from application events

Without logs, diagnosing issues becomes nearly impossible, especially in distributed systems where problems can span multiple services.

### How It Works

#### Loki + Promtail Model

**Loki Architecture**:
1. **Log Ingestion**: Receives log streams from agents (Promtail, Fluentd, etc.)
2. **Label Indexing**: Indexes logs by labels (not full-text), making it efficient
3. **Storage**: Stores log data in compressed chunks (similar to Prometheus)
4. **Querying**: Uses LogQL (Log Query Language) similar to PromQL

**Promtail Architecture**:
1. **Discovery**: Discovers log sources (Kubernetes pods, files, systemd journals)
2. **Label Extraction**: Extracts labels from Kubernetes metadata (pod name, namespace, labels)
3. **Log Shipping**: Ships logs to Loki via HTTP push
4. **Position Tracking**: Tracks read positions to prevent duplicate shipping

**Key Concepts**:
- **Log Stream**: A unique combination of labels
- **Labels**: Key-value pairs for filtering (e.g., `app=backend`, `level=error`)
- **Chunks**: Compressed log data stored in object storage
- **Index**: Small index of labels for fast querying

#### Example Flow

```
Application Pods (write to stdout/stderr)
    ↓
Promtail DaemonSet (collects from /var/log/pods)
    ↓
Label Extraction (adds Kubernetes metadata)
    ↓
Loki (receives log streams)
    ↓
Storage (compressed chunks)
    ↓
Grafana (queries via LogQL)
```

### How to Achieve It with Datadog

Datadog provides a comprehensive log management solution that replaces Loki + Promtail.

#### Architecture Overview

```
Application/Infrastructure (logs)
    ↓
Datadog Agent (collects logs)
    ↓
Datadog Platform (processing, indexing, storage)
    ↓
Datadog UI (search, analysis, correlation)
```

#### Step-by-Step Implementation

**1. Enable Log Collection in Datadog Agent**

Update the DaemonSet configuration:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
  namespace: datadog
spec:
  template:
    spec:
      containers:
      - name: agent
        image: gcr.io/datadoghq/agent:7
        env:
        - name: DD_LOGS_ENABLED
          value: "true"
        - name: DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL
          value: "true"
        - name: DD_LOGS_CONFIG_K8S_CONTAINER_USE_FILE
          value: "true"
        - name: DD_CONTAINER_EXCLUDE
          value: "name:datadog-agent"
        volumeMounts:
        - name: pointerdir
          mountPath: /opt/datadog-agent/run
        - name: logpath
          mountPath: /var/log/pods
          readOnly: true
        - name: containerpath
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: pointerdir
        hostPath:
          path: /opt/datadog-agent/run
      - name: logpath
        hostPath:
          path: /var/log/pods
      - name: containerpath
        hostPath:
          path: /var/lib/docker/containers
```

**2. Automatic Log Collection**

The Datadog Agent automatically:
- Discovers all pods in the cluster
- Collects logs from stdout/stderr
- Extracts Kubernetes metadata (pod name, namespace, labels, annotations)
- Adds structured tags for filtering

**3. Application Log Configuration**

For Node.js applications, configure structured logging:

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'backend' },
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

logger.info('User logged in', {
  userId: '123',
  ip: '192.168.1.1',
  timestamp: new Date().toISOString()
});
```

**4. Custom Log Processing**

Configure log processing pipelines in Datadog:

```yaml
# In Datadog Agent ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-config
  namespace: datadog
data:
  datadog.yaml: |
    logs_config:
      processing_rules:
        - type: multi_line
          name: stack_traces
          pattern: \d{4}-\d{2}-\d{2}
        - type: exclude_at_match
          name: exclude_health_checks
          pattern: /health
```

**5. Log Parsing and Enrichment**

Use Datadog's log parsing:

- **Automatic Parsing**: JSON logs automatically parsed
- **Grok Parsing**: Custom patterns for structured extraction
- **Date Parsing**: Automatic timestamp extraction
- **Attribute Extraction**: Extract key-value pairs from logs

Example Grok pattern:

```
%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{DATA:message}
```

**6. Log Filtering and Sampling**

Control log volume:

```yaml
logs_config:
  container_collect_all: true
  container_exclude:
    - "name:datadog-agent"
    - "name:kube-system"
  container_include:
    - "name:backend"
    - "name:frontend"
  processing_rules:
    - type: exclude_at_match
      name: exclude_debug
      pattern: "level=debug"
```

**7. Log Correlation with Traces**

Enable trace correlation in application:

```javascript
const tracer = require('dd-trace').init({
  logInjection: true  // Injects trace_id and span_id into logs
});

// Logs automatically include trace context
logger.error('Database query failed', {
  error: err.message,
  // trace_id and span_id automatically added
});
```

**8. Log Search and Querying**

Datadog Log Explorer supports:

- **Full-Text Search**: Search across all log content
- **Faceted Search**: Filter by tags, services, environments
- **Time Range Queries**: Search within specific time windows
- **Saved Views**: Create reusable search queries
- **Log Analytics**: Aggregate and analyze log data

Example queries:

```
service:backend status:error
service:backend @message:*timeout*
service:backend @http.status_code:[400 TO 599]
service:backend @timestamp:[now-1h TO now]
```

**9. Log Retention and Archiving**

- **Live Tail**: Real-time log streaming
- **Retention**: Configurable retention (7 days to 30 days on Pro, longer on Enterprise)
- **Archiving**: Archive to S3, Azure Blob, or GCS for long-term storage
- **Rehydration**: Restore archived logs for analysis

**10. Advantages Over Loki + Promtail**

- **Full-Text Search**: Indexes full log content, not just labels
- **Automatic Parsing**: Intelligent parsing of common log formats
- **Correlation**: Automatic correlation with metrics and traces
- **Live Tail**: Real-time log streaming
- **Log Analytics**: Advanced analytics and aggregation
- **No Infrastructure**: Cloud-based, no storage management
- **Better UI**: More intuitive search and visualization
- **Alerting**: Built-in alerting on log patterns

**11. Cost Considerations**

- **Ingestion-Based Pricing**: Pay per GB ingested
- **Indexing**: Additional cost for indexed logs (faster search)
- **Archiving**: Separate cost for long-term storage
- **Retention**: Longer retention increases costs

---

## 3. Traces

### What It Is

Distributed tracing tracks requests as they flow through multiple services in a microservices architecture. Each trace represents a complete request journey, showing how different services interact and where time is spent.

**Example Tools**: Tempo, Jaeger, Zipkin, Datadog APM, New Relic

### Why It Is Needed

Distributed tracing is essential for:

- **Performance Debugging**: Identify slow services and bottlenecks
- **Request Flow Visualization**: Understand how requests traverse services
- **Dependency Mapping**: Discover service dependencies automatically
- **Error Propagation**: Track errors across service boundaries
- **Latency Analysis**: Measure time spent in each service
- **Service Mesh Observability**: Monitor service-to-service communication

Without tracing, understanding request flows in microservices is nearly impossible, especially when issues span multiple services.

### How It Works

#### Tempo Model

**Tempo Architecture**:
1. **Trace Ingestion**: Receives traces via OTLP (OpenTelemetry Protocol), Jaeger, Zipkin
2. **Trace Storage**: Stores traces efficiently in object storage (S3, GCS, Azure Blob)
3. **Trace Querying**: Queries traces by trace ID, service name, or tags
4. **Integration**: Integrates with Grafana for visualization

**Key Concepts**:
- **Trace**: Complete request journey across services
- **Span**: Individual operation within a trace (e.g., database query, HTTP call)
- **Span Context**: Propagates trace ID and span ID across service boundaries
- **Parent-Child Relationships**: Spans form a tree structure showing call hierarchy

#### Example Flow

```
Frontend (initiates request)
    ↓ (creates trace, sends trace ID in headers)
Backend Service A
    ↓ (creates child span, propagates trace ID)
Backend Service B
    ↓ (creates child span)
Database Query
    ↓
OTel Collector (receives traces via OTLP)
    ↓
Tempo (stores traces)
    ↓
Grafana (queries and visualizes)
```

### How to Achieve It with Datadog

Datadog APM (Application Performance Monitoring) provides distributed tracing with automatic instrumentation.

#### Architecture Overview

```
Application (instrumented with Datadog APM)
    ↓
Datadog Agent (receives traces)
    ↓
Datadog Platform (processing, storage, analysis)
    ↓
Datadog UI (trace visualization, service map)
```

#### Step-by-Step Implementation

**1. Enable APM in Datadog Agent**

Update the DaemonSet:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
  namespace: datadog
spec:
  template:
    spec:
      containers:
      - name: agent
        image: gcr.io/datadoghq/agent:7
        env:
        - name: DD_APM_ENABLED
          value: "true"
        - name: DD_APM_NON_LOCAL_TRAFFIC
          value: "true"
        ports:
        - containerPort: 8126
          name: apm
          protocol: TCP
        - containerPort: 8125
          name: dogstatsd
          protocol: UDP
```

**2. Node.js Application Instrumentation**

Install and configure the Datadog tracer:

```bash
npm install dd-trace
```

```javascript
const tracer = require('dd-trace').init({
  service: 'backend',
  env: 'production',
  version: '1.0.0',
  logInjection: true,
  runtimeMetrics: true,
  profiling: true
});

const express = require('express');
const app = express();

app.get('/api/users', async (req, res) => {
  const span = tracer.startSpan('get_users');
  
  try {
    const users = await db.query('SELECT * FROM users');
    span.setTag('db.query', 'SELECT * FROM users');
    span.setTag('db.rows', users.length);
    res.json(users);
  } catch (error) {
    span.setTag('error', true);
    span.setTag('error.message', error.message);
    throw error;
  } finally {
    span.finish();
  }
});
```

**3. Automatic Instrumentation**

Datadog automatically instruments:

- **HTTP Frameworks**: Express, Fastify, Koa, Hapi
- **Databases**: MySQL, PostgreSQL, MongoDB, Redis
- **Message Queues**: RabbitMQ, Kafka
- **HTTP Clients**: axios, fetch, request
- **GraphQL**: Apollo Server, GraphQL.js

**4. Custom Spans**

Create custom spans for business logic:

```javascript
app.post('/api/orders', async (req, res) => {
  const span = tracer.startSpan('order.creation', {
    tags: {
      'order.amount': req.body.amount,
      'order.currency': req.body.currency
    }
  });
  
  try {
    await validateOrder(req.body);
    span.setTag('order.validated', true);
    
    const order = await createOrder(req.body);
    span.setTag('order.id', order.id);
    
    await sendConfirmationEmail(order);
    span.setTag('email.sent', true);
    
    res.json(order);
  } catch (error) {
    span.setTag('error', true);
    span.setTag('error.type', error.constructor.name);
    throw error;
  } finally {
    span.finish();
  }
});
```

**5. Trace Context Propagation**

Trace context automatically propagates via HTTP headers:

```javascript
const axios = require('axios');

app.get('/api/data', async (req, res) => {
  const span = tracer.startSpan('fetch_external_data');
  
  try {
    const response = await axios.get('https://api.external.com/data', {
      headers: {
        // Trace context automatically injected
      }
    });
    
    span.setTag('http.status_code', response.status);
    res.json(response.data);
  } finally {
    span.finish();
  }
});
```

**6. Service Map**

Datadog automatically generates service maps showing:
- Service dependencies
- Request flow between services
- Error rates and latency per service
- Database and external API calls

**7. Trace Search and Filtering**

Search traces by:
- Service name
- Resource name (endpoint, query)
- Error status
- Duration
- Tags (custom attributes)
- Trace ID

Example queries:

```
service:backend resource_name:/api/users
service:backend @http.status_code:500
service:backend @duration:>1s
service:backend @error:true
```

**8. Performance Analysis**

- **Flame Graphs**: Visualize where time is spent
- **Top Operations**: Identify slowest endpoints
- **Error Analysis**: See error rates per endpoint
- **Latency Distribution**: Understand P50, P95, P99 latencies
- **Throughput**: Requests per second per service

**9. Trace Sampling**

Control trace volume:

```javascript
const tracer = require('dd-trace').init({
  sampleRate: 1.0,  // 100% sampling
  // Or use priority sampling
  prioritySampling: true
});

// Or set sampling per request
app.get('/api/health', (req, res) => {
  const span = tracer.startSpan('health_check');
  span.setTag('_sampling_priority_v1', 0);  // Drop this trace
  span.finish();
  res.json({ status: 'ok' });
});
```

**10. Integration with Metrics and Logs**

- **Trace-to-Log Correlation**: Click from trace to related logs
- **Trace-to-Metric Correlation**: See metrics for the same time period
- **Unified View**: Single interface for traces, logs, and metrics

**11. Advantages Over Tempo**

- **Automatic Instrumentation**: No manual code changes needed for many frameworks
- **Service Map**: Automatic dependency discovery and visualization
- **Better UI**: More intuitive trace visualization
- **Performance Insights**: Automatic identification of bottlenecks
- **Error Tracking**: Integrated error tracking and analysis
- **No Infrastructure**: Cloud-based, no storage management
- **Longer Retention**: Default 15 days, configurable to 30 days
- **Sampling Control**: More flexible sampling strategies

**12. Cost Considerations**

- **APM Included**: APM included in Pro and Enterprise plans
- **Trace Volume**: Additional cost for high-volume trace ingestion
- **Retention**: Longer retention increases costs

---

## 4. Aggregator

### What It Is

An aggregator (or collector) is a centralized component that receives, processes, and routes telemetry data (metrics, logs, traces) from multiple sources to various backends. It acts as a unified collection point and processing pipeline.

**Example Tools**: OpenTelemetry Collector, Fluentd, Logstash, Datadog Agent

### Why It Is Needed

Aggregators provide:

- **Decoupling**: Applications don't need to know about specific backends
- **Processing**: Filter, transform, enrich, and batch data before export
- **Protocol Translation**: Convert between different telemetry protocols
- **Centralized Configuration**: Change backends without redeploying applications
- **Multi-Export**: Send the same data to multiple destinations
- **Resource Efficiency**: Batch and compress data for efficient transmission
- **Reliability**: Buffer and retry failed exports

Without an aggregator, each application must be configured to send data directly to backends, making changes difficult and creating tight coupling.

### How It Works

#### OpenTelemetry Collector Model

**OTel Collector Architecture**:

1. **Receivers**: Accept telemetry data via various protocols (OTLP, Prometheus, Jaeger, Zipkin, etc.)
2. **Processors**: Transform, filter, batch, and enrich data
3. **Exporters**: Send processed data to backends (Prometheus, Loki, Tempo, etc.)
4. **Pipelines**: Connect receivers → processors → exporters

**Key Components**:
- **Receivers**: OTLP (gRPC/HTTP), Prometheus, Jaeger, Zipkin, StatsD
- **Processors**: Batch, Memory Limiter, Attributes, Resource, Sampling
- **Exporters**: OTLP, Prometheus Remote Write, Loki, Tempo, Datadog

#### Example Flow

```
Application (sends OTLP)
    ↓
OTel Collector Receiver (OTLP)
    ↓
Processors (batch, filter, enrich)
    ↓
Exporters (Prometheus, Loki, Tempo)
    ↓
Backends (storage and querying)
```

### How to Achieve It with Datadog

The Datadog Agent serves as the aggregator, collecting and processing all telemetry data.

#### Architecture Overview

```
Applications/Infrastructure
    ↓
Datadog Agent (aggregator)
    ↓
Processing (filtering, enrichment, batching)
    ↓
Datadog Platform (cloud-based backend)
```

#### Step-by-Step Implementation

**1. Datadog Agent as Universal Aggregator**

The Datadog Agent collects:
- **Metrics**: From applications, infrastructure, Kubernetes
- **Logs**: From containers, files, systemd
- **Traces**: Via APM from instrumented applications
- **Events**: Kubernetes events, deployments, pod lifecycle

**2. Unified Configuration**

Configure all telemetry types in one place:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-config
  namespace: datadog
data:
  datadog.yaml: |
    # Metrics configuration
    dogstatsd_port: 8125
    collect_kubernetes_events: true
    kubernetes_collect_metadata_tags: true
    
    # Logs configuration
    logs_enabled: true
    logs_config:
      container_collect_all: true
      processing_rules:
        - type: multi_line
          name: stack_traces
          pattern: \d{4}-\d{2}-\d{2}
    
    # APM configuration
    apm_config:
      enabled: true
      non_local_traffic: true
      max_traces_per_second: 10
    
    # Processing
    tags:
      - env:production
      - team:backend
```

**3. Custom Processing Rules**

Process and enrich data:

```yaml
logs_config:
  processing_rules:
    # Parse JSON logs
    - type: log_date_format
      name: parse_json_timestamp
      format: '%Y-%m-%d %H:%M:%S'
    
    # Extract attributes
    - type: exclude_at_match
      name: exclude_health
      pattern: /health
    
    # Add custom tags
    - type: add_attributes
      name: add_service_tag
      attributes:
        service: backend
```

**4. Metric Aggregation**

Aggregate metrics before sending:

```yaml
dogstatsd_config:
  dogstatsd_port: 8125
  metrics_stats_enable: true
  # Aggregation intervals
  aggregation_ranges:
    - 10s
    - 60s
    - 300s
```

**5. Trace Processing**

Process traces:

```yaml
apm_config:
  enabled: true
  max_traces_per_second: 10
  # Trace sampling
  extra_sample_rate: 1.0
  max_events_per_second: 50
  # Error tracking
  analyzed_rate_by_service:
    backend: 1.0
```

**6. Multi-Destination Export**

While Datadog Agent primarily sends to Datadog, you can configure forwarding:

```yaml
# Forward metrics to external Prometheus
prometheus_remote_write:
  - url: http://prometheus:9090/api/v1/write
    api_key: <key>

# Forward logs to external system
logs_config:
  logs:
    - type: tcp
      port: 514
      service: syslog
```

**7. Data Batching and Compression**

The Agent automatically:
- Batches data for efficient transmission
- Compresses payloads
- Implements retry logic for failed sends
- Buffers data during network issues

**8. Resource Efficiency**

```yaml
# Limit resource usage
process_config:
  enabled: true
  max_proc_fds: 200

# Memory limits
container_memory_limit: 512Mi

# CPU limits
container_cpu_limit: 500m
```

**9. Advantages Over OTel Collector**

- **Unified Agent**: Single agent for all telemetry types
- **Automatic Discovery**: Automatically discovers Kubernetes resources
- **Built-in Processing**: Pre-configured processing for common scenarios
- **Cloud Integration**: Native integration with AWS, Azure, GCP
- **No Configuration**: Works out-of-the-box with minimal setup
- **Better Performance**: Optimized for Datadog's backend
- **Automatic Enrichment**: Automatically adds tags and metadata

**10. When to Use OTel Collector with Datadog**

Use OTel Collector if you need:
- Multi-vendor export (send to Datadog + other backends)
- Complex custom processing
- Protocol translation (e.g., Jaeger → OTLP → Datadog)
- Vendor-agnostic instrumentation

Example setup:

```
Application → OTel Collector → Datadog Agent → Datadog Platform
```

---

## 5. Visualization

### What It Is

Visualization is the presentation layer that transforms raw telemetry data (metrics, logs, traces) into visual representations like dashboards, graphs, charts, and interactive interfaces for analysis and monitoring.

**Example Tools**: Grafana, Datadog Dashboards, Kibana, New Relic, CloudWatch Dashboards

### Why It Is Needed

Visualization is essential for:

- **Quick Understanding**: Visual representation is faster than raw data
- **Trend Analysis**: Identify patterns and trends over time
- **Correlation**: See relationships between different metrics
- **Alerting**: Visual thresholds help set appropriate alert conditions
- **Reporting**: Share insights with stakeholders
- **Troubleshooting**: Quickly identify anomalies and issues
- **Capacity Planning**: Visualize resource trends for planning

Without visualization, making sense of telemetry data is extremely difficult, especially at scale.

### How It Works

#### Grafana Model

**Grafana Architecture**:

1. **Data Sources**: Connect to Prometheus, Loki, Tempo, and other backends
2. **Dashboards**: Create visual panels (graphs, tables, heatmaps, etc.)
3. **Queries**: Use query languages (PromQL, LogQL) to fetch data
4. **Visualization**: Render data in various chart types
5. **Alerting**: Set up alerts based on dashboard queries
6. **Sharing**: Export dashboards, create snapshots, share links

**Key Features**:
- Multi-datasource dashboards
- Template variables for dynamic dashboards
- Alerting rules
- Dashboard versioning
- Plugin ecosystem

### How to Achieve It with Datadog

Datadog provides comprehensive visualization with pre-built dashboards and custom dashboard creation.

#### Step-by-Step Implementation

**1. Pre-Built Dashboards**

Datadog includes dashboards for:
- **Infrastructure**: Host metrics, containers, Kubernetes
- **APM**: Service performance, traces, service maps
- **Logs**: Log analytics, log patterns
- **Database**: MySQL, PostgreSQL, MongoDB, Redis
- **Cloud**: AWS, Azure, GCP services
- **Integrations**: 500+ integrations with pre-built dashboards

**2. Create Custom Dashboards**

Build custom dashboards via UI or API:

```json
{
  "title": "Backend Service Dashboard",
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:http.request.duration{service:backend} by {endpoint}",
            "display_type": "line"
          }
        ],
        "title": "Request Duration by Endpoint"
      }
    },
    {
      "definition": {
        "type": "query_value",
        "requests": [
          {
            "q": "sum:http.requests{service:backend}",
            "aggregator": "sum"
          }
        ],
        "title": "Total Requests"
      }
    },
    {
      "definition": {
        "type": "heatmap",
        "requests": [
          {
            "q": "avg:http.request.duration{service:backend}",
            "style": {
              "palette": "dog_classic"
            }
          }
        ],
        "title": "Request Duration Distribution"
      }
    }
  ]
}
```

**3. Widget Types**

- **Time Series**: Line, area, bar charts over time
- **Query Value**: Single metric value with comparison
- **Heatmap**: Distribution of values over time
- **Distribution**: Histogram visualization
- **Top List**: Ranked list of entities
- **Geomap**: Geographic visualization
- **Log Stream**: Real-time log streaming
- **Trace**: Individual trace visualization
- **Service Map**: Service dependency graph
- **SLO**: Service Level Objective tracking

**4. Dashboard Variables**

Create dynamic dashboards with template variables:

```json
{
  "template_variables": [
    {
      "name": "service",
      "prefix": "service",
      "available_values": ["backend", "frontend", "api"]
    },
    {
      "name": "env",
      "prefix": "env",
      "default": "production"
    }
  ],
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:http.requests{$service,$env}"
          }
        ]
      }
    }
  ]
}
```

**5. Dashboard Sharing**

- **Public URLs**: Share dashboards via public links
- **Embedding**: Embed dashboards in external applications
- **Snapshot**: Create static snapshots
- **Export**: Export dashboard JSON for version control

**6. Screenboards vs. Timeboards**

- **Timeboards**: Time-series focused, auto-refresh, best for monitoring
- **Screenboards**: Free-form layout, static, best for status pages

**7. Dashboard API**

Manage dashboards programmatically:

```bash
# Create dashboard
curl -X POST "https://api.datadoghq.com/api/v1/dashboard" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d @dashboard.json

# List dashboards
curl -X GET "https://api.datadoghq.com/api/v1/dashboard" \
  -H "DD-API-KEY: ${DD_API_KEY}"

# Update dashboard
curl -X PUT "https://api.datadoghq.com/api/v1/dashboard/${dashboard_id}" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -d @updated_dashboard.json
```

**8. Notebooks**

Create interactive notebooks for ad-hoc analysis:

- Combine metrics, logs, and traces
- Add markdown explanations
- Share with team
- Export as reports

**9. Service Map Visualization**

Automatic service map showing:
- Service dependencies
- Request flow
- Error rates
- Latency between services
- Database and external API calls

**10. Log Explorer**

Visual log analysis:
- Time-series log volume
- Log patterns
- Faceted search
- Log analytics
- Correlation with metrics and traces

**11. Trace View**

Interactive trace visualization:
- Flame graphs
- Timeline view
- Span details
- Error highlighting
- Performance breakdown

**12. Advantages Over Grafana**

- **Pre-Built Dashboards**: Hundreds of ready-to-use dashboards
- **Automatic Correlation**: Automatic linking between metrics, logs, and traces
- **Service Map**: Automatic dependency visualization
- **Better UI**: More intuitive and modern interface
- **Notebooks**: Interactive analysis and reporting
- **Mobile App**: Monitor on mobile devices
- **Real-Time Updates**: Faster refresh and real-time data
- **Alert Integration**: Alerts directly on dashboards

**13. Dashboard Best Practices**

- **Group Related Metrics**: Organize widgets logically
- **Use Variables**: Make dashboards reusable
- **Set Appropriate Time Ranges**: Default to relevant time windows
- **Add Annotations**: Mark deployments and incidents
- **Use SLOs**: Track service level objectives
- **Optimize Queries**: Use efficient queries to reduce load

---

## 6. Alerts

### What It Is

Alerting is the mechanism that notifies teams when specific conditions are met, such as errors exceeding thresholds, services going down, or performance degradation. Alerts help teams respond quickly to issues.

**Example Tools**: Alertmanager, Datadog Monitors, PagerDuty, Opsgenie, VictorOps

### Why It Is Needed

Alerting is critical for:

- **Proactive Response**: Detect issues before users are affected
- **SLA Compliance**: Ensure services meet availability targets
- **Incident Management**: Trigger incident response procedures
- **On-Call Rotation**: Route alerts to the right team members
- **Escalation**: Escalate critical alerts when not acknowledged
- **Reduced MTTR**: Faster mean time to resolution
- **Prevention**: Catch issues early before they become critical

Without alerting, teams only discover issues when users report them, leading to poor user experience and potential revenue loss.

### How It Works

#### Alertmanager Model

**Alertmanager Architecture**:

1. **Alert Evaluation**: Prometheus evaluates alert rules continuously
2. **Alert Firing**: When conditions are met, alerts are sent to Alertmanager
3. **Grouping**: Alertmanager groups related alerts
4. **Deduplication**: Removes duplicate alerts
5. **Routing**: Routes alerts to appropriate channels based on labels
6. **Notification**: Sends notifications via Slack, email, PagerDuty, etc.
7. **Silencing**: Allows temporary suppression of alerts

**Key Concepts**:
- **Alert Rules**: Conditions that trigger alerts (PromQL expressions)
- **Alert Labels**: Metadata attached to alerts for routing
- **Notification Channels**: Destinations for alerts (Slack, email, etc.)
- **Routing Rules**: Logic for directing alerts to channels
- **Grouping**: Combining related alerts into single notifications

#### Example Flow

```
Prometheus (evaluates alert rules)
    ↓ (alert fires)
Alertmanager (receives alert)
    ↓ (groups and deduplicates)
Routing Rules (match labels)
    ↓ (routes to channel)
Notification Channel (Slack/Email/PagerDuty)
    ↓
On-Call Engineer (receives notification)
```

### How to Achieve It with Datadog

Datadog Monitors provide comprehensive alerting with advanced features.

#### Step-by-Step Implementation

**1. Create a Monitor**

Via UI or API:

```json
{
  "type": "metric alert",
  "query": "avg(last_5m):avg:http.request.duration{service:backend} > 1",
  "name": "High Backend Latency",
  "message": "Backend latency is above 1s for 5 minutes. @slack-backend-team",
  "options": {
    "notify_no_data": false,
    "notify_audit": false,
    "silenced": {},
    "thresholds": {
      "critical": 1.0,
      "warning": 0.5
    },
    "require_full_window": true,
    "new_host_delay": 300,
    "evaluation_delay": 0,
    "no_data_timeframe": 10,
    "renotify_interval": 0
  }
}
```

**2. Monitor Types**

- **Metric Alert**: Alert on metric thresholds
- **Log Alert**: Alert on log patterns
- **APM Alert**: Alert on trace metrics
- **RUM Alert**: Alert on real user monitoring metrics
- **Synthetic Alert**: Alert on synthetic test failures
- **Process Alert**: Alert on process availability
- **Network Alert**: Alert on network issues
- **Integration Alert**: Alert on third-party service status

**3. Alert Conditions**

Define alert conditions:

```json
{
  "query": "avg(last_5m):avg:http.request.duration{service:backend} by {endpoint}",
  "options": {
    "thresholds": {
      "critical": 1.0,
      "warning": 0.5
    },
    "comparison": ">",
    "aggregation": "avg",
    "time_window": "last_5m"
  }
}
```

**4. Multi-Alert**

Alert on multiple series:

```json
{
  "query": "avg(last_5m):avg:http.request.duration{service:backend} by {endpoint}",
  "multi": true,
  "options": {
    "thresholds": {
      "critical": 1.0
    }
  }
}
```

This creates separate alerts for each endpoint.

**5. Alert Grouping**

Group alerts by tags:

```json
{
  "query": "avg(last_5m):avg:http.request.duration{service:backend} by {endpoint,env}",
  "multi": true,
  "group_by": ["endpoint", "env"]
}
```

**6. Notification Channels**

Configure notification channels:

- **Email**: Send to email addresses
- **Slack**: Post to Slack channels
- **PagerDuty**: Create PagerDuty incidents
- **Webhooks**: Send to custom endpoints
- **Microsoft Teams**: Post to Teams channels
- **ServiceNow**: Create ServiceNow incidents
- **Jira**: Create Jira tickets

Example Slack integration:

```json
{
  "message": "High latency detected! @slack-backend-team @pagerduty-backend-oncall",
  "options": {
    "notify_audit": true,
    "renotify_interval": 60
  }
}
```

**7. Alert Message Templates**

Customize alert messages:

```
{{#is_alert}}
🚨 High latency detected!
Service: {{service.name}}
Endpoint: {{endpoint.name}}
Current: {{value}}
Threshold: {{threshold}}
{{/is_alert}}

{{#is_warning}}
⚠️ Latency approaching threshold
{{/is_warning}}

{{#is_recovery}}
✅ Latency has recovered
{{/is_recovery}}
```

**8. Alert Escalation**

Configure escalation policies:

```json
{
  "options": {
    "renotify_interval": 60,
    "escalation_message": "Alert still firing after 1 hour. Escalating to manager.",
    "escalation_tags": ["team:backend", "severity:critical"]
  }
}
```

**9. Alert Deduplication**

Datadog automatically:
- Groups related alerts
- Deduplicates similar alerts
- Suppresses noise from flapping alerts

**10. SLO-Based Alerts**

Alert on SLO violations:

```json
{
  "type": "slo alert",
  "slo_id": "slo-123",
  "slo_threshold": 0.99,
  "name": "SLO Violation: Backend Availability",
  "message": "Backend availability SLO is below 99%"
}
```

**11. Composite Monitors**

Combine multiple conditions:

```json
{
  "type": "composite",
  "query": "12345 && 67890",
  "name": "Backend Down and High Error Rate",
  "message": "Backend is down AND error rate is high"
}
```

**12. Monitor API**

Manage monitors programmatically:

```bash
# Create monitor
curl -X POST "https://api.datadoghq.com/api/v1/monitor" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d @monitor.json

# List monitors
curl -X GET "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: ${DD_API_KEY}"

# Mute monitor
curl -X POST "https://api.datadoghq.com/api/v1/monitor/${monitor_id}/mute" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -d '{"scope": "env:production"}'
```

**13. Alert Management**

- **Muting**: Temporarily silence alerts
- **Downtime**: Schedule maintenance windows
- **Alert History**: View past alerts and resolutions
- **Alert Analytics**: Analyze alert patterns and noise

**14. Advantages Over Alertmanager**

- **More Monitor Types**: Log alerts, APM alerts, synthetic alerts
- **Better UI**: More intuitive monitor creation and management
- **SLO Integration**: Built-in SLO-based alerting
- **Composite Monitors**: Combine multiple conditions
- **Better Grouping**: More sophisticated alert grouping
- **Mobile Notifications**: Receive alerts on mobile app
- **Alert Analytics**: Analyze alert patterns
- **Integration**: Native integration with PagerDuty, ServiceNow, etc.

**15. Best Practices**

- **Set Appropriate Thresholds**: Avoid alert fatigue
- **Use Multi-Alert**: Alert on each service/endpoint separately
- **Add Context**: Include relevant information in messages
- **Test Alerts**: Verify alerts work correctly
- **Review Regularly**: Remove noisy or unused alerts
- **Use SLOs**: Alert on SLO violations, not raw metrics
- **Escalate Properly**: Configure escalation for critical alerts

---

## Summary

This document has covered all six layers of the observability stack:

1. **Metrics**: Quantitative performance measurements (Prometheus → Datadog Metrics)
2. **Logs**: Textual event records (Loki + Promtail → Datadog Logs)
3. **Traces**: Distributed request flows (Tempo → Datadog APM)
4. **Aggregator**: Centralized collection and processing (OTel Collector → Datadog Agent)
5. **Visualization**: Dashboards and analytics (Grafana → Datadog Dashboards)
6. **Alerts**: Notification system (Alertmanager → Datadog Monitors)

Each component has been explained with:
- **What it is**: Definition and purpose
- **Why it is needed**: Business and technical value
- **How it works**: Technical architecture and flow
- **How to achieve it with Datadog**: Detailed implementation guide

Datadog provides a unified platform that replaces the open-source stack with additional features, better integration, and cloud-based scalability, while maintaining the same observability principles.

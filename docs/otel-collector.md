# OpenTelemetry Collector

## Overview
The `otel-collector.yaml` file defines a complete OpenTelemetry Collector setup including Deployment, Service, and ConfigMap. The collector receives telemetry data (traces, metrics, logs) and exports it to various backends (Prometheus, Loki, Tempo).

## Key Components

### Deployment Resource
- **Name**: `otel-collector`
- **Namespace**: `observability`
- **Replicas**: 1
- **Image**: `otel/opentelemetry-collector-contrib:0.85.0`

### Container Ports
- **4317**: OTLP gRPC receiver
- **4318**: OTLP HTTP receiver
- **8888**: Health check and metrics endpoint

### Resource Limits
- **Requests**: 50m CPU, 64Mi memory
- **Limits**: 100m CPU, 128Mi memory

### Service Resource
- **Name**: `otel-collector`
- **Ports**:
  - `4317`: OTLP gRPC (name: `otlp-grpc`)
  - `4318`: OTLP HTTP (name: `otlp-http`)

### ConfigMap Resource
Contains the collector configuration with:

#### Receivers
- **OTLP**: Receives traces, metrics, and logs via gRPC and HTTP
- **Prometheus**: Scrapes metrics from:
  - `backend.app.svc.cluster.local:3000` (Node.js app)
  - `mysql-exporter.app.svc.cluster.local:9104` (MySQL exporter)

#### Processors
- **Batch**: Batches telemetry data before exporting (improves efficiency)

#### Exporters
- **Prometheus Remote Write**: Sends metrics to Prometheus
  - Endpoint: `http://prometheus-operated.observability.svc:9090/api/v1/write`
- **Loki**: Sends logs to Loki
  - Endpoint: `http://loki.observability.svc:3100/loki/api/v1/push`
- **OTLP/Tempo**: Sends traces to Tempo
  - Endpoint: `tempo.observability.svc:4317`
  - TLS: Insecure (for internal cluster communication)

#### Service Pipelines
- **Traces Pipeline**: OTLP → Batch → Tempo
- **Metrics Pipeline**: Prometheus + OTLP → Batch → Prometheus Remote Write
- **Logs Pipeline**: OTLP → Batch → Loki

## How It Works
1. Applications send telemetry data to the collector via OTLP (gRPC or HTTP)
2. The collector receives data through configured receivers
3. Data is processed through processors (batching, filtering, etc.)
4. Processed data is exported to configured backends:
   - Traces → Tempo
   - Metrics → Prometheus
   - Logs → Loki

## Data Flow
```
Applications → OTLP Receiver → Batch Processor → Exporters → Backends
                ↓
         Prometheus Scraper → Batch Processor → Prometheus
```

## Integration Points
- **Backend Application**: Sends traces via OTLP HTTP to port 4318
- **Prometheus**: Receives metrics via remote write API
- **Loki**: Receives logs via push API
- **Tempo**: Receives traces via OTLP gRPC

## Benefits
- Single collection point for all telemetry
- Reduces load on applications
- Centralized processing and routing
- Supports multiple export formats
- Can enrich and transform data

## Use Cases
- Unified observability data collection
- Protocol translation (OTLP to various formats)
- Data enrichment and filtering
- Reducing application-side telemetry overhead

## Production Considerations
- Scale horizontally for high throughput
- Configure resource limits appropriately
- Use persistent storage for queuing
- Enable TLS for external communication
- Monitor collector health and performance


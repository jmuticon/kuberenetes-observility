# Tempo

## Overview
The `tempo.yaml` file defines a complete Tempo distributed tracing backend including Deployment, Service, and ConfigMap. Tempo stores and queries trace data collected from applications via OpenTelemetry.

## Key Components

### Deployment Resource
- **Name**: `tempo`
- **Namespace**: `observability`
- **Replicas**: 1
- **Image**: `grafana/tempo:2.5.0`

### Container Ports
- **3200**: HTTP API (query interface)
- **4317**: OTLP gRPC receiver
- **4318**: OTLP HTTP receiver

### Resource Limits
- **Requests**: 100m CPU, 128Mi memory
- **Limits**: 200m CPU, 256Mi memory

### Volumes
- **config**: ConfigMap volume for Tempo configuration
- **storage**: emptyDir for trace storage (ephemeral)

### Service Resource
- **Name**: `tempo`
- **Ports**:
  - `3200`: HTTP API (name: `http`)
  - `4317`: OTLP gRPC (name: `otlp-grpc`)
  - `4318`: OTLP HTTP (name: `otlp-http`)

### ConfigMap Resource
Contains Tempo configuration with:

#### Server Configuration
- `http_listen_port`: 3200 (query API)
- `grpc_listen_port`: 4317 (OTLP gRPC)

#### Distributor Configuration
- **OTLP Receivers**:
  - gRPC endpoint: `0.0.0.0:4317`
  - HTTP endpoint: `0.0.0.0:4318`

#### Ingester Configuration
- `max_block_duration`: 5 minutes
  - Maximum time before flushing a block to storage

#### Compactor Configuration
- `block_retention`: 1 hour
  - How long to keep trace blocks before deletion

#### Storage Configuration
- **Backend**: `local` (filesystem)
- **Path**: `/var/tempo/traces`
  - Where trace data is stored

## How It Works
1. Applications send traces to Tempo via OTLP (gRPC or HTTP) on ports 4317/4318
2. Tempo's distributor receives traces and routes them to ingesters
3. Ingesters batch traces into blocks
4. Blocks are flushed to storage after `max_block_duration`
5. Compactor merges and compresses blocks
6. Old blocks are deleted after `block_retention` period
7. Grafana queries Tempo via HTTP API on port 3200 to retrieve traces

## Trace Flow
```
Application → OTLP → Tempo Distributor → Ingester → Storage → Compactor
                                                              ↓
                                                          Query API
```

## Storage Considerations
⚠️ **Important**: Uses `emptyDir` volume:
- Traces are stored on the node's local filesystem
- Data is lost when the pod is deleted or rescheduled
- For production, use PersistentVolume (PV) or object storage (S3, GCS, Azure Blob)

## Integration Points
- **OpenTelemetry Collector**: Sends traces via OTLP gRPC
- **Applications**: Can send traces directly via OTLP
- **Grafana**: Queries traces via HTTP API for visualization

## API Endpoints
- **Query Trace by ID**: `GET http://tempo.observability.svc:3200/api/traces/{traceID}`
- **Search Traces**: `GET http://tempo.observability.svc:3200/api/search`
- **OTLP gRPC**: `tempo.observability.svc:4317`
- **OTLP HTTP**: `http://tempo.observability.svc:4318`

## Use Cases
- Distributed tracing for microservices
- Performance analysis and debugging
- Request flow visualization
- Latency analysis across services
- Error tracking and root cause analysis

## Production Recommendations
- Use object storage (S3, GCS, Azure Blob) for trace storage
- Increase `block_retention` based on compliance requirements
- Scale horizontally with multiple ingesters
- Enable authentication for API access
- Configure proper resource limits
- Use persistent storage or object storage backend

## Trace Retention
Current configuration:
- **Block Duration**: 5 minutes
- **Retention**: 1 hour
- Traces older than 1 hour are automatically deleted

Adjust based on:
- Compliance requirements
- Storage capacity
- Debugging needs


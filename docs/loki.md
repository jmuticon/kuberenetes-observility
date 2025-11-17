# Loki

## Overview
The `loki.yaml` file defines a complete Loki logging stack including Deployment, Service, and ConfigMap. Loki is a horizontally scalable log aggregation system designed to work with Grafana.

## Key Components

### Service Resource
- **Name**: `loki`
- **Namespace**: `observability`
- **Port**: 3100 (HTTP API)

### Deployment Resource
- **Name**: `loki`
- **Namespace**: `observability`
- **Replicas**: 1
- **Image**: `grafana/loki:2.8.2`

### Container Configuration
- **Port**: 3100
- **Config File**: `/etc/loki/local-config.yaml`
- **Storage Paths**:
  - `/loki/index`: BoltDB index storage
  - `/loki/chunks`: Log chunk storage
  - `/wal`: Write-ahead log

### Resource Limits
- **Requests**: 100m CPU, 128Mi memory
- **Limits**: 200m CPU, 256Mi memory

### Volumes
- **config**: ConfigMap volume for Loki configuration
- **storage**: emptyDir for log chunks (ephemeral)
- **wal**: emptyDir for write-ahead log (ephemeral)

### ConfigMap Resource
Contains Loki configuration file with:

#### Server Configuration
- `http_listen_port`: 3100
- `auth_enabled`: false (no authentication)

#### Ingester Configuration
- `lifecycler.address`: 127.0.0.1
- `ring.kvstore.store`: inmemory
- `replication_factor`: 1

#### Schema Configuration
- **Schema Version**: v11
- **Storage**: BoltDB for index, filesystem for chunks
- **Index Period**: 168 hours (7 days)

#### Storage Configuration
- **BoltDB**: Index stored in `/loki/index`
- **Filesystem**: Chunks stored in `/loki/chunks`

## How It Works
1. Loki receives log entries via HTTP API (port 3100)
2. Logs are written to write-ahead log (WAL) for durability
3. Logs are batched and stored as chunks in filesystem
4. Index metadata is stored in BoltDB
5. Grafana queries Loki using LogQL to retrieve and search logs

## Storage Considerations
⚠️ **Important**: Uses `emptyDir` volumes:
- Data is stored on the node's local filesystem
- Data is lost when the pod is deleted or rescheduled
- For production, use PersistentVolume (PV) or object storage (S3, GCS)

## Integration Points
- **Promtail**: Sends logs to Loki via `/loki/api/v1/push`
- **OpenTelemetry Collector**: Can send logs to Loki
- **Grafana**: Queries Loki for log visualization

## API Endpoints
- **Push Logs**: `POST http://loki.observability.svc:3100/loki/api/v1/push`
- **Query Logs**: `GET http://loki.observability.svc:3100/loki/api/v1/query`
- **Label Queries**: `GET http://loki.observability.svc:3100/loki/api/v1/labels`

## Use Cases
- Centralized log aggregation
- Log search and analysis
- Integration with Grafana for log visualization
- Correlation with metrics and traces

## Production Recommendations
- Use object storage (S3, GCS) for chunks
- Use distributed storage for index (DynamoDB, Bigtable)
- Enable authentication
- Configure retention policies
- Scale horizontally with multiple ingesters


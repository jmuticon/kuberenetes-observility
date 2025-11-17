# Promtail

## Overview
The `promtail.yaml` file defines a complete Promtail log collection setup including ServiceAccount, ClusterRole, ClusterRoleBinding, DaemonSet, and ConfigMap. Promtail is an agent that ships logs from Kubernetes pods to Loki.

## Key Components

### ServiceAccount
- **Name**: `promtail`
- **Namespace**: `observability`
- Purpose: Provides identity for Promtail pods

### ClusterRole
- **Name**: `promtail`
- **Permissions**: Read access to:
  - `nodes` and `nodes/proxy`
  - `services`
  - `endpoints`
  - `pods`
- **Verbs**: `get`, `list`, `watch`

### ClusterRoleBinding
- **Name**: `promtail`
- **Role**: References the `promtail` ClusterRole
- **Subject**: `promtail` ServiceAccount in `observability` namespace

### DaemonSet Resource
- **Name**: `promtail`
- **Namespace**: `observability`
- **Type**: DaemonSet (runs one pod per node)
- **Image**: `grafana/promtail:2.8.2`

### Container Configuration
- **Config File**: `/etc/promtail/promtail.yaml`
- **Port**: 9080 (HTTP server for metrics/health)

### Resource Limits
- **Requests**: 50m CPU, 64Mi memory
- **Limits**: 100m CPU, 128Mi memory

### Volume Mounts
- **/var/log**: Host path to node's log directory
- **/var/lib/docker/containers**: Host path to Docker container logs (read-only)
- **/etc/promtail**: ConfigMap with Promtail configuration

### ConfigMap Resource
Contains Promtail configuration with:

#### Server Configuration
- `http_listen_port`: 9080
- `grpc_listen_port`: 0 (disabled)

#### Client Configuration
- **Loki URL**: `http://loki.observability.svc:3100/loki/api/v1/push`
  - Where to send collected logs

#### Positions File
- `filename`: `/tmp/positions.yaml`
  - Tracks read position in log files (prevents re-reading)

#### Scrape Configuration
- **Job Name**: `kubernetes-pods`
- **Discovery**: Uses Kubernetes service discovery to find pods
- **Pipeline Stages**: Empty (no log transformation)
- **Relabel Configs**:
  - Extracts `app` label from pod labels
  - Extracts `namespace` label
  - Maps all pod labels to log labels

## How It Works
1. Promtail runs as a DaemonSet (one pod per Kubernetes node)
2. Each Promtail instance:
   - Discovers pods running on its node via Kubernetes API
   - Reads log files from `/var/log` and `/var/lib/docker/containers`
   - Applies relabeling to add metadata (labels)
   - Sends logs to Loki via HTTP push API
3. Loki receives and stores the logs
4. Grafana queries Loki to display logs

## DaemonSet Explained
A DaemonSet ensures:
- One Promtail pod runs on each node
- Automatically schedules on new nodes
- Collects logs from all pods on the node
- Provides node-level log collection

## RBAC Permissions
Promtail needs cluster-wide permissions to:
- Discover pods across all namespaces
- Read pod metadata and labels
- Access node information
- Discover services and endpoints

## Log Collection
Promtail collects logs from:
- **/var/log**: System and application logs
- **/var/lib/docker/containers**: Docker container logs
- Automatically discovers new pods and starts tailing their logs

## Label Extraction
Logs are enriched with labels:
- `app`: Extracted from pod label `app`
- `namespace`: Kubernetes namespace
- All pod labels are mapped to log labels

## Integration
- **Loki**: Receives logs from Promtail
- **Grafana**: Queries Loki to display logs
- **Kubernetes**: Provides pod discovery and metadata

## Use Cases
- Centralized log collection from all pods
- Automatic log discovery for new pods
- Log aggregation across the cluster
- Integration with Grafana for log visualization

## Production Considerations
- Monitor Promtail resource usage (runs on every node)
- Adjust resource limits based on log volume
- Consider using persistent storage for positions file
- Configure log filtering to reduce noise
- Set up log retention policies in Loki

## Troubleshooting
- Check Promtail pod logs if logs aren't appearing in Loki
- Verify RBAC permissions are correct
- Ensure Loki service is accessible
- Check positions file for read progress
- Verify pod labels are being extracted correctly


# MySQL Deployment

## Overview
The `mysql-deployment.yaml` file defines a Kubernetes Deployment that runs a MySQL 8.0 database server. It also includes a Service definition for database access.

## Key Components

### Deployment Resource
- **Name**: `mysql`
- **Namespace**: `app`
- **Replicas**: 1 (single instance, not suitable for production)

### Container Configuration
- **Image**: `mysql:8.0`
- **Port**: 3306 (MySQL default port)

### Environment Variables
- `MYSQL_ROOT_PASSWORD`: Root user password (set to `example`)
- `MYSQL_DATABASE`: Initial database to create (set to `demo`)

### Resource Limits
- **Requests**: 200m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory

### Volume Configuration
- **Volume Name**: `mysql-data`
- **Volume Type**: `emptyDir` (ephemeral storage, data lost on pod restart)
- **Mount Path**: `/var/lib/mysql` (MySQL data directory)

### Service Resource
The file also includes a Service definition:
- **Name**: `mysql`
- **Namespace**: `app`
- **Type**: Headless Service (`clusterIP: None`)
- **Port**: 3306

## How It Works
1. Kubernetes creates a Pod with the MySQL container
2. MySQL initializes with the root password and creates the `demo` database
3. Data is stored in the mounted volume at `/var/lib/mysql`
4. The Service provides network access to the MySQL pod
5. Other pods can connect using the service name `mysql`

## Headless Service
The `clusterIP: None` setting creates a headless service, which:
- Returns the pod IP directly instead of a virtual IP
- Useful for stateful applications
- Allows direct pod-to-pod communication

## Storage Considerations
⚠️ **Important**: The `emptyDir` volume is ephemeral:
- Data is stored on the node's local filesystem
- Data is lost when the pod is deleted or rescheduled
- For production, use PersistentVolume (PV) or PersistentVolumeClaim (PVC)

## Connection Details
Other pods in the cluster can connect using:
- **Host**: `mysql.app.svc.cluster.local` or `mysql`
- **Port**: 3306
- **User**: `root`
- **Password**: `example`
- **Database**: `demo`

## Dependencies
- Backend deployment connects to this MySQL instance
- MySQL exporter can connect to scrape metrics


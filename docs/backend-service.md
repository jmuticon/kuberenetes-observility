# Backend Service

## Overview
The `backend-service.yaml` file defines a Kubernetes Service that provides network access to the backend deployment pods.

## Key Components

### Service Resource
- **Name**: `backend`
- **Namespace**: `app`
- **Type**: ClusterIP (default, internal cluster access only)

### Service Selector
- **Selector**: `app: backend`
- Matches pods with the label `app: backend` from the backend deployment

### Port Configuration
- **Port**: 3000 (service port)
- **Target Port**: 3000 (container port)
- **Protocol**: TCP (default)
- **Name**: `http`

## How It Works
1. The Service acts as a stable network endpoint
2. It routes traffic to pods matching the `app: backend` label
3. Other pods in the cluster can access the backend via `backend.app.svc.cluster.local:3000`
4. The Service provides load balancing across multiple backend pods (if replicas > 1)

## Use Cases
- Allows other services (like frontend) to connect to the backend
- Enables Prometheus ServiceMonitor to discover and scrape metrics
- Provides stable DNS name for service-to-service communication

## DNS Resolution
Within the cluster, the service is accessible at:
- `backend.app.svc.cluster.local:3000`
- `backend.app:3000` (short form)
- `backend:3000` (within the same namespace)


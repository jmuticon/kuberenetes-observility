# Frontend Service

## Overview
The `frontend-service.yaml` file defines a Kubernetes Service that provides network access to the frontend deployment pods.

## Key Components

### Service Resource
- **Name**: `frontend`
- **Namespace**: `app`
- **Type**: ClusterIP (default, internal cluster access only)

### Service Selector
- **Selector**: `app: frontend`
- Matches pods with the label `app: frontend` from the frontend deployment

### Port Configuration
- **Port**: 80 (service port)
- **Target Port**: 80 (container port)
- **Protocol**: TCP (default)
- **Name**: `http`

## How It Works
1. The Service acts as a stable network endpoint for the frontend
2. It routes traffic to pods matching the `app: frontend` label
3. The Ingress controller uses this service to route external traffic
4. Other pods in the cluster can access the frontend via `frontend.app.svc.cluster.local:80`

## Use Cases
- Allows Ingress to route external traffic to frontend pods
- Enables service-to-service communication within the cluster
- Provides stable DNS name for the frontend service

## DNS Resolution
Within the cluster, the service is accessible at:
- `frontend.app.svc.cluster.local:80`
- `frontend.app:80` (short form)
- `frontend:80` (within the same namespace)

## Integration with Ingress
The Ingress resource references this service to route traffic from `frontend.local` to the frontend pods.


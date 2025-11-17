# Ingress

## Overview
The `ingress.yaml` file defines a Kubernetes Ingress resource that routes external HTTP traffic to internal services based on hostname and path rules.

## Key Components

### Ingress Resource
- **Name**: `demo-ingress`
- **Namespace**: `app`
- **Ingress Class**: `nginx` (requires NGINX Ingress Controller)

### Routing Rules

#### Frontend Route
- **Host**: `frontend.local`
- **Path**: `/` (root path, Prefix type)
- **Backend Service**: `frontend`
- **Backend Port**: 80

#### Backend API Route
- **Host**: `api.local`
- **Path**: `/` (root path, Prefix type)
- **Backend Service**: `backend`
- **Backend Port**: 3000

## How It Works
1. External traffic arrives at the Ingress Controller (NGINX)
2. The Ingress Controller reads this Ingress resource
3. Based on the `Host` header, traffic is routed to the appropriate service:
   - Requests to `frontend.local` → frontend service (port 80)
   - Requests to `api.local` → backend service (port 3000)
4. The service then routes to the appropriate pods

## Path Types
- **Prefix**: Matches all paths that start with the specified path
- The `/` path matches all requests to that host

## Requirements
- NGINX Ingress Controller must be installed in the cluster
- The annotation `kubernetes.io/ingress.class: nginx` tells Kubernetes which controller to use
- DNS must be configured to point `frontend.local` and `api.local` to the Ingress Controller's IP
- For local development, add entries to `/etc/hosts`:
  ```
  <ingress-ip> frontend.local
  <ingress-ip> api.local
  ```

## Use Cases
- Exposes frontend application to external users
- Exposes backend API to external clients
- Provides single entry point for multiple services
- Enables hostname-based routing

## Access
Once configured, you can access:
- Frontend: `http://frontend.local`
- Backend API: `http://api.local/api/hello`


# Grafana Ingress

## Overview
The `grafana-ingress.yaml` file defines a Kubernetes Ingress resource that exposes the Grafana web interface to external traffic via a hostname.

## Key Components

### Ingress Resource
- **Name**: `grafana-ingress`
- **Namespace**: `observability`
- **Ingress Class**: `nginx` (requires NGINX Ingress Controller)

### Routing Rule
- **Host**: `grafana.local`
- **Path**: `/` (root path, Prefix type)
- **Backend Service**: `observability-grafana`
- **Backend Port**: 80

## How It Works
1. External traffic arrives at the NGINX Ingress Controller
2. The Ingress Controller reads this Ingress resource
3. Requests to `grafana.local` are routed to the `observability-grafana` service
4. The service forwards traffic to Grafana pods
5. Users can access Grafana UI via the hostname

## Service Reference
- **Service Name**: `observability-grafana`
  - This is the default service name created by the Prometheus Stack Helm chart
  - The service is in the `observability` namespace

## Requirements
- NGINX Ingress Controller must be installed
- DNS must be configured to point `grafana.local` to the Ingress Controller's IP
- For local development, add to `/etc/hosts`:
  ```
  <ingress-ip> grafana.local
  ```

## Access
Once configured, access Grafana at:
- URL: `http://grafana.local`
- Default credentials (from prometheus-stack-values.yaml):
  - Username: `admin`
  - Password: `admin`

## Security Considerations
⚠️ **Important**: This configuration exposes Grafana without authentication at the Ingress level. For production:
- Configure TLS/HTTPS
- Use authentication annotations (OAuth, basic auth)
- Restrict access via network policies
- Change default admin password

## Use Cases
- Access Grafana dashboards from outside the cluster
- Share Grafana access with team members
- Integrate with external monitoring tools
- Provide single entry point for observability stack


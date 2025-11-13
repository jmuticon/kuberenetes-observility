# Minikube Observability Stack (Prometheus/Grafana/Loki/Tempo/OTel) — Local

A complete observability stack for Minikube including Prometheus, Grafana, Loki, Tempo, and OpenTelemetry Collector with a sample Node.js application.

## Prerequisites

- **minikube** (v1.30+)
- **kubectl** (v1.25+)
- **helm** (v3.10+)
- **Minimum 3.1GB RAM and 2 CPUs available for Minikube** (optimized for low-resource environments)
  - Note: 4-5GB RAM recommended for better performance

### Optional (for external access via ingress):
Add hosts to `/etc/hosts`:
```
127.0.0.1 frontend.local api.local grafana.local
```

## Architecture

### Observability Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Tempo**: Distributed tracing
- **OpenTelemetry Collector**: Unified telemetry collection
- **Promtail**: Log shipper (DaemonSet)
- **Alertmanager**: Alert routing and notification

### Application Stack
- **Frontend**: Nginx serving a simple HTML page
- **Backend**: Node.js Express API with Prometheus metrics
- **MySQL**: Database with mysqld-exporter for metrics

## Quick Start

### Automated Deployment

```bash
chmod +x deploy.sh
./deploy.sh
```

### Manual Deployment

```bash
# Start minikube (optimized for 3.1GB RAM)
minikube start --memory=3072 --cpus=2
minikube addons enable ingress

# Create namespaces
kubectl create ns observability || true
kubectl create ns app || true

# Add helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm upgrade --install observability prometheus-community/kube-prometheus-stack \
  -n observability -f ./k8s/observability/prometheus-stack-values.yaml

# Wait for Prometheus stack to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n observability --timeout=300s || true

# Apply observability components
kubectl apply -n observability -f ./k8s/observability/loki.yaml
kubectl apply -n observability -f ./k8s/observability/promtail.yaml
kubectl apply -n observability -f ./k8s/observability/tempo.yaml
kubectl apply -n observability -f ./k8s/observability/otel-collector.yaml
kubectl apply -n observability -f ./k8s/observability/prometheus-rules.yaml
kubectl apply -n observability -f ./k8s/observability/alertmanager-config.yaml
kubectl apply -n observability -f ./k8s/observability/grafana-datasources.yaml
kubectl apply -n observability -f ./k8s/observability/grafana-dashboard-nodejs.json
kubectl apply -n observability -f ./k8s/observability/grafana-dashboard-mysql.json
kubectl apply -n observability -f ./k8s/observability/grafana-ingress.yaml

# Deploy application
kubectl apply -n app -f ./k8s/app/backend-deployment.yaml
kubectl apply -n app -f ./k8s/app/backend-service.yaml
kubectl apply -n app -f ./k8s/app/frontend-deployment.yaml
kubectl apply -n app -f ./k8s/app/frontend-service.yaml
kubectl apply -n app -f ./k8s/app/ingress.yaml
kubectl apply -n app -f ./k8s/app/mysql-deployment.yaml
kubectl apply -n app -f ./k8s/app/mysql-service.yaml
kubectl apply -n app -f ./k8s/app/mysql-exporter-deployment.yaml

# Apply ServiceMonitor for backend metrics
kubectl apply -n observability -f ./k8s/app/backend-servicemonitor.yaml

# Wait for application pods
kubectl wait --for=condition=ready pod -l app=backend -n app --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=mysql -n app --timeout=300s || true

# Check status
kubectl get pods -A
```

## Accessing Services

### Via Ingress (after adding to /etc/hosts)

**Important for macOS/Linux**: Minikube runs in a VM, so you need to run `minikube tunnel` in a separate terminal to expose the ingress controller:

```bash
# Run this in a separate terminal (keep it running)
minikube tunnel
```

**Note**: On macOS, `minikube tunnel` may require your password to set up network routes.

After running `minikube tunnel`, you can access:
- **Grafana**: http://grafana.local (admin/admin)
- **Frontend**: http://frontend.local
- **Backend API**: http://api.local/api/hello

### Via Port Forwarding (alternative - recommended if ingress doesn't work)
```bash
# Frontend
kubectl -n app port-forward svc/frontend 8080:80
# Open http://localhost:8080

# Backend API
kubectl -n app port-forward svc/backend 3000:3000
# Open http://localhost:3000/api/hello

# Grafana
kubectl -n observability port-forward svc/observability-grafana 3000:80
# Open http://localhost:3000

# Prometheus
kubectl -n observability port-forward svc/prometheus-operated 9090:9090
# Open http://localhost:9090
```

## Verification

### Check Pod Status
```bash
kubectl get pods -A
```

All pods should be in `Running` state. If any pod is not ready:
```bash
# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Describe pod for events
kubectl describe pod -n <namespace> <pod-name>
```

### Verify Services
```bash
# Test backend API
curl http://api.local/api/hello

# Test metrics endpoint
curl http://api.local/metrics

# Check Prometheus targets
kubectl port-forward -n observability svc/prometheus-operated 9090:9090
# Open http://localhost:9090/targets
```

### Verify Grafana Dashboards
1. Log into Grafana (admin/admin)
2. Navigate to Dashboards
3. You should see:
   - Node.js Backend Metrics
   - MySQL Metrics

## Troubleshooting

### Ingress Not Working

**On macOS/Linux**, Minikube ingress requires `minikube tunnel` to be running:

1. **Check if tunnel is running**:
   ```bash
   ps aux | grep "minikube tunnel" | grep -v grep
   ```

2. **Start minikube tunnel** (in a separate terminal):
   ```bash
   minikube tunnel
   ```
   - Keep this terminal open while accessing services
   - On macOS, you may be prompted for your password

3. **Verify ingress controller**:
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   - Should show `TYPE: LoadBalancer` with an `EXTERNAL-IP` after tunnel starts

4. **Test ingress**:
   ```bash
   curl -I http://frontend.local
   ```

**Alternative: Use Port Forwarding** (more reliable for local development):
```bash
# Frontend
kubectl -n app port-forward svc/frontend 8080:80
# Open http://localhost:8080

# Backend API
kubectl -n app port-forward svc/backend 3000:3000
# Open http://localhost:3000/api/hello

# Grafana
kubectl -n observability port-forward svc/observability-grafana 3000:80
# Open http://localhost:3000
```

### Pods Not Starting
1. Check resource availability:
   ```bash
   minikube status
   ```
2. If you have more resources available, you can increase Minikube resources:
   ```bash
   minikube stop
   minikube start --memory=4096 --cpus=2  # or higher
   ```

### Backend Pod Crashing
Check backend logs:
```bash
kubectl logs -n app -l app=backend
```

Common issues:
- MySQL not ready: Wait for MySQL pod to be ready first
- npm install failing: Check network connectivity in pod

### Prometheus Not Scraping
1. Check ServiceMonitor:
   ```bash
   kubectl get servicemonitor -n observability
   ```
2. Check Prometheus targets (via port-forward to Prometheus UI)

### Grafana Dashboards Not Appearing
1. Check dashboard ConfigMaps:
   ```bash
   kubectl get configmap -n observability | grep dashboard
   ```
2. Restart Grafana pod to reload dashboards:
   ```bash
   kubectl delete pod -n observability -l app.kubernetes.io/name=grafana
   ```

## Project Structure

```
.
├── README.md
├── deploy.sh
├── Dockerfiles/
│   ├── backend.Dockerfile
│   └── frontend.Dockerfile
└── k8s/
    ├── observability/
    │   ├── prometheus-stack-values.yaml
    │   ├── alertmanager-config.yaml
    │   ├── grafana-datasources.yaml
    │   ├── grafana-dashboard-nodejs.json
    │   ├── grafana-dashboard-mysql.json
    │   ├── grafana-ingress.yaml
    │   ├── loki.yaml
    │   ├── promtail.yaml
    │   ├── tempo.yaml
    │   ├── otel-collector.yaml
    │   └── prometheus-rules.yaml
    └── app/
        ├── mysql-deployment.yaml
        ├── mysql-service.yaml
        ├── mysql-exporter-deployment.yaml
        ├── backend-deployment.yaml
        ├── backend-service.yaml
        ├── backend-servicemonitor.yaml
        ├── frontend-deployment.yaml
        ├── frontend-service.yaml
        └── ingress.yaml
```

## Cleanup

### Automated Cleanup (Recommended)

Use the provided cleanup script:
```bash
./cleanup.sh
```

This script will:
- Uninstall Helm releases
- Delete all namespaces
- Wait for and verify complete deletion
- Provide clear status feedback

### Manual Cleanup

To manually remove all resources:
```bash
helm uninstall observability -n observability
kubectl delete ns observability app
```

### Force Cleanup (if stuck)

If namespaces are stuck in "Terminating" state:
```bash
kubectl delete ns app observability --force --grace-period=0
```

## Notes

- This is a **local development/demo** setup optimized for **3.1GB RAM**. For production:
  - Use PersistentVolumes instead of emptyDir
  - Lock images to specific digests
  - Secure credentials (use Secrets)
  - Configure TLS for ingress
  - Tune resource limits and retention policies
  - Use proper storage backends for Loki/Tempo

- **Resource Optimizations Applied:**
  - Prometheus retention reduced to 1 day (from 10 days)
  - All components have strict memory and CPU limits
  - Prometheus limited to 1.5GB max memory
  - Total memory footprint: ~2.5-3GB under normal load
  - If pods are OOMKilled, consider increasing Docker memory allocation

- The backend installs npm packages at runtime. For production, build a proper Docker image using the provided Dockerfile.

- Alertmanager is configured with placeholder Slack/Email settings. Update `alertmanager-config.yaml` with real credentials.


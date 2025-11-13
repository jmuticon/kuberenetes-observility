# Quick Start Guide - Kubernetes Observability Stack

Welcome! This guide will help you set up a complete observability stack on Kubernetes from scratch. Perfect for beginners learning Kubernetes, observability, and monitoring.

## What You'll Learn

This project demonstrates:
- **Kubernetes fundamentals**: Deployments, Services, Ingress, ConfigMaps
- **Observability stack**: Prometheus, Grafana, Loki, Tempo
- **Application monitoring**: Metrics, logs, and distributed tracing
- **Real-world setup**: Complete monitoring solution for a sample application

## Prerequisites

Before starting, ensure you have the following tools installed:

### 1. Minikube (v1.30+)

**What it is**: Local Kubernetes cluster for development

**Installation**:

**macOS**:
```bash
brew install minikube
```

**Linux**:
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Windows**:
```bash
choco install minikube
```

**Verify installation**:
```bash
minikube version
```

### 2. kubectl (v1.25+)

**What it is**: Command-line tool for interacting with Kubernetes clusters

**Installation**:

**macOS**:
```bash
brew install kubectl
```

**Linux**:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Windows**:
```bash
choco install kubernetes-cli
```

**Verify installation**:
```bash
kubectl version --client
```

### 3. Helm (v3.10+)

**What it is**: Package manager for Kubernetes

**Installation**:

**macOS**:
```bash
brew install helm
```

**Linux**:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows**:
```bash
choco install kubernetes-helm
```

**Verify installation**:
```bash
helm version
```

### 4. System Requirements

- **Minimum**: 3.1GB RAM, 2 CPUs available for Minikube
- **Recommended**: 4-5GB RAM for better performance
- **Disk**: At least 10GB free space

**Check available resources**:
```bash
# macOS/Linux
free -h  # or: vm_stat (macOS)
nproc    # CPU count
```

## Step-by-Step Setup

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd kuberenetes-observility
```

### Step 2: Start Minikube

Start Minikube with optimized settings for low-resource environments:

```bash
minikube start --memory=3072 --cpus=2
```

**What this does**: Creates a local Kubernetes cluster with 3GB RAM and 2 CPUs

**Verify Minikube is running**:
```bash
minikube status
```

You should see:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Step 3: Enable Ingress Addon

```bash
minikube addons enable ingress
```

**What this does**: Enables the NGINX ingress controller for external access to services

**Verify**:
```bash
kubectl get pods -n ingress-nginx
```

### Step 4: Configure Hosts File (Optional but Recommended)

Add these entries to your `/etc/hosts` file for easy access:

**macOS/Linux**:
```bash
sudo nano /etc/hosts
```

Add these lines:
```
127.0.0.1 frontend.local
127.0.0.1 api.local
127.0.0.1 grafana.local
```

**Windows**:
Edit `C:\Windows\System32\drivers\etc\hosts` (as Administrator) and add the same lines.

**Why**: Allows you to access services using friendly names instead of IP addresses

### Step 5: Deploy Everything

The project includes an automated deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

**What the script does**:
1. Creates namespaces (`observability` and `app`)
2. Adds Helm repositories
3. Installs Prometheus and Grafana stack
4. Deploys Loki, Tempo, and OpenTelemetry Collector
5. Deploys sample application (frontend, backend, MySQL)
6. Configures monitoring and dashboards

**Expected output**: The script will show progress and wait for pods to be ready. This may take 3-5 minutes.

### Step 6: Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -A
```

**What to look for**: All pods should show `STATUS: Running` and `READY: 1/1` (or similar)

**If pods are not ready**: Wait 1-2 minutes and check again. Some pods take time to start.

**Check specific namespaces**:
```bash
# Observability stack
kubectl get pods -n observability

# Application
kubectl get pods -n app
```

## Accessing Services

### Option 1: Using Ingress (Recommended)

**Important**: On macOS/Linux, you need to run `minikube tunnel` in a separate terminal:

```bash
# In a NEW terminal window (keep it running)
minikube tunnel
```

**Note**: On macOS, you may be prompted for your password to set up network routes.

Once the tunnel is running, access:

- **Grafana**: http://grafana.local
  - Username: `admin`
  - Password: `admin`
  
- **Frontend**: http://frontend.local
  
- **Backend API**: http://api.local/api/hello

### Option 2: Using Port Forwarding (Alternative)

If ingress doesn't work, use port forwarding:

**Grafana**:
```bash
kubectl -n observability port-forward svc/observability-grafana 3000:80
```
Access: http://localhost:3000 (admin/admin)

**Frontend**:
```bash
kubectl -n app port-forward svc/frontend 8080:80
```
Access: http://localhost:8080

**Backend API**:
```bash
kubectl -n app port-forward svc/backend 3001:3000
```
Access: http://localhost:3001/api/hello

**Prometheus**:
```bash
kubectl -n observability port-forward svc/prometheus-operated 9090:9090
```
Access: http://localhost:9090

## Verification Checklist

### ✅ Check 1: All Pods Running

```bash
kubectl get pods -A
```

All pods should be `Running`. If any are `Pending` or `Error`, check logs:
```bash
kubectl logs -n <namespace> <pod-name>
```

### ✅ Check 2: Services Accessible

**Test Backend API**:
```bash
curl http://api.local/api/hello
# Or if using port-forward:
curl http://localhost:3001/api/hello
```

Expected response: `{"message":"Hello from backend!"}`

**Test Metrics Endpoint**:
```bash
curl http://api.local/metrics
```

Should show Prometheus metrics output.

### ✅ Check 3: Grafana Dashboards

1. Log into Grafana (http://grafana.local or http://localhost:3000)
2. Go to **Dashboards** → **Browse**
3. You should see:
   - **Node.js Backend Metrics**
   - **MySQL Metrics**

### ✅ Check 4: Prometheus Targets

1. Access Prometheus (http://localhost:9090 via port-forward)
2. Go to **Status** → **Targets**
3. Check that `backend` target shows `State: UP`

## Understanding the Architecture

### What Gets Deployed

**Observability Stack** (in `observability` namespace):
- **Prometheus**: Collects and stores metrics
- **Grafana**: Visualizes metrics, logs, and traces
- **Loki**: Aggregates logs
- **Tempo**: Stores distributed traces
- **OpenTelemetry Collector**: Unified telemetry gateway
- **Promtail**: Ships logs from pods to Loki
- **Alertmanager**: Handles alert routing

**Application Stack** (in `app` namespace):
- **Frontend**: Nginx serving HTML
- **Backend**: Node.js Express API with metrics and tracing
- **MySQL**: Database with metrics exporter

### Data Flow

1. **Metrics**: Backend exposes `/metrics` → Prometheus scrapes → Grafana visualizes
2. **Logs**: Pod logs → Promtail collects → Loki stores → Grafana queries
3. **Traces**: Backend instruments → OTel Collector → Tempo stores → Grafana visualizes

## Common Issues and Solutions

### Issue 1: Minikube Won't Start

**Error**: `minikube start` fails

**Solutions**:
- Check Docker/VM is running
- Increase Docker Desktop memory allocation
- Try: `minikube delete` then `minikube start --memory=3072 --cpus=2`

### Issue 2: Pods Stuck in Pending

**Error**: Pods show `STATUS: Pending`

**Solutions**:
```bash
# Check why pod is pending
kubectl describe pod -n <namespace> <pod-name>

# Check node resources
kubectl top nodes

# If out of resources, increase Minikube resources
minikube stop
minikube start --memory=4096 --cpus=2
```

### Issue 3: Ingress Not Working

**Error**: Can't access services via `*.local` domains

**Solutions**:
1. **Ensure minikube tunnel is running**:
   ```bash
   minikube tunnel
   ```

2. **Check ingress controller**:
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   Should show `EXTERNAL-IP` after tunnel starts

3. **Use port-forwarding instead** (more reliable for local dev)

### Issue 4: Backend Pod Crashing

**Error**: Backend pod shows `CrashLoopBackOff`

**Solutions**:
```bash
# Check logs
kubectl logs -n app -l app=backend

# Common causes:
# - MySQL not ready: Wait for MySQL pod to be ready first
# - npm install failing: Check network connectivity
```

### Issue 5: No Data in Grafana Dashboards

**Error**: Dashboards show "No data"

**Solutions**:
1. **Generate some traffic**:
   ```bash
   for i in {1..10}; do curl http://api.local/api/hello; sleep 1; done
   ```

2. **Check Prometheus is scraping**:
   - Access Prometheus UI
   - Go to Status → Targets
   - Verify backend target is UP

3. **Check ServiceMonitor**:
   ```bash
   kubectl get servicemonitor -n observability
   ```

### Issue 6: Can't Access Grafana

**Error**: Connection refused or timeout

**Solutions**:
1. **Check if pod is running**:
   ```bash
   kubectl get pods -n observability -l app.kubernetes.io/name=grafana
   ```

2. **Use port-forwarding**:
   ```bash
   kubectl -n observability port-forward svc/observability-grafana 3000:80
   ```

3. **Check if service exists**:
   ```bash
   kubectl get svc -n observability | grep grafana
   ```

## Learning Path

### Beginner Level

1. **Explore Kubernetes Resources**:
   ```bash
   # List all resources
   kubectl get all -A
   
   # Describe a deployment
   kubectl describe deployment backend -n app
   
   # View service details
   kubectl get svc -n app
   ```

2. **View Logs**:
   ```bash
   # Backend logs
   kubectl logs -n app -l app=backend
   
   # Follow logs in real-time
   kubectl logs -n app -l app=backend -f
   ```

3. **Explore Grafana**:
   - Browse pre-built dashboards
   - Try creating a simple panel
   - Explore different data sources

### Intermediate Level

1. **Query Prometheus**:
   - Access Prometheus UI
   - Try PromQL queries:
     - `up` - Check if targets are up
     - `rate(http_request_duration_seconds_count[5m])` - Request rate
     - `histogram_quantile(0.95, http_request_duration_seconds_bucket)` - 95th percentile latency

2. **Explore Logs in Grafana**:
   - Go to Explore → Loki
   - Try LogQL queries:
     - `{namespace="app"}` - All logs from app namespace
     - `{app="backend"}` - Backend logs only

3. **View Traces**:
   - Go to Explore → Tempo
   - Make API requests and find traces
   - Understand span hierarchy

### Advanced Level

1. **Modify Configurations**:
   - Edit `prometheus-stack-values.yaml` to change retention
   - Add custom alert rules in `prometheus-rules.yaml`
   - Create custom Grafana dashboards

2. **Add Custom Metrics**:
   - Modify backend code to expose new metrics
   - Create new ServiceMonitor
   - Build custom dashboard

3. **Understand Resource Management**:
   ```bash
   # Check resource usage
   kubectl top pods -A
   kubectl top nodes
   
   # Adjust resource limits in deployment YAMLs
   ```

## Useful Commands Reference

### Pod Management
```bash
# List all pods
kubectl get pods -A

# Describe a pod
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

### Service Management
```bash
# List services
kubectl get svc -A

# Port forward
kubectl port-forward svc/<service-name> <local-port>:<remote-port> -n <namespace>
```

### Debugging
```bash
# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -A
kubectl top nodes

# Check ingress
kubectl get ingress -A
```

### Cleanup
```bash
# Remove everything
./cleanup.sh

# Or manually
helm uninstall observability -n observability
kubectl delete ns observability app
```

## Next Steps

1. **Read the Full Documentation**:
   - `README.md` - Complete project documentation
   - `OBSERVABILITY_GUIDE.md` - Deep dive into observability concepts

2. **Experiment**:
   - Modify the backend code
   - Add new metrics
   - Create custom dashboards
   - Set up alerts

3. **Learn More**:
   - Kubernetes official docs: https://kubernetes.io/docs/
   - Prometheus docs: https://prometheus.io/docs/
   - Grafana docs: https://grafana.com/docs/

## Getting Help

If you encounter issues:

1. **Check logs**: `kubectl logs -n <namespace> <pod-name>`
2. **Describe resources**: `kubectl describe <resource> -n <namespace>`
3. **Review troubleshooting section** in `README.md`
4. **Check GitHub issues** (if applicable)

## Summary

You now have:
- ✅ A running Kubernetes cluster (Minikube)
- ✅ Complete observability stack (Prometheus, Grafana, Loki, Tempo)
- ✅ Sample application with monitoring
- ✅ Access to dashboards and metrics

**Happy Learning!** 🚀


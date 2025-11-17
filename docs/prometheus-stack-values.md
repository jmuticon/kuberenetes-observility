# Prometheus Stack Values

## Overview
The `prometheus-stack-values.yaml` file contains Helm values for the kube-prometheus-stack chart. This chart deploys Prometheus, Grafana, Alertmanager, and the Prometheus Operator as a complete observability stack.

## Key Components

### Prometheus Configuration
```yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    ruleSelector: {}
    retention: 1d
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
      limits:
        memory: 1.5Gi
        cpu: 1000m
```

**Settings Explained**:
- `serviceMonitorSelectorNilUsesHelmValues: false`: Allows Prometheus to discover ServiceMonitors from all namespaces
- `serviceMonitorSelector: {}`: Empty selector means "select all ServiceMonitors"
- `ruleSelector: {}`: Empty selector means "select all PrometheusRules"
- `retention: 1d`: Keeps metrics for 1 day (24 hours)
- **Resources**: CPU and memory limits for Prometheus pods

### Grafana Configuration
```yaml
grafana:
  enabled: true
  adminUser: admin
  adminPassword: admin
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m
  sidecar:
    dashboards:
      enabled: true
    datasources:
      enabled: true
```

**Settings Explained**:
- `enabled: true`: Deploys Grafana
- `adminUser/adminPassword`: Default credentials (change in production!)
- **Resources**: CPU and memory limits for Grafana pods
- **Sidecar**: Automatically loads ConfigMaps as dashboards and datasources

### Ingress Configuration
```yaml
ingress:
  enabled: false
```

**Settings Explained**:
- `enabled: false`: Does not create Ingress automatically
- Ingress is configured separately via `grafana-ingress.yaml`

### Alertmanager Configuration
```yaml
alertmanager:
  enabled: true
  alertmanagerSpec:
    resources:
      requests:
        memory: 64Mi
        cpu: 50m
      limits:
        memory: 128Mi
        cpu: 100m
```

**Settings Explained**:
- `enabled: true`: Deploys Alertmanager
- **Resources**: CPU and memory limits for Alertmanager pods

### Disabled Components
```yaml
kubeControllerManager:
  enabled: false

kubeScheduler:
  enabled: false

kubeProxy:
  enabled: false
```

**Settings Explained**:
- These components are disabled because they require cluster admin access
- They're not needed for application monitoring

### Prometheus Operator Configuration
```yaml
prometheusOperator:
  createCustomResource: true
  rbacEnable: true
```

**Settings Explained**:
- `createCustomResource: true`: Creates CRDs for ServiceMonitor, PrometheusRule, etc.
- `rbacEnable: true`: Enables RBAC for the operator

## How It Works
1. Helm installs the kube-prometheus-stack chart using these values
2. The chart creates:
   - Prometheus Operator (manages Prometheus instances)
   - Prometheus (scrapes metrics)
   - Grafana (visualization)
   - Alertmanager (handles alerts)
3. ServiceMonitors and PrometheusRules are automatically discovered
4. Grafana sidecar loads datasources and dashboards from ConfigMaps

## Resource Planning
Total resource requirements (approximate):
- **Prometheus**: 250m-1000m CPU, 512Mi-1.5Gi memory
- **Grafana**: 100m-200m CPU, 128Mi-256Mi memory
- **Alertmanager**: 50m-100m CPU, 64Mi-128Mi memory
- **Operator**: Additional resources for management

## Production Considerations
⚠️ **Important Changes for Production**:
- Change Grafana admin password
- Increase Prometheus retention (e.g., 30d)
- Adjust resource limits based on workload
- Enable persistent storage for Prometheus
- Configure Alertmanager with real notification channels
- Enable TLS/authentication for Grafana

## Usage
Deploy using Helm:
```bash
helm install observability prometheus-community/kube-prometheus-stack \
  -f prometheus-stack-values.yaml \
  -n observability \
  --create-namespace
```

## Customization
You can override these values:
- Add more resource limits
- Configure additional scrape configs
- Enable additional exporters
- Customize Grafana settings
- Configure Alertmanager routing


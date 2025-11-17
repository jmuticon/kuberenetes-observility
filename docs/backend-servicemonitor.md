# Backend ServiceMonitor

## Overview
The `backend-servicemonitor.yaml` file defines a Prometheus ServiceMonitor that tells Prometheus how to scrape metrics from the backend service.

## Key Components

### ServiceMonitor Resource
- **Name**: `backend-servicemonitor`
- **Namespace**: `observability` (where Prometheus runs)
- **Label**: `release: observability` (matches Prometheus operator selector)

### Selector Configuration
- **Selector**: Matches services with label `app: backend`
- **Namespace Selector**: Looks in the `app` namespace (where backend runs)

### Endpoint Configuration
- **Port**: `http` (matches the port name in backend-service)
- **Path**: `/metrics` (Prometheus metrics endpoint)
- **Interval**: 15 seconds (scraping frequency)

## How It Works
1. Prometheus Operator watches for ServiceMonitor resources
2. When this ServiceMonitor is created, Prometheus discovers it
3. Prometheus uses the selector to find the backend service in the `app` namespace
4. Prometheus scrapes metrics from `http://backend.app.svc.cluster.local:3000/metrics` every 15 seconds
5. Metrics are stored in Prometheus time-series database

## Requirements
- Requires Prometheus Operator to be installed
- Prometheus must have a selector that matches `release: observability` label
- The backend service must have the `app: backend` label
- The backend deployment must expose a `/metrics` endpoint

## Benefits
- Automatic service discovery for metrics
- No need to manually configure Prometheus scrape targets
- Works across namespaces
- Supports multiple endpoints per service


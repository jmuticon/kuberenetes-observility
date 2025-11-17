# Backend Deployment

## Overview
The `backend-deployment.yaml` file defines a Kubernetes Deployment that runs a Node.js backend application with Express, Prometheus metrics, MySQL connectivity, and OpenTelemetry tracing.

## Key Components

### Deployment Resource
- **Name**: `backend`
- **Namespace**: `app`
- **Replicas**: 1 (single instance)

### Container Configuration
- **Image**: `node:18-alpine` (lightweight Node.js runtime)
- **Port**: 3000 (HTTP server)

### Application Setup
The container runs a startup script that:
1. Installs bash and curl utilities
2. Creates the application directory
3. Initializes npm and installs dependencies:
   - `express`: Web framework
   - `prom-client`: Prometheus metrics client
   - `mysql2`: MySQL database driver
   - `@opentelemetry/sdk-node`: OpenTelemetry SDK
   - `@opentelemetry/auto-instrumentations-node`: Auto-instrumentation
   - `@opentelemetry/exporter-trace-otlp-http`: OTLP trace exporter

### Application Code
The deployment includes an inline Node.js server that:
- Creates an Express application
- Sets up CORS headers
- Defines a `/api/hello` endpoint that:
  - Connects to MySQL database
  - Executes a test query
  - Returns a JSON response
  - Records HTTP request duration metrics
- Exposes a `/metrics` endpoint for Prometheus scraping
- Listens on port 3000

### Environment Variables
- `MYSQL_HOST`: Database hostname (default: `mysql`)
- `MYSQL_USER`: Database user (default: `root`)
- `MYSQL_PASSWORD`: Database password (default: `example`)
- `MYSQL_DATABASE`: Database name (default: `demo`)
- `OTEL_EXPORTER_OTLP_ENDPOINT`: OpenTelemetry collector endpoint for traces

### Resource Limits
- **Requests**: 100m CPU, 128Mi memory
- **Limits**: 500m CPU, 512Mi memory

## How It Works
1. Kubernetes creates a Pod with the Node.js container
2. The container runs the startup script to install dependencies and create the server
3. The Express server starts and listens on port 3000
4. The application exposes metrics at `/metrics` for Prometheus
5. Traces are sent to the OpenTelemetry collector via OTLP HTTP

## Dependencies
- Requires MySQL service to be running (connects via `mysql` hostname)
- Requires OpenTelemetry collector in `observability` namespace
- ServiceMonitor should be configured to scrape `/metrics` endpoint


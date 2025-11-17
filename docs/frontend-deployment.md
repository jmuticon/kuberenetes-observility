# Frontend Deployment

## Overview
The `frontend-deployment.yaml` file defines a Kubernetes Deployment that runs an Nginx web server serving a simple HTML frontend application. It also includes a ConfigMap that contains the HTML content.

## Key Components

### Deployment Resource
- **Name**: `frontend`
- **Namespace**: `app`
- **Replicas**: 1

### Container Configuration
- **Image**: `nginx:stable-alpine` (lightweight Nginx server)
- **Port**: 80 (HTTP)

### Volume Mounts
- **Volume Name**: `site`
- **Mount Path**: `/usr/share/nginx/html` (Nginx default document root)
- **Source**: ConfigMap named `frontend-site`

### Resource Limits
- **Requests**: 50m CPU, 32Mi memory
- **Limits**: 100m CPU, 64Mi memory

### ConfigMap Resource
The file also defines a ConfigMap that contains:
- **Name**: `frontend-site`
- **Namespace**: `app`
- **Data**: `index.html` file with HTML content

### Frontend Application
The HTML page includes:
- A simple page structure
- JavaScript that makes an API call to `http://api.local/api/hello`
- Displays the API response in the page
- Error handling for failed API calls

## How It Works
1. Kubernetes creates a Pod with the Nginx container
2. The ConfigMap is mounted as a volume into the container
3. Nginx serves the HTML file from the mounted volume
4. When users access the frontend, the HTML page loads
5. The JavaScript code makes a fetch request to the backend API
6. The API response is displayed on the page

## Volume Configuration
- **Type**: ConfigMap volume
- **Mount**: Read-only access to the HTML file
- **Update**: Changes to ConfigMap require pod restart to take effect

## Dependencies
- Requires backend service to be accessible at `api.local` (via Ingress)
- The frontend is accessed via Ingress at `frontend.local`


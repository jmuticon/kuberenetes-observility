# MySQL Service

## Overview
The `mysql-service.yaml` file defines a Kubernetes Service that provides network access to the MySQL database pods. This is a headless service configuration.

## Key Components

### Service Resource
- **Name**: `mysql`
- **Namespace**: `app`
- **Type**: Headless Service (`clusterIP: None`)

### Service Selector
- **Selector**: `app: mysql`
- Matches pods with the label `app: mysql` from the MySQL deployment

### Port Configuration
- **Port**: 3306 (service port)
- **Target Port**: 3306 (container port)
- **Protocol**: TCP (default)
- **Name**: `mysql`

## Headless Service Explained
A headless service (`clusterIP: None`) means:
- No virtual IP is assigned to the service
- DNS returns the actual pod IP addresses directly
- Each pod gets its own DNS record
- Useful for stateful applications like databases

## How It Works
1. The Service selects pods with label `app: mysql`
2. When queried via DNS, it returns the pod's actual IP address
3. Clients connect directly to the pod IP
4. No load balancing occurs (since there's only one pod)

## DNS Resolution
When a pod queries `mysql.app.svc.cluster.local`:
- DNS returns the pod's IP address directly
- Short form: `mysql.app` or `mysql` (within same namespace)

## Use Cases
- Direct database connections without service proxy overhead
- StatefulSet integration (when scaling MySQL)
- Service discovery for database pods
- Used by backend application to connect to MySQL

## Connection String
Applications connect using:
- Host: `mysql` or `mysql.app.svc.cluster.local`
- Port: 3306
- Example: `mysql://root:example@mysql:3306/demo`


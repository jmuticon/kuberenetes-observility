# Kubernetes Guide - Plain English Explanation

A comprehensive guide to Kubernetes concepts, components, and keywords explained in simple terms. Perfect for beginners, yet deep enough for staff engineer interviews.

## Table of Contents

1. [What is Kubernetes?](#what-is-kubernetes)
2. [Core Concepts](#core-concepts)
3. [Kubernetes Components](#kubernetes-components)
4. [Resources and Objects](#resources-and-objects)
5. [Networking](#networking)
6. [Storage](#storage)
7. [Security](#security)
8. [Control Plane vs Data Plane](#control-plane-vs-data-plane)
9. [Common Keywords Explained](#common-keywords-explained)
10. [Interview-Ready Answers](#interview-ready-answers)

---

## What is Kubernetes?

**Simple Answer**: Kubernetes (often abbreviated as K8s) is like a smart manager for your applications. Imagine you run a restaurant:

- **Without Kubernetes**: You manually tell each chef what to cook, when to start, and handle everything yourself
- **With Kubernetes**: You have a manager who automatically assigns chefs, ensures enough staff are working, replaces anyone who gets sick, and handles all the logistics

**Technical Answer**: Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications across clusters of machines.

### Why Use Kubernetes?

1. **High Availability**: If one server fails, Kubernetes automatically moves your app to another
2. **Scaling**: Need more capacity? Kubernetes can add more instances automatically
3. **Self-Healing**: If an application crashes, Kubernetes restarts it
4. **Resource Efficiency**: Better utilization of your hardware
5. **Portability**: Run the same application on any cloud or on-premises

---

## Core Concepts

### Cluster

**What it is**: A cluster is a group of machines (nodes) that work together to run your applications.

**Real-world analogy**: Think of a cluster as a team of workers. Each worker (node) can do tasks, and they coordinate through a manager (control plane).

**In this project**: Minikube creates a single-node cluster on your local machine for development.

### Node

**What it is**: A node is a single machine (physical or virtual) in your Kubernetes cluster.

**Types**:
- **Control Plane Node** (Master): Manages the cluster, makes decisions, monitors health
- **Worker Node**: Runs your actual applications

**In this project**: Minikube creates one node that acts as both control plane and worker.

### Pod

**What it is**: A pod is the smallest deployable unit in Kubernetes. It's like a "wrapper" that contains one or more containers.

**Key points**:
- Pods are ephemeral (temporary) - they can be created and destroyed
- Each pod gets its own IP address
- Containers in the same pod share storage and network
- Pods are usually created by higher-level resources (Deployments, StatefulSets)

**Real-world analogy**: A pod is like a shipping container. It can hold one or more items (containers), and the container itself is temporary - once delivered, it might be reused or destroyed.

**Example from this project**:
```yaml
# A pod contains the backend container
containers:
  - name: backend
    image: node:18-alpine
```

### Container

**What it is**: A container is a lightweight, portable package that includes your application and everything it needs to run (code, runtime, libraries, dependencies).

**Think of it as**: A shipping container for software - it works the same way whether it's on a ship, train, or truck (your laptop, cloud, or server).

### Namespace

**What it is**: A namespace is like a virtual folder that organizes resources in your cluster. It provides logical separation and isolation.

**Why use namespaces**:
- Organization: Group related resources together
- Resource quotas: Limit CPU/memory per namespace
- Access control: Different teams can have different namespaces
- Environment separation: dev, staging, production

**In this project**:
- `observability`: All monitoring tools (Prometheus, Grafana, Loki, etc.)
- `app`: Application components (frontend, backend, database)

**Real-world analogy**: Like folders on your computer - you can have a "Work" folder and a "Personal" folder, each containing different files but on the same computer.

---

## Kubernetes Components

### Control Plane Components

These run on the control plane node and manage the cluster.

#### API Server

**What it is**: The front door to Kubernetes. All communication goes through the API server.

**What it does**:
- Validates requests
- Processes and stores cluster state
- Coordinates all operations

**Think of it as**: The receptionist at a company - everyone who wants to do something must go through them first.

**When you run**: `kubectl get pods`, you're talking to the API server.

#### etcd

**What it is**: A distributed key-value store that holds all cluster data.

**What it stores**:
- Current state of all resources
- Configuration data
- Cluster metadata

**Think of it as**: The company's central filing system - all important information is stored here.

**Key point**: etcd is the "source of truth" for your cluster.

#### Scheduler

**What it is**: Decides which node should run a new pod.

**What it considers**:
- Resource requirements (CPU, memory)
- Node capacity
- Affinity/anti-affinity rules
- Taints and tolerations

**Think of it as**: A smart assignment manager who looks at all available workers and assigns tasks to the best fit.

#### Controller Manager

**What it is**: Runs controllers that watch the cluster state and make changes to move from current state to desired state.

**Controllers include**:
- Deployment Controller: Ensures desired number of pods are running
- ReplicaSet Controller: Maintains correct number of replicas
- Node Controller: Monitors node health

**Think of it as**: Quality control managers who constantly check if things are as they should be and fix any issues.

#### Cloud Controller Manager

**What it is**: Links your cluster to your cloud provider's API (if running on cloud).

**What it does**: Handles cloud-specific tasks like load balancers, storage volumes, etc.

**Note**: Not used in Minikube (local development).

### Node Components

These run on every worker node.

#### kubelet

**What it is**: An agent that runs on each node and communicates with the control plane.

**What it does**:
- Receives pod specifications from API server
- Ensures containers in pods are running
- Reports node and pod status back to control plane
- Manages container lifecycle

**Think of it as**: The foreman on a construction site - they receive instructions from the main office and ensure workers (containers) are doing their jobs correctly.

#### kube-proxy

**What it is**: Maintains network rules on nodes that allow communication to pods.

**What it does**:
- Implements Services (load balancing, routing)
- Handles network policies
- Manages iptables or IPVS rules

**Think of it as**: A traffic director who ensures network packets reach the right destination.

#### Container Runtime

**What it is**: The software responsible for running containers (e.g., Docker, containerd, CRI-O).

**What it does**: Pulls images, starts/stops containers, manages container lifecycle.

**In this project**: Minikube uses Docker or containerd.

---

## Resources and Objects

### Deployment

**What it is**: A resource that manages a set of identical pods. It ensures a specified number of pods are running at all times.

**Key features**:
- Declarative: You describe desired state, Kubernetes makes it happen
- Self-healing: If a pod dies, Deployment creates a new one
- Rolling updates: Can update pods without downtime
- Rollback: Can revert to previous version

**Real-world analogy**: Like a manager who ensures you always have 3 cashiers working. If one goes on break, they immediately call in a replacement.

**Example from this project**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1  # Always keep 1 pod running
  selector:
    matchLabels:
      app: backend
  template:
    # Pod template goes here
```

**Interview answer**: "A Deployment is a declarative resource that manages pod replicas. It ensures the desired number of pods are running, handles rolling updates, and provides self-healing capabilities. When a pod fails, the Deployment controller detects it and creates a replacement."

### Service

**What it is**: An abstraction that provides a stable network endpoint to access pods. Since pods are ephemeral (they can be created/destroyed), Services provide a permanent way to reach your application.

**Why needed**: Pods have temporary IP addresses. If a pod dies and is recreated, it gets a new IP. Services provide a stable IP and DNS name.

**Types**:
1. **ClusterIP** (default): Internal access only, within cluster
2. **NodePort**: Exposes service on each node's IP at a static port
3. **LoadBalancer**: Exposes service externally via cloud provider's load balancer
4. **ExternalName**: Maps service to external DNS name

**Real-world analogy**: Like a phone number that stays the same even if you change your physical address. People call the number, and the phone company routes it to your current location.

**Example from this project**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend  # Routes to pods with this label
  ports:
    - port: 3000
      targetPort: 3000
```

**Interview answer**: "A Service provides stable networking for pods. Since pods are ephemeral and get new IPs when recreated, Services act as a permanent endpoint. They use label selectors to find matching pods and load balance traffic across them. ClusterIP is for internal access, NodePort exposes on node IPs, and LoadBalancer integrates with cloud load balancers."

### Ingress

**What it is**: An API object that manages external HTTP/HTTPS access to services. It provides routing, SSL termination, and load balancing.

**What it does**:
- Routes traffic based on hostname or path
- Terminates SSL/TLS
- Provides a single entry point for multiple services

**Requires**: An Ingress Controller (like NGINX, Traefik) to actually implement the Ingress rules.

**Real-world analogy**: Like a receptionist at a building who directs visitors to different offices based on who they're visiting.

**Example from this project**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
spec:
  rules:
    - host: api.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: backend
```

**Interview answer**: "Ingress provides HTTP/HTTPS routing to services. It's like a reverse proxy that routes traffic based on hostname or URL path. It requires an Ingress Controller (like NGINX) to actually implement the rules. Ingress is useful for exposing multiple services through a single IP with path-based or host-based routing."

### ConfigMap

**What it is**: Stores configuration data as key-value pairs. Allows you to decouple configuration from container images.

**Use cases**:
- Application configuration files
- Environment-specific settings
- Command-line arguments

**Real-world analogy**: Like a settings file that you can change without rebuilding your application.

**Example from this project**: Loki and Tempo configurations are stored in ConfigMaps.

**Interview answer**: "ConfigMaps store non-sensitive configuration data. They allow you to separate configuration from application code, making it easier to use the same image across different environments. ConfigMaps can be mounted as files or exposed as environment variables in pods."

### Secret

**What it is**: Similar to ConfigMap but for sensitive data (passwords, tokens, keys).

**Key features**:
- Base64 encoded (not encrypted by default)
- Should use external secret management in production
- Can be mounted as files or environment variables

**Real-world analogy**: Like a safe for storing sensitive documents.

**Best practice**: Use tools like Sealed Secrets, External Secrets Operator, or cloud provider secret managers for production.

**Interview answer**: "Secrets store sensitive data like passwords and API keys. They're base64 encoded but not encrypted by default, so you should use external secret management in production. Secrets can be mounted as files or environment variables, but be careful about logging and access control."

### DaemonSet

**What it is**: Ensures a copy of a pod runs on every node (or specific nodes).

**Use cases**:
- Log collection agents (like Promtail)
- Monitoring agents
- Network plugins
- Storage daemons

**Real-world analogy**: Like having a security guard at every entrance of a building.

**Example from this project**: Promtail runs as a DaemonSet to collect logs from every node.

**Interview answer**: "DaemonSets ensure a pod runs on every node in the cluster. They're perfect for node-level services like log collectors, monitoring agents, or network plugins. Unlike Deployments which maintain a specific number of replicas, DaemonSets automatically scale with the number of nodes."

### StatefulSet

**What it is**: Manages stateful applications that need stable network identities and persistent storage.

**Features**:
- Stable, predictable pod names (pod-0, pod-1, pod-2)
- Ordered deployment and scaling
- Stable storage (each pod gets its own PersistentVolume)
- Stable network identity (headless service)

**Use cases**: Databases, message queues, applications requiring stable identities.

**Real-world analogy**: Like numbered parking spots - each car (pod) always gets the same spot (identity and storage).

**Interview answer**: "StatefulSets are for stateful applications that need stable identities and persistent storage. Unlike Deployments where pods are interchangeable, StatefulSet pods have unique, stable names and identities. They're deployed and scaled in order, and each pod gets its own PersistentVolume. Perfect for databases and distributed systems that need stable network identities."

### Job

**What it is**: Creates one or more pods and ensures they complete successfully.

**Use cases**:
- Batch processing
- One-time tasks
- Database migrations
- Data processing

**Real-world analogy**: Like hiring temporary workers for a specific project - once the work is done, they leave.

**Interview answer**: "Jobs run pods to completion for batch or one-time tasks. They ensure a specified number of pods complete successfully. Useful for database migrations, batch processing, or any task that should run once and finish."

### CronJob

**What it is**: A Job that runs on a schedule (like cron).

**Use cases**:
- Scheduled backups
- Periodic data processing
- Cleanup tasks

**Real-world analogy**: Like a scheduled maintenance task that runs automatically.

**Interview answer**: "CronJobs are Jobs that run on a schedule using cron syntax. They're perfect for scheduled tasks like backups, data processing, or cleanup jobs. The schedule is defined using standard cron format."

### ReplicaSet

**What it is**: Ensures a specified number of pod replicas are running.

**Relationship to Deployment**: Deployments create and manage ReplicaSets. You typically don't create ReplicaSets directly - Deployments do it for you.

**Interview answer**: "ReplicaSets maintain a desired number of pod replicas. They're the underlying mechanism that Deployments use. When you create a Deployment, it creates a ReplicaSet, which then creates the pods. ReplicaSets ensure the correct number of pods are running and replace any that fail."

---

## Networking

### Pod Networking

**How it works**: Every pod gets its own IP address. Pods can communicate with each other directly using these IPs.

**Key points**:
- Pod IPs are routable within the cluster
- Containers in the same pod share the network namespace (same IP)
- Pod-to-pod communication doesn't require NAT

### Service Networking

**ClusterIP**: Internal virtual IP that load balances to pod IPs.

**How Services work**:
1. You create a Service with a selector (e.g., `app: backend`)
2. Service gets a stable ClusterIP (e.g., 10.96.0.1)
3. kube-proxy creates iptables/IPVS rules
4. Traffic to ClusterIP is forwarded to pod IPs
5. Service DNS: `<service-name>.<namespace>.svc.cluster.local`

**Example**: `backend.app.svc.cluster.local` resolves to the backend service in the app namespace.

### DNS

**What it is**: Kubernetes has a built-in DNS server (CoreDNS) that provides DNS records for Services and Pods.

**Naming**:
- Service: `<service-name>.<namespace>.svc.cluster.local`
- Pod: `<pod-ip>.<namespace>.pod.cluster.local`
- Short names work within the same namespace

**Example**: From a pod in the `app` namespace, you can reach the backend service as:
- `backend` (short name, same namespace)
- `backend.app` (service.namespace)
- `backend.app.svc.cluster.local` (FQDN)

### Network Policies

**What it is**: Rules that control traffic flow between pods.

**What it does**:
- Allow/deny traffic based on labels
- Ingress and egress rules
- Default deny or allow

**Use case**: Security isolation, micro-segmentation.

**Interview answer**: "Network Policies are like firewalls for pods. They control which pods can communicate with each other based on labels. You can define ingress (incoming) and egress (outgoing) rules. By default, all traffic is allowed, but you can create policies to restrict it for security."

---

## Storage

### Volume

**What it is**: A directory accessible to containers in a pod.

**Types**:
- **emptyDir**: Temporary storage, deleted when pod is deleted
- **hostPath**: Mounts a directory from the node (not portable)
- **PersistentVolume (PV)**: Cluster-wide storage resource
- **PersistentVolumeClaim (PVC)**: Request for storage by a user

### PersistentVolume (PV)

**What it is**: A cluster resource representing physical storage.

**Think of it as**: A physical hard drive in the cluster.

### PersistentVolumeClaim (PVC)

**What it is**: A request for storage by a user/application.

**Think of it as**: A request form saying "I need 10GB of storage."

**How it works**:
1. You create a PVC requesting storage
2. Kubernetes finds a matching PV
3. Binds them together
4. You mount the PVC in your pod

**Interview answer**: "PVs are cluster-wide storage resources, while PVCs are requests for storage. When you create a PVC, Kubernetes finds a matching PV and binds them. This abstraction allows applications to request storage without knowing the underlying storage details. The storage can be local, network-attached, or cloud storage."

### StorageClass

**What it is**: Defines different classes of storage (fast SSD, slow HDD, etc.) and how PVs are provisioned.

**Dynamic Provisioning**: When you create a PVC, Kubernetes can automatically create a PV using a StorageClass.

**Interview answer**: "StorageClasses define storage types and enable dynamic provisioning. When you create a PVC with a StorageClass, Kubernetes automatically provisions a PV. This is essential for cloud environments where storage can be provisioned on-demand."

---

## Security

### ServiceAccount

**What it is**: An identity for pods to authenticate with the Kubernetes API.

**Default**: Every namespace has a `default` ServiceAccount. Pods use it if none is specified.

**Use case**: Grant pods permissions to access the API server.

**Interview answer**: "ServiceAccounts provide identity for pods. They're used for API authentication and can be bound to RBAC roles to grant permissions. Each namespace has a default ServiceAccount, but you can create custom ones for different permission levels."

### RBAC (Role-Based Access Control)

**What it is**: Controls who can do what in the cluster.

**Components**:
- **Role**: Defines permissions within a namespace
- **ClusterRole**: Defines permissions cluster-wide
- **RoleBinding**: Grants a Role to users/groups/ServiceAccounts in a namespace
- **ClusterRoleBinding**: Grants a ClusterRole cluster-wide

**Example from this project**: Promtail needs permissions to read pods and nodes, so it has a ClusterRole and ClusterRoleBinding.

**Interview answer**: "RBAC controls access to Kubernetes resources. Roles define what actions can be performed (verbs like get, list, create) on which resources. RoleBindings connect Roles to subjects (users, groups, ServiceAccounts). ClusterRoles and ClusterRoleBindings work cluster-wide, while Roles and RoleBindings are namespace-scoped."

### SecurityContext

**What it is**: Settings that control security features for pods and containers.

**Settings include**:
- Run as non-root user
- Read-only root filesystem
- Capabilities to add/remove
- SELinux/AppArmor profiles

**Interview answer**: "SecurityContext defines security settings for pods and containers. Best practices include running as non-root, using read-only root filesystems, and dropping unnecessary capabilities. This follows the principle of least privilege."

---

## Control Plane vs Data Plane

### Control Plane

**What it is**: The "brain" of Kubernetes - makes decisions and manages the cluster.

**Components**: API Server, etcd, Scheduler, Controller Manager

**Responsibility**: "What should happen?"

### Data Plane

**What it is**: The "workers" that actually run your applications.

**Components**: kubelet, kube-proxy, container runtime

**Responsibility**: "Make it happen"

**Interview answer**: "The control plane is the decision-making layer - it decides what should run where and ensures desired state. The data plane is the execution layer - it actually runs the containers and handles networking. The control plane is stateless (state is in etcd), while the data plane is where your workloads run."

---

## Common Keywords Explained

### Label

**What it is**: Key-value pairs attached to objects for organization and selection.

**Example**: `app: backend`, `environment: production`

**Use case**: Selectors use labels to find resources.

**Interview answer**: "Labels are key-value pairs used for organizing and selecting resources. They're fundamental to how Kubernetes works - Services use label selectors to find pods, Deployments use them to manage pods. Labels should be meaningful and follow a consistent naming scheme."

### Selector

**What it is**: Criteria used to select resources based on labels.

**Types**:
- **MatchLabels**: Exact match
- **MatchExpressions**: More complex matching (In, NotIn, Exists, DoesNotExist)

**Example**: A Service with selector `app: backend` finds all pods with that label.

### Annotation

**What it is**: Key-value pairs for metadata (unlike labels, not used for selection).

**Use cases**: Build info, contact info, tooling metadata.

**Example**: `deployment.kubernetes.io/revision: "1"`

### Owner Reference

**What it is**: Links a resource to its parent (e.g., pod belongs to ReplicaSet).

**Purpose**: Cascading deletion - when parent is deleted, children are deleted too.

### Finalizer

**What it is**: A mechanism to ensure cleanup happens before resource deletion.

**How it works**: Resource stays in "Terminating" state until finalizer is removed.

**Use case**: Ensure external resources are cleaned up (e.g., cloud load balancers).

### Taint

**What it is**: A mark on a node that prevents pods from being scheduled (unless they tolerate it).

**Use case**: Reserve nodes for specific workloads, mark nodes as unschedulable.

**Interview answer**: "Taints mark nodes so pods won't be scheduled on them unless the pod has a matching toleration. Useful for dedicating nodes to specific workloads or marking nodes for maintenance."

### Toleration

**What it is**: Allows a pod to be scheduled on a tainted node.

**Interview answer**: "Tolerations allow pods to be scheduled on tainted nodes. They don't guarantee scheduling (other constraints still apply), but they allow it."

### Affinity

**What it is**: Rules that influence pod scheduling.

**Types**:
- **Node Affinity**: Prefer or require specific nodes
- **Pod Affinity**: Prefer or require pods to be co-located
- **Pod Anti-Affinity**: Prefer or require pods to be separated

**Interview answer**: "Affinity rules influence scheduling. Node affinity targets node properties, pod affinity/anti-affinity targets other pods. Useful for co-locating related pods or spreading pods across nodes for high availability."

### Resource Requests and Limits

**Requests**: Minimum resources guaranteed to a container.

**Limits**: Maximum resources a container can use.

**Interview answer**: "Requests are what the container needs - Kubernetes uses this for scheduling and guarantees this amount. Limits are the maximum - if exceeded, the container is throttled or killed. Requests should be based on typical usage, limits on worst-case scenarios."

### Liveness Probe

**What it is**: Checks if container is running. If fails, container is restarted.

**Use case**: Detect and recover from deadlocks or hung processes.

### Readiness Probe

**What it is**: Checks if container is ready to serve traffic. If fails, pod is removed from Service endpoints.

**Use case**: Don't send traffic until application is fully started.

**Interview answer**: "Liveness probes detect if a container is alive - failure results in restart. Readiness probes detect if a container is ready for traffic - failure removes the pod from Service endpoints. Readiness is about 'can I handle requests?', liveness is about 'am I running?'"

### Init Container

**What it is**: Containers that run before the main container(s) in a pod.

**Use case**: Setup tasks, waiting for dependencies, initialization scripts.

**Interview answer**: "Init containers run to completion before main containers start. They're useful for setup tasks, waiting for dependencies, or running initialization scripts. They run sequentially, and all must succeed for the pod to start."

### Sidecar

**What it is**: A container in the same pod as the main application container.

**Use case**: Log collection, monitoring agents, proxies.

**Example**: A logging sidecar that collects logs from the main container.

**Interview answer**: "A sidecar is an auxiliary container in the same pod as the main application. They share network and storage, making them perfect for log collection, monitoring, or proxy functionality. Common pattern in service mesh architectures."

---

## Interview-Ready Answers

### Q: Explain Kubernetes architecture

**Answer**: "Kubernetes has a control plane and data plane. The control plane includes the API server (entry point), etcd (state store), scheduler (assigns pods to nodes), and controller manager (ensures desired state). The data plane consists of worker nodes running kubelet (node agent), kube-proxy (networking), and container runtime. The control plane makes decisions, the data plane executes them."

### Q: How does Kubernetes ensure high availability?

**Answer**: "Multiple mechanisms: ReplicaSets ensure multiple pod replicas, Services provide load balancing across pods, Deployments handle rolling updates without downtime, liveness probes restart failed containers, and node failures trigger pod rescheduling. For control plane HA, you run multiple control plane nodes with etcd clustering."

### Q: Explain the pod lifecycle

**Answer**: "Pods go through: Pending (scheduling), Running (at least one container running), Succeeded (all containers terminated successfully), Failed (at least one container failed), and Unknown (node communication lost). The scheduler assigns pods to nodes, kubelet creates containers, and the container runtime actually runs them."

### Q: How do Deployments work?

**Answer**: "Deployments manage ReplicaSets, which manage pods. When you update a Deployment, it creates a new ReplicaSet and performs a rolling update - gradually replacing old pods with new ones. It supports rollback, can pause/resume updates, and maintains deployment history. The Deployment controller watches for changes and reconciles actual state with desired state."

### Q: Explain Service discovery in Kubernetes

**Answer**: "Kubernetes provides DNS-based service discovery. Services get DNS names in the format `<service>.<namespace>.svc.cluster.local`. CoreDNS provides the DNS service. When a pod queries a service name, DNS resolves to the Service's ClusterIP, and kube-proxy routes traffic to pod IPs using iptables or IPVS. Services use label selectors to find matching pods."

### Q: How does Kubernetes handle storage?

**Answer**: "Kubernetes abstracts storage through PersistentVolumes (cluster resources) and PersistentVolumeClaims (user requests). StorageClasses enable dynamic provisioning. When a pod needs storage, it claims a PVC, Kubernetes binds it to a PV, and the volume is mounted into the pod. This decouples applications from storage implementation details."

### Q: Explain RBAC in Kubernetes

**Answer**: "RBAC controls access through Roles (permissions) and RoleBindings (who gets those permissions). Roles define verbs (get, list, create, delete) on resources. ClusterRoles work cluster-wide, Roles are namespace-scoped. ServiceAccounts are identities for pods. Best practice is least privilege - grant minimum permissions needed."

### Q: How do you debug a pod that won't start?

**Answer**: "Check pod status with `kubectl describe pod` to see events and conditions. Check logs with `kubectl logs`. Common issues: image pull errors (check image name and registry access), resource constraints (check requests/limits), init container failures, or configuration errors. Use `kubectl get events` to see recent cluster events."

### Q: Explain rolling updates vs blue-green deployments

**Answer**: "Rolling updates gradually replace old pods with new ones - zero downtime but both versions run simultaneously. Blue-green maintains two complete environments and switches traffic - faster rollback but requires double resources. Kubernetes Deployments use rolling updates by default, but you can implement blue-green with multiple Deployments and Service switching."

### Q: How does Kubernetes handle secrets?

**Answer**: "Secrets store sensitive data as base64-encoded key-value pairs. They can be mounted as files or environment variables. Important: base64 is not encryption - use external secret management in production (Sealed Secrets, External Secrets Operator, or cloud provider solutions). Secrets should have restricted RBAC access."

### Q: Explain the difference between Deployments, StatefulSets, and DaemonSets

**Answer**: "Deployments are for stateless apps - pods are interchangeable, any pod can handle any request. StatefulSets are for stateful apps - pods have stable identities, ordered deployment, and persistent storage per pod. DaemonSets run one pod per node - perfect for node-level services like log collectors or monitoring agents."

### Q: How does network policy work?

**Answer**: "Network Policies are like firewalls for pods. They define ingress and egress rules based on pod selectors. By default, all traffic is allowed. You can create policies to deny all and then explicitly allow specific traffic. Network policies require a CNI plugin that supports them (like Calico). They're namespace-scoped but can reference pods in other namespaces."

### Q: Explain resource quotas and limits

**Answer**: "ResourceQuotas limit total resources in a namespace. LimitRanges set default/min/max for individual containers. Requests are guaranteed resources used for scheduling. Limits are maximums - exceeding causes throttling or termination. Proper resource management prevents resource starvation and enables better scheduling decisions."

---

## Key Takeaways

1. **Kubernetes is declarative**: You describe desired state, Kubernetes makes it happen
2. **Everything is an object**: Pods, Services, Deployments are all API objects
3. **Labels are fundamental**: Used for selection, organization, and management
4. **Controllers ensure desired state**: They watch and reconcile continuously
5. **Abstraction is key**: Kubernetes abstracts away infrastructure details
6. **Self-healing**: Automatic restarts, rescheduling, and recovery
7. **Scalability**: Horizontal scaling is built-in
8. **Portability**: Same manifests work across environments

---

## Further Reading

- **Official Kubernetes Documentation**: https://kubernetes.io/docs/
- **Kubernetes Concepts**: https://kubernetes.io/docs/concepts/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Project-Specific Examples

This project demonstrates many Kubernetes concepts:

- **Namespaces**: `observability` and `app` namespaces
- **Deployments**: Backend, frontend, MySQL, Loki, Tempo deployments
- **Services**: ClusterIP services for internal communication
- **Ingress**: Routes external traffic to services
- **ConfigMaps**: Loki, Tempo, OTel Collector configurations
- **DaemonSet**: Promtail for log collection
- **ServiceAccount & RBAC**: Promtail needs permissions to read pods
- **ServiceMonitor**: Custom Resource for Prometheus service discovery

Explore the YAML files in `k8s/` directory to see these concepts in practice!


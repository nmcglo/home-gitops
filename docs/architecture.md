# Architecture Overview

This document describes the architecture and design decisions for the home infrastructure.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Home Network                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Kubernetes Cluster (K3s)                 │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │   ArgoCD     │  │  AdGuard     │  │    Home      │     │ │
│  │  │   (GitOps)   │  │   Home       │  │  Assistant   │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐                        │ │
│  │  │  Minecraft   │  │     VPN      │                        │ │
│  │  │   Server     │  │              │                        │ │
│  │  └──────────────┘  └──────────────┘                        │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Docker Compose Services                        │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐                        │ │
│  │  │     Emby     │  │     Scan     │                        │ │
│  │  │    Server    │  │   Station    │                        │ │
│  │  └──────────────┘  └──────────────┘                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Storage Layer                            │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐                        │ │
│  │  │  Local Disk  │  │  NFS Server  │                        │ │
│  │  │  /mnt/data   │  │  nas-alpha│                        │ │
│  │  └──────────────┘  └──────────────┘                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Kubernetes Layer (K3s)

**Purpose**: Lightweight Kubernetes distribution for home lab use

**Why K3s**:
- Minimal resource footprint (~512MB RAM)
- Single binary installation
- Built-in features (LoadBalancer, storage, metrics)
- Production-ready but home-lab friendly

**Services Running**:
- AdGuard Home
- Home Assistant
- Minecraft Server

### Network Layer (MetalLB)

**Purpose**: LoadBalancer implementation for bare-metal Kubernetes

**Why MetalLB**:
- Provides LoadBalancer service type on bare-metal (non-cloud) clusters
- Automatic external IP assignment from configured pool
- Layer 2 (ARP) mode for simple home network integration
- No router configuration required for L2 mode

**How it Works**:
- Monitors for LoadBalancer services
- Assigns external IPs from configured pool (192.168.100.10-254)
- Announces IPs via ARP to make them accessible on the network
- Enables external access to Kubernetes services

**Services Using LoadBalancers**:
- AdGuard Home (DNS + Web UI)
- Home Assistant (Web UI)
- Minecraft Server (Game Port)

### GitOps Layer (ArgoCD)

**Purpose**: Automated deployment and synchronization from Git

**Why ArgoCD**:
- Declarative GitOps workflow
- Automatic sync from Git repository
- Visual dashboard for monitoring
- Self-healing capabilities
- Easy rollbacks

**Workflow**:
1. Changes committed to Git
2. ArgoCD detects changes
3. Automatically applies to cluster
4. Monitors health and syncs state

### Application Layer

#### Kubernetes Applications (Helm Charts)

All Kubernetes applications are packaged as Helm charts for:
- Consistent templating
- Easy configuration management
- Version control
- Reusability

**Structure**:
```
kubernetes/apps/<service>/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Configuration values
└── templates/          # Kubernetes manifests
    ├── namespace.yaml
    ├── deployment.yaml
    ├── service.yaml
    ├── pv.yaml
    └── pvc.yaml
```

#### Docker Compose Applications

Services that don't benefit from Kubernetes orchestration:

**Emby**:
- Requires host networking for device discovery
- Simple single-container deployment
- Direct hardware access beneficial

- Requires USB device access
- Simple automation tool
- No scaling needed

### Storage Layer

#### Local Storage (HostPath)

**Used for**: Most Kubernetes services

**Advantages**:
- Fast local disk access
- Simple configuration
- No network overhead

**Disadvantages**:
- Not portable across nodes
- No redundancy
- Manual backup required

**Services**:
- Home Assistant: `/mnt/data/home-assist`
- Minecraft: `/mnt/data/minecraft-mscs`
- Emby: `/mnt/data/emby`

#### NFS Storage

**Used for**: Services requiring network storage or shared access

**Advantages**:
- Centralized storage
- Easy backups on NAS
- Accessible from multiple nodes
- Potential RAID redundancy

**Services**:
- AdGuard Home: `nas-alpha.example.net:/volume1/adguardhome`

## Design Decisions

### Why Kubernetes for Home Lab?

**Pros**:
- Declarative configuration
- Self-healing
- Easy scaling
- GitOps workflow
- Industry-standard skills
- Service discovery
- Rolling updates

**Cons**:
- Higher complexity
- More resource overhead
- Learning curve

**Decision**: Benefits outweigh costs for learning and home automation use case.

### Why Helm Charts?

**Alternatives Considered**:
- Raw Kubernetes manifests
- Kustomize
- Custom templating

**Chosen**: Helm
- Industry standard
- Good templating
- Easy values management
- Reusable charts

### Why ArgoCD?

**Alternatives Considered**:
- Flux
- Manual kubectl apply
- Jenkins/CI pipelines

**Chosen**: ArgoCD
- Better UI than Flux
- Simpler than full CI/CD
- GitOps best practices
- Active community

### Service Placement (K8s vs Docker Compose)

**Kubernetes**:
- Services needing orchestration
- Services with multiple components
- Services benefiting from service discovery
- Services requiring easy updates/rollbacks

**Docker Compose**:
- Simple single-container services
- Services requiring specific host access
- Services with simpler requirements
- Services not needing scaling

## Network Architecture

### Service Exposure

**LoadBalancer Services** (via K3s built-in LoadBalancer):
- AdGuard Home: DNS (53), Web (80, 3000)
- Home Assistant: HTTP (80, 443)
- Minecraft: Game Server (25565)

**NodePort Services**:

**Host Network**:
- Emby: For DLNA and device discovery

### DNS and Ad-Blocking

AdGuard Home serves as:
- Primary DNS server for network
- Ad-blocking layer
- DNS-level privacy protection

## Security Considerations

### Network Security

- Services isolated in namespaces
- No public internet exposure (home network only)

### Secrets Management

- Kubernetes secrets for sensitive data
- Secrets not committed to Git
- Manual secret creation required

**Improvements Needed**:
- Consider sealed-secrets or external secrets operator
- Encrypt secrets at rest
- Implement secret rotation

### Container Security

- Non-root users where possible
- Security contexts defined
- Capabilities limited (except VPN which requires NET_ADMIN)

## Scalability

### Current State
- Single-node cluster
- All services replicas=1
- Local and NFS storage

### Future Scalability

**Multi-node**:
- Add worker nodes to K3s
- Use NFS for shared storage
- Keep services as single replica (home use case)

**High Availability**:
- Not critical for home lab
- Could implement for learning
- Would require 3+ nodes and shared storage

## Monitoring and Observability

### Current State
- ArgoCD dashboard for deployment status
- kubectl for pod logs
- Docker logs for compose services

### Future Improvements
- Prometheus for metrics
- Grafana for dashboards
- Loki for log aggregation
- Alert manager for notifications

## Backup Strategy

### What to Backup

**Critical**:
- Kubernetes secrets
- PersistentVolume data
- Docker environment files
- Git repository (already backed up via Git)

**Important**:
- Service configurations
- Application data

**Nice to Have**:
- Media files (large, can be re-added)

### Backup Approach

**Configuration**: `scripts/backup-configs.sh`
- Kubernetes resources
- Secrets (encrypted)
- Docker configs

**Data**:
- NFS server backups (via NAS)
- Local disk snapshots
- Manual backups as needed

## Disaster Recovery

### Recovery Steps

1. **Reinstall K3s**:
   ```bash
   ./scripts/setup-cluster.sh
   ```

2. **Restore Secrets**:
   ```bash
   kubectl apply -f backups/<timestamp>/secrets.yaml
   ```

3. **ArgoCD Auto-Sync**:
   - Applications automatically deployed from Git

4. **Restore Data**:
   - Restore PersistentVolume data from backups
   - Restore NFS data from NAS backups

**Recovery Time**: ~30 minutes (excluding large data restores)

## Future Enhancements

### Short Term
- Add monitoring (Prometheus/Grafana)
- Implement proper secrets management
- Set up automated backups

### Medium Term
- Add more services
- Implement ingress controller
- Add SSL/TLS certificates
- Set up external DNS

### Long Term
- Multi-node cluster
- Add CI/CD for custom images
- Implement service mesh (if needed)
- Add authentication layer (OAuth proxy)

## Repository Structure Rationale

```
infrastructure/    # Cluster setup - run once
kubernetes/        # K8s apps - managed by ArgoCD
  apps/           # Helm charts - deployment configs
  argocd-apps/    # ArgoCD apps - what to deploy
  core/           # Core resources - namespaces, storage
docker/           # Docker Compose - separate from K8s
images/           # Custom images - source of truth
scripts/          # Automation - operational tools
docs/             # Documentation - this file!
```

**Benefits**:
- Clear separation of concerns
- Easy to find configurations
- GitOps-friendly structure
- Scalable as infrastructure grows

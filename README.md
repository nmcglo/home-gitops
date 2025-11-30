# Home Infrastructure

A GitOps-based home infrastructure management system using K3s, ArgoCD, and Docker Compose.

## Overview

This repository contains all configuration and deployment code for managing home infrastructure services. Services are deployed using:

- **Kubernetes (K3s)**: Lightweight Kubernetes for containerized services
- **MetalLB**: LoadBalancer implementation for bare-metal Kubernetes
- **ArgoCD**: GitOps-based continuous deployment
- **Docker Compose**: For simpler services that don't need Kubernetes

## Repository Structure

```
home-infra/
├── docs/                    # Detailed documentation
├── infrastructure/          # Core infrastructure setup
│   ├── k3s/                # K3s cluster installation
│   ├── metallb/            # MetalLB LoadBalancer
│   ├── argocd/             # ArgoCD installation
│   └── storage/            # Storage configurations
├── kubernetes/              # Kubernetes deployments
│   ├── apps/               # Helm charts for all services
│   ├── argocd-apps/        # ArgoCD Application definitions
│   └── core/               # Core cluster resources
├── docker/                  # Docker Compose services
├── images/                  # Custom Docker images
└── scripts/                 # Automation scripts
```

## Quick Start

### Prerequisites

- Linux server (Ubuntu 20.04+ recommended)
- Minimum 4GB RAM, 2 CPU cores
- 50GB+ storage
- sudo/root access

### Initial Setup

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd home-infra
   ```

2. Run the setup script:
   ```bash
   sudo ./scripts/setup-cluster.sh
   ```

   **Optional**: Install with Longhorn distributed storage:
   ```bash
   sudo ./scripts/setup-cluster.sh --with-longhorn
   ```

3. This will:
   - Install K3s
   - Install MetalLB for LoadBalancer services
   - Optionally install Longhorn distributed storage
   - Deploy ArgoCD
   - Create all Kubernetes applications

4. Access ArgoCD to monitor deployments:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Visit https://localhost:8080

### Deploy Docker Services

1. Configure environment files:
   ```bash
   cp docker/emby/.env.example docker/emby/.env
   # Edit .env files as needed
   ```

2. Deploy services:
   ```bash
   ./scripts/deploy-docker-services.sh
   ```

## Services

### Kubernetes Services

| Service | Description | Port | Namespace |
|---------|-------------|------|-----------|
| **AdGuard Home** | DNS ad-blocking | 53, 80, 3000 | adguard |
| **Home Assistant** | Home automation | 80, 443 | home-assist |
| **Minecraft** | Minecraft server | 25565 | minecraft |
| **Error Pages** | Custom Traefik error pages | 8080 | default |
| **Monitoring** | Prometheus + Grafana | 9090, 3000 | monitoring |
| **Emby Exporter** | Emby metrics for Prometheus | 8080 | prometheus-exporters |
| **qBittorrent Exporter** | qBittorrent metrics | 8080 | prometheus-exporters |
| **Nginx Proxy Manager** | Reverse proxy with UI | 80, 443, 81 | nginx-proxy-manager |
| **Nginx Test** | Static test page | 80 | nginx-test |

### Docker Compose Services

| Service | Description | Port |
|---------|-------------|------|
| **Emby** | Media server | 8096, 8920 |

## Configuration

### Updating Service Configuration

1. Edit the Helm chart values in `kubernetes/apps/<service>/values.yaml`
2. Commit and push changes
3. ArgoCD will automatically sync (or sync manually via UI)

### Adding New Services

1. Create Helm chart in `kubernetes/apps/<service>/`
2. Create ArgoCD Application in `kubernetes/argocd-apps/<service>.yaml`
3. Commit and push
4. Apply the Application:
   ```bash
   kubectl apply -f kubernetes/argocd-apps/<service>.yaml
   ```

## Secrets Management

See individual service documentation for specific secret requirements.

## Storage

Services use different storage backends:

- **HostPath**: Local storage on cluster nodes (`/mnt/data/`)
- **NFS**: Network storage (`nas-alpha.example.net`)
- **Longhorn** (optional): Distributed block storage with replication and snapshots

### Longhorn Distributed Storage

For high availability and advanced features, install Longhorn:

```bash
# During cluster setup
sudo ./scripts/setup-cluster.sh --with-longhorn

# Or install separately
cd infrastructure/longhorn
./install.sh
```

**Benefits**:
- Automatic data replication across nodes
- Volume snapshots and backups
- Web UI for management
- Dynamic volume provisioning

**Access Longhorn UI**:
```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```
Visit: http://localhost:8000

See `infrastructure/longhorn/README.md` for detailed documentation.

Configure storage paths in each service's `values.yaml`.

## Backup

Backup configurations and secrets:

```bash
./scripts/backup-configs.sh
```

Backups are saved to `backups/<timestamp>/`

## Maintenance

### Updating Services

Services are automatically updated by ArgoCD when you push changes to git.

Manual sync:
```bash
argocd app sync <service-name>
```

### Viewing Logs

Kubernetes services:
```bash
kubectl logs -n <namespace> -l app=<service> -f
```

Docker services:
```bash
docker-compose -f docker/<service>/docker-compose.yaml logs -f
```

### Cluster Status

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get applications -n argocd
```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## Documentation

- [Setup Guide](docs/setup.md) - Detailed setup instructions
- [Services](docs/services.md) - Service-specific documentation
- [Architecture](docs/architecture.md) - System architecture overview

## Custom Images

Custom Docker images are built from `images/`:

```bash
cd images/minecraft-mscs
./build.sh
docker push nmcglo/minecraft-mscs:v0.1
```

## Contributing

When making changes:

1. Test locally first
2. Update documentation if needed
3. Commit with clear messages
4. Push to trigger ArgoCD sync

## License

Personal home infrastructure - use at your own risk.

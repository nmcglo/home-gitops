# Home Infrastructure

> [!NOTE]
> This is a sanitized, public fork of a private GitOps repository hosted on an on-prem Git remote. Secrets, internal hostnames/IPs, and environment-specific values have been scrubbed or replaced with placeholders. Some history/commits may be squashed or redacted - I'm also unlikely to update it frequently.

A GitOps-based home infrastructure management system using K3s, ArgoCD, and Docker Compose.

## Overview

This repository contains configuration and deployment code for managing home infrastructure services. Services are deployed using:

- **Kubernetes (K3s)**: Lightweight Kubernetes for containerized services
- **MetalLB**: LoadBalancer implementation for bare-metal Kubernetes
- **ArgoCD**: GitOps-based continuous deployment
- **Longhorn**: Optional distributed block storage
- **1Password Connect**: Secrets sourced from 1Password instead of committed to Git
- **Docker Compose**: For simpler services that don't need Kubernetes

## Repository Structure

```
home-gitops/
├── docs/                    # Detailed documentation
├── infrastructure/          # Core infrastructure setup
│   ├── k3s/                 # K3s cluster installation
│   ├── metallb/              # MetalLB LoadBalancer
│   ├── argocd/               # ArgoCD installation
│   ├── longhorn/             # Optional distributed storage
│   ├── storage/              # NFS/storage class configs
│   ├── 1password/            # 1Password Connect for secrets
│   ├── traefik-extra/        # Extra Traefik IngressRoutes
│   └── rockchip-npu-device-plugin/  # NPU device plugin (RK1/rockchip nodes)
├── kubernetes/
│   ├── apps/                 # Helm charts for all services
│   ├── argocd-apps/          # ArgoCD Application definitions
│   └── resources/            # Shared cluster resources (namespaces, etc.)
├── docker/                   # Docker Compose services
├── images/                   # Custom Docker images
├── scripts/                  # Automation scripts
├── skills/                   # Agent/automation skill definitions (e.g. scaffolding new apps)
├── utility/                  # One-off tooling, migration helpers, test manifests
└── to_port/                  # Manifests staged for migration into kubernetes/apps
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
   cd home-gitops
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

### Kubernetes Services (`kubernetes/apps/`)

Each service is a Helm chart deployed via an ArgoCD Application (`kubernetes/argocd-apps/`).

| Category | Services |
|----------|----------|
| **Networking / Ingress** | adguard-home, adguard-home-sync, nginx-proxy-manager, nginx-test, cloudflared-tunnel, error-pages |
| **Media** | audiobookshelf, tronbyt-server, emby-exporter, qbittorrent-exporter |
| **Home / Personal** | home-assistant, homepage, homelable, actual-budget, mealie |
| **AI / LLM** | openwebui, anythingllm, litellm, firecrawl, camofox, searxng, rk-llama.cpp-server, rockllama |
| **Dev Tooling** | onedev, jenkins, docker-registry |
| **Documents / Productivity** | paperless-ngx, stirling-pdf, overleaf |
| **Monitoring / Observability** | app-monitoring (Prometheus + Grafana), gatus |
| **Games** | minecraft |

### Docker Compose Services (`docker/`)

| Service | Description |
|---------|-------------|
| **emby** | Media server |
| **paperless-ngx** | Document management (compose-only variant) |
| **mealie** | Recipe manager (compose-only variant) |
| **scanner-pi** | Document scanning helper running on a Raspberry Pi |

## Infrastructure Components

| Component | Path | Purpose |
|-----------|------|---------|
| K3s | `infrastructure/k3s/` | Lightweight Kubernetes distribution |
| MetalLB | `infrastructure/metallb/` | Bare-metal LoadBalancer |
| ArgoCD | `infrastructure/argocd/` | GitOps continuous deployment |
| Longhorn | `infrastructure/longhorn/` | Optional distributed block storage |
| Storage | `infrastructure/storage/` | NFS and StorageClass configuration |
| 1Password Connect | `infrastructure/1password/` | Secrets management integration |
| Traefik Extra | `infrastructure/traefik-extra/` | Additional IngressRoutes for the built-in Traefik |
| Rockchip NPU Device Plugin | `infrastructure/rockchip-npu-device-plugin/` | Exposes RK1/rockchip NPU hardware to Kubernetes |

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

See `skills/new-k8s-app/SKILL.md` for a guided scaffold of the chart + Application boilerplate.

## Secrets Management

Secrets are sourced from 1Password via the Connect server in `infrastructure/1password/` rather than committed to Git. See individual service documentation for specific secret requirements.

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
docker compose -f docker/<service>/docker-compose.yaml logs -f
```

### Cluster Status

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get applications -n argocd
```

## Utility & Staging Areas

- `utility/` — one-off migration helpers, test manifests, and scratch tooling not part of the steady-state GitOps flow (e.g. `pvc-copy/`, `rk1dev/`, `1password-test/`).
- `to_port/` — manifests for services awaiting conversion into proper Helm charts under `kubernetes/apps/`.

## Documentation

- [Setup Guide](docs/setup.md) - Detailed setup instructions
- [Services](docs/services.md) - Service-specific documentation
- [Architecture](docs/architecture.md) - System architecture overview
- [Migration Guide](docs/migration-guide.md) - Notes on the move to the GitOps layout
- [Changelog](CHANGELOG.md) - Notable changes to this repository

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

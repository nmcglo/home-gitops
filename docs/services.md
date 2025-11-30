# Services Documentation

Detailed documentation for each service in the home infrastructure.

## Kubernetes Services

### AdGuard Home

**Purpose**: Network-wide DNS ad-blocking and privacy protection

**Deployment**: Helm chart with NFS storage
- **Namespace**: `adguard`
- **Ports**:
  - DNS: 53/UDP
  - HTTP: 80, 3000
- **Storage**: NFS on `nas-alpha.example.net:/volume1/adguardhome`

**Configuration**:
Edit `kubernetes/apps/adguard-home/values.yaml`:

```yaml
persistence:
  nfs:
    server: nas-alpha.example.net
    path: /volume1/adguardhome
```

**Access**: http://<cluster-ip>:3000

**Initial Setup**:
1. Visit web UI on first run
2. Set admin credentials
3. Configure DNS settings
4. Add filter lists

**Location**: `kubernetes/apps/adguard-home/`

---

### Home Assistant

**Purpose**: Home automation platform

**Deployment**: Helm chart with hostPath storage
- **Namespace**: `home-assist`
- **Ports**: 80, 443 (LoadBalancer)
- **Target Port**: 8123
- **Storage**: hostPath `/mnt/data/home-assist` (5Gi)

**Configuration**:
Edit `kubernetes/apps/home-assistant/values.yaml`:

```yaml
persistence:
  hostPath: /mnt/data/home-assist
  size: 5Gi
```

**Access**: http://<cluster-ip>

**Notes**:
- May have limited device discovery in Kubernetes
- Consider running on dedicated Raspberry Pi for better hardware integration
- Configuration stored in `/config` mount

**Location**: `kubernetes/apps/home-assistant/`

---

### Minecraft Server (MSCS)

**Purpose**: Minecraft server with MSCS management

**Deployment**: Helm chart with custom image
- **Namespace**: `minecraft`
- **Port**: 25565 (LoadBalancer)
- **Storage**: hostPath `/mnt/data/minecraft-mscs` (30Gi)
- **Image**: `nmcglo/minecraft-mscs:v0.1`

**Configuration**:
Edit `kubernetes/apps/minecraft/values.yaml`:

```yaml
image:
  repository: nmcglo/minecraft-mscs
  tag: v0.1

persistence:
  size: 30Gi
  hostPath: /mnt/data/minecraft-mscs
```

**Custom Image**:
Build from `images/minecraft-mscs/`:
```bash
cd images/minecraft-mscs
./build.sh v0.2
docker push nmcglo/minecraft-mscs:v0.2
```

**Server Management**:
Access container to use MSCS commands:
```bash
kubectl exec -it -n minecraft <pod-name> -- bash
mscs status
mscs start world
mscs backup world
```

**Location**: `kubernetes/apps/minecraft/`

---

### Error Pages

**Purpose**: Custom error pages for Traefik ingress controller

**Deployment**: Helm chart with Traefik integration
- **Namespace**: `default`
- **Port**: 8080 (ClusterIP)
- **Image**: `tarampampam/error-pages:2.20.0`

**Configuration**:
Edit `kubernetes/apps/error-pages/values.yaml`:

```yaml
# Error page template
template: app-down  # Available: ghost, l7-dark, hacker-terminal, cats, etc.

# Show error details
showDetails: true

# Traefik middleware for error handling
middleware:
  statusCodes:
    - "400-599"  # HTTP error codes to handle
```

**Available Templates**:
- `app-down` - Application down message (default)
- `ghost` - Friendly ghost theme
- `l7-dark` / `l7-light` - Modern minimalist design
- `hacker-terminal` - Terminal/matrix style
- `cats` - Cat pictures
- `lost-in-space` - Space theme
- `matrix` - Matrix movie theme
- `shuffle` - Random template on each error

Preview templates: https://error-pages.vercel.app/

**Using with Other Services**:
Add the middleware to any IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-service
spec:
  routes:
    - kind: Rule
      match: Host(`example.com`)
      services:
        - name: my-service
          port: 80
      middlewares:
        - name: error-pages-middleware  # Add this
```

**Access**: Error pages are displayed automatically when services return HTTP errors

**Notes**:
- Intercepts HTTP 400-599 errors across all Traefik routes
- Runs as non-root with read-only filesystem
- Lightweight: 16-32MB memory usage
- Multiple template options for different aesthetics

**Location**: `kubernetes/apps/error-pages/`

---

## Docker Compose Services

### Emby

**Purpose**: Media server for streaming personal media

**Deployment**: Docker Compose with host networking
- **Ports**: 8096 (HTTP), 8920 (HTTPS)
- **Storage**:
  - Config: `/mnt/data/emby/config`
  - Media: `/media/user/media/plexmedia`

**Configuration**:
Edit `docker/emby/.env`:

```env
UID=1000
GID=100
EMBY_CONFIG_PATH=/mnt/data/emby/config
EMBY_MEDIA_PATH=/media/user/media/plexmedia
```

**Deployment**:
```bash
cd docker/emby
docker-compose up -d
```

**Access**: http://<host-ip>:8096

**Notes**:
- Uses host networking for better device discovery
- Transcoding requires adequate CPU
- Hardware acceleration available on compatible systems

**Location**: `docker/emby/`

---

## Service Management

### Kubernetes Services

**View status**:
```bash
kubectl get pods -n <namespace>
kubectl get svc -n <namespace>
```

**View logs**:
```bash
kubectl logs -n <namespace> -l app=<service> -f
```

**Restart service**:
```bash
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

**Update configuration**:
1. Edit `kubernetes/apps/<service>/values.yaml`
2. Commit and push
3. ArgoCD auto-syncs (or manual sync)

### Docker Compose Services

**View status**:
```bash
docker ps
```

**View logs**:
```bash
docker-compose -f docker/<service>/docker-compose.yaml logs -f
```

**Restart service**:
```bash
docker-compose -f docker/<service>/docker-compose.yaml restart
```

**Update configuration**:
1. Edit `docker/<service>/.env` or `docker-compose.yaml`
2. Recreate container:
   ```bash
   docker-compose -f docker/<service>/docker-compose.yaml up -d
   ```

## Storage Paths

### Kubernetes Services
- AdGuard Home: NFS `nas-alpha.example.net:/volume1/adguardhome`
- Home Assistant: `/mnt/data/home-assist`
- Minecraft: `/mnt/data/minecraft-mscs`

### Docker Services
- Emby: `/mnt/data/emby/config`

## Backup Recommendations

**Critical data to backup**:
- Kubernetes secrets (via `scripts/backup-configs.sh`)
- Service configurations in persistent volumes
- Docker environment files
- Custom application data

**Suggested backup schedule**:
- Kubernetes configs: Daily
- Service data: Weekly
- Media files: As needed

## Monitoring

**Check service health**:
```bash
# Kubernetes
kubectl get pods --all-namespaces

# Docker
docker ps

# ArgoCD
kubectl get applications -n argocd
```

**Resource usage**:
```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2024

### Major Restructure - GitOps Migration

Complete repository restructure to follow GitOps best practices with ArgoCD.

### Added

#### Infrastructure
- **K3s setup scripts** (`infrastructure/k3s/`) - Automated K3s installation
- **MetalLB** (`infrastructure/metallb/`) - LoadBalancer for bare-metal Kubernetes
- **Longhorn** (`infrastructure/longhorn/`) - Optional distributed block storage with replication
- **ArgoCD installation** (`infrastructure/argocd/`) - GitOps deployment system
- **Storage configurations** (`infrastructure/storage/`) - NFS and storage class configs
- **Core resources** (`kubernetes/core/`) - Namespaces and storage classes

#### Kubernetes Applications (Helm Charts)
- **AdGuard Home** - Converted to Helm chart with NFS storage
- **Home Assistant** - New Helm chart with hostPath storage
- **Minecraft Server** - New Helm chart for MSCS deployment
- **Error Pages** - Custom error pages for Traefik with multiple templates
- **Monitoring Stack** - Prometheus and Grafana for metrics and dashboards
- **Emby Exporter** - Prometheus exporter for Emby media server metrics
- **qBittorrent Exporter** - Prometheus exporter for qBittorrent metrics
- **Nginx Proxy Manager** - Web-based reverse proxy with SSL management
- **Nginx Test** - Simple static test page for Traefik ingress testing

#### ArgoCD Applications
- Application CRDs for all services (`kubernetes/argocd-apps/`)
- Automated sync configuration
- Health monitoring

#### Docker Compose
- Restructured Emby deployment (`docker/emby/`)
- Environment file templates (`.env.example`)
- Service-specific READMEs

#### Custom Images
- Minecraft MSCS build scripts (`images/minecraft-mscs/`)
- Automated build scripts

#### Scripts
- `setup-cluster.sh` - Full cluster setup automation
- `deploy-docker-services.sh` - Docker Compose deployment
- `backup-configs.sh` - Configuration backup
- `cleanup-old-structure.sh` - Migration cleanup

#### Documentation
- Comprehensive main README
- Detailed setup guide (`docs/setup.md`)
- Service documentation (`docs/services.md`)
- Architecture overview (`docs/architecture.md`)
- Migration guide (`docs/migration-guide.md`)

### Changed

#### Directory Structure
- **Before**: Flat structure with service directories at root
- **After**: Organized hierarchy (infrastructure, kubernetes, docker, images, scripts, docs)

#### Deployment Method
- **Before**: Manual kubectl apply with raw manifests
- **After**: GitOps with ArgoCD and Helm charts

#### Configuration Management
- **Before**: Mixed approaches (raw YAML, docker-compose)
- **After**: Standardized Helm values and environment files

### Migration Path

From old structure:

### Benefits

1. **GitOps Workflow**: All changes tracked in Git with ArgoCD auto-sync
2. **Standardization**: Consistent Helm chart structure for all K8s services
3. **Automation**: One-command cluster setup and service deployment
4. **Documentation**: Comprehensive docs for setup, services, and architecture
5. **Maintainability**: Clear separation of concerns and easy to understand structure
6. **Scalability**: Easy to add new services following established patterns

### Breaking Changes

- **Deployment process changed**: Now uses ArgoCD instead of manual kubectl apply
- **Configuration location changed**: Helm values.yaml instead of hardcoded YAML
- **Git repository URL required**: Must be configured in ArgoCD Application CRDs

### Migration Notes

See `docs/migration-guide.md` for complete migration instructions.

Key migration steps:
1. Install infrastructure (K3s, ArgoCD)
2. Create required secrets
3. Deploy services via ArgoCD
4. Migrate Docker Compose services
5. Verify all services working
6. Clean up old structure

### Deprecated

- Old flat directory structure (to be removed after migration)
- Manual deployment scripts in old service directories
- Raw Kubernetes manifests (replaced with Helm charts)

### Removed

Nothing removed yet - cleanup pending migration verification.

### Security

- Secret management improved (not committed to Git)
- Security contexts defined for all deployments
- Capability management for privileged containers

### Fixed

- Standardized namespace naming across services
- Consistent storage configuration approach
- Proper templating with Helm (no hardcoded values)
- Documentation of all configuration options

## Future Improvements

### Planned
- [ ] Monitoring with Prometheus/Grafana
- [ ] Sealed Secrets or External Secrets Operator
- [ ] Automated backup scheduling
- [ ] Ingress controller with SSL/TLS
- [ ] CI/CD for custom images

### Under Consideration
- [ ] Multi-node cluster support
- [ ] Service mesh (Istio/Linkerd)
- [ ] External DNS
- [ ] Authentication proxy (OAuth2)
- [ ] Log aggregation (Loki)

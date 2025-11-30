# Migration Guide

Guide for migrating from the old directory structure to the new GitOps-based structure.

## Overview

The repository has been restructured to follow GitOps best practices with ArgoCD. This guide helps you migrate your running services to the new structure.

## What Changed

### Old Structure
```
home-infra/
├── adguard-home/
├── emby/
├── home-assistant/
├── minecraft-mscs/
└── microk8s-setup/
```

### New Structure
```
home-infra/
├── infrastructure/      # Cluster setup
├── kubernetes/         # K8s deployments
│   ├── apps/          # Helm charts
│   ├── argocd-apps/   # ArgoCD Application CRDs
│   └── core/          # Core resources
├── docker/            # Docker Compose services
├── images/            # Custom Docker images
├── scripts/           # Automation scripts
└── docs/              # Documentation
```

## Migration Steps

### 1. Review the New Structure

Familiarize yourself with the new organization:
- All Kubernetes apps are now Helm charts in `kubernetes/apps/`
- ArgoCD manages deployments via `kubernetes/argocd-apps/`
- Docker Compose services in `docker/`
- Custom images in `images/`

### 2. Verify Current Services

Before migrating, document your current service configurations:

```bash
# Kubernetes services
kubectl get all --all-namespaces

# Docker services
docker ps
```

Save any custom configurations you've made.

### 3. Install New Infrastructure

If starting fresh or on a new cluster:

```bash
sudo ./scripts/setup-cluster.sh
```

This installs K3s, ArgoCD, and deploys all services.

### 4. Migrate Secrets

Copy any other secrets from the old deployment:
```bash
# List existing secrets
kubectl get secrets -n <old-namespace>

# Export and recreate as needed
kubectl get secret <secret-name> -n <old-namespace> -o yaml > secret.yaml
# Edit namespace if needed
kubectl apply -f secret.yaml
```

### 5. Migrate Persistent Data

**Option A: In-Place Migration (Same Paths)**

If your PersistentVolume paths remain the same, no action needed. The new deployments will use the existing data.

**Option B: Copy Data to New Locations**

If paths changed, copy data:

```bash
# Example: Copy AdGuard Home data
sudo cp -r /old/path/adguardhome /volume1/adguardhome

# Update ownership if needed
sudo chown -R <user>:<group> /new/path
```

### 6. Update Custom Images (If Needed)

If you've made changes to custom images, rebuild and push:

```bash
# Minecraft MSCS
cd images/minecraft-mscs
./build.sh v0.2
docker push nmcglo/minecraft-mscs:v0.2

# Update values.yaml to use new tag
# Edit kubernetes/apps/minecraft/values.yaml
```

### 7. Deploy Services via ArgoCD

Deploy all services:

```bash
kubectl apply -f kubernetes/argocd-apps/
```

Or deploy individually:

```bash
kubectl apply -f kubernetes/argocd-apps/adguard-home.yaml
kubectl apply -f kubernetes/argocd-apps/home-assistant.yaml
# etc.
```

### 8. Verify Deployments

Monitor ArgoCD:

```bash
# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or via CLI
argocd app list
argocd app get <app-name>
```

Check pod status:

```bash
kubectl get pods --all-namespaces
```

### 9. Migrate Docker Compose Services

```bash
# Stop old services
docker-compose -f emby/docker-compose.yaml down

# Configure new services
cp docker/emby/.env.example docker/emby/.env

# Edit .env files with your paths
nano docker/emby/.env

# Deploy new services
./scripts/deploy-docker-services.sh
```

### 10. Update Git Remote (If Changed)

Update ArgoCD Application CRDs if your Git repo URL changed:

```bash
# Edit each file in kubernetes/argocd-apps/
# Update the repoURL field
nano kubernetes/argocd-apps/adguard-home.yaml
# Change: repoURL: https://github.com/your-username/home-infra.git
```

Then reapply:

```bash
kubectl apply -f kubernetes/argocd-apps/
```

### 11. Test Services

Verify each service is working:

**AdGuard Home**: http://<cluster-ip>:3000
**Home Assistant**: http://<cluster-ip>
**Minecraft**: Connect client to <cluster-ip>:25565
**Emby**: http://<host-ip>:8096

### 12. Cleanup Old Structure

Once everything is verified working:

```bash
./scripts/cleanup-old-structure.sh
```

This creates a backup before removing old directories.

## Rollback Plan

If you need to rollback:

### Kubernetes Services

```bash
# Delete ArgoCD applications
kubectl delete -f kubernetes/argocd-apps/

# Redeploy old manifests
kubectl apply -f old-structure-backup-<timestamp>/adguard-home/helm/adguard-home/
# etc.
```

### Docker Services

```bash
# Stop new services
docker-compose -f docker/emby/docker-compose.yaml down

# Start old services
docker-compose -f old-structure-backup-<timestamp>/emby/docker-compose.yaml up -d
```

## Customization

### Modifying Service Configuration

**Old Way**:
Edit deployment YAML → kubectl apply

**New Way**:
Edit Helm values → commit → push → ArgoCD auto-syncs

Example:

```bash
# Edit values
nano kubernetes/apps/minecraft/values.yaml

# Commit and push
git add kubernetes/apps/minecraft/values.yaml
git commit -m "Update Minecraft memory limits"
git push

# ArgoCD automatically syncs (or manual sync)
argocd app sync minecraft
```

### Adding New Services

1. Create Helm chart in `kubernetes/apps/<service>/`
2. Create ArgoCD Application in `kubernetes/argocd-apps/<service>.yaml`
3. Commit and push
4. Apply the Application: `kubectl apply -f kubernetes/argocd-apps/<service>.yaml`

## Benefits of New Structure

✅ **GitOps**: All changes tracked in Git
✅ **Automation**: ArgoCD handles deployments
✅ **Consistency**: Helm charts standardize deployments
✅ **Visibility**: Clear separation of concerns
✅ **Rollback**: Easy to revert via Git
✅ **Scalability**: Easy to add new services
✅ **Documentation**: Centralized docs

## Troubleshooting

### ArgoCD Application Not Syncing

```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Manual sync
argocd app sync <app-name>

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n <namespace> <pod-name>
```

### Storage Issues

```bash
# Check PVs and PVCs
kubectl get pv
kubectl get pvc --all-namespaces

# Describe for details
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name> -n <namespace>
```

### Secret Issues

```bash
# List secrets
kubectl get secrets -n <namespace>

# Verify secret content (base64 encoded)
kubectl get secret <secret-name> -n <namespace> -o yaml
```

## Support

For issues:
1. Check logs: `kubectl logs` or `docker logs`
2. Review documentation in `docs/`
3. Check ArgoCD UI for sync status
4. Verify secrets and storage configurations

## Next Steps

After migration:
1. Set up monitoring (Prometheus/Grafana)
2. Configure automated backups
3. Implement proper secrets management
4. Add more services as needed

#!/bin/bash
set -e

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "======================================"
echo "Backing up configurations"
echo "======================================"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""

# Backup Kubernetes secrets
echo "Backing up Kubernetes secrets..."
kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml"

# Backup PersistentVolumes
echo "Backing up PersistentVolumes..."
kubectl get pv -o yaml > "$BACKUP_DIR/pvs.yaml"

# Backup ArgoCD applications
echo "Backing up ArgoCD applications..."
kubectl get applications -n argocd -o yaml > "$BACKUP_DIR/argocd-apps.yaml"

# Backup Docker environment files
echo "Backing up Docker environment files..."
mkdir -p "$BACKUP_DIR/docker"
for service in docker/*; do
  if [ -f "$service/.env" ]; then
    cp "$service/.env" "$BACKUP_DIR/docker/$(basename $service).env"
  fi
done

echo ""
echo "======================================"
echo "Backup complete!"
echo "======================================"
echo ""
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "To restore:"
echo "  kubectl apply -f $BACKUP_DIR/secrets.yaml"
echo "  kubectl apply -f $BACKUP_DIR/pvs.yaml"

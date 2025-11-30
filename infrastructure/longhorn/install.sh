#!/bin/bash
set -e

echo "======================================"
echo "Installing Longhorn Storage"
echo "======================================"
echo ""

# Check for required dependencies
echo "Checking prerequisites..."

# Check if open-iscsi is installed (required for Longhorn)
if ! systemctl is-active --quiet iscsid 2>/dev/null; then
  echo "WARNING: open-iscsi service not running or not installed"
  echo "Longhorn requires open-iscsi. Installing..."

  # Detect OS and install accordingly
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y open-iscsi
    systemctl enable iscsid
    systemctl start iscsid
  elif command -v yum &> /dev/null; then
    yum install -y iscsi-initiator-utils
    systemctl enable iscsid
    systemctl start iscsid
  else
    echo "ERROR: Could not install open-iscsi automatically"
    echo "Please install open-iscsi/iscsi-initiator-utils manually and run this script again"
    exit 1
  fi
fi

# Check for NFSv4 client (optional but recommended)
if ! command -v mount.nfs4 &> /dev/null; then
  echo "INFO: NFS client not found (optional for Longhorn backup to NFS)"
  echo "To enable NFS backups, install: apt-get install nfs-common (Debian/Ubuntu)"
fi

echo "Prerequisites check complete!"
echo ""

# Longhorn version
LONGHORN_VERSION="v1.5.3"

# Install Longhorn via Helm (recommended) or kubectl
INSTALL_METHOD="${1:-helm}"

if [ "$INSTALL_METHOD" == "helm" ]; then
  echo "Installing Longhorn via Helm..."

  # Add Longhorn Helm repository
  helm repo add longhorn https://charts.longhorn.io
  helm repo update

  # Install or upgrade Longhorn
  if [ -f "values.yaml" ]; then
    echo "Using custom values.yaml..."
    helm upgrade --install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --create-namespace \
      --version ${LONGHORN_VERSION} \
      --values values.yaml
  else
    echo "Using default values..."
    helm upgrade --install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --create-namespace \
      --version ${LONGHORN_VERSION}
  fi

elif [ "$INSTALL_METHOD" == "kubectl" ]; then
  echo "Installing Longhorn via kubectl..."

  # Install Longhorn using kubectl
  kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${LONGHORN_VERSION}/deploy/longhorn.yaml

else
  echo "ERROR: Unknown install method: $INSTALL_METHOD"
  echo "Usage: $0 [helm|kubectl]"
  exit 1
fi

echo ""
echo "Waiting for Longhorn pods to be ready..."
kubectl wait --for=condition=ready pod \
  --selector=app=longhorn-manager \
  --namespace=longhorn-system \
  --timeout=300s

echo ""
echo "======================================"
echo "Longhorn installation complete!"
echo "======================================"
echo ""
echo "Access Longhorn UI:"
echo "  1. Port-forward:"
echo "     kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80"
echo "     Then visit: http://localhost:8000"
echo ""
echo "  2. Or create an Ingress/LoadBalancer service (see README.md)"
echo ""
echo "Check installation:"
echo "  kubectl get pods -n longhorn-system"
echo "  kubectl get storageclass"
echo ""
echo "The 'longhorn' StorageClass is now available for PVCs"

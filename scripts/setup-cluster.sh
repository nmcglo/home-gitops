#!/bin/bash
set -e

# Parse command line arguments
INSTALL_LONGHORN=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --with-longhorn)
      INSTALL_LONGHORN=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --with-longhorn    Install Longhorn distributed storage"
      echo "  --help, -h         Show this help message"
      echo ""
      echo "Example:"
      echo "  sudo $0 --with-longhorn"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo "======================================"
echo "Home Infrastructure Cluster Setup"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script requires sudo privileges for K3s installation."
  echo "Please run with sudo or as root."
  exit 1
fi

# Step 1: Install K3s
echo "Step 1: Installing K3s..."
cd infrastructure/k3s
./install.sh
cd ../..

# Wait for cluster to be ready
echo ""
echo "Waiting for cluster to stabilize..."
sleep 15

# Step 2: Install MetalLB (LoadBalancer for bare-metal)
echo ""
echo "Step 2: Installing MetalLB..."
cd infrastructure/metallb
./install.sh
cd ../..

# Step 3: Install Longhorn (optional)
if [ "$INSTALL_LONGHORN" = true ]; then
  echo ""
  echo "Step 3: Installing Longhorn distributed storage..."
  cd infrastructure/longhorn
  ./install.sh
  cd ../..
  NEXT_STEP=4
else
  echo ""
  echo "Step 3: Skipping Longhorn (use --with-longhorn to install)"
  NEXT_STEP=3
fi

# Step 4: Apply core resources
echo ""
echo "Step $((NEXT_STEP++)): Applying core resources..."
kubectl apply -f kubernetes/core/

# Step 5/6: Install ArgoCD
echo ""
echo "Step $((NEXT_STEP++)): Installing ArgoCD..."
cd infrastructure/argocd
./install.sh
cd ../..

# Step 6/7: Deploy applications via ArgoCD
echo ""
echo "Step $NEXT_STEP: Deploying applications..."
echo "Waiting for ArgoCD to be fully ready..."
sleep 10

echo "Creating ArgoCD applications..."
kubectl apply -f kubernetes/argocd-apps/

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Access ArgoCD UI to monitor deployments"
echo "3. Deploy Docker Compose services (see scripts/deploy-docker-services.sh)"
if [ "$INSTALL_LONGHORN" = true ]; then
  echo "4. Access Longhorn UI (see infrastructure/longhorn/README.md)"
fi
echo ""
echo "View cluster status:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo ""
echo "View ArgoCD applications:"
echo "  kubectl get applications -n argocd"
echo ""
if [ "$INSTALL_LONGHORN" = true ]; then
  echo "View Longhorn status:"
  echo "  kubectl get pods -n longhorn-system"
  echo "  kubectl get storageclass longhorn"
  echo ""
  echo "Access Longhorn UI:"
  echo "  kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80"
  echo "  Then visit: http://localhost:8000"
  echo ""
fi

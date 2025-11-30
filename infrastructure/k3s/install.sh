#!/bin/bash
set -e

echo "Installing K3s..."

# Install K3s with default options
# Customize this based on your needs
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644

echo "Waiting for K3s to be ready..."
sleep 10

# Verify installation
kubectl get nodes

echo "K3s installation complete!"
echo "To use kubectl without sudo, add yourself to the k3s group or copy the kubeconfig:"
echo "  sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
echo "  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"

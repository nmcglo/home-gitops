#!/bin/bash
set -e

echo "Installing MetalLB..."

# MetalLB version
METALLB_VERSION="v0.13.12"

# Install MetalLB via manifest
echo "Applying MetalLB manifest (${METALLB_VERSION})..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

echo "Waiting for MetalLB pods to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

echo "Applying MetalLB configuration..."
kubectl apply -f config.yaml

echo ""
echo "======================================"
echo "MetalLB installation complete!"
echo "======================================"
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspool -n metallb-system"
echo "  kubectl get l2advertisement -n metallb-system"
echo ""
echo "LoadBalancer services will now receive external IPs from the configured pool."

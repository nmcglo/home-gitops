#!/bin/bash
set -e

VAULT_NAME="${VAULT_NAME:-}"

echo "======================================"
echo "Installing 1Password Connect Server"
echo "======================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v op &> /dev/null; then
  echo "ERROR: 1Password CLI (op) is not installed."
  echo "Install it from: https://developer.1password.com/docs/cli/get-started/"
  exit 1
fi

if ! command -v helm &> /dev/null; then
  echo "ERROR: helm is not installed."
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "ERROR: kubectl is not installed."
  exit 1
fi

if ! op account list &> /dev/null; then
  echo "ERROR: Not signed in to 1Password CLI."
  echo "Run: op signin"
  exit 1
fi

echo "Prerequisites check complete!"
echo ""

# Configuration - override via environment variables
NAMESPACE="${NAMESPACE:-onepassword}"
SERVER_NAME="${SERVER_NAME:-k3s-connect}"
TOKEN_NAME="${TOKEN_NAME:-k3s-operator}"
CREDENTIALS_FILE="./1password-credentials.json"

# Create Connect server
echo "Creating 1Password Connect server: ${SERVER_NAME}..."
if [ -n "${VAULT_NAME:-}" ]; then
  op connect server create "${SERVER_NAME}" --vaults "${VAULT_NAME}"
else
  op connect server create "${SERVER_NAME}"
fi

if [ ! -f "${CREDENTIALS_FILE}" ]; then
  echo "ERROR: credentials file not generated at ${CREDENTIALS_FILE}"
  exit 1
fi

echo "Credentials file created: ${CREDENTIALS_FILE}"
echo ""

# Create access token
echo "Creating access token '${TOKEN_NAME}' for Connect server..."
if [ -n "${VAULT_NAME:-}" ]; then
  ACCESS_TOKEN=$(op connect token create "${TOKEN_NAME}" --server "${SERVER_NAME}" --vaults "${VAULT_NAME}")
else
  ACCESS_TOKEN=$(op connect token create "${TOKEN_NAME}" --server "${SERVER_NAME}")
fi

echo ""
echo "======================================"
echo "IMPORTANT: Save your access token now!"
echo "======================================"
echo "Access Token: ${ACCESS_TOKEN}"
echo ""
echo "This token will not be shown again."
echo "======================================"
echo ""
read -r -p "Press Enter once you have saved the token to continue..."
echo ""

# Deploy with Helm
echo "Adding 1Password Helm repository..."
helm repo add 1password https://1password.github.io/connect-helm-charts/
helm repo update

echo ""
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "======================================"
echo "Installation options:"
echo "======================================"
echo "1) Deploy Connect server only"
echo "2) Deploy Connect server + Kubernetes operator"
echo ""
read -r -p "Select option (1 or 2) [default: 1]: " INSTALL_OPTION
INSTALL_OPTION="${INSTALL_OPTION:-1}"
echo ""

# Deploy with Helm
echo "Deploying 1Password Connect..."
if [ "${INSTALL_OPTION}" = "2" ]; then
  echo "Installing with Kubernetes operator..."
  helm upgrade --install onepassword-connect 1password/connect \
    --namespace "${NAMESPACE}" \
    --set-file connect.credentials="${CREDENTIALS_FILE}" \
    --set operator.create=true \
    --set operator.token.value=${ACCESS_TOKEN}
else
  echo "Installing Connect server only..."
  helm upgrade --install onepassword-connect 1password/connect \
    --namespace "${NAMESPACE}" \
    --set-file connect.credentials="${CREDENTIALS_FILE}"
fi

echo ""
echo "Waiting for 1Password Connect to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/onepassword-connect \
  -n "${NAMESPACE}"

echo ""
echo "======================================"
echo "1Password Connect installation complete!"
echo "======================================"
echo ""
echo "Connect server is running in namespace: ${NAMESPACE}"
echo ""
echo "Verify installation:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get svc -n ${NAMESPACE}"
echo ""
echo "The Connect API is available within the cluster at:"
echo "  http://onepassword-connect.${NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "Next steps:"
echo "  - Create a Kubernetes secret with the token for applications:"
echo "    kubectl create secret generic onepassword-token \\"
echo "      --from-literal=token=<YOUR_TOKEN> \\"
echo "      --namespace <YOUR_APP_NAMESPACE>"
echo ""
echo "Clean up the local credentials file (already stored in the Helm release):"
echo "  rm ${CREDENTIALS_FILE}"
echo ""





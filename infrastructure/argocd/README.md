# ArgoCD Setup

ArgoCD is a GitOps continuous delivery tool for Kubernetes.

## Installation

### Method 1: Using the install script

```bash
cd infrastructure/argocd
./install.sh
```

### Method 2: Manual installation

1. Create namespace:
   ```bash
   kubectl create namespace argocd
   ```

2. Install ArgoCD:
   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. Get the initial admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

## Accessing ArgoCD

### Port Forward (recommended for initial setup)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit https://localhost:8080

### LoadBalancer (if configured)

If you have MetalLB or similar:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

## Deploying Applications

Once ArgoCD is installed, deploy all applications:

```bash
kubectl apply -f kubernetes/argocd-apps/
```

ArgoCD will automatically sync and deploy all applications from the git repository.

## CLI Installation

Install ArgoCD CLI for easier management:

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Login to ArgoCD:

```bash
argocd login localhost:8080
```

## Managing Applications

View applications:
```bash
argocd app list
```

Sync an application:
```bash
argocd app sync <app-name>
```

View application details:
```bash
argocd app get <app-name>
```

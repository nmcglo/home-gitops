# Setup Guide

Complete guide for setting up the home infrastructure from scratch.

## Prerequisites

### Hardware Requirements

- **Minimum**:
  - 4GB RAM
  - 2 CPU cores
  - 50GB storage

- **Recommended**:
  - 8GB+ RAM
  - 4+ CPU cores
  - 100GB+ SSD storage
  - NFS server for persistent storage

### Software Requirements

- Linux (Ubuntu 20.04+ or similar)
- Git
- Docker (for Docker Compose services)
- Internet connection
- sudo/root access

## Installation Steps

### 1. Prepare the Host

Update system packages:

```bash
sudo apt update && sudo apt upgrade -y
```

Install required packages:

```bash
sudo apt install -y curl wget git
```

### 2. Clone the Repository

```bash
git clone <your-repo-url>
cd home-infra
```

### 3. Prepare Storage Directories

Create local storage directories:

```bash
sudo mkdir -p /mnt/data/{adguardhome,home-assist,minecraft-mscs,emby}
sudo chmod 755 /mnt/data
```

If using NFS, mount your NFS shares:

```bash
# Example NFS mount
sudo mkdir -p /mnt/nas-alpha
sudo mount -t nfs nas-alpha.example.net:/volume1 /mnt/nas-alpha

# Add to /etc/fstab for persistence
echo "nas-alpha.example.net:/volume1 /mnt/nas-alpha nfs defaults 0 0" | sudo tee -a /etc/fstab
```

### 4. Configure MetalLB IP Range

Before running setup, configure the IP address range for LoadBalancer services.

Edit `infrastructure/metallb/config.yaml`:

```bash
nano infrastructure/metallb/config.yaml
```

Update the IP range to match your network:

```yaml
spec:
  addresses:
  - 192.168.100.10-192.168.100.254  # Change to your network range
```

**Important**:
- Use IPs on your local network that are NOT assigned by DHCP
- Reserve this range in your router/DHCP server to avoid conflicts
- The IPs must be in the same subnet as your Kubernetes nodes

Example for different networks:
- `192.168.1.240-192.168.1.250` (if your network is 192.168.1.0/24)
- `10.0.0.100-10.0.0.200` (if your network is 10.0.0.0/24)

### 5. Run Automated Setup

The automated setup script will:
- Install K3s
- Install MetalLB (LoadBalancer for bare-metal)
- Deploy core resources
- Install ArgoCD
- Create all applications

```bash
sudo ./scripts/setup-cluster.sh
```

This takes 5-10 minutes depending on your internet connection.

### 6. Configure kubectl Access

For non-root users:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

Or set the KUBECONFIG environment variable:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### 7. Access ArgoCD

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

Forward the ArgoCD server port:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open https://localhost:8080 in your browser:
- Username: `admin`
- Password: (from previous command)

### 8. Configure Secrets

Some services require secrets to be created manually.

### 9. Deploy Docker Compose Services

Configure environment files:

```bash
# Emby
cp docker/emby/.env.example docker/emby/.env
nano docker/emby/.env  # Edit paths as needed

```

Install Docker (if not already installed):

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

Install Docker Compose:

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Deploy services:

```bash
./scripts/deploy-docker-services.sh
```

## Verification

### Check Cluster Status

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

All pods should be in `Running` state.

### Check ArgoCD Applications

```bash
kubectl get applications -n argocd
```

All applications should show `Healthy` and `Synced`.

### Check Services

```bash
kubectl get svc --all-namespaces
```

LoadBalancer services should have external IPs assigned.

## Post-Installation

### 1. Change ArgoCD Password

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login and change password
argocd login localhost:8080
argocd account update-password
```

### 2. Configure Service Settings

Each service may require additional configuration:

- **AdGuard Home**: Visit http://<cluster-ip>:3000 for initial setup
- **Home Assistant**: Visit http://<cluster-ip> for initial setup
- **Emby**: Visit http://<host-ip>:8096 for initial setup

### 3. Set Up Backups

Schedule regular backups:

```bash
# Add to crontab
crontab -e

# Add line for daily backups at 2 AM
0 2 * * * /path/to/home-infra/scripts/backup-configs.sh
```

## Troubleshooting

### Pods Not Starting

Check pod logs:
```bash
kubectl logs -n <namespace> <pod-name>
```

Check events:
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Storage Issues

Verify directories exist and have correct permissions:
```bash
ls -la /mnt/data/
```

Check PersistentVolumes:
```bash
kubectl get pv
kubectl describe pv <pv-name>
```

### ArgoCD Sync Issues

Check application status:
```bash
kubectl describe application <app-name> -n argocd
```

Manual sync:
```bash
argocd app sync <app-name>
```

## Next Steps

- Review [Services Documentation](services.md) for service-specific configuration
- Set up monitoring and alerting
- Configure backups for persistent data
- Review [Architecture](architecture.md) to understand the system

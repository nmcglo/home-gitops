# Longhorn - Distributed Block Storage for Kubernetes

Longhorn is a lightweight, reliable, and easy-to-use distributed block storage system for Kubernetes, designed for cloud-native storage.

## Features

- **Distributed Storage**: Automatically replicates data across nodes
- **Snapshots & Backups**: Built-in snapshot and backup functionality
- **Disaster Recovery**: Restore from backups, cross-cluster recovery
- **Web UI**: Easy management via web interface
- **StorageClass**: Seamless integration with Kubernetes PVCs
- **Volume Cloning**: Clone volumes for testing or backup
- **Recurring Backups**: Automated backup schedules

## Prerequisites

### System Requirements

**Per Node**:
- 4GB+ RAM (8GB+ recommended)
- 10GB+ free disk space for Longhorn storage
- Linux kernel 5.8+ (for better performance)

**Software Requirements**:
- `open-iscsi` or `iscsiadm` installed on all nodes
- `nfs-common` (optional, for NFS backups)
- `cryptsetup` (optional, for encryption)

### Pre-Installation

The installation script will check and install `open-iscsi` automatically, but you can install manually:

**Debian/Ubuntu**:
```bash
sudo apt-get update
sudo apt-get install -y open-iscsi nfs-common
sudo systemctl enable iscsid
sudo systemctl start iscsid
```

**RHEL/CentOS**:
```bash
sudo yum install -y iscsi-initiator-utils nfs-utils
sudo systemctl enable iscsid
sudo systemctl start iscsid
```

## Installation

### Automated Installation

The easiest way to install Longhorn:

```bash
cd infrastructure/longhorn
./install.sh
```

This will:
1. Check prerequisites
2. Install open-iscsi if needed
3. Install Longhorn via Helm
4. Wait for pods to be ready
5. Verify the StorageClass is created

### Manual Installation Options

**Via Helm** (recommended):
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --values values.yaml
```

**Via kubectl**:
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml
```

### Custom Installation

To customize the installation, edit `values.yaml` before running install.sh:

```bash
nano values.yaml
./install.sh
```

## Configuration

### Storage Location

By default, Longhorn stores data in `/var/lib/longhorn` on each node.

To change this, edit `values.yaml`:
```yaml
persistence:
  defaultDataPath: /mnt/longhorn-storage  # Your custom path
```

Ensure the path exists on all nodes:
```bash
sudo mkdir -p /mnt/longhorn-storage
```

### Replica Count

Default is 2 replicas for high availability. Adjust based on your cluster size:

```yaml
persistence:
  defaultReplicaCount: 2  # 2-3 for home lab
```

**Recommendations**:
- 1 replica: Single node or testing (no redundancy)
- 2 replicas: 2-3 node clusters (basic redundancy)
- 3 replicas: 3+ node clusters (high availability)

### Resource Limits

The default values.yaml includes sensible limits for home labs. Adjust if needed:

```yaml
longhornManager:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
```

## Accessing the UI

### Port Forward (Quick Access)

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

Then visit: http://localhost:8000

### LoadBalancer Service

Edit `values.yaml`:
```yaml
service:
  ui:
    type: LoadBalancer
```

Upgrade Longhorn:
```bash
helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --values values.yaml
```

Get the external IP:
```bash
kubectl get svc -n longhorn-system longhorn-frontend
```

### Traefik Ingress

Create an IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: longhorn
  namespace: longhorn-system
spec:
  entryPoints:
    - web
  routes:
    - kind: Rule
      match: Host(`longhorn.local`)
      services:
        - name: longhorn-frontend
          port: 80
```

Add to /etc/hosts or configure DNS:
```
<cluster-ip> longhorn.local
```

## Usage

### Creating Volumes with Longhorn

Longhorn automatically creates a StorageClass named `longhorn`.

**Option 1: Use in PVC**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

**Option 2: Set as Default StorageClass**:
```bash
kubectl patch storageclass longhorn \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Then PVCs without a storageClassName will use Longhorn automatically.

### Converting Existing Services

To migrate a service from hostPath to Longhorn:

1. **Check current PVC**:
   ```bash
   kubectl get pvc -n <namespace>
   ```

2. **Backup data** (if important)

3. **Edit Helm values** to use Longhorn:
   ```yaml
   persistence:
     storageClass: longhorn
   ```

4. **Delete old PV/PVC** and redeploy

5. **Restore data** from backup if needed

### Volume Snapshots

Create snapshots via the Longhorn UI or kubectl:

```bash
# Via UI: Select volume → Take Snapshot

# Via kubectl (requires VolumeSnapshot CRD)
kubectl create -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
spec:
  volumeSnapshotClassName: longhorn
  source:
    persistentVolumeClaimName: my-pvc
EOF
```

### Backups to NFS

Configure NFS backup target in `values.yaml`:

```yaml
defaultSettings:
  backupTarget: "nfs://nfs-server:/backup/longhorn"
```

Or configure via UI:
1. Settings → General → Backup Target
2. Enter: `nfs://nfs-server:/backup/longhorn`
3. Save

Then create backups:
- Via UI: Select volume → Create Backup
- Backups are incremental and compressed

## Monitoring

### Check Longhorn Status

```bash
# All Longhorn pods
kubectl get pods -n longhorn-system

# Longhorn nodes
kubectl get nodes -n longhorn-system

# Volumes
kubectl get volumes -n longhorn-system

# StorageClass
kubectl get storageclass longhorn
```

### Disk Usage

Monitor via Longhorn UI or kubectl:

```bash
kubectl get node -n longhorn-system <node-name> -o yaml
```

Look for disk usage under status.

## Troubleshooting

### Pods Stuck in Pending

**Cause**: Insufficient resources or scheduling issues

**Solution**:
```bash
# Check events
kubectl describe pod <pod-name> -n longhorn-system

# Check node resources
kubectl top nodes

# Check disk space on nodes
df -h /var/lib/longhorn
```

### Volume Attachment Issues

**Cause**: iSCSI daemon not running

**Solution**:
```bash
# Check iscsid on all nodes
sudo systemctl status iscsid

# Restart if needed
sudo systemctl restart iscsid
```

### Degraded Volumes

**Cause**: Node failure or disk issues

**Solution**:
1. Check Longhorn UI for volume status
2. Identify failed replicas
3. Longhorn will auto-rebuild on healthy nodes
4. Manual intervention via UI if needed

### Performance Issues

**Symptoms**: Slow I/O, high latency

**Solutions**:
1. **Check disk performance** on nodes:
   ```bash
   sudo fio --name=random-write --ioengine=libaio --rw=randwrite \
     --bs=4k --size=1G --numjobs=1 --iodepth=32 --runtime=60 \
     --filename=/var/lib/longhorn/test
   ```

2. **Adjust replica count** (fewer = faster):
   ```yaml
   persistence:
     defaultReplicaCount: 1  # For testing only
   ```

3. **Use local storage** for cache-heavy workloads

4. **Enable node selector** to use SSD nodes:
   ```yaml
   nodeSelector:
     disktype: ssd
   ```

## Uninstallation

To remove Longhorn:

```bash
# Delete all Longhorn volumes first
kubectl delete volumesnapshotclass longhorn
kubectl delete volumesnapshots --all

# Uninstall via Helm
helm uninstall longhorn -n longhorn-system

# Or via kubectl
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml

# Clean up namespace
kubectl delete namespace longhorn-system

# Clean up data on nodes (WARNING: destroys all Longhorn data)
sudo rm -rf /var/lib/longhorn
```

## Best Practices

### For Home Labs

1. **Start with 2 replicas** for basic redundancy
2. **Use separate disk** for Longhorn if possible (not root filesystem)
3. **Enable automatic backups** to NFS or S3
4. **Monitor disk space** regularly
5. **Test recovery** procedures

### Storage Paths

Recommended storage locations:
- ✅ `/var/lib/longhorn` (default, easy)
- ✅ `/mnt/longhorn` (separate mount)
- ✅ `/data/longhorn` (dedicated disk)
- ❌ Avoid network mounts (NFS, CIFS)

### Backup Strategy

1. **Regular snapshots** (hourly/daily)
2. **Backups to external storage** (weekly)
3. **Test restores** periodically
4. **Document recovery procedures**

## Integration with Home Infrastructure

### Using with Existing Apps

Update Helm values to use Longhorn storage:

**Example - Grafana**:
```yaml
persistence:
  enabled: true
  storageClass: longhorn
  size: 10Gi
```

**Example - Prometheus**:
```yaml
persistence:
  enabled: true
  storageClass: longhorn
  size: 50Gi
```

### Migration from hostPath

1. **Create Longhorn PVC** with same size
2. **Mount both volumes** in a migration pod
3. **Copy data** from hostPath to Longhorn
4. **Update deployment** to use Longhorn
5. **Delete old hostPath** volume

## Advanced Features

### Volume Encryption

Enable encryption for sensitive data:

1. Create encryption secret
2. Set in volume parameters
3. Automatic encryption/decryption

### DR Volumes

Cross-cluster disaster recovery:

1. Configure backup target (S3 or NFS)
2. Create backups in cluster A
3. Restore as DR volume in cluster B
4. Activate when needed

### ReadWriteMany (RWX)

Longhorn supports RWX with NFS provisioner:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rwx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

## References

- [Longhorn Official Documentation](https://longhorn.io/docs/)
- [Longhorn GitHub](https://github.com/longhorn/longhorn)
- [Best Practices](https://longhorn.io/docs/1.5.3/best-practices/)
- [Troubleshooting Guide](https://longhorn.io/docs/1.5.3/troubleshooting/)

# MetalLB - LoadBalancer for Bare-Metal Kubernetes

MetalLB provides LoadBalancer capabilities for bare-metal Kubernetes clusters, allowing services to receive external IP addresses.

## Overview

In cloud environments, Kubernetes LoadBalancer services automatically get external IPs. On bare-metal (like home labs), MetalLB fills this gap by:

- Assigning external IPs from a configured pool
- Announcing those IPs on your network (via L2/ARP or BGP)
- Enabling external access to your services

## Installation

### Automated Installation

Run the installation script:

```bash
cd infrastructure/metallb
./install.sh
```

This will:
1. Install MetalLB v0.13.12
2. Wait for pods to be ready
3. Apply the configuration (IP pool and L2 advertisement)

### Manual Installation

1. Install MetalLB:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
   ```

2. Wait for MetalLB to be ready:
   ```bash
   kubectl wait --namespace metallb-system \
     --for=condition=ready pod \
     --selector=app=metallb \
     --timeout=90s
   ```

3. Apply configuration:
   ```bash
   kubectl apply -f config.yaml
   ```

## Configuration

### IP Address Pool

The IP address pool defines which IPs MetalLB can assign to LoadBalancer services.

**Current configuration** (edit `config.yaml`):
```yaml
addresses:
- 192.168.100.10-192.168.100.254
```

**Important**:
- These IPs must be on your network but NOT used by DHCP
- Reserve this range in your router/DHCP server
- IPs must be in the same subnet as your Kubernetes nodes

### L2 Advertisement

L2 mode uses ARP to announce IPs on the local network. This is the simplest mode and works well for home labs.

**Advantages**:
- Simple configuration
- Works on any network
- No router configuration needed

**Limitations**:
- All traffic goes through one node (no load balancing)
- Limited to local network (no routing across subnets)

## Verification

Check MetalLB is running:

```bash
# Check pods
kubectl get pods -n metallb-system

# Check IP address pool
kubectl get ipaddresspool -n metallb-system

# Check L2 advertisement
kubectl get l2advertisement -n metallb-system
```

Expected output:
```
NAME           READY   STATUS    RESTARTS   AGE
controller-xxx 1/1     Running   0          1m
speaker-xxx    1/1     Running   0          1m
```

## Usage

Once MetalLB is installed, LoadBalancer services automatically get external IPs:

```bash
# Check services with external IPs
kubectl get svc --all-namespaces | grep LoadBalancer
```

Example output:
```
adguard        adguard-home-service       LoadBalancer   10.43.x.x    192.168.100.10   53:30053/UDP,80:30080/TCP
home-assist    home-assistant-service     LoadBalancer   10.43.x.x    192.168.100.11   80:30081/TCP,443:30443/TCP
```

## Customization

### Changing IP Range

Edit `config.yaml` and update the addresses:

```yaml
spec:
  addresses:
  - 192.168.1.240-192.168.1.250  # Your IP range
```

Apply changes:
```bash
kubectl apply -f config.yaml
```

### Multiple IP Pools

You can create multiple pools for different purposes:

```yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.100.10-192.168.100.100
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: development-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.100.200-192.168.100.254
```

Then specify which pool to use in your service:

```yaml
metadata:
  annotations:
    metallb.universe.tf/address-pool: production-pool
```

### Requesting Specific IPs

Request a specific IP for a service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.100.50  # Deprecated but still works
  # Or use annotation:
  # annotations:
  #   metallb.universe.tf/loadBalancerIPs: 192.168.100.50
```

## Troubleshooting

### Service Stuck in Pending

If a LoadBalancer service shows `<pending>` for EXTERNAL-IP:

1. Check MetalLB pods are running:
   ```bash
   kubectl get pods -n metallb-system
   ```

2. Check MetalLB logs:
   ```bash
   kubectl logs -n metallb-system -l app=metallb
   ```

3. Verify configuration is applied:
   ```bash
   kubectl get ipaddresspool -n metallb-system
   ```

4. Check for IP exhaustion:
   ```bash
   kubectl get svc --all-namespaces | grep LoadBalancer
   ```
   If all IPs in your pool are assigned, expand the range.

### Can't Access Service from Network

1. Verify IP is assigned:
   ```bash
   kubectl get svc <service-name> -n <namespace>
   ```

2. Ping the external IP from another machine:
   ```bash
   ping 192.168.100.10
   ```

3. Check firewall rules on Kubernetes nodes

4. Verify the IP is in your network's subnet

### ARP Not Working

If L2 advertisement isn't working:

1. Check speaker pods are running on all nodes:
   ```bash
   kubectl get pods -n metallb-system -o wide
   ```

2. Verify L2Advertisement is configured:
   ```bash
   kubectl describe l2advertisement -n metallb-system
   ```

3. Check network interface (some networks block ARP)

## BGP Mode (Advanced)

For more advanced setups, MetalLB supports BGP mode. This requires router configuration but provides:
- True load balancing across nodes
- Routing across subnets
- Better failover

See [MetalLB BGP documentation](https://metallb.universe.tf/configuration/) for details.

## Integration with Home Infrastructure

MetalLB is automatically installed by `scripts/setup-cluster.sh`.

Services using LoadBalancer type:
- **AdGuard Home**: DNS and web interface
- **Home Assistant**: Web interface
- **Minecraft**: Game server

All these services will automatically receive external IPs from the MetalLB pool.

## References

- [MetalLB Official Documentation](https://metallb.universe.tf/)
- [MetalLB GitHub](https://github.com/metallb/metallb)
- [Kubernetes Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

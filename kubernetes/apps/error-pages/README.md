# Traefik Error Pages

Custom error pages for Traefik ingress controller using [tarampampam/error-pages](https://github.com/tarampampam/error-pages).

## Overview

This service provides beautiful, customizable error pages for HTTP errors (400-599) served through Traefik. When a service returns an error, Traefik will display a custom error page instead of the default browser error.

## Features

- Multiple error page templates (ghost, l7-light, l7-dark, app-down, etc.)
- Automatic error handling for HTTP 400-599 status codes
- Lightweight container (16-32MB memory)
- Security hardened (runs as non-root, read-only filesystem)

## Configuration

### Error Page Template

Choose from available templates by editing `values.yaml`:

```yaml
template: app-down  # Default template
```

**Available templates:**
- `ghost` - Friendly ghost theme
- `l7-light` / `l7-dark` - Modern minimalist design
- `noise` - Glitch/static effect
- `hacker-terminal` - Terminal/matrix style
- `cats` - Cat pictures (because internet)
- `lost-in-space` - Space theme
- `app-down` - Application down message
- `connection` - Connection error theme
- `matrix` - Matrix movie theme
- `shuffle` - Random template on each error

Preview templates at: https://error-pages.vercel.app/

### Show Error Details

Control whether to show technical error details:

```yaml
showDetails: true  # Shows error codes and details
```

Set to `false` for production to hide technical information.

### Traefik Integration

The chart creates:
1. **Middleware** - Intercepts HTTP errors (400-599)
2. **IngressRoute** - Catch-all route with low priority
3. **Service** - Serves error pages on port 8080

#### Using the Middleware

To use error pages on other services, add the middleware to their IngressRoute:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-service
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(`example.com`)
      services:
        - name: my-service
          port: 80
      middlewares:
        - name: error-pages-middleware  # Add this line
```

Now when `my-service` returns an error, the custom error page will be displayed.

## Deployment

### Via ArgoCD

The service is deployed automatically via ArgoCD:

```bash
kubectl apply -f kubernetes/argocd-apps/error-pages.yaml
```

### Manual Deployment

```bash
helm install error-pages kubernetes/apps/error-pages/
```

## Customization

### Change Template

Edit `values.yaml`:

```yaml
template: hacker-terminal
```

Then sync via ArgoCD or upgrade the Helm release.

### Adjust Resources

For high-traffic environments:

```yaml
replicas: 2

resources:
  requests:
    cpu: 100m
    memory: 32Mi
  limits:
    memory: 64M
```

### Custom Status Codes

Handle only specific error codes:

```yaml
middleware:
  statusCodes:
    - "404"
    - "500-503"
```

## Troubleshooting

### Error pages not showing

1. **Check middleware is applied:**
   ```bash
   kubectl get middleware -n default
   ```

2. **Verify service is running:**
   ```bash
   kubectl get pods -n default -l app=error-pages
   ```

3. **Check Traefik logs:**
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
   ```

4. **Ensure IngressRoute has middleware:**
   Check that your IngressRoute includes the error-pages-middleware

### Testing error pages

Trigger a 404 error:
```bash
curl http://your-domain/nonexistent-page
```

Should display custom error page instead of default 404.

### Wrong namespace

The error-pages service must be in the same namespace as the middleware reference. By default, it's deployed to the `default` namespace.

To change:
```yaml
namespace: my-namespace
```

Update the middleware reference in other IngressRoutes accordingly.

## Template Comparison

| Template | Style | Best For |
|----------|-------|----------|
| `app-down` | Clean, professional | Production apps |
| `l7-dark` | Modern, dark theme | Developer sites |
| `ghost` | Friendly, playful | User-facing sites |
| `hacker-terminal` | Terminal/Matrix | Tech/gaming sites |
| `cats` | Fun, cat pictures | Personal projects |

## Security

The container runs with:
- Non-root user (UID 65534)
- Read-only root filesystem
- Dropped capabilities (NET_RAW)
- No privilege escalation

## References

- [Error Pages GitHub](https://github.com/tarampampam/error-pages)
- [Template Preview](https://error-pages.vercel.app/)
- [Traefik Error Pages Documentation](https://doc.traefik.io/traefik/middlewares/http/errorpages/)

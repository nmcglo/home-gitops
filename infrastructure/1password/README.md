# 1Password Connect

Installs a [1Password Connect](https://developer.1password.com/docs/connect/) server on Kubernetes using the 1Password CLI and Helm.

## Prerequisites

- [1Password CLI](https://developer.1password.com/docs/cli/get-started/) installed and signed in
- `helm` and `kubectl` installed and configured against your cluster

## Usage

```bash
./install.sh
```

### Optional environment variables

| Variable | Default | Description |
|---|---|---|
| `NAMESPACE` | `1password` | Kubernetes namespace to deploy into |
| `SERVER_NAME` | `home-connect` | Name for the Connect server |
| `TOKEN_NAME` | `home-infra` | Name for the generated access token |
| `VAULT_NAME` | *(all vaults)* | Restrict server access to a specific vault |

Example:

```bash
VAULT_NAME="Home" ./install.sh
```

## What it does

1. Creates a Connect server via `op connect server create`, generating `1password-credentials.json`
2. Creates an access token — **save this when prompted, it won't be shown again**
3. Deploys the Connect server via the [1password Helm chart](https://github.com/1Password/connect-helm-charts)
4. The credentials file can be deleted after installation; it's stored inside the Helm release

## Notes

- `1password-credentials.json` is gitignored — do not commit it
- The Connect API is available in-cluster at `http://1password-connect.1password.svc.cluster.local:8080`
- To grant applications access, create a Kubernetes secret with the token:
  ```bash
  kubectl create secret generic onepassword-token \
    --from-literal=token=<YOUR_TOKEN> \
    --namespace <YOUR_APP_NAMESPACE>
  ```

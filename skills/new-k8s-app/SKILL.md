---
name: new-k8s-app
description: Use this skill whenever the user wants to add a new application to their home-infra Kubernetes cluster. This includes scaffolding a new Helm chart under kubernetes/apps/{name}/ and an ArgoCD Application manifest under kubernetes/argocd-apps/{name}.yaml. Trigger on prompts like "add X to the cluster", "create a helm chart for Y", "deploy Z to kubernetes", "scaffold a new app", or "set up {app-name} in ArgoCD". Always use this skill when working in a repo that has kubernetes/apps/ and kubernetes/argocd-apps/ directories following these conventions.
---

# New Kubernetes App Scaffold

This skill scaffolds a new Helm chart and ArgoCD Application for a self-hosted app, following the conventions of this home-infra repo.

## Repo Conventions

- Helm charts live at `kubernetes/apps/<app-name>/`
- ArgoCD Applications live at `kubernetes/argocd-apps/<app-name>.yaml`
- Secrets are managed via the 1Password Kubernetes operator (`OnePasswordItem` CRDs)
- Storage uses `PersistentVolumeClaim` with configurable `storageClassName` in `values.yaml`
- Services are `LoadBalancer` type (MetalLB) with optional static IP

## Step 1: Gather Information

If the user hasn't provided all of these, ask before generating:

1. **App name** — used as the directory name, Helm release name, and namespace (e.g. `stirling-pdf`)
2. **Container image** — full repository and tag (e.g. `ghcr.io/stirling-tools/stirling-pdf:latest`)
3. **Port** — the port the container listens on
4. **LoadBalancer IP** — optional static IP for MetalLB (leave blank to use DHCP)
5. **Persistent storage?** — yes/no. If yes:
   - Storage class (common options: `longhorn`, `nfs`)
   - Access mode (`ReadWriteOnce` or `ReadWriteMany`)
   - Size (e.g. `5Gi`)
   - Mount paths — list of directories the app needs persisted (e.g. `/config`, `/data`). If multiple, they'll share one PVC via `subPath`.
6. **1Password secrets?** — yes/no. If yes, for each secret:
   - Kubernetes secret name
   - 1Password item path (e.g. `vaults/home-gitops/items/my_item`)
   - Which env vars to map from which secret keys

## Step 2: Generate Files

Create these files:

### `kubernetes/apps/<name>/Chart.yaml`

```yaml
apiVersion: v2
name: <name>
description: <One-line description>
type: application
version: 0.1.0
appVersion: "latest"
```

### `kubernetes/apps/<name>/values.yaml`

Include all knobs the user will want to tune. Use this structure:

```yaml
namespace: <name>

# 1Password secrets — omit section entirely if not needed
onepasswordSecrets:
  - name: <secret-name>
    enabled: true
    autoRestart: true
    itemPath: "vaults/home-gitops/items/<item>"
    env:
      - envVar: MY_ENV_VAR      # env var name in the container
        secretKey: field-name   # field name in the 1Password item

image:
  repository: <repo>
  tag: <tag>
  pullPolicy: IfNotPresent

# Extra env vars (plain values or secretKeyRef)
env: {}
#  MY_VAR: "value"
#  SECRET_VAR:
#    valueFrom:
#      secretKeyRef:
#        name: <secret-name>
#        key: <key>

service:
  type: LoadBalancer
  port: <port>
  targetPort: <port>
  loadBalancerIP: ""   # Set to a static IP for MetalLB, e.g. "192.168.100.X"

# Omit persistence block entirely if no storage needed
persistence:
  storageClassName: longhorn
  accessMode: ReadWriteOnce
  size: 5Gi
```

### `kubernetes/apps/<name>/templates/namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace }}
```

### `kubernetes/apps/<name>/templates/onepassworditems.yaml`

Only create this file if secrets are needed.

```yaml
{{- range .Values.onepasswordSecrets }}
{{- if .enabled }}
---
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: {{ .name }}
  namespace: {{ $.Values.namespace }}
  labels:
    app: {{ $.Release.Name }}
  annotations:
    operator.1password.io/auto-restart: {{ .autoRestart | default "true" | toString | quote }}
spec:
  itemPath: {{ .itemPath | quote }}
{{- end }}
{{- end }}
```

### `kubernetes/apps/<name>/templates/pvc.yaml`

Only create this file if persistent storage is needed. Ask the user to clarify if they would like the deployment to use a **single PVC** regardless of how many mount paths there are (multiple directories are handled with `subPath` in the deployment) or **separate PVCs** for different mount paths.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-pvc
  namespace: {{ .Values.namespace }}
spec:
  storageClassName: {{ .Values.persistence.storageClassName }}
  accessModes:
    - {{ .Values.persistence.accessMode }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
```

### `kubernetes/apps/<name>/templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Values.namespace }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: <app-name>
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          env:
            # 1Password secret env vars — omit block if no secrets
            {{- range .Values.onepasswordSecrets }}
            {{- if .enabled }}
            {{- $secretName := .name }}
            {{- range .env }}
            - name: {{ .envVar }}
              valueFrom:
                secretKeyRef:
                  name: {{ $secretName }}
                  key: {{ .secretKey }}
            {{- end }}
            {{- end }}
            {{- end }}
            # Plain/complex env vars from values
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              {{- if kindIs "string" $value }}
              value: {{ $value | quote }}
              {{- else }}
              {{- toYaml $value | nindent 14 }}
              {{- end }}
            {{- end }}
          # volumeMounts — omit if no persistence
          volumeMounts:
            - name: data
              mountPath: /config         # use subPath if multiple dirs
              subPath: config
            - name: data
              mountPath: /data
              subPath: data
      # volumes — omit if no persistence
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ .Release.Name }}-pvc
```

Adjust `volumeMounts` to match the actual mount paths. If only one directory needs to be mounted, `subPath` is optional but still fine to include.

### `kubernetes/apps/<name>/templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Values.namespace }}
  labels:
    app: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  {{- if .Values.service.loadBalancerIP }}
  loadBalancerIP: {{ .Values.service.loadBalancerIP }}
  {{- end }}
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      name: http
```

### `kubernetes/argocd-apps/<name>.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <name>
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git@github.com/nmcglo/home-infra.git
    targetRevision: HEAD  # Uses default branch
    path: kubernetes/apps/<name>
  destination:
    server: https://kubernetes.default.svc
    namespace: <name>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
```

## Step 3: Summarize

After generating, briefly list the files created and call out any values the user should fill in before deploying — especially 1Password item paths and the LoadBalancer IP.

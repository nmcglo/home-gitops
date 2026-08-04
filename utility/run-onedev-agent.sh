#!/usr/bin/env bash
#
# Launches a OneDev build agent as a Kubernetes Pod, equivalent to:
#   docker run -t -v /var/run/docker.sock:/var/run/docker.sock \
#     -v $(pwd)/agent/work:/agent/work \
#     -e serverUrl=<url> -e agentToken=<token> -h <name> 1dev/agent
#
# Creates a Longhorn-backed PVC for /agent/work and a Pod that mounts the
# host's Docker socket so the agent can run Docker-based build steps.
# Requires the node the pod lands on to run a Docker daemon (docker.sock),
# not just containerd.
#
# Usage: ./run-agent.sh <agent-name> <agent-token>

set -euo pipefail

NAMESPACE="onedev"
SERVER_URL="${SERVER_URL:-https://onedev.example.net}"
WORK_SIZE="${WORK_SIZE:-20Gi}"
STORAGE_CLASS="${STORAGE_CLASS:-longhorn}"

usage() {
  echo "Usage: $0 <agent-name> <agent-token>" >&2
  echo "Env overrides: SERVER_URL (default: $SERVER_URL), WORK_SIZE (default: $WORK_SIZE), STORAGE_CLASS (default: $STORAGE_CLASS)" >&2
  exit 1
}

[ $# -eq 2 ] || usage

AGENT_NAME="$1"
AGENT_TOKEN="$2"

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${AGENT_NAME}-work-pvc
  namespace: ${NAMESPACE}
  labels:
    app: onedev-agent
    agent: ${AGENT_NAME}
spec:
  storageClassName: ${STORAGE_CLASS}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${WORK_SIZE}
---
apiVersion: v1
kind: Pod
metadata:
  name: ${AGENT_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: onedev-agent
    agent: ${AGENT_NAME}
spec:
  hostname: ${AGENT_NAME}
  restartPolicy: Always
  containers:
    - name: onedev-agent
      image: 1dev/agent
      tty: true
      env:
        - name: serverUrl
          value: "${SERVER_URL}"
        - name: agentToken
          value: "${AGENT_TOKEN}"
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
        - name: work
          mountPath: /agent/work
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
        type: Socket
    - name: work
      persistentVolumeClaim:
        claimName: ${AGENT_NAME}-work-pvc
EOF

echo "Agent pod '${AGENT_NAME}' launched in namespace '${NAMESPACE}'."

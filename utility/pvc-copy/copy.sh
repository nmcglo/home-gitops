#!/bin/bash

kubectl run pvc-copy --rm -it --restart=Never \
  --image=alpine \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "pvc-copy",
        "image": "alpine",
        "command": ["sh", "-c", "apk add --no-cache rsync && rsync -av /source/ /dest/"],
        "volumeMounts": [
          {"name": "source", "mountPath": "/source"},
          {"name": "dest",   "mountPath": "/dest"}
        ]
      }],
      "volumes": [
        {"name": "source", "persistentVolumeClaim": {"claimName": "nginx-proxy-manager-letsencrypt"}},
        {"name": "dest",   "persistentVolumeClaim": {"claimName": "nginx-proxy-manager-new-letsencrypt"}}
      ]
    }
  }'
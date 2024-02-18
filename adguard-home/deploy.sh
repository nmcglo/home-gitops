#!/bin/bash

# Default configuration file path
CONFIG_PATH="/mnt/data/adguard/conf"
# Flag to skip copying configuration file
SKIP_COPY=false

# Parse command line arguments
while [[ $# -gt 1 ]]; do
    case "$1" in
        -s|--skip-copy-config)
            SKIP_COPY=true
            shift 1
            ;; 
        -c|--config-path)
            CONFIG_PATH="$2"
            shift 2
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

# Create necessary directories
mkdir -p "$CONFIG_PATH"

# Copy AdGuardHome.yaml to the configurable path
if [ "$SKIP_COPY" = false ]; then
  cp ./AdGuardHome.yaml "$CONFIG_PATH"
fi

# Apply full_deploy.yaml
kc apply -f ./full_deploy.yaml


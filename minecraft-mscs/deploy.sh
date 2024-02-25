#!/bin/zsh

# Where our deployment config expects the server data to be
SERVER_DATA_PATH="/mnt/data/minecraft-mscs"
# default flag to create world or not
CREATE_WORLD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--initialize-world)
            CREATE_WORLD=true
            shift 1
            ;;
        -d|--copy-data)
            COPY_DATA=true
            shift 1
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done


if [ "$CREATE_WORLD" = true ]; then
    echo "Creating world"
    deploy/create_world.sh -d /mnt/data -n minecraft-mscs -w default
fi

# Apply full_deploy.yaml
microk8s kubectl apply -f deploy/full_deploy.yaml


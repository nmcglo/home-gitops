#! /bin/bash

# default location for minecraft server data on host
DATA_PARENT="/mnt/data"
MSCS_DIR="minecraft-mscs"

# default world name
WORLD_NAME="default"

# Parse command line arguments
while [[ $# -gt 1 ]]; do
    case "$1" in
        # override default location for minecraft server data on host
        -d|--data-parent)
            DATA_PARENT="$2"
            shift 2
            ;;
        # override default directory name for minecraft server data on host
        -n|--mscs-dir)
            MSCS_DIR="$2"
            shift 2
            ;;
        # override default world name
        -w|--world-name)
            WORLD_NAME="$2"
            shift 2
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

# check if we have permissions to $DATA_PARENT
if [ ! -w "$DATA_PARENT" ]; then
    echo "You do not have write permissions to $DATA_PARENT"
    exit 1
fi

DATA_PATH="$DATA_PARENT/$MSCS_DIR"
# check if $DATA_PATH already exists
if [ -d "$DATA_PATH" ]; then
    echo "$DATA_PATH already exists. Exiting"
    exit 1
fi

# make data directory
mkdir $DATA_PATH
if [ $? -ne 0 ]; then
    echo "Failed to create $DATA_PATH"
    exit 1
fi

docker run -d --userns=host --user=${UID}:${UID} --name mscs-init -v $DATA_PATH:/opt/mscs nmcglo/minecraft-mscs:v0.1 

# execute minecraft world create command and accept eula
docker exec -it mscs-init /bin/bash -c "msctl -p mscs -l /opt/mscs -c /opt/mscs/mscs.defaults create $WORLD_NAME && echo 'eula=true' > /opt/mscs/worlds/default/eula.txt"

# stop and remove mscs-init container
docker stop mscs-init && docker rm mscs-init


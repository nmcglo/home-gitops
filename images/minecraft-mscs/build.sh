#!/bin/bash
set -e

IMAGE_NAME="nmcglo/minecraft-mscs"
VERSION="${1:-v0.1}"

echo "Building Minecraft MSCS image: ${IMAGE_NAME}:${VERSION}"

docker build -t "${IMAGE_NAME}:${VERSION}" .
docker tag "${IMAGE_NAME}:${VERSION}" "${IMAGE_NAME}:latest"

echo "Build complete!"
echo "To push to registry:"
echo "  docker push ${IMAGE_NAME}:${VERSION}"
echo "  docker push ${IMAGE_NAME}:latest"

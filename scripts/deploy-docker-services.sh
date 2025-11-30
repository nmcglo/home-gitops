#!/bin/bash
set -e

echo "======================================"
echo "Deploying Docker Compose Services"
echo "======================================"
echo ""

SERVICES=("emby")

for service in "${SERVICES[@]}"; do
  echo "Deploying $service..."

  if [ ! -f "docker/$service/.env" ]; then
    echo "WARNING: docker/$service/.env not found!"
    echo "Please copy .env.example to .env and configure it:"
    echo "  cp docker/$service/.env.example docker/$service/.env"
    echo ""
    continue
  fi

  cd "docker/$service"
  docker-compose up -d
  cd ../..

  echo "$service deployed successfully!"
  echo ""
done

echo "======================================"
echo "Docker services deployment complete!"
echo "======================================"
echo ""
echo "View running containers:"
echo "  docker ps"
echo ""
echo "View logs:"
echo "  docker-compose -f docker/emby/docker-compose.yaml logs -f"

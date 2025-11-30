# Emby Media Server

Emby is a media server for organizing, streaming, and accessing your media files.

## Prerequisites

- Docker and Docker Compose installed
- Media files accessible on the host
- Storage available for Emby configuration

## Configuration

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` to customize paths and settings:
   - `EMBY_CONFIG_PATH`: Where Emby stores its configuration
   - `EMBY_MEDIA_PATH`: Path to your media library

3. Ensure the paths exist on your host:
   ```bash
   sudo mkdir -p /mnt/data/emby/config
   ```

## Deployment

Start the service:
```bash
docker-compose up -d
```

Stop the service:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f
```

## Access

- Web UI: http://localhost:8096
- HTTPS: https://localhost:8920

## Notes

- Uses host networking for better device discovery
- Runs as UID/GID specified in environment
- Data persists in the configured volumes

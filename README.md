# Hytale Docker Server

![Build Status](https://github.com/f-gillmann/hytale-docker/actions/workflows/publish.yml/badge.svg)

## Documentation
For detailed documentation, please visit the [Docs](https://f-gillmann.github.io/hytale-docker/).

## Quick Start

### Docker

```bash
docker run -d \
  --name hytale \
  -v ./data:/data \
  ghcr.io/f-gillmann/hytale-docker:latest
```

### Docker Compose

```yaml
services:
  hytale:
    image: ghcr.io/f-gillmann/hytale-docker:latest
    container_name: hytale
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/data 
```

## Available Docker Tags

| Tag                                                       | Base Image                    | Description                                                  |
|:----------------------------------------------------------|:------------------------------|:-------------------------------------------------------------|
| `latest`,<br>`ubuntu`                                     | Eclipse Temurin 25 (Ubuntu)   | Recommended for most users. Updates on every push to master. |
| `alpine`                                                  | Eclipse Temurin 25 (Alpine)   | Lightweight version. Updates on every push to master.        |
| `<version>`,<br>`<version>-alpine`,<br>`<version>-ubuntu` | Specific versions             | Fixed version tags from GitHub Releases.                     |

You can find all available tags on the [GitHub Container Registry](https://github.com/f-gillmann/hytale-docker/pkgs/container/hytale-docker).

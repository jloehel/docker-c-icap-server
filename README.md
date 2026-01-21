# c-icap-server Docker Image

[![Test Build](https://github.com/jloehel/docker-c-icap-server/actions/workflows/test-build.yml/badge.svg)](https://github.com/jloehel/docker-c-icap-server/actions/workflows/test-build.yml)
[![Weekly Build](https://github.com/jloehel/docker-c-icap-server/actions/workflows/weekly-build.yml/badge.svg)](https://github.com/jloehel/docker-c-icap-server/actions/workflows/weekly-build.yml)

A lightweight, security-focused Docker image for [c-icap](http://c-icap.sourceforge.net/) with [SquidClamav](https://squidclamav.darold.net/) - an ICAP server for virus scanning.

## Features

- Based on Fedora 43 with up-to-date packages (c-icap 0.6.3, squidclamav 7.4)
- **Uses INSTREAM protocol** - no shared filesystem required between c-icap and clamd!
- **Failover support** - configure multiple clamd servers for high availability
- Runs as non-root user (rootless/OpenShift compatible)
- Dynamic configuration via environment variables
- Built-in healthcheck
- Multi-architecture support (amd64, arm64)

## Why SquidClamav?

The default c-icap virus_scan module (clamd_mod) writes files to disk and sends the file path to clamd via the `SCAN` command. This requires a shared filesystem between c-icap and clamd - inconvenient in containerized environments.

**SquidClamav simplifies this** by using clamd's `INSTREAM` command, which streams the data directly over TCP. No shared volumes needed!

| Feature | clamd_mod (default) | SquidClamav |
|---------|---------------------|-------------|
| Protocol | SCAN (file path) | INSTREAM (streaming) |
| Shared filesystem | Required | Not required |
| Multiple clamd servers | No | Yes (failover) |
| Container-friendly | No | Yes |

## Quick Start

### With ClamAV (Docker Compose)

```yaml
services:
  clamav:
    image: jloehel/clamav:latest
    container_name: clamav
    volumes:
      - clamav-data:/var/lib/clamav

  c-icap:
    image: ghcr.io/jloehel/c-icap-server:latest
    container_name: c-icap
    ports:
      - "1344:1344"
    environment:
      - CICAP_CLAMD_HOSTS=clamav
      - CICAP_CLAMD_PORT=3310
    depends_on:
      - clamav

volumes:
  clamav-data:
```

### With Multiple ClamAV Servers (Failover)

```yaml
services:
  c-icap:
    image: ghcr.io/jloehel/c-icap-server:latest
    ports:
      - "1344:1344"
    environment:
      # Comma-separated list of clamd servers
      # On timeout, automatically switches to next server
      - CICAP_CLAMD_HOSTS=clamav1,clamav2,clamav3
      - CICAP_CLAMD_PORT=3310
      - CICAP_CLAMD_TIMEOUT=3
```

### Standalone

```bash
docker run -d \
  --name c-icap \
  -p 1344:1344 \
  -e CICAP_CLAMD_HOSTS=your-clamav-host \
  -e CICAP_CLAMD_PORT=3310 \
  ghcr.io/jloehel/c-icap-server:latest
```

## Configuration

### Environment Variables

#### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CICAP_PORT` | `1344` | ICAP server port |
| `CICAP_TIMEOUT` | `300` | Connection timeout in seconds |
| `CICAP_MAX_SERVERS` | `10` | Maximum number of server processes |
| `CICAP_START_SERVERS` | `3` | Initial number of server processes |
| `CICAP_THREADS_PER_CHILD` | `10` | Threads per server process |
| `CICAP_DEBUG_LEVEL` | `1` | Debug level (0-10, higher = more verbose) |

#### ClamAV Connection

| Variable | Default | Description |
|----------|---------|-------------|
| `CICAP_CLAMD_HOSTS` | `clamav` | Comma-separated list of clamd hostnames (failover support) |
| `CICAP_CLAMD_PORT` | `3310` | Port of the ClamAV daemon |
| `CICAP_CLAMD_TIMEOUT` | `3` | Timeout per clamd server (seconds) |
| `CICAP_MAX_OBJECT_SIZE` | `5000000` | Maximum file size to scan (bytes, 0 = no limit) |

#### Scanning Options

| Variable | Default | Description |
|----------|---------|-------------|
| `CICAP_LOG_REDIRECT` | `1` | Log virus detections (0/1) |
| `CICAP_DNS_LOOKUP` | `0` | DNS lookup of client IPs (0/1, disable for performance) |
| `CICAP_SAFE_BROWSING` | `0` | Enable Safe Browsing checks (0/1) |
| `CICAP_WHITELIST_HOSTS` | - | Comma-separated hosts to skip scanning |
| `CICAP_TRUSTCLIENT` | - | Comma-separated trusted client IPs |

#### Service Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CICAP_ENABLE_ECHO` | `false` | Enable echo service for debugging |

### Custom Configuration File

Mount custom configuration files:

```bash
docker run -d \
  --name c-icap \
  -v /path/to/c-icap.conf:/etc/c-icap/c-icap.conf:ro \
  -v /path/to/squidclamav.conf:/etc/squidclamav.conf:ro \
  -e CICAP_USE_MOUNTED_CONFIG=true \
  ghcr.io/jloehel/c-icap-server:latest
```

## Integration with ownCloud OCIS

```yaml
services:
  ocis:
    image: owncloud/ocis:latest
    environment:
      - ANTIVIRUS_SCANNER_TYPE=icap
      - ANTIVIRUS_ICAP_URL=icap://c-icap:1344/squidclamav
      - POSTPROCESSING_STEPS=virusscan
    depends_on:
      - c-icap

  c-icap:
    image: ghcr.io/jloehel/c-icap-server:latest
    environment:
      - CICAP_CLAMD_HOSTS=clamav
      - CICAP_CLAMD_PORT=3310

  clamav:
    image: jloehel/clamav:latest
    volumes:
      - clamav-data:/var/lib/clamav

volumes:
  clamav-data:
```

**Note:** The ICAP service URL is `icap://c-icap:1344/squidclamav` (not `/avscan`).

## Testing

### Test with EICAR

```bash
# Inside the container
docker exec c-icap sh -c '
  echo "X5O!P%@AP[4\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*" > /tmp/eicar.txt
  c-icap-client -i localhost -p 1344 -s squidclamav -f /tmp/eicar.txt -v
'
```

Expected output should show virus detection:
```
X-Infection-Found: Type=0; Resolution=2; Threat=...
```

### Check Service Status

```bash
# OPTIONS request
docker exec c-icap c-icap-client -i localhost -p 1344 -s squidclamav

# Server statistics
docker exec c-icap c-icap-client -s "info?view=text" -i localhost -p 1344 -req use-any-url
```

## Healthcheck

The container includes a built-in healthcheck using `c-icap-client`:

```bash
# Manual healthcheck
docker exec c-icap c-icap-client -i localhost -p 1344 -s squidclamav
```

## Building Locally

```bash
# Clone the repository
git clone https://github.com/jloehel/docker-c-icap-server.git
cd docker-c-icap-server

# Build
./docker_build.sh

# Or with custom settings
IMAGE_VERSION=43-0.6.3-1 ./docker_build.sh
```

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable release (rebuilt weekly) |
| `43-X.Y.Z-N` | Full version tag (os_version-app_version-build) |
| `fedora-latest` | Latest Fedora build |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Install pre-commit hooks: `pre-commit install`
4. Make your changes
5. Make sure the image builds and starts successfully: `./docker_test_build.sh`
6. Submit a pull request

## Acknowledgments

This project would not be possible without the excellent work of:

- **[c-icap project](http://c-icap.sourceforge.net/)** - The c-icap server, maintained by Christos Tsantilas
- **[SquidClamav](https://squidclamav.darold.net/)** - The INSTREAM-capable ClamAV module, by Gilles Darold
- **[ClamAV](https://www.clamav.net/)** - Open source antivirus engine
- **[Fedora Project](https://fedoraproject.org/)** - Base operating system and package maintenance

Special thanks to all contributors and the open source community!

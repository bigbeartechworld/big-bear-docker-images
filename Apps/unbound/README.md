# BigBear Unbound DNS Resolver

A privacy-focused, validating, recursive, caching DNS resolver Docker image based on [NLnet Labs Unbound](https://nlnetlabs.nl/projects/unbound/about/).

## Features

- ✅ **Full Recursive Resolution** - Acts as your own DNS resolver, querying root servers directly
- ✅ **DNSSEC Validation** - Validates DNS responses to prevent DNS spoofing attacks
- ✅ **Privacy Focused** - QNAME minimization reduces data leaked to DNS servers
- ✅ **Security Hardened** - Includes protections against DNSBomb, CAMP, CacheFlush, and other attacks
- ✅ **Multi-Architecture** - Supports `amd64`, `arm64`, and `arm/v7`
- ✅ **Non-Root** - Runs as unprivileged user for enhanced security
- ✅ **Health Checks** - Built-in health monitoring for container orchestration
- ✅ **Auto-Updated** - Weekly checks for new Unbound releases

## Quick Start

### Docker Compose (Recommended)

```yaml
version: '3'
services:
  unbound:
    image: bigbeartechworld/big-bear-unbound:latest
    container_name: unbound
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    volumes:
      # Optional: Mount custom config
      - ./unbound.conf:/etc/unbound/unbound.conf:ro
    restart: unless-stopped
    # Optional: Use host networking for better performance
    # network_mode: host
```

### Docker Run

```bash
docker run -d \
  --name unbound \
  -p 53:53/udp \
  -p 53:53/tcp \
  --restart unless-stopped \
  bigbeartechworld/big-bear-unbound:latest
```

## Testing Your Resolver

```bash
# Test DNS resolution
dig example.com @localhost

# Test DNSSEC validation
dig +dnssec nlnetlabs.nl @localhost

# Verify DNSSEC is working (should show "ad" flag for authenticated data)
dig +dnssec +short example.com @localhost
```

## Configuration

### Custom Configuration

Mount your own `unbound.conf` to override the default configuration:

```yaml
volumes:
  - /path/to/your/unbound.conf:/etc/unbound/unbound.conf:ro
```

### Important Configuration Options

The default configuration includes:

| Option | Default | Description |
|--------|---------|-------------|
| `qname-minimisation` | yes | Privacy: Sends minimal query info |
| `aggressive-nsec` | yes | Performance: Reduces queries using NSEC |
| `prefetch` | yes | Performance: Pre-fetches expiring entries |
| `serve-expired` | yes | Reliability: Serves stale data while refreshing |
| `harden-*` | yes | Security: Various hardening options |
| `cache-min-ttl` | 300 | Cache minimum 5 minutes |
| `cache-max-ttl` | 86400 | Cache maximum 24 hours |

### Forwarding Mode (Optional)

To use DNS-over-TLS forwarding instead of recursive resolution, uncomment the forward-zone section in `unbound.conf`:

```conf
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
```

## CasaOS Integration

For CasaOS users, use this docker-compose configuration:

```yaml
version: '3'
services:
  unbound:
    image: bigbeartechworld/big-bear-unbound:latest
    container_name: big-bear-unbound
    ports:
      - "5353:53/udp"
      - "5353:53/tcp"
    volumes:
      - /DATA/AppData/big-bear-unbound/conf:/etc/unbound:ro
    restart: unless-stopped
```

> **Note**: Using port 5353 to avoid conflict with system DNS. Configure your devices to use port 5353 or set up port forwarding.

## Network Configuration

### Using as Network-Wide DNS

1. Set your router's DHCP server to advertise this container's IP as the DNS server
2. Or configure individual devices to use this resolver

### Pi-hole Integration

Use Unbound as upstream DNS for Pi-hole:

```
# In Pi-hole, set custom upstream DNS:
# Use the Docker network IP of your Unbound container, e.g.:
172.17.0.2#53
```

## Security Considerations

- **Access Control**: By default, accepts queries from all IPs. Restrict `access-control` in production.
- **Non-Root**: Runs as the `unbound` user, not root
- **DNSSEC**: Validates DNS responses by default
- **Attack Mitigations**: Includes protections against:
  - DNSBomb (CVE-2024-33655)
  - CAMP amplification attacks
  - CacheFlush attacks
  - DNS cache poisoning

## Troubleshooting

### Check Container Logs

```bash
docker logs unbound
```

### Test Configuration

```bash
docker exec unbound unbound-checkconf /etc/unbound/unbound.conf
```

### Common Issues

1. **Port 53 already in use**: Stop systemd-resolved or use a different port
   ```bash
   sudo systemctl stop systemd-resolved
   ```

2. **Permission denied**: Ensure mounted volumes are readable by UID 101 (unbound user)

3. **DNSSEC failures**: Check if your system clock is accurate

## Links

- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [NLnet Labs Unbound](https://nlnetlabs.nl/projects/unbound/about/)
- [BigBearTechWorld YouTube](https://www.youtube.com/playlist?list=PL2RAscIdkpt9_yeFJvG6Nhby8gTVStxb0)

## License

This Docker image configuration is provided under the MIT License. Unbound itself is licensed under the BSD License.

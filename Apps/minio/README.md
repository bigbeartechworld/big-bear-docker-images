# MinIO - High-Performance S3-Compatible Object Storage

MinIO is a high-performance, S3-compatible object storage solution released under the GNU AGPL v3.0 license. This Docker image is built from source following MinIO's new source-only distribution model.

## Features

- **S3 API Compatible** - Seamless integration with existing S3 tools and libraries
- **High Performance** - Optimized for AI/ML, analytics, and data-intensive workloads
- **Built from Source** - Always up-to-date with the latest MinIO release
- **Multi-Architecture** - Supports both AMD64 and ARM64 platforms
- **Web Console** - Built-in web UI for managing buckets and objects

## Important Note

As of October 2025, MinIO has transitioned to a **source-only distribution** model. Pre-built Docker images are no longer provided by the MinIO team. This image is built from source using the official MinIO repository with automated builds via GitHub Actions.

Reference: [MinIO Issue #21647](https://github.com/minio/minio/issues/21647)

**Automated Builds**: This image is automatically built and published to Docker Hub when new MinIO releases are detected.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# From the Apps/minio directory
docker-compose -f compose/docker-compose.yml up -d

# Or for development
docker-compose -f compose/docker-compose.dev.yml up -d

# Or for production
docker-compose -f compose/docker-compose.prod.yml up -d
```

### Using Docker

```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v minio_data:/data \
  bigbeartechworld/big-bear-minio:latest \
  server /data --console-address ":9001"
```

### Available Image Tags

The image is published with multiple tags to maintain release history:

- **`latest`** - Most recent build (automatically updated)
- **`<version>`** - Specific MinIO release (e.g., `RELEASE.2025-10-15T17-29-55Z`)

**For production, pin to a specific version:**
```bash
docker pull bigbeartechworld/big-bear-minio:RELEASE.2025-10-15T17-29-55Z
```

**For development, use latest:**
```bash
docker pull bigbeartechworld/big-bear-minio:latest
```

View all available tags: [Docker Hub Tags](https://hub.docker.com/r/bigbeartechworld/big-bear-minio/tags)

## Access

- **MinIO Console (Web UI)**: http://localhost:9001
- **MinIO API**: http://localhost:9000
- **Default Credentials**: 
  - Username: `minioadmin`
  - Password: `minioadmin`

**⚠️ SECURITY WARNING**: Change the default credentials in production!

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MINIO_ROOT_USER` | Root username for MinIO | `minioadmin` |
| `MINIO_ROOT_PASSWORD` | Root password for MinIO | `minioadmin` |
| `MINIO_USERNAME` | Custom user name (optional) | - |
| `MINIO_GROUPNAME` | Custom group name (optional) | - |
| `MINIO_UID` | Custom user ID (optional) | `1000` |
| `MINIO_GID` | Custom group ID (optional) | `1000` |

### Volumes

- `/data` - MinIO data directory where all objects and metadata are stored

### Ports

- `9000` - MinIO API port (S3 compatible)
- `9001` - MinIO Console (Web UI)

## Production Deployment

For production deployments, you should:

1. **Pin to a specific version** (highly recommended):
   ```yaml
   services:
     minio:
       image: bigbeartechworld/big-bear-minio:RELEASE.2025-10-15T17-29-55Z  # Pin version
       # ... rest of config
   ```
   This ensures reproducible deployments and prevents unexpected updates.

2. **Change default credentials**:
   ```yaml
   environment:
     MINIO_ROOT_USER: your-secure-username
     MINIO_ROOT_PASSWORD: your-secure-password-min-8-chars
   ```

3. **Use persistent volumes**:
   ```yaml
   volumes:
     - /path/to/your/data:/data
   ```

4. **Enable TLS/SSL** (recommended):
   - Place certificates in `/data/.minio/certs/`
   - MinIO will automatically use them

5. **Consider using distributed mode** for high availability:
   - Multiple MinIO instances with erasure coding
   - See [MinIO Distributed Mode](https://docs.min.io/community/minio-object-store/operations/concepts/erasure-coding.html)

## Using MinIO Client (mc)

Install the MinIO Client to interact with your MinIO server:

```bash
# Download mc
curl -O https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Configure alias
mc alias set myminio http://localhost:9000 minioadmin minioadmin

# List buckets
mc ls myminio

# Create a bucket
mc mb myminio/mybucket

# Upload a file
mc cp myfile.txt myminio/mybucket/

# List bucket contents
mc ls myminio/mybucket
```

## Using with AWS CLI

MinIO is S3-compatible, so you can use the AWS CLI:

```bash
# Configure AWS CLI
aws configure --profile minio
# Enter:
# - AWS Access Key ID: minioadmin
# - AWS Secret Access Key: minioadmin
# - Default region: us-east-1
# - Default output format: json

# List buckets
aws --profile minio --endpoint-url http://localhost:9000 s3 ls

# Create a bucket
aws --profile minio --endpoint-url http://localhost:9000 s3 mb s3://mybucket

# Upload a file
aws --profile minio --endpoint-url http://localhost:9000 s3 cp myfile.txt s3://mybucket/
```

## Building the Image

To build the image yourself:

```bash
docker build -t bigbeartechworld/big-bear-minio:latest .
```

### Multi-Architecture Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t bigbeartechworld/big-bear-minio:latest \
  --push .
```

### Automated CI/CD with GitHub Actions

This repository includes a GitHub Actions workflow that automatically:
- Monitors for new MinIO releases weekly
- Builds multi-architecture Docker images
- Publishes to Docker Hub
- Runs comprehensive tests
- Creates GitHub releases

**Workflow triggers:**
- Weekly check for new MinIO releases (Mondays at 2 AM UTC)
- Manual trigger via GitHub Actions UI
- Push to main branch (when MinIO files change)

## Health Check

The container includes a health check that verifies MinIO is responding:

```bash
docker ps
# Look for (healthy) status
```

Manual health check:
```bash
curl http://localhost:9000/minio/health/live
```

## Troubleshooting

### Container won't start

1. Check logs: `docker logs minio`
2. Verify port availability: `netstat -tlnp | grep -E '9000|9001'`
3. Ensure data directory has correct permissions

### Permission denied errors

If you encounter permission issues:

```yaml
environment:
  MINIO_UID: 1000  # Your user ID
  MINIO_GID: 1000  # Your group ID
```

### Cannot access console

1. Verify the console port is mapped: `docker ps`
2. Check firewall rules
3. Ensure `--console-address ":9001"` is in the command

## Resources

- [MinIO Documentation](https://docs.min.io/)
- [MinIO GitHub Repository](https://github.com/minio/minio)
- [MinIO Client Documentation](https://docs.min.io/community/minio-object-store/reference/minio-mc.html)
- [S3 API Compatibility](https://docs.min.io/community/minio-object-store/operations/concepts/s3-compatibility.html)

## License

MinIO is licensed under GNU AGPLv3. See the [LICENSE](https://github.com/minio/minio/blob/master/LICENSE) file for details.

This Docker image is provided as-is for community use by Big Bear Tech World and the BigBearCommunity.

## Support

- [MinIO Slack Community](https://slack.min.io/)
- [GitHub Issues](https://github.com/minio/minio/issues)
- [MinIO Documentation](https://docs.min.io/)

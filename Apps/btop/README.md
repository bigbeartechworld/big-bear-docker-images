# btop Docker Image

This Docker image provides [btop++](https://github.com/aristocratos/btop) - a resource monitor that works in a terminal environment.

## Features

- System resource monitoring including CPU, Memory, Disks, Network, and Processes
- GPU monitoring support (depends on your host system configuration)
- Beautiful terminal-based UI with responsive graphs
- Accessible through a web browser using gotty
- Optional authentication support

## Usage

```bash
docker run -d \
  --name=btop \
  -p 7681:7681 \
  --restart=unless-stopped \
  --privileged \
  -v /path/to/config:/root/.config/btop \
  bigbeartechworld/btop
```

### Parameters

|                Parameter                | Function                                                      |
| :-------------------------------------: | ------------------------------------------------------------- |
|             `-p 7681:7681`              | Web UI port                                                   |
| `-v /path/to/config:/root/.config/btop` | Configuration storage                                         |
|      `-e GOTTY_AUTH_ENABLED=true`       | Enable basic authentication                                   |
|      `-e GOTTY_AUTH_USER=username`      | Set auth username                                             |
|      `-e GOTTY_AUTH_PASS=password`      | Set auth password                                             |
|             `--privileged`              | Required for full access to system metrics and GPU monitoring |

## Notes on GPU Support

This container includes GPU monitoring capabilities:

1. The container needs to run in `--privileged` mode
2. The host must have proper GPU drivers installed:
   - NVIDIA GPUs require the official NVIDIA driver
   - AMD GPUs require ROCm SMI library
   - Intel GPUs require proper permissions to read from SYSFS

## Web Terminal Options

We provide two variants of this container:

- Default variant using `gotty` (Alpine-based)
- Alternative variant using `ttyd` (Debian-based) available as `bigbeartechworld/btop:ttyd`

## Access

The web interface is available at `http://your-ip:7681`

You can use keyboard shortcuts to navigate in btop:

- Press '5' to show GPU1 monitoring (if available)
- Press '6' to show GPU2 monitoring (if available)
- Press 'h' for help
- Press 'q' to quit and return to shell

## Support

This container is maintained by Big Bear Tech World.

## Instructions to build and run the Docker image

```
# Build default image (Alpine with gotty)
docker build . -t big-bear-btop

# Build alternative image (Debian with ttyd)
docker build -f Dockerfile.ttyd . -t big-bear-btop:ttyd
```

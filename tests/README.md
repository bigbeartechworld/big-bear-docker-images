# Credential regression tests

Run these commands from the repository root inside an isolated environment
meeting the security audit skill's execution requirements:

```bash
python3 -m unittest discover -s tests -v
python3 -m unittest discover -s Apps/big-bear-casaos-user-management/tests -v
```

The root suite requires an already installed Docker CLI with the Compose
plugin and `/bin/sh`. It only renders Compose configuration and executes
terminal wrappers against dummy command stubs. It does not start containers,
contact the Docker daemon, launch real terminal utilities, or fetch dependencies.
The CasaOS suite additionally requires Flask and uses temporary SQLite data.

The credential regression workflow prepares a separate toolchain image, then
runs both suites without network access in a non-root, read-only container.
Only the application and test directories are mounted, both read-only. The
test process receives a fresh environment and a 32 MiB scratch filesystem,
with CPU, memory, process, file-size, and execution-time limits. No host Docker
socket or checkout credentials are exposed to the test process.

These changes require explicit private credentials before restarting the
affected Compose deployments. Production CasaOS now builds the checked-out
source instead of pulling the old registry image. Other image startup changes
still require rebuilding and releasing the affected images. Existing registry
tags do not receive local source changes automatically.

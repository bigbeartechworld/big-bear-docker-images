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

These changes require explicit private credentials before restarting the
affected Compose deployments. Image startup changes require rebuilding and
releasing the affected images. Existing registry tags do not receive local
source changes automatically.

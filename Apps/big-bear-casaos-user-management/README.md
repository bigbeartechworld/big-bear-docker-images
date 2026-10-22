# CasaOS user management

Set a management username and a unique private password before starting the
service. Every Compose variant requires `ADMIN_USERNAME` and `ADMIN_PASSWORD`.
The source application refuses to start with missing or blank values, or with
the public example passwords `casaos` and `YOUR_SECURE_PASSWORD`.

From this directory, use Bash to enter credentials without saving the password
in shell history:

```bash
read -r -p "Management username: " ADMIN_USERNAME
read -r -s -p "Management password: " ADMIN_PASSWORD
printf '\n'
export ADMIN_USERNAME ADMIN_PASSWORD
docker compose up -d --build
```

Existing deployments must supply explicit credentials before restarting with
these configurations. The source authentication changes require a rebuilt
image. `docker-compose.prod.yml` still selects the existing `0.1.1` registry
image, which does not receive local source changes. After publishing a reviewed
replacement image, update that image reference before deploying the fixes.

## Regression tests

With Flask already installed, run from the repository root in an isolated test
environment that meets the security audit's execution requirements:

```bash
python3 -m unittest discover -s Apps/big-bear-casaos-user-management/tests -v
```

The tests use dummy management credentials and temporary SQLite data. They
exercise the real account mutation handlers without starting an HTTP listener
or invoking CasaOS service management.

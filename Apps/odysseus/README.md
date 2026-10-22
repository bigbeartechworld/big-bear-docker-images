# Big Bear Odysseus

A self-hosted AI workspace (Python/FastAPI) packaged as a Docker image, built from the upstream [Odysseus](https://github.com/odysseus-dev/odysseus) source.

## Image

`bigbeartechworld/big-bear-odysseus`

### Tags
- `latest` - newest build
- `<date>` - e.g. `2026.06.01` (moving, last build of the day)
- `<date>-<short-sha>` - immutable, pinned to the exact upstream commit

## Quick Start (full stack)

From `Apps/odysseus`, set a private administrator password first. All Compose variants require it,
including development, which now also enables login. In Bash:

```bash
read -r -s -p "Odysseus administrator password: " ODYSSEUS_ADMIN_PASSWORD
printf '\n'
export ODYSSEUS_ADMIN_PASSWORD
docker compose -f compose/docker-compose.yml up -d
```

Open `http://localhost:7000`. The stack also starts ChromaDB, SearXNG, and ntfy.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `PUID` / `PGID` | `1000` | User/group the process drops to |
| `AUTH_ENABLED` | `true` | Require login |
| `ODYSSEUS_ADMIN_PASSWORD` | Required | Private administrator password; missing or empty values stop Compose |
| `SEARXNG_INSTANCE` | `http://searxng:8080` | SearXNG URL |
| `CHROMADB_HOST` / `CHROMADB_PORT` | `chromadb` / `8000` | Vector store |

LLM provider (Ollama/OpenAI) is user-supplied via env - see `config/.env.example`.

To use a `.env` file instead of the exported password, copy the example from
`Apps/odysseus`:

```bash
cp config/.env.example .env
```

Edit `.env` to fill in the blank `ODYSSEUS_ADMIN_PASSWORD` with a private value.
Keep the file private, then start the stack with `--env-file .env` to explicitly
load it from `Apps/odysseus` when `-f` selects a file in `compose/`:

```bash
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

Existing deployments must also supply a password before restarting with these files.

## Ports & Volumes

- Port `7000` - Web UI / API
- `/app/data` - application data
- `/app/logs` - logs

## Versioning

This image is built from upstream `main`. Upstream has no releases, so builds are
date-tagged (CalVer) with the upstream commit SHA appended for traceability. A weekly
job rebuilds only when upstream `main` has changed.

## License

The Odysseus application is MIT licensed. See the upstream repository.

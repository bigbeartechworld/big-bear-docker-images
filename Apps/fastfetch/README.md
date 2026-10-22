# Instructions to build and run the Docker image

# Build docker image with:

```
docker build . -t big-bear-fastfetch
```

The Compose example enables authentication and requires `GOTTY_AUTH_USER` and
`GOTTY_AUTH_PASS` in your environment. Set a private pair before running
`docker compose up -d --build`. Missing or empty values stop Compose.

For direct container launches, enabling authentication also requires both
variables. The ttyd variant uses `TTYD_AUTH_USER` and `TTYD_AUTH_PASS` instead.
Rebuild and release images to apply the new startup guard to registry images.

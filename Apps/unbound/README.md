```
version: '3'
services:
  unbound:
    image: bigbeartechworld/big-bear-unbound
    container_name: unbound-container
    ports:
      - "53:53/udp"
    volumes:
      - /DATA/AppData/big-bear-unbound/conf:/etc/unbound
    restart: unless-stopped
```

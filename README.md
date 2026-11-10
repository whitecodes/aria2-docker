<p align="center">
  <img src="https://raw.githubusercontent.com/binux/yaaw/master/img/favicon.ico" width="48" />
</p>

# [Aria2](https://github.com/aria2/aria2) + [YAAW webui](https://github.com/binux/yaaw) inside a [docker container](https://github.com/whitecodes/aria2-docker/pkgs/container/aria2-docker)

[![Build image](https://github.com/whitecodes/aria2-docker/actions/workflows/dockerimage.yml/badge.svg)](https://github.com/whitecodes/aria2-docker/actions/workflows/dockerimage.yml)
[![Container image](https://img.shields.io/badge/ghcr.io-whitecodes%2Faria2--docker-blue)](https://github.com/whitecodes/aria2-docker/pkgs/container/aria2-docker)
[![Base image](https://img.shields.io/badge/base-alpine-blue)](https://hub.docker.com/_/alpine)

- **[Github](https://github.com/whitecodes/aria2-docker)**
- **[Container image](https://github.com/whitecodes/aria2-docker/pkgs/container/aria2-docker)**
- Forked from **[hurlenko/aria2-ariang-docker](https://github.com/hurlenko/aria2-ariang-docker)**

## Introduction

YAAW ("Yet Another Aria2 Web Frontend") is a web frontend making [aria2](https://github.com/aria2/aria2) easier to use. It is written in pure HTML/CSS/Javascript and needs no HTTP server, backend or server-side program — any browser is enough. Just put it behind a web server and open it.

## Table of Contents

- [Demo website](#demo-website)
- [Features](#features)
- [Usage](#usage)
  - [Docker](#docker)
  - [docker-compose](#docker-compose)
  - [Configuration (aria2.conf)](#configuration-aria2conf)
  - [BitTorrent](#bittorrent)
  - [Security (RPC authentication)](#security-rpc-authentication)
  - [Nginx](#running-behind-nginx-proxy)
  - [Supported environment variables](#supported-environment-variables)
  - [Supported volumes](#supported-volumes)
  - [User / Group identifiers](#user-/-group-identifiers)
- [Building](#building)

## Demo website

Please visit [http://binux.github.io/yaaw/demo/](http://binux.github.io/yaaw/demo/)

## Features

- Configurable via your own `aria2.conf` (mounted at runtime, not baked into the image)
- Bundled [YAAW](https://github.com/binux/yaaw) web UI, pinned to a commit (`YAAW_COMMIT` build arg)
- Uses the PUID and PGID evironment variables to map the container's internal user to a user on the host machine
- Supports multiple architectures, tested on Ubuntu 18.04 (`amd64`), Rock64 🍍 (`arm64`) and Raspberry Pi 🍓 (`arm32`)

## Usage

### Docker

```bash
mkdir -p aria2-conf
cp aria2.conf aria2-conf/aria2.conf   # edit to your needs
touch aria2-conf/aria2.session        # aria2 reads it on startup (input-file)

docker run -d --name aria2 \
    -p 8080:8080 \
    -v "$PWD/aria2-conf:/aria2/conf" \
    ghcr.io/whitecodes/aria2-docker
```

> Note, `aria2.conf` is **not** shipped inside the image: the file in this repository is only a sample. Mount your own copy as shown above — the container exits with an error when `/aria2/conf/aria2.conf` is missing.

> The bundled web UI is [YAAW](https://github.com/binux/yaaw) and its built-in default is `<host>:6800/jsonrpc`, which is not the port this container serves. Open `http://localhost:8080/#path=http://localhost:8080/jsonrpc` once (adjust host/port), or set the `JSON-RPC Path` field in the gear-icon settings dialog. The path is remembered in the browser's local storage.

To run as a different user and to map custom volume locations use:

```bash
docker run -d \
    --name aria2-ui \
    -p 8080:8080 \
    -p 6881-6999:6881-6999/tcp \
    -p 6881-6999:6881-6999/udp \
    -v /DOWNLOAD_DIR:/aria2/data \
    -v /CONFIG_DIR:/aria2/conf \
    -e PUID=1000 \
    -e PGID=1000 \
    ghcr.io/whitecodes/aria2-docker
```

> Note, `PUID`/`PGID` are optional: when they are not set the container runs as `root` (`0:0`).

### docker-compose

Minimal `docker-compose.yml` may look like this:

```yaml
version: "3"

services:
  aria2:
    image: ghcr.io/whitecodes/aria2-docker
    ports:
      - 443:8080
      - 6881-6999:6881-6999/tcp
      - 6881-6999:6881-6999/udp
    volumes:
      - /DOWNLOAD_DIR:/aria2/data
      - /CONFIG_DIR:/aria2/conf # must contain aria2.conf
    environment:
      - PUID=1000
      - PGID=1000
    restart: always
```

Simply run:

```bash
docker-compose up
```

### Configuration (`aria2.conf`)

The image does **not** ship an `aria2.conf`. The `aria2.conf` found in this repository is only a sample to start from:

```bash
mkdir -p /PATH/TO/CONF
cp aria2.conf /PATH/TO/CONF/aria2.conf   # then edit it
touch /PATH/TO/CONF/aria2.session        # required, see below
docker run -d --name aria2 \
    -p 8080:8080 \
    -p 6881-6999:6881-6999/tcp \
    -p 6881-6999:6881-6999/udp \
    -v /PATH/TO/CONF:/aria2/conf \
    -v /PATH/TO/DOWNLOADS:/aria2/data \
    ghcr.io/whitecodes/aria2-docker
```

`start.sh` refuses to start when `/aria2/conf/aria2.conf` is missing, so the mount is mandatory.

> **The session file must exist too.** `aria2.conf` sets `input-file=/aria2/conf/aria2.session`, and `aria2c` aborts with `errorCode=1` ("Failed to open the file") when it is missing — including on the very first start of a fresh volume. Create it once with `touch /PATH/TO/CONF/aria2.session` (the container keeps it updated from then on through `save-session`), or point `input-file` at another existing file, or comment that line out.

Settings you are most likely to touch:

| Key | Meaning |
|---|---|
| `rpc-listen-port` | aria2 RPC port; must match the `reverse_proxy` target in `Caddyfile` (`127.0.0.1:6845`). The proxy target is static, so changing this also means editing `Caddyfile` and rebuilding the image |
| `rpc-listen-all` | listen on all interfaces — keep the RPC endpoint behind the proxy or a secret |
| `dir` | download directory inside the container (`/aria2/data`) |
| `input-file` / `save-session` | session file; must already exist inside the mounted config folder (create it with `touch`) |
| `listen-port` | BT/DHT port range, publish it with `-p 6881-6999:6881-6999/tcp` and `/udp` |
| `disable-ipv6` | set to `true` when the Docker host has no IPv6 support |

The configuration is read once at startup: restart the container after editing it. Since the file lives in your volume, image updates never overwrite your settings — compare against the sample in the repository if you want to pick up new defaults.

### BitTorrent

BitTorrent (and DHT) need the peer ports published, otherwise downloads will connect poorly:

```bash
-p 6881-6999:6881-6999/tcp -p 6881-6999:6881-6999/udp
```

The range comes from `listen-port` in `aria2.conf`. IPv6 is enabled by default; if your Docker host has no IPv6 support, set `disable-ipv6=true` in `aria2.conf` to avoid pointless bind attempts.

### Security (RPC authentication)

**This image ships no authentication of its own.** In the sample `aria2.conf` the RPC endpoint is enabled with `enable-rpc=true` and `rpc-listen-all=true`, and the bundled `Caddyfile` proxies `/jsonrpc` and `/rpc` from port `8080` straight to aria2 (`127.0.0.1:6845`, i.e. `rpc-listen-port`) without any credentials. Anyone who can reach the published port can add, pause and delete downloads, and write files anywhere the container's user can write.

Recommended, in order of effectiveness:

1. **Do not publish the port to untrusted networks.** Bind it to loopback (`-p 127.0.0.1:8080:8080`) and/or put your own reverse proxy with basic auth + TLS in front of it — see [Running behind Nginx proxy](#running-behind-nginx-proxy).
2. **Keep the RPC on loopback inside the container.** With the bundled web UI this is enough, because Caddy runs in the same container:
   ```
   rpc-listen-all=false
   ```
3. **Set a secret** if your client supports it — in `aria2.conf`:
   ```
   rpc-secret=CHANGE_ME
   ```
   Every RPC call then has to carry `token:CHANGE_ME`. The bundled web UI is [YAAW](https://github.com/binux/yaaw), which supports the secret through the userinfo part of the RPC path: set `JSON-RPC Path` (gear icon) to `http://token:CHANGE_ME@your.host/jsonrpc`.

Also consider `rpc-allow-origin-all=false` (the sample enables it) to stop arbitrary websites from calling the RPC endpoint through a browser.

> The environment variables `RPC_SECRET`, `EMBED_RPC_SECRET`, `BASIC_AUTH_USERNAME` and `BASIC_AUTH_PASSWORD` are **not implemented** by this image — authentication is entirely up to your `aria2.conf` and the proxy in front of it.

### Running behind Nginx proxy

You can use this nginx config:

```nginx
location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    # proxy_set_header X-Forwarded-Proto https;
    proxy_pass http://127.0.0.1:5002;

    # enables WS support
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_read_timeout 999999999;
}
```

### Supported environment variables

- `PUID` - Userid who will own all downloaded files and configuration files (Default `0` which is root)
- `PGID` - Groupid who will own all downloaded files and configuration files (Default `0` which is root)

> Note, **ports are not configurable through environment variables** (the upstream `ARIA2RPCPORT` is gone: if your run command or compose file still sets it, delete it). The web UI always listens on `8080` inside the container — publish it on any host port with `-p 443:8080`. aria2's RPC port comes from `rpc-listen-port` in your `aria2.conf` and must match the `reverse_proxy` target in `Caddyfile` (`127.0.0.1:6845`), which is fixed at build time.

> Note, RPC authentication is **not** configured through environment variables; see [Security (RPC authentication)](#security-rpc-authentication).

### Supported volumes

- `/aria2/data` The folder of all Aria2 downloaded files
- `/aria2/conf` The Aria2 configuration folder. It **must** contain `aria2.conf` (copy the sample from this repository and edit it) and `aria2.session` (see `input-file` / `save-session`), otherwise the container will not start.

### User / Group identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1001` and `PGID=1001`, to find yours use `id user` as below:

```bash
id username
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```

## Building

```bash
git clone https://github.com/whitecodes/aria2-docker
cd aria2-docker
docker build -t ghcr.io/whitecodes/aria2-docker .
```

<p align="center">
  <img src="https://raw.githubusercontent.com/mayswind/AriaNg-Native/master/assets/AriaNg.ico" />
</p>

# [Aria2](https://github.com/aria2/aria2) + [AriaNg webui](https://github.com/mayswind/AriaNg) inside a [docker container](https://hub.docker.com/r/hurlenko/aria2-ariang)

[![Latest Github release](https://img.shields.io/github/release/hurlenko/aria2-ariang-docker.svg)](https://github.com/hurlenko/aria2-ariang-docker/releases/latest)
[![Image size](https://img.shields.io/docker/image-size/hurlenko/aria2-ariang/latest)](https://hub.docker.com/r/hurlenko/aria2-ariang/)
[![Docker Pulls](https://img.shields.io/docker/pulls/hurlenko/aria2-ariang.svg)](https://hub.docker.com/r/hurlenko/aria2-ariang/)
[![Docker Stars](https://img.shields.io/docker/stars/hurlenko/aria2-ariang.svg)](https://hub.docker.com/r/hurlenko/aria2-ariang/)

- **[Github](https://github.com/hurlenko/aria2-ariang-docker)**
- **[Dockerhub](https://hub.docker.com/r/hurlenko/aria2-ariang/)**

## Introduction

AriaNg is a modern web frontend making [aria2](https://github.com/aria2/aria2) easier to use. AriaNg is written in pure html & javascript, thus it does not need any compilers or runtime environment. You can just put AriaNg in your web server and open it in your browser. AriaNg uses responsive layout, and supports any desktop or mobile devices.

## Table of Contents

- [Screenshots](#screenshots)
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

## Screenshots

### Desktop

![AriaNg](https://raw.githubusercontent.com/mayswind/AriaNg-WebSite/master/screenshots/desktop.png)

### Mobile device

![AriaNg](https://raw.githubusercontent.com/mayswind/AriaNg-WebSite/master/screenshots/mobile.png)

## Demo website

Please visit [http://ariang.mayswind.net/latest](http://ariang.mayswind.net/latest)

## Features

- Configurable via your own `aria2.conf` (mounted at runtime, not baked into the image)
- Bundled [AriaNg](https://github.com/mayswind/AriaNg) web UI, pinned to a release version (`ARIANG_VERSION` build arg)
- Uses the PUID and PGID evironment variables to map the container's internal user to a user on the host machine
- Supports multiple architectures, tested on Ubuntu 18.04 (`amd64`), Rock64 🍍 (`arm64`) and Raspberry Pi 🍓 (`arm32`)

## Usage

### Docker

```bash
mkdir -p ariang-conf
cp aria2.conf ariang-conf/aria2.conf   # edit to your needs
touch ariang-conf/aria2.session        # aria2 reads it on startup (input-file)

docker run -d --name ariang \
    -p 8080:8080 \
    -v "$PWD/ariang-conf:/aria2/conf" \
    hurlenko/aria2-ariang
```

> Note, `aria2.conf` is **not** shipped inside the image: the file in this repository is only a sample. Mount your own copy as shown above — the container exits with an error when `/aria2/conf/aria2.conf` is missing.

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
    -e ARIA2RPCPORT=443 \
    -e RPC_SECRET=NOBODYKNOWSME \
    hurlenko/aria2-ariang
```

> Note, `PUID`/`PGID` are optional: when they are not set the container runs as `root` (`0:0`).

### docker-compose

Minimal `docker-compose.yml` may look like this:

```yaml
version: "3"

services:
  ariang:
    image: hurlenko/aria2-ariang
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
      - RPC_SECRET=secret
      - ARIA2RPCPORT=443
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
docker run -d --name ariang \
    -p 8080:8080 \
    -p 6881-6999:6881-6999/tcp \
    -p 6881-6999:6881-6999/udp \
    -v /PATH/TO/CONF:/aria2/conf \
    -v /PATH/TO/DOWNLOADS:/aria2/data \
    hurlenko/aria2-ariang
```

`start.sh` refuses to start when `/aria2/conf/aria2.conf` is missing, so the mount is mandatory.

> **The session file must exist too.** `aria2.conf` sets `input-file=/aria2/conf/aria2.session`, and `aria2c` aborts with `errorCode=1` ("Failed to open the file") when it is missing — including on the very first start of a fresh volume. Create it once with `touch /PATH/TO/CONF/aria2.session` (the container keeps it updated from then on through `save-session`), or point `input-file` at another existing file, or comment that line out.

Settings you are most likely to touch:

| Key | Meaning |
|---|---|
| `rpc-listen-port` | aria2 RPC port; must match the reverse proxy target in `Caddyfile` (`127.0.0.1:6845` by default) |
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

**This image ships no authentication of its own.** In the sample `aria2.conf` the RPC endpoint is enabled with `enable-rpc=true` and `rpc-listen-all=true`, and the bundled `Caddyfile` proxies `/jsonrpc` and `/rpc` from port `8080` straight to aria2 (`127.0.0.1:6845`) without any credentials. Anyone who can reach the published port can add, pause and delete downloads, and write files anywhere the container's user can write.

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
   Every RPC call then has to carry `token:CHANGE_ME`. The bundled web UI is [AriaNg](https://github.com/mayswind/AriaNg), which supports the secret: set it once in `AriaNg Settings` > `RPC` > `Secret` (and keep the RPC URL on `/jsonrpc`).

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
- `ARIA2RPCPORT` - The port that will be used for rpc calls to aria2. Usually you want to set it to the port your website is running on. For example if your AriaNg instance is accessible on `https://ariang.mysite.com` you need to set `ARIA2RPCPORT` to `443` (default https port), otherwise AriaNg won't be able to access aria2 rpc running on the default port `8080`. You can set the port in the web ui by going to `AriaNg Settings` > `Rpc` tab > `Aria2 RPC Address` field, and changing the default rpc port to whatever you need, but this has to be done per browser.

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
git clone https://github.com/hurlenko/aria2-ariang-docker
cd aria2-ariang-docker
docker build -t hurlenko/aria2-ariang .
```

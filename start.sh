#!/bin/sh
set -e

conf_path=/aria2/conf
data_path=/aria2/data
caddyfile=/usr/local/caddy/Caddyfile

# aria2.conf is not shipped inside the image: it is a sample file in the repo,
# the user is expected to mount their own copy.
if [ ! -f "$conf_path/aria2.conf" ]; then
    echo "error: $conf_path/aria2.conf not found." >&2
    echo "mount your configuration, e.g. -v /PATH/TO/aria2.conf:/aria2/conf/aria2.conf" >&2
    exit 1
fi

# Run as a non-root user only when PUID/PGID are given, otherwise stay root (0:0).
userid="${PUID:-0}"
groupid="${PGID:-0}"

# Fail fast on a broken Caddyfile instead of starting aria2 with a dead web UI.
if ! caddy validate --config "$caddyfile" --adapter=caddyfile; then
    echo "error: invalid Caddy configuration in $caddyfile" >&2
    exit 1
fi

# Caddy serves the web UI: keep it in the background so aria2c can be PID 1
# and receive SIGTERM from `docker stop` directly.
caddy run --config "$caddyfile" --adapter=caddyfile &
caddy_pid=$!

# `caddy run` reports bind/permission errors asynchronously, so give it a moment
# and bail out when it is already gone (e.g. port 8080 already in use).
sleep 1
if ! kill -0 "$caddy_pid" 2>/dev/null; then
    echo "error: caddy exited right after startup, see the log above" >&2
    exit 1
fi

if [ "$userid" != "0" ] || [ "$groupid" != "0" ]; then
    if [ "$(id -u)" = "0" ]; then
        echo "Running as user $userid:$groupid"
        chown -R "$userid:$groupid" "$data_path" "$conf_path"
        exec su-exec "$userid:$groupid" aria2c "$@"
    fi
    echo "warning: container already runs as $(id -u):$(id -g), PUID/PGID $userid:$groupid ignored" >&2
fi

exec aria2c "$@"

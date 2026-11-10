# syntax=docker/dockerfile:1

FROM alpine:3.24.4

# YAAW is unmaintained (last commit 2020), so pin the commit for reproducible builds.
# Bump manually: https://github.com/binux/yaaw/commits/master
ARG YAAW_COMMIT=7511684b9af552445d0dd849ac25705b79a5ad0d

RUN apk add --no-cache caddy aria2 su-exec curl ca-certificates unzip

# YAAW web UI
WORKDIR /usr/local/www

RUN wget -q -O /tmp/yaaw.zip \
        "https://codeload.github.com/binux/yaaw/zip/${YAAW_COMMIT}" \
    && unzip -q /tmp/yaaw.zip -d /tmp/yaaw \
    && mv /tmp/yaaw/yaaw-* /usr/local/www/yaaw \
    && rm -rf /tmp/yaaw /tmp/yaaw.zip

WORKDIR /aria2

RUN mkdir -p /aria2/data /aria2/conf

COPY --chmod=0755 start.sh /aria2/start.sh
COPY Caddyfile /usr/local/caddy/Caddyfile

EXPOSE 8080
# BitTorrent peer / DHT ports (see listen-port in aria2.conf)
EXPOSE 6881-6999/tcp
EXPOSE 6881-6999/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fs "http://127.0.0.1:8080/" || exit 1

ENTRYPOINT ["/aria2/start.sh"]
CMD ["--conf-path=/aria2/conf/aria2.conf"]

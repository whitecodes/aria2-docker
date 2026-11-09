# syntax=docker/dockerfile:1

FROM alpine:3.24.4

# Bump manually or via Dependabot PR: https://github.com/mayswind/AriaNg/releases
ARG ARIANG_VERSION=1.3.15

ENV ARIA2RPCPORT=8080

RUN apk add --no-cache caddy aria2 su-exec curl ca-certificates unzip

# AriaNg web UI
WORKDIR /usr/local/www/ariang

RUN wget -q -O /tmp/ariang.zip \
        "https://github.com/mayswind/AriaNg/releases/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip" \
    && unzip -q /tmp/ariang.zip -d /usr/local/www/ariang \
    && rm -f /tmp/ariang.zip

WORKDIR /aria2

RUN mkdir -p /aria2/data /aria2/conf

COPY --chmod=0755 start.sh /aria2/start.sh
COPY Caddyfile /usr/local/caddy/Caddyfile

EXPOSE 8080
# BitTorrent peer / DHT ports (see listen-port in aria2.conf)
EXPOSE 6881-6999/tcp
EXPOSE 6881-6999/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fs "http://127.0.0.1:${ARIA2RPCPORT:-8080}/" || exit 1

ENTRYPOINT ["/aria2/start.sh"]
CMD ["--conf-path=/aria2/conf/aria2.conf"]

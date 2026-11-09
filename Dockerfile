# syntax=docker/dockerfile:1

FROM alpine:3.24.4

ENV ARIA2RPCPORT=8080

RUN apk add --no-cache caddy aria2 su-exec curl ca-certificates unzip

# AriaNG
WORKDIR /usr/local/www/ariang

RUN wget -q https://codeload.github.com/binux/yaaw/zip/refs/heads/master \
    -O ariang.zip \
    && unzip -q ariang.zip \
    && rm ariang.zip

WORKDIR /aria2

RUN mkdir -p /aria2/data /aria2/conf

COPY --chmod=0755 start.sh /aria2/start.sh
COPY aria2.conf /aria2/conf-copy/aria2.conf
COPY Caddyfile /usr/local/caddy/Caddyfile

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fs "http://127.0.0.1:${ARIA2RPCPORT:-8080}/" || exit 1

ENTRYPOINT ["/aria2/start.sh"]
CMD ["--conf-path=/aria2/conf/aria2.conf"]

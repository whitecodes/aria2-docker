FROM alpine:3.16.0


ENV ARIA2RPCPORT=8080

RUN apk update \
    && apk add --no-cache --update caddy aria2 su-exec curl

# AriaNG
WORKDIR /usr/local/www/ariang

RUN wget --no-check-certificate https://codeload.github.com/binux/yaaw/zip/refs/heads/master \
    -O ariang.zip \
    && unzip ariang.zip \
    && rm ariang.zip \
    && chmod -R 755 ./

WORKDIR /aria2

COPY aria2.conf ./conf-copy/aria2.conf
COPY start.sh ./
COPY Caddyfile /usr/local/caddy/

VOLUME /aria2/data
VOLUME /aria2/conf

EXPOSE 8080

ENTRYPOINT ["./start.sh"]
CMD ["--conf-path=/aria2/conf/aria2.conf"]

FROM golang:1.11.4-alpine3.8

RUN apk add --no-cache git tar curl \
     && mkdir -p /go/src/github.com/mholt \
     && cd /go/src/github.com/mholt && git clone https://github.com/mholt/caddy \
     && cd caddy && git checkout 4f5df39bdd9ce05146da14bb60f5a17a163d5262 -b deployment \
     && go get -u -d github.com/caddyserver/builds

WORKDIR /go/src/github.com/mholt/caddy
ADD files/cleanup.patch cleanup.patch
ADD files/telemetry.patch telemetry.patch

RUN patch -p1 < cleanup.patch
#&& patch -p1 < telemetry.patch

WORKDIR /go/src/github.com/mholt/caddy/caddy
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o caddy  && ./caddy -version
# /go/src/github.com/mholt/caddy/caddy/caddy

# custom config
#
FROM alpine:3.8

COPY --from=0 /go/src/github.com/mholt/caddy/caddy/caddy /usr/bin/caddy

ARG plugins=http.cache,http.cors,http.expires

RUN apk add --no-cache ca-certificates curl \
  && chmod 0755 /usr/bin/caddy \
  && /usr/bin/caddy -version \
  && addgroup -g 82 -S www-data \
  && adduser -u 82 -D -S -G www-data www-data

ENV CADDYPATH=/config

RUN mkdir -p /config/tls && chown -R www-data:www-data /config \
    && /usr/bin/caddy -version

VOLUME /config

ADD files/Caddyfile /config/Caddyfile

USER www-data
WORKDIR /config

ENTRYPOINT ["/usr/bin/caddy"]

CMD ["-agree", "-http-port", "8080", "-https-port", "8443", "-conf", "/config/Caddyfile", "-log", "stdout"]

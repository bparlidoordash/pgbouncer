FROM alpine:3.11

FROM alpine:3.11 AS build_stage

LABEL maintainer "ben.parli@doordash.com"

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        autoconf \
        autoconf-doc \
        automake \
        c-ares \
        c-ares-dev \
        curl \
        gcc \
        libc-dev \
        libevent \
        libevent-dev \
        libtool \
        make \
        libressl-dev \
        file \
        git \
        pkgconf

WORKDIR /tmp

COPY . pgbouncer 

RUN  cd pgbouncer \
        && git submodule init \ 
        &&  git submodule update \
        && ./autogen.sh \
        && ./configure --prefix=/usr \
        && mkdir /tmp/pandoc \
        && curl -o /tmp/pandoc/pandoc.tar.gz -L https://github.com/jgm/pandoc/releases/download/2.11.2/pandoc-2.11.2-linux-amd64.tar.gz \
        && tar zxvf /tmp/pandoc/pandoc.tar.gz --strip-components 1 -C /tmp/pandoc \
        && cp /tmp/pandoc/bin/pandoc /usr/local/bin \
        && make \
        && make install

FROM alpine:3.11

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        libevent \
        libressl \
        ca-certificates \
        c-ares

WORKDIR /etc/pgbouncer
WORKDIR /var/log/pgbouncer
WORKDIR /opt/pgbouncer

RUN addgroup -g 70 -S postgres 2>/dev/null \
  && adduser -u 70 -S -D -H -h /var/lib/postgresql -g "Postgres user" -s /bin/sh -G postgres postgres 2>/dev/null \
  && chown -R postgres:root /etc/pgbouncer /var/log/pgbouncer /opt/pgbouncer \
  && apk --no-cache add postgresql-client

USER postgres

COPY --from=build_stage --chown=postgres ["/tmp/pgbouncer", "/opt/pgbouncer"]
COPY --chown=postgres ["entrypoint.sh", "/opt/pgbouncer"]

RUN chmod +x /opt/pgbouncer/entrypoint.sh

WORKDIR /opt/pgbouncer
ENTRYPOINT ["/opt/pgbouncer/entrypoint.sh"]

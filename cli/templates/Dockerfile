FROM crystallang/crystal:0.30.1 AS builder

WORKDIR /usr/src/app

COPY shard.* ./
RUN shards install

COPY . ./
RUN shards build --release --static

FROM ubuntu:16.04

RUN apt-get update && apt-get -y install wget \
 && echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >/etc/apt/sources.list.d/pgdg.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && apt-get update \
 && apt-get -y install postgresql-client \
 && apt-get -y remove wget \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
 && apt-get -y install mysql-client \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /usr/src/app/bin/crystal-sync /usr/local/bin/

ENTRYPOINT ["crystal-sync"]

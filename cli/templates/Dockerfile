FROM crystallang/crystal:0.34.0 AS builder

WORKDIR /usr/src/app

COPY shard.* ./
RUN shards install

COPY . ./
RUN shards build --release --static

FROM ubuntu:20.04

RUN apt-get update \
 && apt-get -y install postgresql-client \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
 && apt-get -y install mysql-client \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /usr/src/app/bin/crystal-sync /usr/local/bin/

ENTRYPOINT ["crystal-sync"]

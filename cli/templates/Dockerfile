FROM crystallang/crystal:1.8.1-alpine-build AS builder

WORKDIR /usr/src/app

COPY shard.* ./
RUN shards install

COPY anonymization_config.cr ./
COPY src ./src
RUN shards build --release --static

FROM alpine:3.17

RUN apk add --no-cache curl mysql-client postgresql-client

COPY --from=builder /usr/src/app/bin/crystal-sync /usr/local/bin/

ENTRYPOINT ["crystal-sync"]

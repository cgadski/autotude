FROM rust:latest AS builder

WORKDIR /usr/src/app

COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && touch src/lib.rs \
    && cargo build --release --lib
RUN rm -rf src

RUN apt-get update && apt-get install -y protobuf-compiler

COPY src src
COPY bin bin
COPY proto proto
COPY build.rs .
RUN cargo build --release --bin dump
RUN cp target/release/dump /bin

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3 \
    cron \
    wget \
    sqlite \
    build-essential

COPY --from=builder /bin/dump /bin/

WORKDIR /app
COPY schema.sql .
COPY csv/ csv/
COPY tables/ tables/
COPY views/ views/
COPY stats/ stats/
COPY materialize_stats.py .
COPY Makefile .

RUN chmod +x materialize_stats.py

COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

run_cycle() {
    echo "--------------------"
    echo "$(date): running..."
    echo "--------------------"
    make
    echo "$(date): done"
}

INTERVAL="${STATS_INTERVAL:-60}"
echo "Starting stats daemon with ${INTERVAL}s interval..."

while true; do
run_cycle || echo "$(date): Cycle failed, continuing..."
echo "$(date): Sleeping for ${INTERVAL}s..."
sleep "$INTERVAL"
done
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

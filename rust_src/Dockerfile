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
RUN cargo build --release --bin index --bin index-lite
RUN cp target/release/index target/release/index-lite /bin

FROM rust:latest

COPY --from=builder /bin/index /bin/index-lite /bin/
COPY --from=builder /lib64 /lib64

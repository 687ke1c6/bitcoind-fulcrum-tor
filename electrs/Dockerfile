FROM    rust:1.85-slim-bookworm AS builder

# Pinned electrs release tag (https://github.com/romanz/electrs/releases)
ARG     ELECTRS_GIT_TAG=v0.10.9

RUN     apt-get update && \
        apt-get install -y --no-install-recommends git clang libclang-dev cmake build-essential ca-certificates && \
        rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Shallow clone of the pinned tag, then build (compiles the bundled RocksDB too)
RUN     git clone --depth 1 --branch "$ELECTRS_GIT_TAG" https://github.com/romanz/electrs.git . && \
        cargo build --locked --release && \
        strip target/release/electrs && \
        ./target/release/electrs --version


FROM    debian:bookworm-slim

ENV     INDEXER_HOME=/home/electrs

ARG     INDEXER_LINUX_GID
ARG     INDEXER_LINUX_UID

RUN     groupadd -r -g ${INDEXER_LINUX_GID} electrs && \
        useradd -r -g electrs -u ${INDEXER_LINUX_UID} -d "$INDEXER_HOME" electrs

# Create data directory
RUN     mkdir -p "$INDEXER_HOME/db" && \
        chown -R electrs:electrs "$INDEXER_HOME"

COPY    --from=builder /build/target/release/electrs /usr/local/bin/electrs

# Copy restart script
COPY    --chmod=755 ./restart.sh /restart.sh

USER    electrs

EXPOSE  50001 4224

STOPSIGNAL SIGINT

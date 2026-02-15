# ── Stage 1: Build ────────────────────────────────────────────
FROM rustlang/rust:nightly-slim AS builder

# openssl-sys needs pkg-config + libssl-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src/ src/

RUN cargo build --release --locked && \
    strip target/release/zeroclaw

# ── Stage 2: Runtime (distroless nonroot) ──────────────────────
FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=builder /app/target/release/zeroclaw /usr/local/bin/zeroclaw

VOLUME ["/data"]
ENV ZEROCLAW_WORKSPACE=/data/workspace

USER 65534:65534
EXPOSE 3000

ENTRYPOINT ["zeroclaw"]
CMD ["gateway"]

# ── Stage 1: Build ────────────────────────────────────────────
FROM rustlang/rust:nightly-slim AS builder

# 1) 安装 openssl-sys 需要的构建依赖：pkg-config + libssl-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2) 先拷 manifest，尽量利用 Docker layer cache
COPY Cargo.toml Cargo.lock ./

# 可选：如果项目里还有 build.rs/额外 crate 配置，也一起 COPY（没有就删掉这行）
# COPY build.rs ./

# 3) 预先 fetch 依赖（失败更早暴露，也更利于缓存）
RUN cargo fetch

# 4) 再拷源码并编译
COPY src/ src/

RUN cargo build --release --locked && \
    strip target/release/zeroclaw

# ── Stage 2: Runtime (distroless nonroot) ──────────────────────
FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=builder /app/target/release/zeroclaw /usr/local/bin/zeroclaw

# Default workspace and data directory
VOLUME ["/data"]
ENV ZEROCLAW_WORKSPACE=/data/workspace

USER 65534:65534

EXPOSE 3000

ENTRYPOINT ["zeroclaw"]
CMD ["gateway"]

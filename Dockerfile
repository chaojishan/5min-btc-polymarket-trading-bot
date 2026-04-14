# ==================== 第一阶段：编译 ====================
FROM rust:1.94 AS builder

WORKDIR /app

# 缓存依赖层（默认 x86_64-unknown-linux-gnu，与 native-tls/openssl 兼容）
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build --release

# 复制完整源码
COPY . .

# 正式编译
RUN cargo build --release

# ==================== 第二阶段：最终镜像 ====================
FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/polymarket-arbitrage-bot /usr/local/bin/polymarket-arbitrage-bot

# 若构建上下文中存在 config.json 则打入镜像；否则请在运行时挂载
COPY --from=builder /app/config.json /config.json

WORKDIR /

ENTRYPOINT ["/usr/local/bin/polymarket-arbitrage-bot"]
CMD ["--production", "--config", "config.json"]

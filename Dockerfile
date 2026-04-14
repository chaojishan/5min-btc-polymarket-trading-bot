# ==================== 第一阶段：编译 ====================
FROM rust:1.94-bullseye AS builder

WORKDIR /app

# 复制完整源码并编译（避免占位 main 产物被误用）
COPY . .
RUN cargo build --release --locked

# ==================== 第二阶段：最终镜像 ====================
FROM debian:bullseye-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/polymarket-arbitrage-bot /usr/local/bin/polymarket-arbitrage-bot

# 若构建上下文中存在 config.json 则打入镜像；否则请在运行时挂载
COPY --from=builder /app/config.json /config.json

WORKDIR /

ENTRYPOINT ["/usr/local/bin/polymarket-arbitrage-bot"]
CMD ["--production", "--config", "config.json"]

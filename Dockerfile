# ==================== 第一阶段：编译 ====================
FROM rust:1.94 AS builder

# 安装 musl target（生成静态二进制，适合直接放到 Linux VPS 上运行）
RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /app

# 缓存依赖层
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build --release --target x86_64-unknown-linux-musl

# 复制完整源码
COPY . .

# 正式编译
RUN cargo build --release --target x86_64-unknown-linux-musl

# ==================== 第二阶段：最终镜像 ====================
FROM scratch

# 复制编译好的二进制文件
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/polymarket-arbitrage-bot /polymarket-arbitrage-bot

# 如果你的项目里有 config.json，也一起复制进去
COPY --from=builder /app/config.json /config.json

WORKDIR /

# 默认启动命令（你可以后面用 docker run 覆盖）
ENTRYPOINT ["/polymarket-arbitrage-bot"]
CMD ["--production", "--config", "config.json"]
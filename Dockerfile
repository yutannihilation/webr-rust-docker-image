# https://github.com/r-wasm/webr/blob/main/Dockerfile
FROM ghcr.io/r-wasm/webr:main

# Copied from https://github.com/rust-lang/docker-rust/blob/master/Dockerfile-debian.template
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \

RUN set -eux; \
    wget "https://static.rust-lang.org/rustup/archive/1.26.0/x86_64-unknown-linux-gnu/rustup-init"; \
    echo "0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y \
        --no-modify-path \
        --profile minimal \
        --default-toolchain nightly \
        --default-host x86_64-unknown-linux-gnu \
        --target wasm32-unknown-emscripten \
        --component rust-src; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

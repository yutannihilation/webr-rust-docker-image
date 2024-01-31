# based on: https://github.com/r-wasm/webr/blob/main/Dockerfile

ARG BASE=ghcr.io/r-wasm/flang-wasm:main
FROM $BASE as webr

# Setup environment for Emscripten
ENV PATH="/opt/emsdk:/opt/emsdk/upstream/emscripten:${PATH}"
ENV EMSDK="/opt/emsdk"
ENV WEBR_ROOT="/opt/webr"
ENV EM_NODE_JS="/usr/bin/node"
ENV EMFC="/opt/flang/host/bin/flang-new"

FROM webr as scratch
# Install node 18
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
    gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] \
        https://deb.nodesource.com/node_18.x nodistro main" | \
    tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install nodejs -y

RUN curl -L https://rig.r-pkg.org/deb/rig.gpg -o /etc/apt/trusted.gpg.d/rig.gpg && \
    echo "deb http://rig.r-pkg.org/deb rig main" > /etc/apt/sources.list.d/rig.list && \
    apt-get update && \
    apt-get install r-rig -y

# Because $HOME gets masked by GHA with the host $HOME
ENV R_LIBS_USER=/opt/R/current/lib/R/site-library
RUN rig add 4.3.2

# Download webR and configure for LLVM flang
RUN git clone --depth=1 https://github.com/r-wasm/webr.git /opt/webr
WORKDIR /opt/webr
RUN ./configure

# Install r-wasm's webr package for native R
RUN R CMD INSTALL packages/webr

# Build webR with supporting Wasm libs
RUN cd libs && make all
RUN make

# Copied from https://github.com/rust-lang/docker-rust/blob/master/Dockerfile-debian.template
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

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

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/rig
RUN rm -rf libs/download libs/build src/node_modules R/download
RUN cd src && make clean

# Squash docker image layers
FROM webr
COPY --from=scratch / /
WORKDIR /root
SHELL ["/bin/bash", "-c"]

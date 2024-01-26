# webr-rust-docker-image

Build a version of r-wasm/webr Docker image with Rust toolchain.

## How to build and test a Rust-powered R package

### Place `configure` and `Makevars.in`

<details>
<summary>Example</summary>

```sh
if [ "$(uname)" = "Emscripten" ]; then
  TARGET="wasm32-unknown-emscripten"
fi

sed -e "s/@TARGET@/${TARGET}/" src/Makevars.in > src/Makevars
```

```make
TARGET = @TARGET@

CRATE_NAME = foo

TARGET_DIR = ./rust/target
LIBDIR = $(TARGET_DIR)/$(TARGET)/release
STATLIB = $(LIBDIR)/lib$(CRATE_NAME).a
PKG_LIBS = -L$(LIBDIR) -l$(CRATE_NAME)

CARGO_BUILD_ARGS = --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)

all: C_clean

$(SHLIB): $(STATLIB)

$(STATLIB):
	export PATH="$(PATH):$(HOME)/.cargo/bin" && \
	  if [ "$(TARGET)" != "wasm32-unknown-emscripten" ]; then \
	    cargo build $(CARGO_BUILD_ARGS); \
	  else \
	    export CC="$(CC)" && \
	    export CFLAGS="$(CFLAGS)" && \
	    export CARGO_PROFILE_RELEASE_PANIC="abort" && \
	    cargo +nightly build $(CARGO_BUILD_ARGS) --target $(TARGET) -Zbuild-std=panic_abort,std; \
	  fi

C_clean:
	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)

clean:
	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target
```

</details>


### Follow the official guidance

cf. <https://r-wasm.github.io/rwasm/articles/rwasm.html>

```sh
docker pull ghcr.io/yutannihilation/webr-rust:main

cd path/to/your_R_package

# make sure the output repository is not included in the source package
echo '^repo$' >> .Rbuildignore

# For some reason, rwasm::add_pkg() includes .git in the source package in this case (possibly a bug?).
# Since it's so heavy and only the binary package will be installed, you should probably avoid committing it.
echo '/repo/src' >> .gitignore

docker run -it --rm -v ${PWD}:/pkg -w /pkg ghcr.io/yutannihilation/webr-rust:main R
```

In the R session on Docker:

```r
# rwasm is not pre-installed in the image, so this step is needed everytime
install.packages("pak")
pak::pak("r-wasm/rwasm")

# Build a repository
# See https://r-lib.github.io/pkgdepends/reference/pkg_refs.html for the "local::" notation
rwasm::add_pkg("local::.")
```

In the R session **outside** Docker

```r
httpuv::runStaticServer(
  dir = ".",
  port = 9090,
  browse = FALSE,
  headers = list("Access-Control-Allow-Origin" =  "*")
)
```

In the R session on [the WebR REPL](https://webr.r-wasm.org/latest/):

```r
webr::install("<YOUR PACKAGE>", repos = "http://127.0.0.1:9090/repo")

library(<YOUR PACKAGE>)

some_function()
```

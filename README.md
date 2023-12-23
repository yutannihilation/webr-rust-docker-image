# webr-rust-docker-image

Build a version of r-wasm/webr Docker image with Rust toolchain.

## How to build and test a Rust-powered R package

### Place `Makevars.webr`

See [this commit](https://github.com/georgestagg/hellorust-wasm/commit/7383d37ee1c28fc3a86cd941aafc9ac563978c20).

### Follow the official guidance

cf. <https://r-wasm.github.io/rwasm/articles/rwasm.html>

```sh
docker pull ghcr.io/yutannihilation/webr-rust:main

cd path/to/your_R_package

# make sure the output repository is not included in the source package
echo '^repo$' >> .Rbuildignore

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

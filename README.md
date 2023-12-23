# webr-rust-docker-image

Build a version of r-wasm/webr Docker image with Rust toolchain.

## Build a Rust-powered R package

### Place `Makevars.webr`

See [this commit](https://github.com/georgestagg/hellorust-wasm/commit/7383d37ee1c28fc3a86cd941aafc9ac563978c20).

### Follow the official guidance

cf. <https://r-wasm.github.io/rwasm/articles/rwasm.html>

```sh
docker pull ghcr.io/yutannihilation/webr-rust:main

cd path/to/your_R_package

mkdir -p output

# make sure the output is not included in the source package
echo '^output$' > .Rbuildignore

docker run -it --rm -v $(PWD)/output:/output -w /output ghcr.io/yutannihilation/webr:main R
```

In the R session:

```r
# rwasm is not pre-installed in the image, so this step is needed everytime
install.packages("pak")
pak::pak("r-wasm/rwasm")

library(rwasm)

# See https://r-lib.github.io/pkgdepends/reference/pkg_refs.html for the "local::" notation
build("local::.")
```
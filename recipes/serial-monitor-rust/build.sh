#!/usr/bin/env bash

set -euxo pipefail

export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=$CC
export CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=$CC

BINDGEN_EXTRA_CLANG_ARGS="-v ${CPPFLAGS} ${CFLAGS}"
if [[ "${target_platform}" == osx-* ]]; then
  if [[ "${target_platform}" == osx-arm64 ]]; then
      BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS} --target=aarch64-apple-darwin"
  else
      BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS} --target=x86_64-apple-darwin13.4.0"
  fi
  export LIBCLANG_PATH=${BUILD_PREFIX}/lib
fi

cargo build --release --all-targets
cargo test --release --all-targets
CARGO_TARGET_DIR=target cargo install --path . --root "${PREFIX}"
cargo-bundle-licenses --format yaml --output "${RECIPE_DIR}"/THIRDPARTY.yml

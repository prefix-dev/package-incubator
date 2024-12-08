#!/usr/bin/env bash

set -euxo pipefail

cargo build --release --all-targets
cargo test --release --all-targets
CARGO_TARGET_DIR=target cargo install --path . --root "${PREFIX}"
cargo-bundle-licenses --format yaml --output "${RECIPE_DIR}"/THIRDPARTY.yml

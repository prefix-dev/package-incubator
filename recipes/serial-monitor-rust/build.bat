@echo off

cargo build --release --all-targets --verbose
if %errorlevel% NEQ 0 exit /b %errorlevel%

cargo test --release --all-targets --verbose
if %errorlevel% NEQ 0 exit /b %errorlevel%

set CARGO_TARGET_DIR=target
cargo install --path . --root "%PREFIX%" --verbose
if %errorlevel% NEQ 0 exit /b %errorlevel%

cargo-bundle-licenses --format yaml --output "%RECIPE_DIR%\THIRDPARTY.yml"

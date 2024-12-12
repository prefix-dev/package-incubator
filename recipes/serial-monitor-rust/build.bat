@echo off

cargo build --release --all-targets
if %errorlevel% NEQ 0 exit /b %errorlevel%

cargo test --release --all-targets
if %errorlevel% NEQ 0 exit /b %errorlevel%

cargo install --path . --root "%PREFIX%" --features="bin"
if %errorlevel% NEQ 0 exit /b %errorlevel%

cargo-bundle-licenses --format yaml --output "%RECIPE_DIR%\THIRDPARTY.yml"

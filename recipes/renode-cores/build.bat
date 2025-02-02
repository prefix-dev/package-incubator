@echo off

setlocal EnableDelayedExpansion

rem Update the submodule to the latest commit CMakeLists.txt
mkdir %SRC_DIR%\updates
pushd %SRC_DIR%\updates
    git clone "https://github.com/renode/renode-infrastructure.git"
    pushd renode-infrastructure
        git checkout 3fc2d5fe643068e595e875d9408cb4329522b229
        set "CMAKEFILES_TXT=src\Emulator\Cores\CMakeLists.txt"
        copy %CMAKEFILES_TXT% "%SRC_DIR%\src\Infrastructure\%CMAKEFILES_TXT%"
    popd

    git clone "https://github.com/antmicro/tlib.git"
    pushd tlib
        git checkout 69fff75a0eba7471283b0b8db2e55e8388e284f6
        copy "CMakeLists.txt" "%SRC_DIR%\src\Infrastructure\src\Emulator\Cores\tlib"
        copy "tcg\CMakeLists.txt" "%SRC_DIR%\src\Infrastructure\src\Emulator\Cores\tlib\tcg"
        copy LICENSE %RECIPE_DIR%\tlib-LICENSE
    popd
    if %errorlevel% neq 0 exit /b  %errorlevel%
popd

copy "%SRC_DIR%\src\Infrastructure\src\Emulator\Cores\tlib\softfloat-3\COPYING.txt" "%RECIPE_DIR%\softfloat-3-COPYING.txt"

call powershell -ExecutionPolicy Bypass -File "%RECIPE_DIR%\helpers\renode_build_with_cmake.ps1"
if %errorlevel% neq 0 exit /b  %errorlevel%

rem Install procedure into a conda path that renode-cli can retrieve
set "CONFIGURATION=Release"
set "CORES_PATH=%SRC_DIR%\src\Infrastructure\src\Emulator\Cores"
set "CORES_BIN_PATH=%CORES_PATH%\bin\%CONFIGURATION%"

mkdir "%PREFIX%\Library\lib\%PKG_NAME%"
icacls "%PREFIX%\Library\lib\%PKG_NAME%" /grant Users:(OI)(CI)F /T
robocopy "%CORES_BIN_PATH%\lib" "%PREFIX%\Library\lib\%PKG_NAME%" /E /COPY:DATSO

:: Setting conda host environment variables
:: if not exist "%PREFIX%\etc\conda\activate.d\" mkdir "%PREFIX%\etc\conda\activate.d\"
:: if not exist "%PREFIX%\etc\conda\deactivate.d\" mkdir "%PREFIX%\etc\conda\deactivate.d\"
::
:: copy "%RECIPE_DIR%\scripts\activate.bat" "%PREFIX%\etc\conda\activate.d\%PKG_NAME%-activate.bat" > nul
:: if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
:: copy "%RECIPE_DIR%\scripts\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\%PKG_NAME%-deactivate.bat" > nul
:: if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

endlocal

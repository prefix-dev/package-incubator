#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Update the submodule CMakeLists.txt with a recent version (post-CMake conversion)
CMAKEFILES_TXT="src/Emulator/Cores/CMakeLists.txt"
cp "cmake-renode-infrastructure/${CMAKEFILES_TXT}" "${SRC_DIR}/src/Infrastructure/${CMAKEFILES_TXT}"
cp cmake-tlib/CMakeLists.txt "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib"
cp cmake-tlib/tcg/CMakeLists.txt "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/tcg"

if [[ "${target_platform}" == "osx-arm64" ]]; then
  # We use Clang on osx-arm64, which does not support -Wno-error=clobbered/-Wno-error=clobbered
  sed -i -E 's/add_definitions\(-Wno-error=clobbered\)/string(REPLACE "-Wno-error=clobbered" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")/' \
    "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/CMakeLists.txt" \
    "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/CMakeLists.txt" \
    "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/tcg/CMakeLists.txt"

  # Oddly, it does not find additional.h, trying to add the include path
  sed -i -E 's|    \$\{CMAKE_SOURCE_DIR\}|    \$\{CMAKE_SOURCE_DIR\} \$\{CMAKE_SOURCE_DIR\}/tlib/tcg \$\{CMAKE_SOURCE_DIR\}/\.\.|' \
    "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/tcg/CMakeLists.txt"
  grep -r "CMAKE_SOURCE_DIR" "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/tcg/CMakeLists.txt"
  ls -l "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/tcg/additional.h"
fi

cp cmake-tlib/LICENSE "${RECIPE_DIR}/tlib-LICENSE"
cp "${SRC_DIR}/src/Infrastructure/src/Emulator/Cores/tlib/softfloat-3/COPYING.txt" "${RECIPE_DIR}/softfloat-3-COPYING.txt"

chmod +x build.sh tools/building/check_weak_implementations.sh
${RECIPE_DIR}/helpers/renode_build_with_cmake.sh

# Install procedure into a conda path that renode-cli can retrieve
CONFIGURATION="Release"
CORES_PATH="${SRC_DIR}/src/Infrastructure/src/Emulator/Cores"
CORES_BIN_PATH="$CORES_PATH/bin/$CONFIGURATION"

mkdir -p "${PREFIX}/lib/${PKG_NAME}"
tar -c -C "${CORES_BIN_PATH}/lib" . | tar -x -C "${PREFIX}/lib/${PKG_NAME}"

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
# for CHANGE in "activate" "deactivate"
# do
#   mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
#   cp "${RECIPE_DIR}/scripts/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}-${CHANGE}.sh"
# done
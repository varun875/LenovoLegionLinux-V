#!/bin/bash
set -ex

# Get workspace root directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${DIR}"

# 1. Build builder Docker image
docker build -t lenovolegionlinux-builder -f deploy/Dockerfile.build_arch .

# 2. Create out directory on the host if it doesn't exist
mkdir -p out

# 3. Run build steps inside the Docker container
docker run --rm \
  -v "${DIR}:/src:ro" \
  -v "${DIR}/out:/out" \
  lenovolegionlinux-builder bash -c '
    set -ex
    
    # Copy source to building directory to keep host clean
    cp -r /src /build/lenovolegionlinux
    cd /build/lenovolegionlinux
    
    # 1. Build Arch Package
    cd deploy/arch
    makepkg -sc --noconfirm
    
    # 2. Build PyInstaller binaries
    cd /build/lenovolegionlinux
    ./deploy/build_pyinstaller.sh
    
    # 3. Copy artifacts back to the output folder
    cp /build/lenovolegionlinux/deploy/arch/*.pkg.tar.zst /out/
    mkdir -p /out/pyinstaller
    cp -f /build/lenovolegionlinux/python/legion_linux/dist/legion_gui /out/pyinstaller/
    cp -f /build/lenovolegionlinux/python/legion_linux/dist/legion_cli /out/pyinstaller/
    
    echo "=== Build completed successfully! ==="
  '

echo "Built packages are located in: ${DIR}/out/"

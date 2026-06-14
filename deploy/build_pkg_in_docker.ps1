$ErrorActionPreference = "Stop"

# Get workspace root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$WorkspaceRoot = (Get-Item (Join-Path $ScriptDir "..")).FullName

cd $WorkspaceRoot

# 1. Build builder Docker image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t lenovolegionlinux-builder -f deploy/Dockerfile.build_arch .

# 2. Create out directory on the host if it doesn't exist
$OutDir = Join-Path $WorkspaceRoot "out"
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

# 3. Run build steps inside the Docker container
Write-Host "Running build inside Docker container..." -ForegroundColor Cyan
docker run --rm `
  -v "${WorkspaceRoot}:/src:ro" `
  -v "${OutDir}:/out" `
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

Write-Host "Built packages are located in: $OutDir" -ForegroundColor Green

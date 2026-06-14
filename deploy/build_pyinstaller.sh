#!/bin/bash
set -ex

# Go to repository root
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${DIR}/python/legion_linux"

# Ensure dependencies and pyinstaller are installed
python3 -m pip install --upgrade pip
python3 -m pip install PyQt6 PyYAML darkdetect argcomplete pyinstaller build --break-system-packages || \
python3 -m pip install PyQt6 PyYAML darkdetect argcomplete pyinstaller build

# Build legion_gui standalone executable
pyinstaller --clean --noconfirm --onefile --windowed \
  --add-data "legion_linux/legion_logo.png:legion_linux" \
  --add-data "legion_linux/legion_logo_light.png:legion_linux" \
  --add-data "legion_linux/legion_logo_dark.png:legion_linux" \
  --name legion_gui \
  legion_linux/legion_gui.py

# Build legion_cli standalone executable
pyinstaller --clean --noconfirm --onefile \
  --name legion_cli \
  legion_linux/legion_cli.py

echo "Standalone PyInstaller binaries created in: python/legion_linux/dist/"

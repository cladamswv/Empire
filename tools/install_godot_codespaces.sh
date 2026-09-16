#!/usr/bin/env bash
set -euo pipefail
VERSION="4.7.2"
TAG="${VERSION}-stable"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/empires-rise-godot"
mkdir -p "$BIN_DIR" "$CACHE_DIR"
ZIP="$CACHE_DIR/Godot_v${TAG}_linux.x86_64.zip"
URL="https://github.com/godotengine/godot-builds/releases/download/${TAG}/Godot_v${TAG}_linux.x86_64.zip"

if [[ ! -f "$ZIP" ]]; then
  echo "Downloading Godot $VERSION..."
  curl -fL --retry 3 "$URL" -o "$ZIP"
fi
rm -rf "$CACHE_DIR/unpacked"
mkdir -p "$CACHE_DIR/unpacked"
unzip -oq "$ZIP" -d "$CACHE_DIR/unpacked"
EXE="$(find "$CACHE_DIR/unpacked" -maxdepth 1 -type f -name 'Godot_v*-stable_linux.x86_64' | head -n1)"
chmod +x "$EXE"
cp "$EXE" "$BIN_DIR/godot"
echo "Installed $($BIN_DIR/godot --version) to $BIN_DIR/godot"

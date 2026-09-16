#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/assets/cc0/roman_bathhouse"
mkdir -p "$DEST"

fetch() {
  local url="$1"
  local out="$2"
  echo "Fetching CC0 asset: $(basename "$out")"
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 "$url" -o "$out"
}

# 3DAssets.dev Roman Bathhouse and Palaestra kit, CC0 1.0 Universal.
# These are accents only. The city still renders if they are absent.
fetch "https://cdn.3dassets.dev/assets/37861/v1/model.glb" "$DEST/corinthian_column.glb"
fetch "https://cdn.3dassets.dev/assets/37870/v1/model.glb" "$DEST/boundary_gate.glb"
fetch "https://cdn.3dassets.dev/assets/37900/v1/model.glb" "$DEST/amphora_rack.glb"
fetch "https://cdn.3dassets.dev/assets/37894/v1/model.glb" "$DEST/bronze_brazier.glb"

cat > "$DEST/README-LICENSE.txt" <<'TXT'
Roman Bathhouse and Palaestra asset accents
Source: https://3dassets.dev/packs/roman-bathhouse-and-palaestra
License: CC0 1.0 Universal
Attribution: not required
Files fetched by tools/fetch_cc0_assets.sh

Models used:
- Corinthian Column: https://3dassets.dev/assets/roman-bathhouse-and-palaestra-column-corinthian-6e5a51d3
- Boundary Wall Gate: https://3dassets.dev/assets/roman-bathhouse-and-palaestra-boundary-wall-gate-03f1cb0d
- Amphora Rack: part of Roman Bathhouse and Palaestra kit
- Bronze Brazier: part of Roman Bathhouse and Palaestra kit
TXT

echo "CC0 Roman accent assets installed in $DEST"

#!/usr/bin/env bash
# Export data from DuckDB and release to GitHub.
# Usage: bash scripts/release_data.sh [--market cn|us] [version]
#
# This script:
# 1. Runs DuckDB export_to_parquet → output/
# 2. Packages output/ into a single tar.gz
# 3. Creates/updates a GitHub Release on this repo
#
# Prerequisites: poetry install, gh auth login

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Parse arguments
MARKET="cn"
VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --market) MARKET="$2"; shift 2 ;;
    *) VERSION="$1"; shift ;;
  esac
done

MARKET=$(echo "$MARKET" | tr '[:upper:]' '[:lower:]')
if [[ "$MARKET" != "cn" && "$MARKET" != "us" ]]; then
  echo "ERROR: --market must be cn or us"
  exit 1
fi

if [ "$MARKET" = "us" ]; then
  DB_PATH="$PROJECT_ROOT/data/us_stocks.duckdb"
else
  DB_PATH="$PROJECT_ROOT/data/simtradedata.duckdb"
fi

if [ ! -f "$DB_PATH" ]; then
  echo "ERROR: $DB_PATH not found. Run download first."
  exit 1
fi

# 1. Export
echo "=== Exporting $MARKET data from DuckDB ==="
cd "$PROJECT_ROOT"
poetry run python -c "
from simtradedata.writers.duckdb_writer import DuckDBWriter
w = DuckDBWriter('$DB_PATH')
w.export_to_parquet('$OUTPUT_DIR', market='$MARKET')
w.close()
"

# Read version from exported manifest
MANIFEST="$OUTPUT_DIR/manifest.json"
if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: Export did not produce manifest.json"
  exit 1
fi

EXPORTED_VERSION=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['version'])")
VERSION="${VERSION:-$EXPORTED_VERSION}"
TAG="data-${MARKET}-v${VERSION}"
ARCHIVE="/tmp/simtradelab-data-${MARKET}-${VERSION}.tar.gz"

echo ""
echo "=== Packaging ${MARKET} v${VERSION} ==="
tar -czf "$ARCHIVE" -C "$OUTPUT_DIR" .

SIZE=$(ls -lh "$ARCHIVE" | awk '{print $5}')
echo "  -> $ARCHIVE ($SIZE)"

# 3. Release
echo ""
echo "=== Uploading to GitHub ==="
if gh release view "$TAG" >/dev/null 2>&1; then
  echo "  Release $TAG exists, updating..."
  gh release upload "$TAG" "$ARCHIVE" --clobber
else
  gh release create "$TAG" \
    --title "SimTradeData ${MARKET} v${VERSION}" \
    --notes "Data version ${VERSION} (${MARKET})" \
    "$ARCHIVE"
fi

rm -f "$ARCHIVE"
echo ""
echo "=== Done: $(gh release view "$TAG" --json url -q .url) ==="

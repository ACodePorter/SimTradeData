#!/usr/bin/env bash
# Export data from DuckDB and release to GitHub.
# Usage: bash scripts/release_data.sh [version]
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
DB_PATH="$PROJECT_ROOT/data/simtradedata.duckdb"

if [ ! -f "$DB_PATH" ]; then
  echo "ERROR: $DB_PATH not found. Run download first."
  exit 1
fi

# 1. Export
echo "=== Exporting from DuckDB ==="
cd "$PROJECT_ROOT"
poetry run python -c "
from simtradedata.writers.duckdb_writer import DuckDBWriter
w = DuckDBWriter('$DB_PATH')
w.export_to_parquet('$OUTPUT_DIR')
w.close()
"

# Read version from exported manifest
MANIFEST="$OUTPUT_DIR/manifest.json"
if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: Export did not produce manifest.json"
  exit 1
fi

EXPORTED_VERSION=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['version'])")
VERSION="${1:-$EXPORTED_VERSION}"
TAG="data-v${VERSION}"
ARCHIVE="/tmp/simtradelab-data-${VERSION}.tar.gz"

echo ""
echo "=== Packaging v${VERSION} ==="
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
    --title "SimTradeData v${VERSION}" \
    --notes "Data version ${VERSION}" \
    "$ARCHIVE"
fi

rm -f "$ARCHIVE"
echo ""
echo "=== Done: $(gh release view "$TAG" --json url -q .url) ==="

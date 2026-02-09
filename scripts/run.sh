#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: run.sh [--format text|json|markdown] FILE_A FILE_B"
  echo ""
  echo "Compare two config files across formats."
  echo "Supports: JSON, YAML, TOML, INI, .env"
  echo ""
  echo "Options:"
  echo "  --format FORMAT   Output format: text (default), json, markdown"
  echo "  --help            Show this help"
}

FORMAT="text"
FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --format) FORMAT="$2"; shift 2 ;;
    *) FILES+=("$1"); shift ;;
  esac
done

if [ ${#FILES[@]} -lt 2 ]; then
  echo "Error: two config files required. Use --help for usage." >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

"$SCRIPT_DIR/normalize.sh" "${FILES[0]}" > "$TMPDIR/a.json"
"$SCRIPT_DIR/normalize.sh" "${FILES[1]}" > "$TMPDIR/b.json"
"$SCRIPT_DIR/diff.sh" "$TMPDIR/a.json" "$TMPDIR/b.json" | "$SCRIPT_DIR/format.sh" --format "$FORMAT"

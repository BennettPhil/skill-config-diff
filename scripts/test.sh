#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

check_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    ((PASS++))
    echo "  PASS: $desc"
  else
    ((FAIL++))
    echo "  FAIL: $desc — output does not contain '$needle'"
    echo "    output: $haystack"
  fi
}

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Running tests for: config-diff"
echo "================================="

# --- Normalize tests ---
echo ""
echo "Normalize:"

echo '{"b":1,"a":2}' > "$TMPDIR/test.json"
RESULT=$("$SCRIPT_DIR/normalize.sh" "$TMPDIR/test.json")
check_contains "JSON sorted keys" '"a": 2' "$RESULT"

printf 'name: test\nport: 8080' > "$TMPDIR/test.yaml"
RESULT=$("$SCRIPT_DIR/normalize.sh" "$TMPDIR/test.yaml")
check_contains "YAML to JSON" '"name": "test"' "$RESULT"

printf 'DB_HOST=localhost\nDB_PORT=5432' > "$TMPDIR/test.env"
RESULT=$("$SCRIPT_DIR/normalize.sh" "$TMPDIR/test.env")
check_contains "env to JSON" '"DB_HOST": "localhost"' "$RESULT"

# --- Diff tests ---
echo ""
echo "Diff:"

echo '{"a":1,"b":2}' > "$TMPDIR/a.json"
echo '{"a":1,"b":3,"c":4}' > "$TMPDIR/b.json"
RESULT=$("$SCRIPT_DIR/diff.sh" "$TMPDIR/a.json" "$TMPDIR/b.json")
check_contains "detects added key" '"path": "c"' "$RESULT"
check_contains "detects changed value" '"old": 2' "$RESULT"

echo '{"x":1}' > "$TMPDIR/c.json"
echo '{"x":1}' > "$TMPDIR/d.json"
RESULT=$("$SCRIPT_DIR/diff.sh" "$TMPDIR/c.json" "$TMPDIR/d.json")
check_contains "identical configs" '"identical": true' "$RESULT"

# --- Full pipeline ---
echo ""
echo "Full pipeline:"

echo '{"host":"localhost","port":3000}' > "$TMPDIR/dev.json"
printf 'host: production.example.com\nport: 8080' > "$TMPDIR/prod.yaml"
export CONFIG_DIFF_COLOR=0
RESULT=$("$SCRIPT_DIR/run.sh" "$TMPDIR/dev.json" "$TMPDIR/prod.yaml")
check_contains "cross-format diff detects change" "changed" "$RESULT"

RESULT=$("$SCRIPT_DIR/run.sh" --format json "$TMPDIR/dev.json" "$TMPDIR/prod.yaml")
check_contains "JSON format output" '"changed"' "$RESULT"

# --- Help ---
echo ""
echo "Help:"

RESULT=$("$SCRIPT_DIR/run.sh" --help 2>&1)
check_contains "run.sh --help" "Usage" "$RESULT"

echo ""
echo "================================="
echo "Results: $PASS passed, $FAIL failed, $((PASS + FAIL)) total"
[ "$FAIL" -eq 0 ] || exit 1

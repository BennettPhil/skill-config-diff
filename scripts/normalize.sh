#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: normalize.sh [--format FORMAT] [FILE]"
  echo "Convert a config file to sorted, normalized JSON."
  echo "Auto-detects format from extension or content."
  echo "Reads from stdin if no file given."
}

FORMAT=""
FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --format) FORMAT="$2"; shift 2 ;;
    *) FILE="$1"; shift ;;
  esac
done

if [ -n "$FILE" ] && [ "$FILE" != "-" ]; then
  INPUT=$(cat "$FILE")
  # Auto-detect from extension if format not given
  if [ -z "$FORMAT" ]; then
    case "$FILE" in
      *.json) FORMAT="json" ;;
      *.yaml|*.yml) FORMAT="yaml" ;;
      *.toml) FORMAT="toml" ;;
      *.ini|*.cfg) FORMAT="ini" ;;
      *.env) FORMAT="env" ;;
    esac
  fi
else
  INPUT=$(cat)
fi

echo "$INPUT" | python3 -c "
import sys, json, re

content = sys.stdin.read().strip()
fmt = '$FORMAT'

# Auto-detect from content if not specified
if not fmt:
    try:
        json.loads(content)
        fmt = 'json'
    except Exception:
        lines = content.split('\n')
        has_colon = any(': ' in l for l in lines if not l.strip().startswith('#'))
        has_eq = any('=' in l and not l.strip().startswith('#') for l in lines)
        has_bracket = any(l.strip().startswith('[') for l in lines)
        if content.startswith('---') or (has_colon and not has_eq):
            fmt = 'yaml'
        elif has_bracket and has_eq:
            fmt = 'ini'
        elif has_eq and not has_bracket:
            fmt = 'env'
        else:
            fmt = 'json'  # fallback

if fmt == 'json':
    data = json.loads(content)
elif fmt == 'yaml':
    import yaml
    data = yaml.safe_load(content) or {}
elif fmt == 'toml':
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib
    data = tomllib.loads(content)
elif fmt == 'ini':
    import configparser
    parser = configparser.ConfigParser()
    parser.read_string(content)
    data = {s: dict(parser[s]) for s in parser.sections()}
elif fmt == 'env':
    data = {}
    for line in content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        line = line.removeprefix('export').strip()
        if '=' in line:
            k, _, v = line.partition('=')
            data[k.strip()] = v.strip().strip('\"').strip(\"'\")
else:
    print(f'Error: unknown format: {fmt}', file=sys.stderr)
    sys.exit(1)

print(json.dumps(data, indent=2, sort_keys=True))
"

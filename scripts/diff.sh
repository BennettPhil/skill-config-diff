#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: diff.sh FILE_A FILE_B"
  echo "Compute structural diff between two JSON files."
  echo "Outputs JSON with added, removed, and changed keys."
}

if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ $# -lt 2 ]; then
  echo "Error: two files required" >&2
  exit 1
fi

FILE_A="$1"
FILE_B="$2"

python3 -c "
import json, sys

with open('$FILE_A') as f:
    a = json.load(f)
with open('$FILE_B') as f:
    b = json.load(f)

def deep_diff(obj_a, obj_b, path=''):
    added = []
    removed = []
    changed = []

    if isinstance(obj_a, dict) and isinstance(obj_b, dict):
        all_keys = set(list(obj_a.keys()) + list(obj_b.keys()))
        for key in sorted(all_keys):
            p = f'{path}.{key}' if path else key
            if key not in obj_a:
                added.append({'path': p, 'value': obj_b[key]})
            elif key not in obj_b:
                removed.append({'path': p, 'value': obj_a[key]})
            elif obj_a[key] != obj_b[key]:
                if isinstance(obj_a[key], dict) and isinstance(obj_b[key], dict):
                    sub = deep_diff(obj_a[key], obj_b[key], p)
                    added.extend(sub['added'])
                    removed.extend(sub['removed'])
                    changed.extend(sub['changed'])
                else:
                    changed.append({'path': p, 'old': obj_a[key], 'new': obj_b[key]})
    elif obj_a != obj_b:
        changed.append({'path': path or '<root>', 'old': obj_a, 'new': obj_b})

    return {'added': added, 'removed': removed, 'changed': changed}

result = deep_diff(a, b)
result['identical'] = not (result['added'] or result['removed'] or result['changed'])
print(json.dumps(result, indent=2))
"

#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: format.sh [--format text|json|markdown]"
  echo "Format diff output for display."
  echo "Reads JSON diff from stdin."
}

FORMAT="text"
COLOR="${CONFIG_DIFF_COLOR:-1}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --format) FORMAT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

python3 -c "
import sys, json

fmt = '$FORMAT'
color = bool(int('$COLOR'))
data = json.loads(sys.stdin.read())

RED = '\033[31m' if color else ''
GREEN = '\033[32m' if color else ''
YELLOW = '\033[33m' if color else ''
RESET = '\033[0m' if color else ''

if data.get('identical'):
    print('Configs are identical.')
    sys.exit(0)

if fmt == 'json':
    print(json.dumps(data, indent=2))

elif fmt == 'markdown':
    if data['added']:
        print('### Added')
        print('')
        for item in data['added']:
            print(f'- **{item[\"path\"]}**: \`{json.dumps(item[\"value\"])}\`')
        print('')
    if data['removed']:
        print('### Removed')
        print('')
        for item in data['removed']:
            print(f'- **{item[\"path\"]}**: \`{json.dumps(item[\"value\"])}\`')
        print('')
    if data['changed']:
        print('### Changed')
        print('')
        for item in data['changed']:
            print(f'- **{item[\"path\"]}**: \`{json.dumps(item[\"old\"])}\` -> \`{json.dumps(item[\"new\"])}\`')
        print('')

elif fmt == 'text':
    if data['added']:
        for item in data['added']:
            print(f'{GREEN}+ {item[\"path\"]}: {json.dumps(item[\"value\"])}{RESET}')
    if data['removed']:
        for item in data['removed']:
            print(f'{RED}- {item[\"path\"]}: {json.dumps(item[\"value\"])}{RESET}')
    if data['changed']:
        for item in data['changed']:
            print(f'{YELLOW}~ {item[\"path\"]}: {json.dumps(item[\"old\"])} -> {json.dumps(item[\"new\"])}{RESET}')

    total = len(data['added']) + len(data['removed']) + len(data['changed'])
    print(f'')
    print(f'{len(data[\"added\"])} added, {len(data[\"removed\"])} removed, {len(data[\"changed\"])} changed ({total} total)')
"

# Config Diff

Compare configuration files across formats (JSON, YAML, TOML, INI, .env) by normalizing to JSON and producing structural diffs.

## Prerequisites

- Python 3.6+
- PyYAML (`pip install pyyaml`)

## Usage

```bash
# Compare two config files
./scripts/run.sh dev.yaml prod.json

# Markdown output
./scripts/run.sh --format markdown config.env config.yaml

# Normalize a single file
./scripts/normalize.sh config.yaml

# Pipeline
./scripts/normalize.sh a.yaml > /tmp/a.json
./scripts/normalize.sh b.toml > /tmp/b.json
./scripts/diff.sh /tmp/a.json /tmp/b.json | ./scripts/format.sh --format text
```

## Test

```bash
./scripts/test.sh
```

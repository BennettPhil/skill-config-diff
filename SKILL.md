---
name: config-diff
description: Compare configuration files across formats by normalizing to JSON and producing structured diffs.
version: 0.1.0
license: Apache-2.0
---

# Config Diff

Compare two configuration files that may be in different formats (JSON, YAML, TOML, INI, .env) by normalizing both to JSON and producing a structural diff.

## Purpose

When migrating between config formats or comparing configs across environments (dev vs prod), a plain text diff is noisy and misleading. This skill normalizes both files to a common JSON representation, then computes a structural diff showing added, removed, and changed keys with their values.

## Scripts Overview

| Script | Description |
|--------|-------------|
| `scripts/run.sh` | Main entry point — diff two config files |
| `scripts/normalize.sh` | Convert any supported config format to sorted JSON |
| `scripts/diff.sh` | Compute structural diff between two JSON objects |
| `scripts/format.sh` | Format diff output as text, JSON, or markdown |
| `scripts/test.sh` | Run test suite |

## Pipeline Examples

```bash
# Compare YAML and JSON configs
./scripts/run.sh config.yaml config.json

# Normalize first, then diff manually
./scripts/normalize.sh config.yaml > /tmp/a.json
./scripts/normalize.sh config.json > /tmp/b.json
./scripts/diff.sh /tmp/a.json /tmp/b.json | ./scripts/format.sh --format markdown

# JSON output for tooling
./scripts/run.sh --format json dev.env prod.env
```

## Inputs and Outputs

All scripts read from files or stdin. Format auto-detection by file extension or content. Diff output goes to stdout.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CONFIG_DIFF_IGNORE_ORDER` | `1` | Ignore array element ordering in comparisons |
| `CONFIG_DIFF_COLOR` | `1` | Colorize text output (set to 0 for piping) |

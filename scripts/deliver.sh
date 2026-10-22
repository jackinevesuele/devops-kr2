#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-devops:kr2/}"
rsync -avz --delete --exclude=.env --exclude='.env.*' --include=.env.example \
    --exclude=.git --exclude=__pycache__ --exclude=.pytest_cache --dry-run "$project_dir/" "$target"
rsync -avz --delete --exclude=.env --exclude='.env.*' --include=.env.example \
    --exclude=.git --exclude=__pycache__ --exclude=.pytest_cache "$project_dir/" "$target"

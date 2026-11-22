#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-devops:kr2/}"
rsync -avz --delete --include=.env.example --exclude=.env --exclude='.env.*' \
    --exclude=.git --exclude=__pycache__ --exclude=.pytest_cache --dry-run "$project_dir/" "$target"
rsync -avz --delete --include=.env.example --exclude=.env --exclude='.env.*' \
    --exclude=.git --exclude=__pycache__ --exclude=.pytest_cache "$project_dir/" "$target"

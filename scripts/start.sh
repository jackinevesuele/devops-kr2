#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
command -v docker >/dev/null
command -v openssl >/dev/null
server_version="$(docker version --format '{{.Server.Version}}')"
if [ "$(printf '%s\n' 28.0 "$server_version" | sort -V | head -n 1)" != 28.0 ]; then
    echo 'Требуется Docker Engine 28.0 или новее' >&2; exit 1
fi
if [ ! -f .env ]; then
    umask 077
    printf 'REDIS_PASSWORD=%s\n' "$(openssl rand -hex 32)" > .env
fi
test "$(stat -c '%U' .env)" = "$(id -un)"
chmod 600 .env
grep -Eq '^REDIS_PASSWORD=[[:xdigit:]]{32,}$' .env
unset REDIS_PASSWORD
docker compose --env-file .env up -d --build --wait
curl --fail --silent --show-error http://127.0.0.1:8002/health

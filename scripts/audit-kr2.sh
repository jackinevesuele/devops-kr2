#!/usr/bin/env bash
set -uo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
unset REDIS_PASSWORD
failed=0
check() {
    local label="$1"; shift
    if "$@"; then printf '[OK] %s\n' "$label"
    else printf '[FAIL] %s\n' "$label"; failed=1; fi
}
redis_healthy() {
    local cid
    cid="$(docker compose ps -q redis)" || return 1
    test -n "$cid" || return 1
    test "$(docker inspect -f '{{.State.Health.Status}}' "$cid")" = healthy
}
app_loopback() { test "$(docker compose port app 8002)" = '127.0.0.1:8002'; }
redis_unpublished() {
    local binding
    binding="$(docker compose port redis 6379 2>/dev/null)" || binding=''
    test -z "$binding" || test "$binding" = ':0'
}
env_mode() { test "$(stat -c '%a' .env)" = 600; }
app_nonroot() { docker compose exec -T app python -c 'import os,sys;sys.exit(os.getuid()==0)'; }
redis_nonroot() { docker compose exec -T redis awk '$1 == "Uid:" {exit($2 == 0)}' /proc/1/status; }
check 'Redis healthy' redis_healthy
check 'app опубликован только на 127.0.0.1:8002' app_loopback
check 'Redis не опубликован' redis_unpublished
check 'Права .env равны 600' env_mode
check 'app не от root' app_nonroot
check 'Redis PID 1 не от root' redis_nonroot
check 'Сертификат действует ещё 30 дней' openssl x509 -in /etc/ssl/certs/kr2.crt -noout -checkend 2592000
check 'SAN соответствует notes.devops.local' openssl x509 -in /etc/ssl/certs/kr2.crt -noout -checkhost notes.devops.local
check 'Ресурс kr2 активирован' test -L /etc/nginx/sites-enabled/kr2
check 'Nginx проходит проверку' sudo nginx -t
check 'HTTPS с проверкой сертификата' curl --fail --silent --show-error --cacert /etc/ssl/certs/kr2.crt --resolve notes.devops.local:443:127.0.0.1 https://notes.devops.local/health
if test -f "$HOME/ufw-before-kr2.txt"; then
    check 'Правила UFW не изменились' bash -c 'diff <(sudo ufw status numbered) "$HOME/ufw-before-kr2.txt"'
else
    echo '[FAIL] Нет исходного снимка правил UFW'; failed=1
fi
exit "$failed"

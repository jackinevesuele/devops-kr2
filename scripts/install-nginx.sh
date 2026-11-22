#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
systemctl is-active --quiet nginx
if ! sudo test -f /etc/ssl/certs/kr2.crt && ! sudo test -f /etc/ssl/private/kr2.key; then
    sudo openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/ssl/private/kr2.key -out /etc/ssl/certs/kr2.crt \
        -subj '/CN=notes.devops.local' \
        -addext 'subjectAltName=DNS:notes.devops.local'
fi
sudo test -f /etc/ssl/private/kr2.key
sudo openssl x509 -in /etc/ssl/certs/kr2.crt -noout -checkhost notes.devops.local
sudo chown root:root /etc/ssl/private/kr2.key
sudo chmod 600 /etc/ssl/private/kr2.key
sudo chmod 644 /etc/ssl/certs/kr2.crt
backup_dir="$HOME/kr2-nginx-backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup_dir"
had_config=false
had_link=false
if sudo test -f /etc/nginx/sites-available/kr2; then
    sudo cp -a /etc/nginx/sites-available/kr2 "$backup_dir/kr2"
    had_config=true
fi
if sudo test -e /etc/nginx/sites-enabled/kr2 || sudo test -L /etc/nginx/sites-enabled/kr2; then
    had_link=true
fi
sudo install -o root -g root -m 644 "$project_dir/nginx/kr2" /etc/nginx/sites-available/kr2
sudo ln -sfn /etc/nginx/sites-available/kr2 /etc/nginx/sites-enabled/kr2
if ! sudo nginx -t; then
    if "$had_config"; then
        sudo cp -a "$backup_dir/kr2" /etc/nginx/sites-available/kr2
    else
        sudo rm -f -- /etc/nginx/sites-available/kr2
    fi
    if ! "$had_link"; then sudo rm -f -- /etc/nginx/sites-enabled/kr2; fi
    echo 'Проверка Nginx не пройдена, предыдущая конфигурация восстановлена' >&2
    exit 1
fi
sudo systemctl reload nginx

# КР2 — вариант 2

Босарев Евгений, ЭФБО-11-24.
Домен: notes.devops.local. Порт приложения: 8002.

Источник: https://gitverse.ru/dgimatdinov/kr2-template
Логика app.py и requirements.txt сохранены; в app.py добавлен только комментарий KR2: Bosarev.

## Состояние

Подготовлены Dockerfile, Compose, конфигурация Nginx, ревизия 11 дефектов и сценарии доставки и аудита.
Серверный прогон Docker, HTTPS, сохранности данных и UFW из текущей сессии ещё не выполнен.
Для завершения нужен Ubuntu Server, настроенный в ПР5–7. PR не следует объединять до защиты.

## На хосте

Проверьте SSH-псевдоним devops. Из Bash или WSL выполните:

```bash
bash scripts/deliver.sh
```

## На сервере

Создайте снимок 06-before-kr2 средствами гипервизора.
Сохраните правила UFW до изменений, затем запустите:

```bash
sudo ufw status numbered > ~/ufw-before-kr2.txt
cd ~/kr2
bash scripts/start.sh
bash scripts/install-nginx.sh
bash scripts/audit-kr2.sh
```

Сценарий start.sh формирует случайный пароль только при отсутствии .env. Существующий секрет сохраняется.
Пароль не выводится; не прикладывайте вывод docker compose config или docker inspect с аргументами Redis к отчёту.
Сценарии не меняют UFW и конфигурацию devops-site. Команды sudo могут запросить пароль пользователя.

## Проверки с хоста

Добавьте в hosts запись: <IP Host-only сервера> notes.devops.local.
Скопируйте публичный сертификат, не закрытый ключ:

```bash
scp devops:/etc/ssl/certs/kr2.crt ~/kr2.crt
curl -I http://notes.devops.local/
curl --cacert ~/kr2.crt https://notes.devops.local/
curl --cacert ~/kr2.crt https://notes.devops.local/whoami
curl -m 3 http://notes.devops.local:8002/health
```

Последняя команда должна завершиться ошибкой подключения: приложение публикуется только на loopback сервера.
Проверьте отдельно прежние ресурсы devops.local и devops.local/app/ сертификатом devops.crt.

## Сохранность данных

```bash
cd ~/kr2
unset REDIS_PASSWORD
curl -fsS http://127.0.0.1:8002/
docker compose down
docker volume ls
docker compose up -d --wait
curl -fsS http://127.0.0.1:8002/
```

Счётчик должен продолжиться. Флаг -v не использовать.
После полного прогона нужен снимок 07-kr2 и собственные скриншоты результатов.

#!/usr/bin/env bash
#
# Deploy the mock Django app to a VPS over SSH.
#
# Usage:
#   1. cp .env.deploy.example .env.deploy   и заполни своими данными
#   2. ./deploy.sh
#
# Что делает:
#   - синхронизирует код на VPS через rsync (без .git, .venv, БД)
#   - ставит Docker, если его нет
#   - собирает и поднимает контейнер через `docker compose`
#   - ждёт, пока /health/ ответит, иначе показывает логи и падает
#
set -euo pipefail

cd "$(dirname "$0")"

# --- конфиг ------------------------------------------------------------------
if [ -f .env.deploy ]; then
  # shellcheck disable=SC1091
  set -a; . ./.env.deploy; set +a
fi

VPS_HOST="${VPS_HOST:?VPS_HOST не задан (см. .env.deploy.example)}"
VPS_USER="${VPS_USER:-root}"
VPS_PORT="${VPS_PORT:-22}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/mock-django}"
DOMAIN="${DJANGO_ALLOWED_HOSTS:-$VPS_HOST}"

SSH="ssh -p ${VPS_PORT} ${VPS_USER}@${VPS_HOST}"

echo "==> Деплой на ${VPS_USER}@${VPS_HOST}:${DEPLOY_DIR}"

# --- 1. синхронизация кода ---------------------------------------------------
echo "==> Синхронизирую файлы (rsync)..."
$SSH "mkdir -p ${DEPLOY_DIR}"
rsync -az --delete \
  --exclude '.git' \
  --exclude '.venv' \
  --exclude '__pycache__' \
  --exclude '*.sqlite3' \
  --exclude '.env.deploy' \
  -e "ssh -p ${VPS_PORT}" \
  ./ "${VPS_USER}@${VPS_HOST}:${DEPLOY_DIR}/"

# --- 2. установка Docker при необходимости -----------------------------------
echo "==> Проверяю Docker на VPS..."
$SSH 'command -v docker >/dev/null 2>&1 || (echo "Ставлю Docker..." && curl -fsSL https://get.docker.com | sh)'

# --- 3. сборка и запуск ------------------------------------------------------
echo "==> Собираю и поднимаю контейнер..."
$SSH "cd ${DEPLOY_DIR} && DJANGO_ALLOWED_HOSTS='${DOMAIN}' docker compose up -d --build"

# --- 4. health-check ---------------------------------------------------------
echo "==> Жду готовности приложения..."
$SSH '
  for i in $(seq 1 30); do
    if curl -fs http://localhost:8000/health/ >/dev/null; then
      echo "OK — приложение отвечает"; exit 0
    fi
    sleep 2
  done
  echo "Приложение не поднялось, логи:"; cd '"${DEPLOY_DIR}"' && docker compose logs --tail=50; exit 1
'

echo "==> Готово! Открывай: http://${VPS_HOST}:8000/"

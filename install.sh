#!/usr/bin/env bash
# Автоматическая установка и запуск Закоулки
# Опции: --db sqlite|postgres|mysql --mysql-url URL --port 3001 --backend-port 8000
#        --domain NAME (serveo поддомен) --tunnel (включить serveo) --no-run
set -e
DB="sqlite"
MYSQL_URL=""
FRONT_PORT="3001"
BACK_PORT="8000"
DOMAIN=""
TUNNEL=0
RUN=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db) DB="$2"; shift 2;;
    --mysql-url) MYSQL_URL="$2"; shift 2;;
    --port) FRONT_PORT="$2"; shift 2;;
    --backend-port) BACK_PORT="$2"; shift 2;;
    --domain) DOMAIN="$2"; TUNNEL=1; shift 2;;
    --tunnel) TUNNEL=1; shift;;
    --no-run) RUN=0; shift;;
    *) echo "Неизвестная опция: $1"; exit 1;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/backend" ]; then ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/../zakoulki" ]; then ROOT="$(cd "$SCRIPT_DIR/../zakoulki" && pwd)"
elif [ -d "$HOME/projects/zakoulki" ]; then ROOT="$HOME/projects/zakoulki"
else echo "Не найдена папка проекта zakoulki."; exit 1; fi
cd "$ROOT"

command -v python3 >/dev/null 2>&1 || { echo "Установите Python 3.11+"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Установите Node.js LTS"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm не найден"; exit 1; }

cd backend
[ -d venv ] || python3 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt

[ -f .env ] || cp .env.example .env

case "$DB" in
  sqlite) DB_URL="sqlite:///./zakoulki.db";;
  postgres) DB_URL="postgresql+psycopg2://zakoulki:zakoulki@127.0.0.1:5432/zakoulki";;
  mysql) DB_URL="${MYSQL_URL:-mysql+pymysql://root:@127.0.0.1:3306/zakoulki?charset=utf8mb4}";;
  *) echo "Неизвестная БД: $DB"; exit 1;;
esac
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=$DB_URL|" .env

if echo "$DB_URL" | grep -q '^postgresql'; then
  alembic upgrade head
else
  python -c "from app.db.base import Base; from app.db.session import engine; Base.metadata.create_all(bind=engine); print('DB tables created')"
fi
python -m app.db.seed_accounts 2>/dev/null || true

cd ../frontend
[ -d node_modules ] || npm install --silent
[ -f .env.local ] || echo "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" > .env.local
npm run build --silent 2>/dev/null || npm run build

if [ "$RUN" = "1" ]; then
  cd "$ROOT"
  echo "Запуск backend на порту $BACK_PORT..."
  cd backend && source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port "$BACK_PORT" &
  BACKEND_PID=$!
  cd "$ROOT/frontend"
  echo "Запуск frontend на порту $FRONT_PORT..."
  PORT="$FRONT_PORT" npm start &
  FRONTEND_PID=$!
  sleep 4

  if [ "$TUNNEL" = "1" ]; then
    if [ -n "$DOMAIN" ]; then
      echo "Запуск serveo-туннеля для домена $DOMAIN..."
      ssh -o StrictHostKeyChecking=no -R "$DOMAIN:80:localhost:$FRONT_PORT" serveo.net &
      TUNNEL_PID=$!
      sed -i "s|^SITE_URL=.*|SITE_URL=https://$DOMAIN.serveo.net|" backend/.env 2>/dev/null || true
      sed -i "s|^API_URL=.*|API_URL=https://$DOMAIN.serveo.net|" backend/.env 2>/dev/null || true
    else
      echo "Запуск serveo-туннеля (случайный поддомен)..."
      ssh -o StrictHostKeyChecking=no -R "80:localhost:$FRONT_PORT" serveo.net &
      TUNNEL_PID=$!
    fi
    echo "Туннель запущен. Проверьте вывод ssh для URL."
  fi

  echo "Готово! Локально: http://127.0.0.1:$FRONT_PORT"
  echo "Тестовый пользователь: test@test.ru / test1234 (admin)"
  echo "Для остановки: kill $BACKEND_PID $FRONTEND_PID ${TUNNEL_PID:-}"
fi
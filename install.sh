#!/usr/bin/env bash
# Автоматическая установка и запуск Закоулки
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Проверка программ
command -v python3 >/dev/null 2>&1 || { echo "Установите Python 3.11+ с python.org"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Установите Node.js LTS с nodejs.org"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm не найден (устанавливается вместе с Node.js)"; exit 1; }

# Backend
cd backend
if [ ! -d venv ]; then python3 -m venv venv; fi
source venv/bin/activate
pip install -q -r requirements.txt

if [ ! -f .env ]; then
  cp .env.example .env
  sed -i 's|^DATABASE_URL=.*|DATABASE_URL=sqlite:///./zakoulki.db|' .env
fi

alembic upgrade head >/dev/null 2>&1 || alembic upgrade head
python -m app.db.seed_accounts 2>/dev/null || true

# Frontend
cd ../frontend
if [ ! -d node_modules ]; then npm install --silent; fi
if [ ! -f .env.local ]; then
  echo "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" > .env.local
fi
npm run build --silent 2>/dev/null || npm run build

# Запуск
cd "$ROOT"
echo "Запуск backend..."
cd backend && source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
cd "$ROOT/frontend"
echo "Запуск frontend..."
npm start &
FRONTEND_PID=$!

sleep 4
echo "Готово! Откройте http://127.0.0.1:3001"
echo "Тестовый пользователь: test@test.ru / test1234 (admin)"
echo "Для остановки: kill $BACKEND_PID $FRONTEND_PID"
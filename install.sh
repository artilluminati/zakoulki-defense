#!/usr/bin/env bash
# Автоматическая установка Закоулки
set -e
cd "$(dirname "$0")/.."
# если запускают из папки проекта — ок

# 1. Python venv
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. .env
if [ ! -f .env ]; then
  cp .env.example .env
  # по умолчанию SQLite
  sed -i 's|^DATABASE_URL=.*|DATABASE_URL=sqlite:///./zakoulki.db|' .env
fi

# 3. Миграции
alembic upgrade head

# 4. Тестовые аккаунты
python -m app.db.seed_accounts

# 5. Frontend
cd ../frontend
npm install
if [ ! -f .env.local ]; then
  echo "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" > .env.local
fi
npm run build

echo "Готово. Запуск: backend: uvicorn app.main:app --port 8000; frontend: npm start (порт 3001)"
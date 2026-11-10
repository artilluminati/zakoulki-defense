# Автоматическая установка Закоулки (Windows)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$root\.."

# Backend
Set-Location backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    (Get-Content .env) -replace '^DATABASE_URL=.*', 'DATABASE_URL=sqlite:///./zakoulki.db' | Set-Content .env
}

alembic upgrade head
python -m app.db.seed_accounts

# Frontend
Set-Location ..\frontend
npm install
if (-not (Test-Path .env.local)) {
    "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" | Out-File .env.local
}
npm run build

Write-Host "Готово. Запуск: backend: uvicorn app.main:app --port 8000; frontend: npm start (порт 3001)"
# Автоматическая установка и запуск Закоулки (Windows)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path "$root\..").Path
Set-Location $root

# Проверка программ
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { Write-Host "Установите Python 3.11+ с python.org"; exit 1 }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host "Установите Node.js LTS с nodejs.org"; exit 1 }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Write-Host "npm не найден"; exit 1 }

# Backend
Set-Location "$root\backend"
if (-not (Test-Path venv)) { python -m venv venv }
& .\venv\Scripts\Activate.ps1
pip install -q -r requirements.txt

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    (Get-Content .env) -replace '^DATABASE_URL=.*', 'DATABASE_URL=sqlite:///./zakoulki.db' | Set-Content .env
}
alembic upgrade head
python -m app.db.seed_accounts 2>$null

# Frontend
Set-Location "$root\frontend"
if (-not (Test-Path node_modules)) { npm install --silent }
if (-not (Test-Path .env.local)) { "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" | Out-File .env.local }
npm run build

# Запуск
Set-Location "$root\backend"
Start-Process -NoNewWindow -FilePath ".\venv\Scripts\python.exe" -ArgumentList "-m","uvicorn","app.main:app","--host","0.0.0.0","--port","8000"
Set-Location "$root\frontend"
Start-Process -NoNewWindow -FilePath "npm" -ArgumentList "start"

Start-Sleep -Seconds 5
Write-Host "Готово! Откройте http://127.0.0.1:3001"
Write-Host "Тестовый пользователь: test@test.ru / test1234 (admin)"
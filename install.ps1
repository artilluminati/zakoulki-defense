param(
  [string]$Db = "sqlite",
  [string]$MysqlUrl = "mysql+pymysql://root:@127.0.0.1:3306/zakoulki?charset=utf8mb4",
  [int]$Port = 3001,
  [int]$BackendPort = 8000,
  [switch]$NoRun
)
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$scriptDir\backend") { $root = $scriptDir }
elseif (Test-Path "$scriptDir\..\zakoulki") { $root = (Resolve-Path "$scriptDir\..\zakoulki").Path }
elseif (Test-Path "$env:USERPROFILE\projects\zakoulki") { $root = "$env:USERPROFILE\projects\zakoulki" }
else { Write-Host "Не найдена папка проекта zakoulki."; exit 1 }
Set-Location $root

if (-not (Get-Command python -ErrorAction SilentlyContinue)) { Write-Host "Установите Python 3.11+"; exit 1 }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host "Установите Node.js LTS"; exit 1 }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Write-Host "npm не найден"; exit 1 }

Set-Location "$root\backend"
if (-not (Test-Path venv)) { python -m venv venv }
& .\venv\Scripts\Activate.ps1
pip install -q -r requirements.txt

if (-not (Test-Path .env)) { Copy-Item .env.example .env }

switch ($Db) {
  "sqlite" { $dbUrl = "sqlite:///./zakoulki.db" }
  "postgres" { $dbUrl = "postgresql+psycopg2://zakoulki:zakoulki@127.0.0.1:5432/zakoulki" }
  "mysql" { $dbUrl = $MysqlUrl }
  default { Write-Host "Неизвестная БД: $Db"; exit 1 }
}
(Get-Content .env) -replace '^DATABASE_URL=.*', "DATABASE_URL=$dbUrl" | Set-Content .env

if ($dbUrl -like 'postgresql*') { alembic upgrade head }
else { python -c "from app.db.base import Base; from app.db.session import engine; Base.metadata.create_all(bind=engine); print('DB tables created')" }
python -m app.db.seed_accounts 2>$null

Set-Location "$root\frontend"
if (-not (Test-Path node_modules)) { npm install --silent }
if (-not (Test-Path .env.local)) { "NEXT_PUBLIC_YANDEX_MAPS_API_KEY=" | Out-File .env.local }
npm run build

if (-not $NoRun) {
  Set-Location "$root\backend"
  Start-Process -NoNewWindow -FilePath ".\venv\Scripts\python.exe" -ArgumentList "-m","uvicorn","app.main:app","--host","0.0.0.0","--port",$BackendPort
  Set-Location "$root\frontend"
  $env:PORT = $Port
  Start-Process -NoNewWindow -FilePath "npm" -ArgumentList "start"
  Start-Sleep -Seconds 5
  Write-Host "Готово! Откройте http://127.0.0.1:$Port"
  Write-Host "Тестовый пользователь: test@test.ru / test1234 (admin)"
}
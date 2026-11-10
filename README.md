# Закоулки — материалы защиты дипломного проекта

## Содержимое
- DEFENSE.md — текст для защиты
- DEPLOY-ALT.md — развертывание на Windows/MySQL
- install.sh / install.ps1 — автоматическая установка
- screenshots/ — скриншоты страниц

## Автоматическая установка

### Linux/macOS
```bash
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\install.ps1
```

После установки:
- Backend: `cd backend && venv\Scripts\activate && uvicorn app.main:app --port 8000`
- Frontend: `cd frontend && npm start` (порт 3001)
- Открыть http://127.0.0.1:3001

Тестовый пользователь: test@test.ru / test1234 (admin)
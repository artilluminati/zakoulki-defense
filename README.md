# Закоулки — материалы защиты дипломного проекта

## Содержимое
- DEFENSE.md — текст для защиты
- DEPLOY-ALT.md — развертывание на Windows/MySQL (подробно)
- install.sh / install.ps1 — автоматическая установка и запуск
- screenshots/ — скриншоты страниц

## Что нужно установить вручную
Только две программы:
1. **Python 3.11+** — https://www.python.org/downloads/ (при установке отметить "Add to PATH")
2. **Node.js LTS** — https://nodejs.org/

Всё остальное (зависимости, база данных, миграции, сборка, запуск) выполняется автоматически скриптом.

## Автоматическая установка и запуск

### Linux / macOS
```bash
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\install.ps1
```

После запуска скрипт сам:
- создаст виртуальное окружение Python и установит зависимости
- создаст файл .env (SQLite по умолчанию)
- прогонит миграции БД
- создаст тестовые аккаунты
- установит npm-зависимости и соберёт фронтенд
- запустит backend (порт 8000) и frontend (порт 3001)

Откройте в браузере: http://127.0.0.1:3001

Тестовый пользователь: test@test.ru / test1234 (admin)
Дополнительные аккаунты: alice@test.ru, bob@test.ru, mod@test.ru (пароль test1234)
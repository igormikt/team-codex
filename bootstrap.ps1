# ============================================================
# team-codex - Self-Extracting Bootstrap (inside project)
# Usage:  .\bootstrap.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ВАЖНО: $PSScriptRoot = папка, где лежит сам скрипт
# Скрипт распаковывает файлы в ту же папку, где он находится
$ProjectRoot = $PSScriptRoot

Write-Host ""
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "  team-codex - Bootstrap (inside project)       " -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Project folder: $ProjectRoot" -ForegroundColor Cyan

# Проверка: скрипт должен лежать внутри проекта
if (-not (Test-Path (Join-Path $ProjectRoot "app"))) {
    Write-Host "  ERROR: run this script from project root" -ForegroundColor Red
    Write-Host "  Expected: bootstrap.ps1 inside M:\Projects\team-codex" -ForegroundColor Red
    exit 1
}

# --- Активация / создание окружения ---
Write-Host ""
Write-Host "[1/3] Virtual environment..." -ForegroundColor Cyan
if (-not (Test-Path ".venv")) {
    $py = if (& py -3.11 --version 2>$null) { "py -3.11" } else { "python" }
    & $py -m venv .venv
    Write-Host "  .venv created" -ForegroundColor Green
} else {
    Write-Host "  .venv exists" -ForegroundColor Gray
}

& .\.venv\Scripts\Activate.ps1

# --- Установка зависимостей ---
Write-Host ""
Write-Host "[2/3] Installing dependencies..." -ForegroundColor Cyan
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Dependencies ready" -ForegroundColor Green
} else {
    Write-Host "  Dependencies install failed" -ForegroundColor Red
    exit 1
}

# --- .env ---
Write-Host ""
Write-Host "[3/3] Configuration..." -ForegroundColor Cyan
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "  .env created from template" -ForegroundColor Green
    Write-Host "  IMPORTANT: edit .env and add your keys!" -ForegroundColor Yellow
} else {
    Write-Host "  .env already exists (keeping your keys)" -ForegroundColor Gray
}

# --- Database ---
Write-Host ""
Write-Host "Initializing database..." -ForegroundColor Cyan
python -c "import sys; sys.path.insert(0, '.'); from app.database import engine, Base; import app.models; Base.metadata.create_all(bind=engine); print('Tables ready.')" 2>$null

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Ready to start!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host "  then open http://127.0.0.1:8000" -ForegroundColor Yellow
Write-Host ""
# Boxify-Web Master Installer (Windows)

$ErrorActionPreference = "Stop"

# --- UI Colors ---
function Write-Header { param($Text) Write-Host "`n=========================================" -ForegroundColor Cyan; Write-Host "   $Text" -ForegroundColor Cyan -NoNewline; Write-Host "   " -ForegroundColor Cyan; Write-Host "=========================================" -ForegroundColor Cyan }
function Write-Step { param($Step, $Text) Write-Host "`n[$Step] $Text" -ForegroundColor Blue }
function Write-Success { param($Text) Write-Host "  ✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "  - $Text" }
function Write-ErrorMsg { param($Text) Write-Host "[ERROR] $Text" -ForegroundColor Red }

Write-Header "Boxify-Web Master Installer (Windows)"

# 1. Validation
Write-Step "1/4" "Validating Dependencies..."

try {
    $pythonVersion = python --version 2>&1
    Write-Info "Python: $pythonVersion"
} catch {
    Write-ErrorMsg "Python is not installed or not in PATH."
    exit 1
}

try {
    $nodeVersion = node -v 2>&1
    Write-Info "Node.js: $nodeVersion"
} catch {
    Write-ErrorMsg "Node.js is not installed or not in PATH."
    exit 1
}

try {
    $npmVersion = npm -v 2>&1
    Write-Info "npm: $npmVersion"
} catch {
    Write-ErrorMsg "npm is not installed or not in PATH."
    exit 1
}

# 2. Backend Setup
Write-Step "2/4" "Setting up Backend (FastAPI)..."
Set-Location backend

if (-not (Test-Path "venv") -or -not (Test-Path "venv\Scripts\Activate.ps1")) {
    if (Test-Path "venv") {
        Write-Info "Incompatible virtual environment found. Recreating..."
        Remove-Item -Recurse -Force venv
    }
    Write-Info "Creating virtual environment..."
    py -3.10 -m venv venv
} else {
    Write-Info "Virtual environment already exists."
}

if (-not (Test-Path ".env") -and (Test-Path ".env.example")) {
    Write-Info "Initializing .env from .env.example..."
    Copy-Item ".env.example" ".env"
}

Write-Info "Upgrading pip and installing requirements..."
# We use & to run the commands in the current session context if possible, 
# or just run them directly via the python executable in venv
$pipPath = "venv\Scripts\pip.exe"
if (-not (Test-Path $pipPath)) {
    Write-ErrorMsg "Could not find pip in venv\Scripts. Virtual environment might be corrupted."
    exit 1
}

& $pipPath install --upgrade pip | Out-Null
& $pipPath install -r requirements.txt

Write-Success "Backend setup complete."
Set-Location ..

# 3. Frontend Setup
Write-Step "3/4" "Setting up Frontend (Next.js)..."
Set-Location frontend

if (-not (Test-Path ".env.local") -and (Test-Path ".env.local.example")) {
    Write-Info "Initializing .env.local from .env.local.example..."
    Copy-Item ".env.local.example" ".env.local"
}

Write-Info "Installing npm dependencies (this may take a while)..."
npm install

Write-Success "Frontend setup complete."
Set-Location ..

# 4. Finalization
Write-Header "Installation Successful! 🚀"

Write-Host "`nTo start the project manually:" -ForegroundColor Yellow
Write-Host "Backend:  " -NoNewline -ForegroundColor White; Write-Host "cd backend; .\venv\Scripts\Activate.ps1; uvicorn api.main:app --reload" -ForegroundColor Gray
Write-Host "Frontend: " -NoNewline -ForegroundColor White; Write-Host "cd frontend; npm run dev" -ForegroundColor Gray

Write-Host "`nWould you like to start both services now? (y/n): " -NoNewline -ForegroundColor Cyan
$choice = Read-Host
if ($choice -match "[Yy]") {
    Write-Host "Starting Backend and Frontend in new windows..." -ForegroundColor Blue
    
    # Start Backend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location backend; .\venv\Scripts\Activate.ps1; uvicorn api.main:app --reload"
    Write-Success "Backend starting in a new window."

    # Start Frontend
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location frontend; npm run dev"
    Write-Success "Frontend starting in a new window."

    Write-Host "`nBoth services are being started!" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "Backend:  http://localhost:8000"
}

Write-Host "`nEnjoy annotating!" -ForegroundColor Cyan

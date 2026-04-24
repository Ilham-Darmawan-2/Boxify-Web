#!/bin/bash
set -e

# --- UI Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}=========================================${NC}"
echo -e "${CYAN}${BOLD}   Boxify-Web Master Installer (Linux)   ${NC}"
echo -e "${CYAN}${BOLD}=========================================${NC}\n"

# 1. Validation
echo -e "${BLUE}[1/4] Validating Dependencies...${NC}"

if ! command -v python3.10 &> /dev/null; then
    echo -e "${RED}[ERROR] Python 3.10 is not installed.${NC}"
    exit 1
fi
echo -e "  - Python 3.10: $(python3.10 --version)"

if ! command -v node &> /dev/null; then
    echo -e "${RED}[ERROR] Node.js is not installed.${NC}"
    exit 1
fi
echo -e "  - Node.js: $(node -v)"

if ! command -v npm &> /dev/null; then
    echo -e "${RED}[ERROR] npm is not installed.${NC}"
    exit 1
fi
echo -e "  - npm: $(npm -v)\n"

# 2. Backend Setup
echo -e "${BLUE}[2/4] Setting up Backend (FastAPI)...${NC}"
cd backend

if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
    if [ -d "venv" ]; then
        echo -e "  - Incompatible virtual environment found. Recreating..."
        rm -rf venv
    fi
    echo -e "  - Creating virtual environment..."
    python3.10 -m venv venv
else
    echo -e "  - Virtual environment already exists."
fi

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo -e "  - Initializing .env from .env.example..."
    cp .env.example .env
fi

echo -e "  - Activating venv and installing requirements..."
source venv/bin/activate
pip install --upgrade pip > /dev/null
pip install -r requirements.txt
deactivate

echo -e "${GREEN}  ✅ Backend setup complete.${NC}\n"
cd ..

# 3. Frontend Setup
echo -e "${BLUE}[3/4] Setting up Frontend (Next.js)...${NC}"
cd frontend

if [ ! -f ".env.local" ] && [ -f ".env.local.example" ]; then
    echo -e "  - Initializing .env.local from .env.local.example..."
    cp .env.local.example .env.local
fi

echo -e "  - Installing npm dependencies (this may take a while)..."
npm install

echo -e "${GREEN}  ✅ Frontend setup complete.${NC}\n"
cd ..

# 4. Finalization
echo -e "${CYAN}${BOLD}=========================================${NC}"
echo -e "${GREEN}${BOLD}      Installation Successful! 🚀        ${NC}"
echo -e "${CYAN}${BOLD}=========================================${NC}"

echo -e "\n${YELLOW}To start the project manually:${NC}"
echo -e "${BOLD}Backend:${NC}  cd backend && source venv/bin/activate && uvicorn api.main:app --reload"
echo -e "${BOLD}Frontend:${NC} cd frontend && npm run dev"

echo -e "\n${CYAN}${BOLD}Would you like to start both services now? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting Backend and Frontend in background...${NC}"
    
    # Start Backend
    cd backend
    source venv/bin/activate
    nohup uvicorn api.main:app --reload --port 8000 > backend_auto.log 2>&1 &
    echo -e "  - Backend started (PID: $!). Logs: backend/backend_auto.log"
    cd ..

    # Start Frontend
    cd frontend
    nohup npm run dev > frontend_auto.log 2>&1 &
    echo -e "  - Frontend started (PID: $!). Logs: frontend/frontend_auto.log"
    cd ..

    echo -e "\n${GREEN}${BOLD}Both services are running!${NC}"
    echo -e "Frontend: http://localhost:3000"
    echo -e "Backend:  http://localhost:8000"
    echo -e "\n${YELLOW}Note:${NC} Use 'pkill -f uvicorn' and 'pkill -f next-dev' to stop them."
fi

echo -e "\n${CYAN}Enjoy annotating!${NC}"

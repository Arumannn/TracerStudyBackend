#!/bin/bash
# Quick Start: Jalankan Frontend & Backend

echo "=== Tracer Study Integration Quick Start ==="
echo ""
echo "Prerequisites:"
echo "✓ Node.js & npm installed (React)"
echo "✓ PHP & Composer installed (Laravel)"
echo "✓ PostgreSQL installed"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if PostgreSQL is running
echo "${BLUE}[1] Checking PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL not found. Please install PostgreSQL first."
    exit 1
fi
echo "✅ PostgreSQL found"

# Setup Backend
echo ""
echo "${BLUE}[2] Setting up Backend (Laravel)...${NC}"
cd tracer-study-backend

# Install dependencies
if [ ! -d "vendor" ]; then
    echo "Installing Composer dependencies..."
    composer install
fi

# Setup .env
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local..."
    cp .env.example .env.local 2>/dev/null || echo "Please copy .env.example to .env.local manually"
    
    # Generate app key
    php artisan key:generate
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force --seed

echo "✅ Backend setup complete"

# Setup Frontend
echo ""
echo "${BLUE}[3] Setting up Frontend (React)...${NC}"
cd ../fe-tracer-study

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi

# Create .env.local
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local..."
    cat > .env.local << EOF
VITE_API_URL=http://localhost:8000/api
VITE_APP_URL=http://localhost:5173
EOF
fi

echo "✅ Frontend setup complete"

# Instructions
echo ""
echo "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Now run these commands in separate terminals:"
echo ""
echo "${BLUE}Terminal 1 (Backend):${NC}"
echo "  cd tracer-study-backend"
echo "  php artisan serve"
echo ""
echo "${BLUE}Terminal 2 (Frontend):${NC}"
echo "  cd fe-tracer-study"
echo "  npm run dev"
echo ""
echo "Then open: ${BLUE}http://localhost:5173${NC}"
echo ""
echo "Test credentials:"
echo "  Email: admin@example.com"
echo "  Password: password"
echo ""
echo "API Documentation: ./INTEGRATION_GUIDE.md"

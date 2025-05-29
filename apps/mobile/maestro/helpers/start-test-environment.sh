#!/bin/bash
# Complete E2E test environment setup script
# This script starts all necessary services for E2E testing

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../../../.." && pwd )"
MOBILE_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo "🚀 Starting Karakeep E2E Test Environment"
echo "Root directory: $ROOT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local service=$2
    local max_attempts=30
    local attempt=0
    
    echo -n "⏳ Waiting for $service to be ready..."
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
        echo -n "."
    done
    echo -e " ${RED}✗${NC}"
    return 1
}

# 1. Check prerequisites
echo "📋 Checking prerequisites..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js 22 or later"
    exit 1
fi

# Check for pnpm
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}❌ pnpm is not installed${NC}"
    echo "Installing pnpm..."
    npm install -g pnpm
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed${NC}"
    echo "Some features (Meilisearch) will not be available"
    DOCKER_AVAILABLE=false
else
    DOCKER_AVAILABLE=true
fi

# 2. Set up test environment file
echo "🔧 Setting up test environment..."
TEST_ENV_FILE="$ROOT_DIR/.env.test"

if [ ! -f "$TEST_ENV_FILE" ]; then
    cat > "$TEST_ENV_FILE" << EOF
# Test environment configuration
DATA_DIR=./data-test
NEXTAUTH_SECRET=test-secret-for-e2e-testing-only
NEXTAUTH_URL=http://localhost:3001
MEILI_ADDR=http://localhost:7701
MEILISEARCH_URL=http://localhost:7701
BROWSER_WEB_URL=ws://localhost:9223
DISABLE_SIGNUPS=false
INFERENCE_LANG=english
LOG_LEVEL=debug

# Test server port (different from default 3000)
PORT=3001
EOF
    echo -e "${GREEN}✓${NC} Created test environment file"
else
    echo -e "${GREEN}✓${NC} Test environment file already exists"
fi

# 3. Install dependencies
echo "📦 Installing dependencies..."
cd "$ROOT_DIR"
pnpm install --frozen-lockfile

# 4. Set up test database
echo "🗄️  Setting up test database..."
export DATA_DIR="$ROOT_DIR/data-test"
mkdir -p "$DATA_DIR"

# Run migrations
cd "$ROOT_DIR"
pnpm run db:migrate

# 5. Start Meilisearch (if Docker available)
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "🔍 Starting Meilisearch..."
    
    # Stop existing container if running
    docker stop karakeep-test-meilisearch 2>/dev/null || true
    docker rm karakeep-test-meilisearch 2>/dev/null || true
    
    # Start new container
    docker run -d \
        --name karakeep-test-meilisearch \
        -p 7701:7700 \
        -v "$DATA_DIR/meilisearch:/meili_data" \
        getmeili/meilisearch:v1.13.3 \
        meilisearch --no-analytics
        
    if wait_for_service "http://localhost:7701/health" "Meilisearch"; then
        echo -e "${GREEN}✓${NC} Meilisearch is ready"
    else
        echo -e "${RED}✗${NC} Failed to start Meilisearch"
    fi
fi

# 6. Start the web server
echo "🌐 Starting Karakeep web server..."
cd "$ROOT_DIR/apps/web"

# Kill any existing process on port 3001
if check_port 3001; then
    echo "Stopping existing process on port 3001..."
    lsof -ti:3001 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Start the server in background
export NODE_ENV=test
nohup pnpm next dev -p 3001 > "$ROOT_DIR/test-server.log" 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to be ready
if wait_for_service "http://localhost:3001/api/health" "Karakeep server"; then
    echo -e "${GREEN}✓${NC} Karakeep server is ready"
else
    echo -e "${RED}✗${NC} Failed to start Karakeep server"
    echo "Check logs at: $ROOT_DIR/test-server.log"
    exit 1
fi

# 7. Start workers
echo "⚙️  Starting background workers..."
cd "$ROOT_DIR/apps/workers"
nohup pnpm start > "$ROOT_DIR/test-workers.log" 2>&1 &
WORKERS_PID=$!
echo "Workers PID: $WORKERS_PID"

# 8. Create test user
echo "👤 Creating test user..."
cd "$ROOT_DIR"

# Create a Node.js script to create the test user using curl
cat > "$ROOT_DIR/create-test-user.sh" << 'EOF'
#!/bin/bash

# Use curl to call the tRPC endpoint
echo "Creating test user via tRPC..."

RESPONSE=$(curl -s -X POST http://localhost:3001/api/trpc/users.create \
  -H "Content-Type: application/json" \
  -d '{
    "json": {
      "name": "Test User",
      "email": "test@example.com",
      "password": "testpassword123",
      "confirmPassword": "testpassword123"
    }
  }')

if echo "$RESPONSE" | grep -q "already exists\|already been taken"; then
  echo "✓ Test user already exists"
  exit 0
elif echo "$RESPONSE" | grep -q "\"id\":"; then
  echo "✓ Test user created successfully"
  exit 0
elif echo "$RESPONSE" | grep -q "Signups are disabled"; then
  echo "⚠️  Signups are disabled - you may need to enable them or create user manually"
  exit 0
else
  echo "Failed to create test user. Response:"
  echo "$RESPONSE"
  echo "Continuing anyway..."
  exit 0
fi
EOF

chmod +x "$ROOT_DIR/create-test-user.sh"

# Wait a bit for server to stabilize
sleep 3

# Run the script
"$ROOT_DIR/create-test-user.sh"
TEST_USER_CREATED=$?

# Clean up
rm -f "$ROOT_DIR/create-test-user.sh"

if [ $TEST_USER_CREATED -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Test user ready"
else
    echo -e "${YELLOW}⚠️${NC} Could not create test user (may already exist)"
fi

# 9. Update mobile app config
echo "📱 Updating mobile app configuration..."
MAESTRO_CONFIG="$MOBILE_DIR/.maestro/config.yaml"
cat > "$MAESTRO_CONFIG" << EOF
flows:
  - "maestro/flows"
includeTags:
  - "ios"
env:
  APP_ID: app.hoarder.hoardermobile
  BUNDLE_ID: app.hoarder.hoardermobile
  SERVER_URL: http://localhost:3001
  TEST_EMAIL: test@example.com
  TEST_PASSWORD: testpassword123
EOF

echo -e "${GREEN}✓${NC} Mobile test configuration updated"

# 10. Set up test data
echo "📄 Setting up test data..."
cd "$MOBILE_DIR"
./maestro/helpers/test-data-setup.sh

# Create PID file for cleanup
cat > "$ROOT_DIR/.test-pids" << EOF
SERVER_PID=$SERVER_PID
WORKERS_PID=$WORKERS_PID
EOF

echo ""
echo "✅ E2E Test Environment is ready!"
echo ""
echo "📝 Test credentials:"
echo "   Server: http://localhost:3001"
echo "   Email: test@example.com"
echo "   Password: testpassword123"
echo ""
echo "🏃 Next steps:"
echo "   1. Build and run the mobile app: pnpm ios"
echo "   2. Run E2E tests: pnpm test:e2e"
echo ""
echo "🛑 To stop the test environment:"
echo "   Run: $SCRIPT_DIR/stop-test-environment.sh"
echo ""
echo "📋 Logs:"
echo "   Server: $ROOT_DIR/test-server.log"
echo "   Workers: $ROOT_DIR/test-workers.log"
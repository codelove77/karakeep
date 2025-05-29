#!/bin/bash
# Stop the E2E test environment

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../../../.." && pwd )"

echo "🛑 Stopping Karakeep E2E Test Environment"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Read PIDs
if [ -f "$ROOT_DIR/.test-pids" ]; then
    source "$ROOT_DIR/.test-pids"
    
    # Stop server
    if [ ! -z "$SERVER_PID" ]; then
        echo "Stopping server (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Server stopped"
    fi
    
    # Stop workers
    if [ ! -z "$WORKERS_PID" ]; then
        echo "Stopping workers (PID: $WORKERS_PID)..."
        kill $WORKERS_PID 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Workers stopped"
    fi
    
    rm -f "$ROOT_DIR/.test-pids"
else
    echo "No PID file found. Attempting to stop services by port..."
    
    # Stop anything on port 3001
    if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Stopping process on port 3001..."
        lsof -ti:3001 | xargs kill -9 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Port 3001 cleared"
    fi
fi

# Stop Meilisearch container
if command -v docker &> /dev/null; then
    echo "Stopping Meilisearch container..."
    docker stop karakeep-test-meilisearch 2>/dev/null || true
    docker rm karakeep-test-meilisearch 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Meilisearch stopped"
fi

# Clean up logs
echo "Cleaning up logs..."
rm -f "$ROOT_DIR/test-server.log"
rm -f "$ROOT_DIR/test-workers.log"

echo ""
echo "✅ Test environment stopped"
echo ""
echo "💡 To completely clean test data, run:"
echo "   rm -rf $ROOT_DIR/data-test"
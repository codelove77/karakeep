#!/bin/bash
# Helper script to run Maestro tests on iOS simulator

# Add Maestro to PATH
export PATH="$PATH:$HOME/.maestro/bin"

# Find the first booted iOS simulator
SIMULATOR_ID=$(xcrun simctl list devices | grep "(Booted)" | grep -E "iPhone|iPad" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}")

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No booted iOS simulator found"
    echo "Please start an iOS simulator first with: pnpm ios"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/.*(\(.*\)) (Booted).*/\1/' | xargs)
echo "✅ Found booted iOS simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Set environment to prefer iOS
export MAESTRO_DRIVER=ios

# Run the test passed as argument
if [ -z "$1" ]; then
    echo "Running all tests..."
    maestro test maestro/flows/
else
    echo "Running test: $1"
    maestro test "$1"
fi
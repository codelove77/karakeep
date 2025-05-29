#!/bin/bash

# Script to set up test data for share extension E2E tests

echo "Setting up test data for Maestro E2E tests..."

# Create test PDF for iOS simulator
if [[ "$OSTYPE" == "darwin"* ]]; then
    # iOS Simulator path
    SIMULATOR_ID=$(xcrun simctl list devices booted -j | jq -r '.devices | to_entries | .[].value | .[] | select(.state == "Booted") | .udid' | head -1)
    
    if [ -n "$SIMULATOR_ID" ]; then
        # Create test documents directory in iCloud Drive
        ICLOUD_PATH="$HOME/Library/Developer/CoreSimulator/Devices/$SIMULATOR_ID/data/Library/Mobile Documents/com~apple~CloudDocs/Test Documents"
        mkdir -p "$ICLOUD_PATH"
        
        # Generate test PDF if not exists
        if [ ! -f "./maestro/helpers/test-document.pdf" ]; then
            echo "Generating test PDF..."
            node ./maestro/helpers/generate-test-pdf.js
        fi
        
        # Copy test PDF to simulator
        cp ./maestro/helpers/test-document.pdf "$ICLOUD_PATH/"
        
        echo "✓ Test PDF created for iOS simulator"
    else
        echo "⚠️  No iOS simulator running. Start a simulator and run this script again."
    fi
fi

# Set up for Android emulator
if command -v adb &> /dev/null; then
    if adb devices | grep -q "emulator\|device"; then
        # Push test PDF to Downloads folder
        echo "Creating test PDF for Android..."
        
        # Generate test PDF if not exists
        if [ ! -f "./maestro/helpers/test-document.pdf" ]; then
            echo "Generating test PDF..."
            node ./maestro/helpers/generate-test-pdf.js
        fi
        
        adb push ./maestro/helpers/test-document.pdf /sdcard/Download/
        echo "✓ Test PDF pushed to Android emulator"
    else
        echo "⚠️  No Android device/emulator connected. Connect a device and run this script again."
    fi
fi

echo "Test data setup complete!"
echo ""
echo "Next steps:"
echo "1. Make sure your iOS simulator or Android emulator is running"
echo "2. Install the Karakeep app on the device"
echo "3. Run: maestro test maestro/flows/"
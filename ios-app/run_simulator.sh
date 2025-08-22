#!/bin/bash

echo "📱 Starting FunClip iOS in Simulator..."
echo "========================================"
echo ""

# Boot the iPhone 16 Pro simulator if not already running
DEVICE_ID="28F3A194-1D2D-474A-9CB4-7FE18E5695D2"
DEVICE_NAME="iPhone 16 Pro"

echo "🚀 Booting $DEVICE_NAME simulator..."
xcrun simctl boot $DEVICE_ID 2>/dev/null || echo "✅ Simulator already booted"

# Open the Simulator app
echo "📱 Opening Simulator..."
open -a Simulator

# Wait a moment for simulator to fully boot
sleep 3

# Build and run the app
echo "🔨 Building FunClip app..."
xcodebuild -project FunClipApp.xcodeproj \
           -scheme FunClipApp \
           -destination "platform=iOS Simulator,id=$DEVICE_ID" \
           -configuration Debug \
           build 2>&1 | grep -E "(BUILD|ERROR|WARNING)" | tail -10

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "🚀 Installing and launching app..."
    
    # Install the app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "FunClipApp.app" -path "*/Debug-iphonesimulator/*" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install $DEVICE_ID "$APP_PATH"
        
        # Launch the app
        xcrun simctl launch $DEVICE_ID com.funclip.ios
        
        echo ""
        echo "✨ FunClip is now running in the $DEVICE_NAME simulator!"
        echo ""
        echo "Tips:"
        echo "• Use ⌘+Shift+H to go to home screen"
        echo "• Use ⌘+D to open debug menu"
        echo "• Use Device → Rotate to test orientations"
    else
        echo "❌ Could not find built app. Please build in Xcode first."
    fi
else
    echo ""
    echo "❌ Build failed. Opening Xcode for you to fix issues..."
    open FunClipApp.xcodeproj
fi
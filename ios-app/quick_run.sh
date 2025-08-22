#!/bin/bash

echo "🧹 Cleaning and rebuilding FunClip..."

# Clean build folder
xcodebuild clean -project FunClipApp.xcodeproj -scheme FunClipApp

# Build for simulator without code signing
xcodebuild build \
  -project FunClipApp.xcodeproj \
  -scheme FunClipApp \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

echo "✅ Build complete! Now:"
echo "1. In Xcode, press ⌘+R to run"
echo "2. You should see the login screen with Sign in with Apple"
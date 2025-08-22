#!/bin/bash

echo "🔧 Fixing Xcode Signing for Simulator..."
echo "========================================"
echo ""

# Backup original project file
cp FunClipApp.xcodeproj/project.pbxproj FunClipApp.xcodeproj/project.pbxproj.backup

# Fix the project file to disable code signing for simulator
sed -i '' '
/Debug.*= {/,/};/ {
    /buildSettings = {/ a\
				CODE_SIGNING_ALLOWED = NO;\
				CODE_SIGNING_REQUIRED = NO;\
				CODE_SIGN_IDENTITY = "";\
				DEVELOPMENT_TEAM = "";\
				PROVISIONING_PROFILE_SPECIFIER = "";
}' FunClipApp.xcodeproj/project.pbxproj

echo "✅ Fixed! Now in Xcode:"
echo ""
echo "1. Close and reopen the project:"
echo "   - File → Close Project"
echo "   - File → Open Recent → FunClipApp"
echo ""
echo "2. Select iPhone 16 Pro simulator (not a real device)"
echo ""
echo "3. Press ⌘+R to run"
echo ""
echo "Note: This fix only works for Simulator, not real devices."
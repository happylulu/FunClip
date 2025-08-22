# 📱 Xcode Setup Guide for FunClip iOS App

## 🚀 Step 1: Install Xcode

1. **Open App Store** on your Mac
2. **Search for "Xcode"**
3. **Click "Get"** (it's free but ~7GB)
4. **Wait for download** (takes 15-30 mins)

OR faster via Terminal:
```bash
xcode-select --install
```

## 🎯 Step 2: Create New iOS Project

### Method A: Using Xcode GUI

1. **Open Xcode**
2. **Choose "Create New Project"** (or File → New → Project)
   
   ![](https://docs-assets.developer.apple.com/published/5b94750935/rendered2x-1694130678.png)

3. **Select Template:**
   - Platform: **iOS**
   - Application: **App**
   - Click **Next**

4. **Configure Project:**
   ```
   Product Name: FunClipApp
   Team: None (for now)
   Organization ID: com.funclip
   Bundle ID: com.funclip.ios (auto-generated)
   Interface: SwiftUI ✅
   Language: Swift ✅
   Use Core Data: ❌
   Include Tests: ✅
   ```

5. **Choose location:** `/Users/luluhan/FunClip/ios-app/`
6. Click **Create**

### Method B: Using Terminal (Faster!)

```bash
cd /Users/luluhan/FunClip/ios-app

# Create Xcode project from command line
xcodegen generate

# Or use Swift Package Manager
swift package init --type executable --name FunClipApp
```

## 🏗 Step 3: Project Structure in Xcode

Once opened, you'll see:

```
┌─────────────────────────────────────────┐
│ NAVIGATOR (Left Panel)                  │
├─────────────────────────────────────────┤
│ 📁 FunClipApp                          │
│   📁 FunClipApp                        │
│     📄 FunClipAppApp.swift (Entry)     │
│     📄 ContentView.swift               │
│     📁 Core                            │
│       📁 Auth                          │
│         📄 AuthManager.swift ← Our code│
│     📁 Assets.xcassets                 │
│   📁 FunClipAppTests                   │
│     📄 AuthManagerTests.swift ← Tests  │
├─────────────────────────────────────────┤
│ EDITOR (Center)                         │
│ Your code appears here                  │
├─────────────────────────────────────────┤
│ INSPECTOR (Right Panel)                 │
│ File properties & settings              │
└─────────────────────────────────────────┘
```

## 📂 Step 4: Add Our Files to Xcode

### Option 1: Drag & Drop (Easiest!)

1. **Open Finder** to `/Users/luluhan/FunClip/ios-app/FunClipApp`
2. **Select all our Swift files**
3. **Drag into Xcode's navigator panel**
4. Check:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to target: FunClipApp

### Option 2: Add Files Manually

1. **Right-click** on `FunClipApp` folder in Xcode
2. Select **"New Group"** → Name it `Core`
3. Right-click `Core` → **"New Group"** → Name it `Auth`
4. Right-click `Auth` → **"Add Files to FunClipApp"**
5. Navigate to our files and select them

### Option 3: Terminal Copy (Fastest!)

```bash
# Copy our auth files to Xcode project
cp -r /Users/luluhan/FunClip/ios-app/FunClipApp/Core /path/to/xcode/project/FunClipApp/

# Copy test files
cp -r /Users/luluhan/FunClip/ios-app/FunClipAppTests /path/to/xcode/project/
```

## 🎨 Step 5: Xcode Interface Overview

### Key Areas:

```
┌──────────────────────────────────────────────────┐
│  🔨 Build  ▶️ Run  ⏸ Stop  📱 Device Selector   │  ← Toolbar
├──────────────────────────────────────────────────┤
│ 📁 Files │ 🔍 Search │ ⚠️ Issues │ 🧪 Tests    │  ← Navigator Tabs
│          │           │           │              │
│ Project  │  Find in  │  Errors  │  Test       │
│ Files    │  Project  │  Warnings │  Results   │
├──────────────────────────────────────────────────┤
│                  CODE EDITOR                     │
│                                                  │
│  class AuthManager {                            │
│      @Published var user: User?                 │
│      ...                                         │
│  }                                               │
├──────────────────────────────────────────────────┤
│ Console Output / Debug Area                      │
└──────────────────────────────────────────────────┘
```

### Keyboard Shortcuts:
- **⌘ + B** → Build project
- **⌘ + R** → Run app
- **⌘ + U** → Run tests
- **⌘ + .** → Stop running
- **⌘ + Shift + O** → Quick open file
- **⌘ + 1-9** → Switch navigator tabs

## 🧪 Step 6: Running Tests

### To Run Our Auth Tests:

1. **Click Test Navigator** (diamond icon) in left panel
2. **See test list:**
   ```
   ▼ FunClipAppTests
     ▼ AuthManagerTests
       ✓ test_signInWithApple_whenSuccessful_shouldUpdateAuthState
       ✓ test_signInWithApple_whenSuccessful_shouldStoreTokenInKeychain
       ✓ test_signInWithEmail_whenValidCredentials_shouldAuthenticate
       ... (all our tests)
   ```

3. **Run all tests:** Press **⌘ + U**
4. **Run single test:** Click play button next to test name
5. **See results:** Green ✅ = Pass, Red ❌ = Fail

## 📦 Step 7: Add Dependencies (Supabase)

### Using Swift Package Manager:

1. **File → Add Package Dependencies**
2. **Enter URL:** `https://github.com/supabase/supabase-swift`
3. **Version:** Up to Next Major `2.0.0`
4. **Add Package**
5. **Select Products:**
   - ✅ Supabase
   - ✅ Auth
   - ✅ Realtime

### Or via Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

## 🏃‍♂️ Step 8: Run the App

### On Simulator:

1. **Select Device:** iPhone 15 Pro (top toolbar)
2. **Press ⌘ + R** or click ▶️ button
3. **Wait for build** (first time takes 2-3 mins)
4. **Simulator opens** with your app!

### On Real Device:

1. **Connect iPhone** via USB
2. **Select your device** from dropdown
3. **Sign in with Apple ID** (Xcode → Settings → Accounts)
4. **Trust developer** on iPhone (Settings → General → Device Management)
5. **Run app** (⌘ + R)

## 🎯 Step 9: Visual Debugging

### See Your Auth Flow:

1. **Add Breakpoints:** Click line number in editor
2. **Debug View Hierarchy:** 
   - Run app
   - Click **Debug View Hierarchy** button
   - See 3D view of your UI!

3. **SwiftUI Previews:**
   ```swift
   struct AuthView_Previews: PreviewProvider {
       static var previews: some View {
           AuthView()
       }
   }
   ```
   - See live preview on right side
   - No need to run app!

## 🛠 Step 10: Common Issues & Fixes

### "No such module 'Supabase'"
```bash
# Clean and rebuild
⌘ + Shift + K (Clean)
⌘ + B (Build)
```

### "Signing for FunClipApp requires a development team"
1. Click project name in navigator
2. Select "Signing & Capabilities"
3. Check "Automatically manage signing"
4. Sign in with Apple ID

### "Could not find module 'FunClipApp' for target 'x86_64-apple-ios-simulator'"
```bash
# Select correct architecture
Product → Destination → Any iOS Simulator Device
```

## 📱 Quick Start Commands

```bash
# Open project in Xcode
cd /Users/luluhan/FunClip/ios-app
open FunClipApp.xcodeproj

# Or if using workspace
open FunClipApp.xcworkspace

# Build from terminal
xcodebuild -scheme FunClipApp build

# Run tests from terminal
xcodebuild test -scheme FunClipApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 🎬 Visual Tour of Our Code in Xcode

### 1. Project Navigator (Left)
```
FunClipApp
├── Core/
│   └── Auth/
│       ├── AuthManager.swift        ← Main auth logic
│       ├── AuthProtocols.swift      ← Interfaces
│       └── Services/
│           ├── KeychainService.swift
│           ├── BiometricService.swift
│           └── AppleSignInProvider.swift
├── Models/
│   └── User.swift                   ← User model
└── FunClipAppTests/
    ├── AuthManagerTests.swift       ← Our TDD tests
    └── Mocks/
        └── AuthMocks.swift          ← Test doubles
```

### 2. Test Navigator
Shows all tests with green/red status indicators

### 3. Issue Navigator  
Shows any compile errors or warnings

### 4. Debug Area
Shows console output and variable values

---

## 🚦 Next Steps

1. **Open Xcode**
2. **Create new project** (follow steps above)
3. **Add our files** (drag & drop)
4. **Add Supabase package**
5. **Run tests** (⌘ + U)
6. **See tests pass!** ✅

Need help? Common commands:
- **Build:** ⌘ + B
- **Run:** ⌘ + R  
- **Test:** ⌘ + U
- **Stop:** ⌘ + .
- **Search:** ⌘ + Shift + F

---

*Pro Tip: Xcode has great documentation! Press ⌘ + Shift + 0 to open documentation window.*
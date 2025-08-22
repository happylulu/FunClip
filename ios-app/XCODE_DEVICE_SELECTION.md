# 📱 How to Select a Device in Xcode

## Quick Steps:

### 1. In Xcode Toolbar (Top of Window):
Look for the device selector next to the "Play" button:

```
[▶️ FunClipApp] > [iPhone 16 Pro ▼]
                    ^^^^^^^^^^^^^^^^
                    Click here!
```

### 2. Select from Dropdown:
When you click the device selector, you'll see:

```
📱 iOS Simulators
  ├── iPhone 16 Pro         ← Select this
  ├── iPhone 16 Pro Max
  ├── iPhone 16
  ├── iPhone 16 Plus
  └── iPad Pro 11-inch

🔌 iOS Devices
  └── (Your physical devices if connected)
```

### 3. Alternative: Using Menu Bar
- **Product** → **Destination** → **iPhone 16 Pro**

### 4. Keyboard Shortcut:
- **⌃⇧0** (Control+Shift+0) to open destination chooser

## Available Simulators on Your Mac:

| Device | ID | Status |
|--------|-----|--------|
| **iPhone 16 Pro** ✅ | 28F3A194-1D2D-474A-9CB4-7FE18E5695D2 | Ready |
| iPhone 16 Pro Max | 66E0F68A-86CA-4CCB-8520-6D064272F298 | Available |
| iPhone 16 | 851A0A2B-786F-4054-86E3-F5F9A34DAE07 | Available |
| iPad Pro 11-inch | 878339D4-AC51-4102-B395-3312D8B206CE | Available |

## To Run Your App:

1. **Select iPhone 16 Pro** from the device dropdown
2. Press **⌘+R** (or click the ▶️ Play button)
3. Wait for the simulator to boot (first time takes ~30 seconds)
4. Your app will launch automatically!

## Troubleshooting:

### If no devices appear:
```bash
# Download iOS Simulator runtime
xcodebuild -downloadPlatform iOS
```

### If simulator won't start:
```bash
# Reset all simulators
xcrun simctl erase all
```

### To manually boot a simulator:
```bash
# Boot iPhone 16 Pro
xcrun simctl boot "28F3A194-1D2D-474A-9CB4-7FE18E5695D2"
open -a Simulator
```

## Visual Guide in Xcode:

```
┌─────────────────────────────────────────────────────┐
│ Xcode                                               │
├─────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────┐   │
│ │ [▶️] [⏸] [■] | FunClipApp > iPhone 16 Pro ▼  │   │ ← Click here
│ └───────────────────────────────────────────────┘   │
│                                                     │
│  Your code editor area...                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Quick Command:

To run immediately from terminal:
```bash
./run_simulator.sh
```

Or in Xcode:
1. Click **iPhone 16 Pro** in the toolbar
2. Press **⌘+R**
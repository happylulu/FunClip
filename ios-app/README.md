# FunClip iOS App

AI-powered video clip generator for creating viral content on iOS.

## 📱 Overview

FunClip iOS allows content creators to:
- Upload videos from camera roll or YouTube URLs
- Automatically identify the 3 most viral moments using AI
- Generate 10-second clips optimized for social media
- Share directly to TikTok, Instagram Reels, and YouTube Shorts

## 🚀 Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ device or simulator
- Swift 5.9+
- Active Apple Developer account

### Installation

1. Clone the repository:
```bash
cd /Users/luluhan/FunClip/ios-app
```

2. Install dependencies:
```bash
cd FunClipApp
swift package resolve
```

3. Open in Xcode:
```bash
open FunClipApp.xcodeproj
```

4. Configure environment:
- Copy `Config.example.swift` to `Config.swift`
- Add your API keys and endpoints

5. Build and run:
- Select your target device
- Press `Cmd + R` to run

## 🏗 Project Structure

```
ios-app/
├── Documents/
│   ├── EPIC_STORIES.md      # Product requirements & user stories
│   └── TECHNICAL_SPEC.md    # Technical architecture
├── FunClipApp/
│   ├── App/
│   │   ├── FunClipApp.swift # App entry point
│   │   └── Config.swift     # Configuration
│   ├── Core/
│   │   ├── Auth/           # Authentication
│   │   ├── Network/        # API client
│   │   └── Storage/        # Local data
│   ├── Features/
│   │   ├── Onboarding/     # First launch
│   │   ├── Upload/         # Video input
│   │   ├── Processing/     # AI processing
│   │   ├── Results/        # Clip results
│   │   └── Share/          # Social sharing
│   ├── Shared/
│   │   ├── Components/     # Reusable views
│   │   ├── Extensions/     # Swift extensions
│   │   └── Utilities/      # Helper functions
│   └── Resources/
│       ├── Assets.xcassets # Images & colors
│       └── Localizable.strings
└── FunClipApp.xcodeproj/

```

## 🔑 Key Features

### MVP Features (v1.0)
- [x] Sign in with Apple
- [x] Video upload from camera roll
- [x] YouTube URL processing
- [x] Real-time processing status
- [x] 3 AI-generated clips
- [x] Virality scoring
- [x] Social media sharing
- [x] Processing history

### Coming Soon (v1.1+)
- [ ] Video recording in-app
- [ ] Clip trimming controls
- [ ] Caption generation
- [ ] Batch processing
- [ ] Team workspaces

## 🛠 Tech Stack

- **UI:** SwiftUI
- **Architecture:** MVVM + Coordinators
- **Networking:** URLSession + Async/Await
- **Storage:** SwiftData / Core Data
- **Auth:** Supabase
- **Video:** AVFoundation
- **Backend:** FastAPI + Celery

## 📦 Dependencies

- [Supabase](https://github.com/supabase/supabase-swift) - Authentication
- [Kingfisher](https://github.com/onevcat/Kingfisher) - Image caching
- [Lottie](https://github.com/airbnb/lottie-ios) - Animations
- [Mixpanel](https://github.com/mixpanel/mixpanel-swift) - Analytics

## 🔧 Configuration

### Environment Variables
Create `Config.swift` with:

```swift
enum Config {
    static let apiBaseURL = "http://147.182.255.74"
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_ANON_KEY"
    static let mixpanelToken = "YOUR_MIXPANEL_TOKEN"
}
```

### API Endpoints
- `POST /api/v1/videos/upload` - Upload video file
- `POST /api/v1/videos/youtube` - Process YouTube URL
- `GET /api/v1/jobs/{id}` - Check job status
- `GET /api/v1/clips/{id}/download` - Download clip

## 🧪 Testing

### Run Unit Tests
```bash
xcodebuild test -scheme FunClipApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run UI Tests
```bash
xcodebuild test -scheme FunClipAppUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📱 Screenshots

| Home | Upload | Processing | Results |
|------|--------|------------|---------|
| ![Home](#) | ![Upload](#) | ![Processing](#) | ![Results](#) |

## 🚢 Deployment

### TestFlight Beta

1. Archive the app:
```bash
xcodebuild archive -scheme FunClipApp -archivePath ./build/FunClipApp.xcarchive
```

2. Export for App Store:
```bash
xcodebuild -exportArchive -archivePath ./build/FunClipApp.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

3. Upload to TestFlight:
```bash
xcrun altool --upload-app -f ./build/FunClipApp.ipa -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD
```

### App Store Release

See [RELEASE.md](Documents/RELEASE.md) for detailed App Store submission guide.

## 🐛 Debugging

### Common Issues

1. **Video upload fails**
   - Check file size (< 500MB)
   - Verify network connection
   - Ensure valid auth token

2. **Processing stuck**
   - Check WebSocket connection
   - Verify backend is running
   - Review job status API

3. **Sharing fails**
   - Ensure social apps installed
   - Check Info.plist URL schemes
   - Verify export permissions

## 📊 Analytics Events

- `video_uploaded` - Source, size, duration
- `processing_started` - Job ID, type
- `clips_generated` - Count, avg score
- `clip_shared` - Platform, score
- `error_occurred` - Type, details

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit pull request

## 📄 License

Copyright © 2025 FunClip. All rights reserved.

## 📞 Support

- Email: support@funclip.app
- Discord: [Join our community](#)
- Documentation: [docs.funclip.app](#)

---

**Current Status:** 🟡 In Development

**Target Launch:** September 2025

**Version:** 1.0.0-beta
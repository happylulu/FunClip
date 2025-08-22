# FunClip iOS App - Epic Stories & Product Requirements

## 🎯 Product Vision
**Enable content creators to instantly generate viral-worthy clips from their videos directly on their iPhone, leveraging AI to identify the most engaging moments.**

## 📊 Success Metrics
- User can process a video in < 2 minutes
- 3 clips generated with 80%+ satisfaction rate  
- Successful export to major social platforms
- < 1% crash rate
- 4.0+ App Store rating
- 70% day-1 retention

---

## 🚀 MVP Epic Stories

### Epic 1: User Authentication & Onboarding
**Goal:** Seamless and secure user access to the app

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a new user, I want to sign up with Apple ID so I can quickly create an account | P0 | 5 |
| As a user, I want to sign in with email/password as an alternative option | P0 | 3 |
| As a user, I want to use Face ID/Touch ID for quick access | P1 | 2 |
| As a user, I want to see an onboarding tutorial on first launch | P1 | 3 |
| As a user, I want to reset my password if forgotten | P2 | 2 |

#### Acceptance Criteria:
- [ ] Sign in with Apple implemented (App Store requirement)
- [ ] JWT tokens stored securely in Keychain
- [ ] Auto-login on app launch if token valid
- [ ] Graceful token refresh handling
- [ ] Onboarding shows core features in 3 screens

---

### Epic 2: Video Input & Management
**Goal:** Multiple ways to get videos into the app for processing

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a user, I want to select videos from my camera roll | P0 | 3 |
| As a user, I want to paste a YouTube URL to process online videos | P0 | 5 |
| As a user, I want to record a new video directly in the app | P1 | 5 |
| As a user, I want to see video metadata (duration, size) before upload | P1 | 2 |
| As a user, I want to see upload progress with ability to cancel | P0 | 3 |

#### Acceptance Criteria:
- [ ] Support for common video formats (MP4, MOV, M4V)
- [ ] Maximum video duration: 10 minutes (MVP limit)
- [ ] Maximum file size: 500MB
- [ ] YouTube URL validation and error handling
- [ ] Chunked upload for files > 10MB
- [ ] Background upload support

---

### Epic 3: AI Video Processing
**Goal:** Process videos to extract the most viral moments

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a user, I want the AI to automatically find 3 viral moments | P0 | 8 |
| As a user, I want to see real-time processing progress | P0 | 3 |
| As a user, I want to receive a push notification when complete | P0 | 3 |
| As a user, I want to see estimated time remaining | P1 | 2 |
| As a user, I want processing to continue if I leave the app | P0 | 5 |

#### Acceptance Criteria:
- [ ] WebSocket connection for real-time updates
- [ ] Progress shown in 5 stages: Uploading → Transcribing → Analyzing → Clipping → Complete
- [ ] Push notification includes preview of first clip
- [ ] Processing history persisted locally
- [ ] Retry mechanism for failed jobs

---

### Epic 4: Clip Review & Refinement
**Goal:** Review and refine generated clips before sharing

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a user, I want to preview each generated clip | P0 | 3 |
| As a user, I want to see virality score and reason for each clip | P0 | 2 |
| As a user, I want to adjust clip start/end time (±3 seconds) | P1 | 5 |
| As a user, I want to favorite the best clips | P1 | 2 |
| As a user, I want to regenerate clips if not satisfied | P2 | 3 |
| As a user, I want to add captions to clips | P1 | 5 |

#### Acceptance Criteria:
- [ ] Native video player with scrubbing controls
- [ ] Virality score displayed as percentage with emoji
- [ ] Reason for selection shown as text overlay
- [ ] Trim handles for adjusting clip boundaries
- [ ] One-tap caption generation
- [ ] Caption style customization (position, size, color)

---

### Epic 5: Export & Social Sharing
**Goal:** Seamlessly share clips to social platforms

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a user, I want to save clips to my camera roll | P0 | 2 |
| As a user, I want to share directly to TikTok | P0 | 3 |
| As a user, I want to share directly to Instagram Reels | P0 | 3 |
| As a user, I want to share to YouTube Shorts | P1 | 3 |
| As a user, I want to copy a shareable link | P1 | 2 |
| As a user, I want to share all 3 clips as a batch | P2 | 3 |

#### Acceptance Criteria:
- [ ] Export in platform-optimized formats
- [ ] Maintain video quality (1080p minimum)
- [ ] Include captions in export if added
- [ ] Pre-filled descriptions with virality reason
- [ ] Track sharing analytics
- [ ] Deep linking to social apps

---

### Epic 6: User Dashboard & History
**Goal:** Manage processed videos and track usage

#### User Stories:
| Story | Priority | Points |
|-------|----------|--------|
| As a user, I want to see my processing history | P0 | 3 |
| As a user, I want to re-download previous clips | P0 | 2 |
| As a user, I want to delete old jobs to save space | P1 | 2 |
| As a user, I want to see my usage statistics | P1 | 3 |
| As a user, I want to search/filter my history | P2 | 3 |

#### Acceptance Criteria:
- [ ] Chronological list with thumbnails
- [ ] Show processing date and source (Upload/YouTube)
- [ ] Swipe to delete with confirmation
- [ ] Statistics: Total clips, average virality, most shared
- [ ] Cache management (auto-delete after 30 days)

---

## 🛠 Technical Architecture

### Tech Stack
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 16.0
- **Architecture:** MVVM + Coordinator
- **Networking:** URLSession + Async/Await
- **Storage:** SwiftData (iOS 17) / Core Data fallback
- **Auth:** Supabase Auth SDK
- **Video:** AVFoundation, PhotoKit
- **Analytics:** MixPanel/Amplitude

### Backend Integration
- **Base URL:** https://api.funclip.app (production)
- **Staging URL:** http://147.182.255.74 (current)
- **Authentication:** Bearer token (JWT)
- **Real-time:** WebSockets for progress
- **File Upload:** Multipart/form-data with chunking

### Key Libraries
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.0")
]
```

---

## 📅 Development Timeline

### Sprint 1 (Week 1): Foundation
- [ ] Project setup and architecture
- [ ] Authentication flow with Supabase
- [ ] Tab bar navigation structure
- [ ] Video picker from camera roll
- [ ] Basic networking layer

### Sprint 2 (Week 2): Core Features  
- [ ] Video upload with progress
- [ ] YouTube URL input
- [ ] Processing status UI
- [ ] WebSocket integration
- [ ] Push notifications

### Sprint 3 (Week 3): Polish
- [ ] Video preview player
- [ ] Clip trimming controls
- [ ] Social sharing
- [ ] Error handling
- [ ] Onboarding flow

### Sprint 4 (Week 4): Launch Prep
- [ ] Performance optimization
- [ ] Analytics integration
- [ ] Crash reporting (Sentry)
- [ ] TestFlight beta
- [ ] App Store submission

---

## 🎨 Design System

### Brand Colors
```swift
Primary: #6366F1    // Indigo
Secondary: #EC4899  // Pink
Success: #10B981    // Green
Warning: #F59E0B    // Amber
Error: #EF4444      // Red
Background: #0F172A // Dark
Surface: #1E293B    // Dark Gray
```

### Typography
- **Heading:** SF Pro Display Bold
- **Body:** SF Pro Text Regular
- **Caption:** SF Pro Text Light

### Components
- Custom video player with overlay controls
- Animated progress rings
- Haptic feedback on actions
- Particle effects for viral scores
- Smooth transitions between screens

---

## 📱 Screen Inventory

1. **Splash Screen** - Animated logo
2. **Onboarding** - 3-step carousel
3. **Sign In/Up** - Auth forms with social buttons
4. **Home/Dashboard** - Processing history grid
5. **Upload** - Source selection (Camera Roll/YouTube/Record)
6. **Processing** - Real-time progress with stages
7. **Results** - 3 clips with scores and preview
8. **Clip Editor** - Trim, caption, preview
9. **Share** - Platform selection and options
10. **Profile** - Stats, settings, logout

---

## ⚠️ Out of Scope for MVP

- Advanced video editing (filters, transitions, effects)
- Custom clip durations (fixed at 10 seconds)
- Multi-language support (English only)
- Subscription/payment features
- Team collaboration features
- Desktop/iPad app
- Android version
- Video download from other platforms
- Batch processing multiple videos
- Custom AI model training

---

## 🔄 Post-MVP Roadmap

### Phase 2 (Month 2)
- iPad optimization
- More social platforms (Twitter, LinkedIn)
- Custom clip durations (5-60 seconds)
- Subscription tiers with limits

### Phase 3 (Month 3)
- Android app
- Team workspaces
- Brand kit customization
- API for developers

### Phase 4 (Quarter 2)
- Desktop app (Mac)
- AI voice-over generation
- Auto-posting scheduler
- Analytics dashboard

---

## 📝 Notes

- App Store Review: Ensure compliance with Guidelines 4.2 (Minimum Functionality)
- Privacy: Implement App Tracking Transparency (ATT)
- Accessibility: VoiceOver support required
- Localization: Prepare for future multi-language
- Performance: 60 FPS animations, < 2s cold start

---

*Last Updated: August 2025*
*Version: 1.0.0*
*Author: FunClip Team*
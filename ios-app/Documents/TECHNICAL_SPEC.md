# FunClip iOS - Technical Specification

## 1. System Architecture

### 1.1 High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App (Swift)                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI)                               │
│  ├── Views                                                  │
│  ├── ViewModels (ObservableObject)                         │
│  └── Coordinators                                          │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer                                               │
│  ├── Use Cases                                             │
│  ├── Models                                                │
│  └── Protocols                                             │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ├── Repositories                                          │
│  ├── Network (API Client)                                  │
│  ├── Local Storage (SwiftData)                            │
│  └── Cache Manager                                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Backend API     │
                    │  (FastAPI)        │
                    └──────────────────┘
```

### 1.2 Design Pattern: MVVM-C
- **Model:** Data structures and business logic
- **View:** SwiftUI views (declarative UI)
- **ViewModel:** ObservableObject managing view state
- **Coordinator:** Navigation flow management

## 2. Core Components

### 2.1 Authentication Module
```swift
// AuthManager.swift
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var authState: AuthState = .unknown
    
    private let supabase: SupabaseClient
    private let keychain: KeychainService
    
    func signInWithApple() async throws -> User
    func signInWithEmail(_ email: String, password: String) async throws -> User
    func signOut() async throws
    func refreshToken() async throws -> String
}

enum AuthState {
    case unknown
    case authenticated(User)
    case unauthenticated
    case loading
}
```

### 2.2 Video Processing Module
```swift
// VideoProcessor.swift
class VideoProcessor: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var processingState: ProcessingState = .idle
    @Published var currentJob: ProcessingJob?
    
    func uploadVideo(from url: URL) async throws -> JobID
    func processYouTubeURL(_ url: URL) async throws -> JobID
    func getJobStatus(_ jobID: JobID) async throws -> ProcessingJob
    func downloadClip(_ clipID: ClipID) async throws -> URL
}

enum ProcessingState {
    case idle
    case uploading(progress: Double)
    case processing(stage: ProcessingStage)
    case completed([VideoClip])
    case failed(Error)
}

enum ProcessingStage {
    case transcribing
    case analyzing
    case clipping
    case uploading
}
```

### 2.3 Networking Layer
```swift
// APIClient.swift
actor APIClient {
    private let session: URLSession
    private let baseURL: URL
    private var authToken: String?
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload(_ file: URL, to endpoint: Endpoint) async throws -> UploadResponse
    func download(_ url: URL) async throws -> Data
    
    private func handleAuth() async throws
    private func refreshTokenIfNeeded() async throws
}

// Endpoints.swift
enum Endpoint {
    case login(email: String, password: String)
    case uploadVideo
    case processYouTube(url: URL)
    case jobStatus(id: String)
    case downloadClip(id: String)
    
    var path: String { ... }
    var method: HTTPMethod { ... }
    var headers: [String: String] { ... }
}
```

## 3. Data Models

### 3.1 Core Models
```swift
// User.swift
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let fullName: String?
    let avatarURL: URL?
    let createdAt: Date
}

// Video.swift
struct ProcessingJob: Codable, Identifiable {
    let id: String
    let status: JobStatus
    let progress: Int
    let videoURL: URL?
    let youtubeURL: URL?
    let clips: [VideoClip]?
    let createdAt: Date
    let completedAt: Date?
}

struct VideoClip: Codable, Identifiable {
    let id: String
    let url: URL
    let thumbnailURL: URL?
    let viralityScore: Int
    let reason: String
    let startTime: Double
    let duration: Double
}

enum JobStatus: String, Codable {
    case pending
    case uploading
    case processing
    case completed
    case failed
}
```

### 3.2 Local Storage Models (SwiftData)
```swift
import SwiftData

@Model
final class CachedJob {
    @Attribute(.unique) var id: String
    var status: String
    var progress: Int
    var clips: [CachedClip]?
    var createdAt: Date
    var lastUpdated: Date
    
    init(from job: ProcessingJob) { ... }
}

@Model
final class CachedClip {
    @Attribute(.unique) var id: String
    var localPath: String?
    var viralityScore: Int
    var reason: String
    var downloadedAt: Date?
}
```

## 4. User Interface Components

### 4.1 Custom Views
```swift
// VideoPlayerView.swift
struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View { ... }
}

// ProgressRingView.swift
struct ProgressRingView: View {
    let progress: Double
    let stage: ProcessingStage
    
    var body: some View { ... }
}

// ViralityScoreCard.swift
struct ViralityScoreCard: View {
    let score: Int
    let reason: String
    
    var body: some View { ... }
}
```

### 4.2 View Modifiers
```swift
// HapticFeedback.swift
extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> some View
}

// LoadingOverlay.swift
extension View {
    func loadingOverlay(isLoading: Binding<Bool>) -> some View
}
```

## 5. Services & Utilities

### 5.1 Video Service
```swift
// VideoService.swift
class VideoService {
    func compressVideo(at url: URL, quality: VideoQuality) async throws -> URL
    func generateThumbnail(from url: URL, at time: CMTime) async throws -> UIImage
    func trimVideo(at url: URL, start: Double, duration: Double) async throws -> URL
    func addCaptions(to url: URL, captions: [Caption]) async throws -> URL
}
```

### 5.2 Cache Manager
```swift
// CacheManager.swift
actor CacheManager {
    private let maxCacheSize: Int = 500_000_000 // 500MB
    private let cacheDirectory: URL
    
    func store(_ data: Data, for key: String) async throws
    func retrieve(for key: String) async -> Data?
    func remove(for key: String) async
    func clearExpired() async
    func totalSize() async -> Int
}
```

### 5.3 WebSocket Manager
```swift
// WebSocketManager.swift
class WebSocketManager: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect(to url: URL) async
    func disconnect() async
    func send(_ message: WebSocketMessage) async throws
    func receive() async throws -> WebSocketMessage
}

enum WebSocketMessage: Codable {
    case jobUpdate(JobUpdate)
    case error(String)
}
```

## 6. Security & Privacy

### 6.1 Keychain Service
```swift
// KeychainService.swift
class KeychainService {
    func save(_ token: String, for key: String) throws
    func retrieve(for key: String) throws -> String?
    func delete(for key: String) throws
    func clear() throws
}
```

### 6.2 Biometric Authentication
```swift
// BiometricAuth.swift
class BiometricAuthService {
    func authenticate(reason: String) async throws -> Bool
    func canUseBiometrics() -> Bool
    var biometricType: LABiometryType { get }
}
```

## 7. Error Handling

### 7.1 Error Types
```swift
enum FunClipError: LocalizedError {
    case network(NetworkError)
    case authentication(AuthError)
    case videoProcessing(ProcessingError)
    case storage(StorageError)
    
    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
}
```

### 7.2 Error Recovery
```swift
// ErrorRecovery.swift
protocol ErrorRecoverable {
    func canRecover(from error: Error) -> Bool
    func recover(from error: Error) async throws
}
```

## 8. Testing Strategy

### 8.1 Unit Tests
```swift
// AuthManagerTests.swift
class AuthManagerTests: XCTestCase {
    func testSignInWithApple() async throws { ... }
    func testTokenRefresh() async throws { ... }
}

// VideoProcessorTests.swift  
class VideoProcessorTests: XCTestCase {
    func testVideoUpload() async throws { ... }
    func testYouTubeProcessing() async throws { ... }
}
```

### 8.2 UI Tests
```swift
// LoginUITests.swift
class LoginUITests: XCTestCase {
    func testSuccessfulLogin() throws { ... }
    func testInvalidCredentials() throws { ... }
}
```

## 9. Performance Optimization

### 9.1 Memory Management
- Lazy loading of video thumbnails
- Image caching with size limits
- Automatic cache cleanup
- Weak references in closures

### 9.2 Network Optimization
- Request debouncing
- Retry logic with exponential backoff
- Background URL sessions
- Chunked uploads for large files

### 9.3 UI Optimization
- Lazy grids for video history
- Prefetching in lists
- Image downsampling
- 60 FPS animations

## 10. Analytics & Monitoring

### 10.1 Event Tracking
```swift
enum AnalyticsEvent {
    case videoUploaded(source: VideoSource)
    case clipGenerated(viralityScore: Int)
    case clipShared(platform: SocialPlatform)
    case error(type: String, details: String)
}
```

### 10.2 Crash Reporting
```swift
// CrashReporter.swift
class CrashReporter {
    func initialize()
    func logError(_ error: Error, context: [String: Any])
    func setUser(_ userID: String)
}
```

## 11. Configuration

### 11.1 Environment Configuration
```swift
enum Environment {
    case development
    case staging
    case production
    
    var baseURL: URL { ... }
    var apiKey: String { ... }
    var enableLogging: Bool { ... }
}
```

### 11.2 Feature Flags
```swift
struct FeatureFlags {
    static let enableYouTubeDownload = true
    static let enableCaptions = true
    static let maxVideoDuration = 600 // 10 minutes
    static let maxFileSize = 500_000_000 // 500MB
}
```

## 12. Dependencies

### 12.1 Swift Package Manager
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.0"),
    .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "4.2.0")
]
```

## 13. Build & Deployment

### 13.1 Build Configuration
- **Bundle ID:** com.funclip.ios
- **Deployment Target:** iOS 16.0
- **Swift Version:** 5.9
- **Xcode Version:** 15.0+

### 13.2 CI/CD Pipeline
```yaml
# .github/workflows/ios.yml
- Build & Test (GitHub Actions)
- Code signing (Fastlane Match)
- TestFlight upload (Fastlane)
- App Store submission
```

---

*Last Updated: August 2025*
*Version: 1.0.0*
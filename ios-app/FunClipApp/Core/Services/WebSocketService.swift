import Foundation
import Combine

/// Service for managing WebSocket connections for real-time processing updates
@MainActor
class WebSocketService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected
    @Published var processingStatus: ProcessingStatus?
    @Published var processingProgress: Double = 0.0
    @Published var currentStage: ProcessingStage = .idle
    @Published var error: WebSocketError?
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // MARK: - Constants
    private let webSocketURL = "\(AppConfig.Backend.baseURL.replacingOccurrences(of: "http", with: "ws"))/ws"
    
    // MARK: - Initialization
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket server with job ID
    func connect(jobId: String, token: String? = nil) {
        guard connectionState != .connected else { return }
        
        var urlComponents = URLComponents(string: webSocketURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "job_id", value: jobId)
        ]
        
        if let token = token {
            urlComponents.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        
        guard let url = urlComponents.url else {
            self.error = .invalidURL
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        connectionState = .connecting
        receiveMessage()
        startPing()
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        stopPing()
        stopReconnect()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        connectionState = .disconnected
        currentStage = .idle
        processingProgress = 0.0
    }
    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            processData(data)
            
        case .string(let text):
            processString(text)
            
        @unknown default:
            break
        }
    }
    
    private func processString(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        processData(data)
    }
    
    private func processData(_ data: Data) {
        do {
            let update = try JSONDecoder().decode(ProcessingUpdate.self, from: data)
            handleProcessingUpdate(update)
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleProcessingUpdate(_ update: ProcessingUpdate) {
        // Update connection state if needed
        if connectionState != .connected {
            connectionState = .connected
            reconnectAttempts = 0
        }
        
        // Update processing status
        processingStatus = ProcessingStatus(
            jobId: update.jobId,
            status: update.status,
            message: update.message,
            error: update.error
        )
        
        // Update stage and progress
        if let stage = ProcessingStage(rawValue: update.stage ?? "") {
            currentStage = stage
        }
        
        if let progress = update.progress {
            processingProgress = progress
        }
        
        // Handle completion
        if update.status == "completed" {
            handleCompletion(update)
        } else if update.status == "failed" {
            handleFailure(update)
        }
    }
    
    private func handleCompletion(_ update: ProcessingUpdate) {
        currentStage = .complete
        processingProgress = 1.0
        
        // Post notification for completion
        NotificationCenter.default.post(
            name: .processingCompleted,
            object: nil,
            userInfo: ["jobId": update.jobId, "clips": update.clips ?? []]
        )
        
        // Schedule disconnect after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.disconnect()
        }
    }
    
    private func handleFailure(_ update: ProcessingUpdate) {
        currentStage = .failed
        
        if let errorMessage = update.error {
            error = .processingFailed(errorMessage)
        }
        
        // Post notification for failure
        NotificationCenter.default.post(
            name: .processingFailed,
            object: nil,
            userInfo: ["jobId": update.jobId, "error": update.error ?? "Unknown error"]
        )
        
        disconnect()
    }
    
    // MARK: - Ping/Pong
    
    private func startPing() {
        stopPing()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                self?.handleDisconnection()
            }
        }
    }
    
    // MARK: - Reconnection
    
    private func handleDisconnection() {
        connectionState = .disconnected
        stopPing()
        
        if reconnectAttempts < maxReconnectAttempts {
            attemptReconnect()
        } else {
            error = .connectionLost
        }
    }
    
    private func attemptReconnect() {
        reconnectAttempts += 1
        connectionState = .reconnecting
        
        let delay = Double(min(reconnectAttempts * 2, 10)) // Exponential backoff, max 10 seconds
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if let jobId = self.processingStatus?.jobId {
                self.connect(jobId: jobId)
            }
        }
    }
    
    private func stopReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }
    
    // MARK: - Send Message
    
    func send(_ message: [String: Any]) {
        guard connectionState == .connected else { return }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("Send error: \(error)")
                }
            }
        } catch {
            print("Failed to send message: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        connectionState = .connected
        reconnectAttempts = 0
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed: \(closeCode)")
        handleDisconnection()
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}

enum ProcessingStage: String, CaseIterable {
    case idle = "idle"
    case uploading = "uploading"
    case transcribing = "transcribing"
    case analyzing = "analyzing"
    case clipping = "clipping"
    case complete = "complete"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .uploading: return "Uploading Video"
        case .transcribing: return "Transcribing Audio"
        case .analyzing: return "Finding Viral Moments"
        case .clipping: return "Creating Clips"
        case .complete: return "Complete!"
        case .failed: return "Failed"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .uploading: return "arrow.up.circle"
        case .transcribing: return "mic.circle"
        case .analyzing: return "brain"
        case .clipping: return "scissors"
        case .complete: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .idle: return "gray"
        case .uploading: return "blue"
        case .transcribing: return "purple"
        case .analyzing: return "orange"
        case .clipping: return "green"
        case .complete: return "green"
        case .failed: return "red"
        }
    }
}

struct ProcessingStatus {
    let jobId: String
    let status: String
    let message: String?
    let error: String?
}

struct ProcessingUpdate: Codable {
    let jobId: String
    let status: String
    let stage: String?
    let progress: Double?
    let message: String?
    let error: String?
    let clips: [ClipInfo]?
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case stage
        case progress
        case message
        case error
        case clips
    }
}

struct ClipInfo: Codable {
    let id: String
    let startTime: Double
    let endTime: Double
    let viralityScore: Double
    let reason: String
    let thumbnailUrl: String?
    let clipUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case viralityScore = "virality_score"
        case reason
        case thumbnailUrl = "thumbnail_url"
        case clipUrl = "clip_url"
    }
}

enum WebSocketError: LocalizedError {
    case invalidURL
    case connectionLost
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionLost:
            return "Connection lost. Please check your internet connection."
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let processingCompleted = Notification.Name("processingCompleted")
    static let processingFailed = Notification.Name("processingFailed")
}
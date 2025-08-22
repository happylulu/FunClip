import SwiftUI
import Combine

struct ProcessingStatusView: View {
    @StateObject private var webSocketService = WebSocketService()
    @State private var animationPhase = 0.0
    
    let jobId: String
    let onComplete: ([ClipInfo]) -> Void
    let onError: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Progress Ring
                    ProgressRingView(
                        progress: webSocketService.processingProgress,
                        stage: webSocketService.currentStage
                    )
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 0.5), value: webSocketService.processingProgress)
                    
                    // Stage Information
                    VStack(spacing: 16) {
                        Text(webSocketService.currentStage.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        if let status = webSocketService.processingStatus {
                            Text(status.message ?? "Processing your video...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Stage Progress Indicators
                    ProcessingStagesView(currentStage: webSocketService.currentStage)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Connection Status
                    ConnectionStatusView(state: webSocketService.connectionState)
                        .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Processing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        webSocketService.disconnect()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Connect to WebSocket
            if let token = try? KeychainService().retrieve(for: "backend_token") {
                webSocketService.connect(jobId: jobId, token: token)
            } else {
                webSocketService.connect(jobId: jobId)
            }
        }
        .onDisappear {
            webSocketService.disconnect()
        }
        .onReceive(NotificationCenter.default.publisher(for: .processingCompleted)) { notification in
            if let clips = notification.userInfo?["clips"] as? [ClipInfo] {
                onComplete(clips)
                dismiss()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .processingFailed)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                onError(error)
                dismiss()
            }
        }
    }
}

// MARK: - Progress Ring View

struct ProgressRingView: View {
    let progress: Double
    let stage: ProcessingStage
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Center content
            VStack(spacing: 8) {
                Image(systemName: stage.icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color(stage.color))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        stage == .complete ? nil :
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Processing Stages View

struct ProcessingStagesView: View {
    let currentStage: ProcessingStage
    
    let stages: [ProcessingStage] = [
        .uploading,
        .transcribing,
        .analyzing,
        .clipping,
        .complete
    ]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(stages, id: \.self) { stage in
                StageIndicator(
                    stage: stage,
                    isActive: stage == currentStage,
                    isCompleted: stageIndex(stage) < stageIndex(currentStage)
                )
                
                if stage != stages.last {
                    Rectangle()
                        .fill(stageIndex(stage) < stageIndex(currentStage) ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func stageIndex(_ stage: ProcessingStage) -> Int {
        stages.firstIndex(of: stage) ?? 0
    }
}

struct StageIndicator: View {
    let stage: ProcessingStage
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(isActive ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
            }
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
            
            Text(stageName)
                .font(.system(size: 9))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 50)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .indigo
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var stageName: String {
        switch stage {
        case .uploading: return "Upload"
        case .transcribing: return "Transcribe"
        case .analyzing: return "Analyze"
        case .clipping: return "Clip"
        case .complete: return "Done"
        default: return ""
        }
    }
}

// MARK: - Connection Status View

struct ConnectionStatusView: View {
    let state: ConnectionState
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .reconnecting: return "Reconnecting..."
        case .disconnected: return "Disconnected"
        }
    }
}

// MARK: - Preview

struct ProcessingStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingStatusView(
            jobId: "test-job-123",
            onComplete: { clips in
                print("Completed with \(clips.count) clips")
            },
            onError: { error in
                print("Error: \(error)")
            }
        )
    }
}
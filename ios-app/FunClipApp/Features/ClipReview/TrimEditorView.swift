import SwiftUI
import AVKit

struct TrimEditorView: View {
    let clip: ProcessedClip
    let videoURL: URL?
    let onSave: (TrimmedClip) -> Void
    
    @State private var startTime: Double
    @State private var endTime: Double
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    
    @Environment(\.dismiss) var dismiss
    
    init(clip: ProcessedClip, videoURL: URL?, onSave: @escaping (TrimmedClip) -> Void) {
        self.clip = clip
        self.videoURL = videoURL
        self.onSave = onSave
        
        _startTime = State(initialValue: clip.startTime)
        _endTime = State(initialValue: clip.endTime)
    }
    
    var duration: Double {
        endTime - startTime
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video Preview
                VideoPlayer(player: player)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
                    .background(Color.black)
                    .overlay(alignment: .bottom) {
                        // Playback controls
                        HStack {
                            Button(action: togglePlayPause) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                    }
                
                // Trim Controls
                VStack(spacing: 20) {
                    // Timeline
                    TimelineView(
                        startTime: $startTime,
                        endTime: $endTime,
                        currentTime: currentTime,
                        maxDuration: clip.endTime - clip.startTime + 6 // Allow ±3 seconds
                    )
                    
                    // Time displays
                    HStack {
                        TimeDisplay(label: "Start", time: startTime)
                        Spacer()
                        TimeDisplay(label: "Duration", time: duration)
                        Spacer()
                        TimeDisplay(label: "End", time: endTime)
                    }
                    .padding(.horizontal)
                    
                    // Fine adjustment controls
                    VStack(spacing: 16) {
                        AdjustmentControl(
                            label: "Adjust Start",
                            value: $startTime,
                            min: max(0, clip.startTime - 3),
                            max: endTime - 1,
                            step: 0.1
                        )
                        
                        AdjustmentControl(
                            label: "Adjust End",
                            value: $endTime,
                            min: startTime + 1,
                            max: min(clip.endTime + 3, clip.endTime + 3),
                            step: 0.1
                        )
                    }
                    .padding(.horizontal)
                    
                    // Preset durations
                    HStack(spacing: 12) {
                        ForEach([9, 10, 11, 15], id: \.self) { duration in
                            Button(action: { setDuration(Double(duration)) }) {
                                Text("\(duration)s")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(self.duration == Double(duration) ? Color.indigo : Color.gray.opacity(0.2))
                                    .foregroundColor(self.duration == Double(duration) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Trim Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        guard let url = videoURL ?? URL(string: clip.clipUrl ?? "") else { return }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        
        // Seek to start time
        seekToTime(startTime)
        
        // Observe playback time
        player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { time in
            currentTime = time.seconds
            
            // Loop within trimmed range
            if currentTime >= endTime {
                seekToTime(startTime)
                if isPlaying {
                    player?.play()
                }
            }
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            if currentTime < startTime || currentTime >= endTime {
                seekToTime(startTime)
            }
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func seekToTime(_ time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    private func setDuration(_ duration: Double) {
        endTime = startTime + duration
    }
    
    private func saveAndDismiss() {
        let trimmedClip = TrimmedClip(
            clipId: clip.id,
            startTime: startTime,
            endTime: endTime
        )
        onSave(trimmedClip)
        dismiss()
    }
}

// MARK: - Subviews

struct TimelineView: View {
    @Binding var startTime: Double
    @Binding var endTime: Double
    let currentTime: Double
    let maxDuration: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 40)
                
                // Selected range
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.indigo.opacity(0.3))
                    .frame(
                        width: CGFloat((endTime - startTime) / maxDuration) * geometry.size.width,
                        height: 40
                    )
                    .offset(x: CGFloat(startTime / maxDuration) * geometry.size.width)
                
                // Start handle
                TrimHandle(isStart: true)
                    .offset(x: CGFloat(startTime / maxDuration) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newTime = (value.location.x / geometry.size.width) * maxDuration
                                startTime = max(0, min(newTime, endTime - 1))
                            }
                    )
                
                // End handle
                TrimHandle(isStart: false)
                    .offset(x: CGFloat(endTime / maxDuration) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newTime = (value.location.x / geometry.size.width) * maxDuration
                                endTime = max(startTime + 1, min(newTime, maxDuration))
                            }
                    )
                
                // Current time indicator
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: 50)
                    .offset(x: CGFloat(currentTime / maxDuration) * geometry.size.width)
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
    }
}

struct TrimHandle: View {
    let isStart: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 8)
            
            Image(systemName: isStart ? "chevron.left" : "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 8)
        }
        .frame(width: 20, height: 40)
        .background(Color.indigo)
        .cornerRadius(4)
    }
}

struct TimeDisplay: View {
    let label: String
    let time: Double
    
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, milliseconds)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formattedTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

struct AdjustmentControl: View {
    let label: String
    @Binding var value: Double
    let min: Double
    let max: Double
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: { value = max(min, value - step) }) {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                        .foregroundColor(.indigo)
                }
                
                Slider(value: $value, in: min...max, step: step)
                
                Button(action: { value = min(max, value + step) }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.indigo)
                }
            }
        }
    }
}
import SwiftUI
import AVKit

struct ClipReviewView: View {
    let clips: [ProcessedClip]
    let originalVideoURL: URL?
    
    @State private var selectedClipIndex = 0
    @State private var showingTrimEditor = false
    @State private var showingCaptionEditor = false
    @State private var favoriteClips: Set<String> = []
    @State private var editedClips: [String: EditedClip] = [:]
    
    @Environment(\.dismiss) var dismiss
    
    var currentClip: ProcessedClip {
        clips[selectedClipIndex]
    }
    
    var editedClip: EditedClip? {
        editedClips[currentClip.id]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video Preview
                ClipPlayerView(
                    clip: currentClip,
                    editedClip: editedClip,
                    videoURL: originalVideoURL
                )
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                .background(Color.black)
                
                // Clip Info and Controls
                ScrollView {
                    VStack(spacing: 20) {
                        // Virality Score Card
                        ViralityScoreCard(
                            score: currentClip.viralityScore,
                            reason: currentClip.reason,
                            isFavorite: favoriteClips.contains(currentClip.id),
                            onToggleFavorite: toggleFavorite
                        )
                        
                        // Clip Controls
                        ClipControlsView(
                            onTrim: { showingTrimEditor = true },
                            onCaption: { showingCaptionEditor = true },
                            onRegenerate: regenerateClip,
                            hasCaptions: editedClip?.captions != nil
                        )
                        
                        // Clip Selector
                        ClipSelectorView(
                            clips: clips,
                            selectedIndex: $selectedClipIndex,
                            favoriteClips: favoriteClips,
                            editedClips: editedClips
                        )
                    }
                    .padding()
                }
                
                // Bottom Action Bar
                ClipActionBar(
                    onSave: saveClips,
                    onShare: shareClips,
                    clipCount: clips.count,
                    favoriteCount: favoriteClips.count
                )
            }
            .navigationTitle("Review Clips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export All") {
                        exportAllClips()
                    }
                }
            }
            .sheet(isPresented: $showingTrimEditor) {
                TrimEditorView(
                    clip: currentClip,
                    videoURL: originalVideoURL,
                    onSave: { trimmedClip in
                        saveTrimmedClip(trimmedClip)
                    }
                )
            }
            .sheet(isPresented: $showingCaptionEditor) {
                CaptionEditorView(
                    clip: currentClip,
                    existingCaptions: editedClip?.captions,
                    onSave: { captions in
                        saveCaptions(captions)
                    }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleFavorite() {
        if favoriteClips.contains(currentClip.id) {
            favoriteClips.remove(currentClip.id)
        } else {
            favoriteClips.insert(currentClip.id)
        }
    }
    
    private func saveTrimmedClip(_ trimmedClip: TrimmedClip) {
        var edited = editedClips[currentClip.id] ?? EditedClip(originalClip: currentClip)
        edited.trimmedStart = trimmedClip.startTime
        edited.trimmedEnd = trimmedClip.endTime
        editedClips[currentClip.id] = edited
    }
    
    private func saveCaptions(_ captions: [Caption]) {
        var edited = editedClips[currentClip.id] ?? EditedClip(originalClip: currentClip)
        edited.captions = captions
        editedClips[currentClip.id] = edited
    }
    
    private func regenerateClip() {
        // TODO: Call API to regenerate this specific clip
        print("Regenerating clip: \(currentClip.id)")
    }
    
    private func saveClips() {
        // Save clips to camera roll
        let clipsToSave = favoriteClips.isEmpty ? clips : clips.filter { favoriteClips.contains($0.id) }
        
        Task {
            for clip in clipsToSave {
                await saveClipToCameraRoll(clip)
            }
        }
    }
    
    private func shareClips() {
        // Share clips
        let clipsToShare = favoriteClips.isEmpty ? clips : clips.filter { favoriteClips.contains($0.id) }
        
        // TODO: Implement sharing
        print("Sharing \(clipsToShare.count) clips")
    }
    
    private func exportAllClips() {
        // Export all clips
        print("Exporting all \(clips.count) clips")
    }
    
    private func saveClipToCameraRoll(_ clip: ProcessedClip) async {
        // TODO: Implement save to camera roll
        print("Saving clip \(clip.id) to camera roll")
    }
}

// MARK: - Subviews

struct ClipPlayerView: View {
    let clip: ProcessedClip
    let editedClip: EditedClip?
    let videoURL: URL?
    
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
            }
    }
    
    private func setupPlayer() {
        guard let url = videoURL ?? URL(string: clip.clipUrl ?? "") else { return }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Set clip boundaries
        let startTime = editedClip?.trimmedStart ?? clip.startTime
        let endTime = editedClip?.trimmedEnd ?? clip.endTime
        
        playerItem.seek(to: CMTime(seconds: startTime, preferredTimescale: 600), completionHandler: nil)
        
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        // Loop the clip
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playerItem.seek(to: CMTime(seconds: startTime, preferredTimescale: 600), completionHandler: nil)
            player?.play()
        }
    }
}

struct ViralityScoreCard: View {
    let score: Double
    let reason: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var scoreColor: Color {
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .red
    }
    
    var scoreEmoji: String {
        if score >= 0.8 { return "🔥" }
        if score >= 0.6 { return "✨" }
        return "📊"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Virality Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(scoreEmoji)
                            .font(.title2)
                        
                        Text("\(Int(score * 100))%")
                            .font(.title2.bold())
                            .foregroundColor(scoreColor)
                    }
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Why it's viral")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(reason)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ClipControlsView: View {
    let onTrim: () -> Void
    let onCaption: () -> Void
    let onRegenerate: () -> Void
    let hasCaptions: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ControlButton(
                icon: "scissors",
                title: "Trim",
                action: onTrim
            )
            
            ControlButton(
                icon: hasCaptions ? "captions.bubble.fill" : "captions.bubble",
                title: "Caption",
                action: onCaption,
                isActive: hasCaptions
            )
            
            ControlButton(
                icon: "arrow.clockwise",
                title: "Regenerate",
                action: onRegenerate
            )
        }
    }
}

struct ControlButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var isActive: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : .indigo)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isActive ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? Color.indigo : Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
}

struct ClipSelectorView: View {
    let clips: [ProcessedClip]
    @Binding var selectedIndex: Int
    let favoriteClips: Set<String>
    let editedClips: [String: EditedClip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Clips (\(clips.count))")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(clips.indices, id: \.self) { index in
                        ClipThumbnail(
                            clip: clips[index],
                            index: index,
                            isSelected: index == selectedIndex,
                            isFavorite: favoriteClips.contains(clips[index].id),
                            isEdited: editedClips[clips[index].id] != nil,
                            onTap: {
                                selectedIndex = index
                            }
                        )
                    }
                }
            }
        }
    }
}

struct ClipThumbnail: View {
    let clip: ProcessedClip
    let index: Int
    let isSelected: Bool
    let isFavorite: Bool
    let isEdited: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 120)
                        .overlay(
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Clip \(index + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 3)
                        )
                    
                    // Badges
                    VStack(spacing: 4) {
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(4)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        if isEdited {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(4)
                }
                
                Text(clip.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ClipActionBar: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let clipCount: Int
    let favoriteCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onSave) {
                Label("Save \(favoriteCount > 0 ? "(\(favoriteCount))" : "All")", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Models

struct EditedClip {
    let originalClip: ProcessedClip
    var trimmedStart: Double?
    var trimmedEnd: Double?
    var captions: [Caption]?
}

struct TrimmedClip {
    let clipId: String
    let startTime: Double
    let endTime: Double
}

struct Caption {
    let id: String
    let text: String
    let startTime: Double
    let endTime: Double
    let style: CaptionStyle
}

struct CaptionStyle {
    var position: CaptionPosition = .bottom
    var fontSize: CGFloat = 16
    var color: Color = .white
    var backgroundColor: Color = .black.opacity(0.5)
}

enum CaptionPosition {
    case top, center, bottom
}
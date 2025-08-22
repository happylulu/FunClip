import SwiftUI
import PhotosUI
import AVKit

struct VideoUploadView: View {
    @StateObject private var videoService = VideoService()
    @State private var showingVideoPicker = false
    @State private var youtubeURL = ""
    @State private var showingYouTubeInput = false
    @State private var showingVideoPreview = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Create Viral Clips")
                            .font(.title.bold())
                        
                        Text("Upload a video or paste a YouTube link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Upload Options
                    VStack(spacing: 20) {
                        // Upload from Camera Roll
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .videos
                        ) {
                            UploadOptionCard(
                                icon: "photo.stack.fill",
                                title: "Choose from Library",
                                description: "Select a video from your camera roll",
                                color: .indigo
                            )
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                await processSelectedVideo(newItem)
                            }
                        }
                        
                        // YouTube URL Option
                        Button(action: { showingYouTubeInput = true }) {
                            UploadOptionCard(
                                icon: "play.rectangle.fill",
                                title: "YouTube Video",
                                description: "Process a video from YouTube URL",
                                color: .red
                            )
                        }
                        
                        // Record Video Option (Future)
                        Button(action: { }) {
                            UploadOptionCard(
                                icon: "video.fill",
                                title: "Record Video",
                                description: "Coming soon",
                                color: .gray
                            )
                        }
                        .disabled(true)
                        .opacity(0.6)
                    }
                    .padding(.horizontal)
                    
                    // Video Preview (if selected)
                    if let metadata = videoService.videoMetadata {
                        VideoMetadataCard(metadata: metadata)
                            .transition(.scale.combined(with: .opacity))
                            .onTapGesture {
                                showingVideoPreview = true
                            }
                        
                        // Upload Button
                        Button(action: uploadVideo) {
                            if videoService.isUploading {
                                UploadProgressView(progress: videoService.uploadProgress)
                            } else {
                                Label("Process Video", systemImage: "wand.and.stars")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.indigo)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(videoService.isUploading)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingYouTubeInput) {
                YouTubeInputSheet(
                    youtubeURL: $youtubeURL,
                    onSubmit: processYouTubeURL
                )
            }
            .sheet(isPresented: $showingVideoPreview) {
                if let videoURL = videoService.selectedVideoURL {
                    VideoPreviewSheet(videoURL: videoURL)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingProcessingView) {
                if let jobId = currentJobId {
                    ProcessingStatusView(
                        jobId: jobId,
                        onComplete: { clips in
                            // Handle completed clips
                            print("Processing complete with \(clips.count) clips")
                            // Navigate to results view
                        },
                        onError: { error in
                            errorMessage = error
                            showError = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func processSelectedVideo(_ item: PhotosPickerItem?) async {
        do {
            isProcessing = true
            try await videoService.processVideoSelection(item)
            isProcessing = false
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func processYouTubeURL() {
        Task {
            do {
                let videoID = try await videoService.processYouTubeURL(youtubeURL)
                // TODO: Send to backend for processing
                print("YouTube Video ID: \(videoID)")
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    @State private var showingProcessingView = false
    @State private var currentJobId: String?
    @StateObject private var historyService = ProcessingHistoryService()
    
    private func uploadVideo() {
        Task {
            do {
                let response = try await videoService.uploadVideo(to: "videos/upload")
                
                // Create processing job
                let job = ProcessingJob(
                    id: response.jobId,
                    videoSource: .upload(fileName: videoService.selectedVideoURL?.lastPathComponent ?? "video.mp4"),
                    status: .processing
                )
                historyService.addJob(job)
                
                // Navigate to processing view
                currentJobId = response.jobId
                showingProcessingView = true
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Subviews

struct UploadOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct VideoMetadataCard: View {
    let metadata: VideoMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Video Selected")
                    .font(.headline)
                Spacer()
                Text("Tap to preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                MetadataRow(label: "Duration", value: metadata.formattedDuration)
                MetadataRow(label: "Size", value: metadata.formattedSize)
                MetadataRow(label: "Resolution", value: metadata.resolution)
                MetadataRow(label: "Format", value: metadata.format)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct UploadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 2)
            
            Text("Uploading... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sheets

struct YouTubeInputSheet: View {
    @Binding var youtubeURL: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                Text("Enter YouTube URL")
                    .font(.title2.bold())
                
                Text("Paste a link to any YouTube video")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("https://youtube.com/watch?v=...", text: $youtubeURL)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                Button(action: {
                    onSubmit()
                    dismiss()
                }) {
                    Text("Process Video")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(youtubeURL.isEmpty ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(youtubeURL.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VideoPreviewSheet: View {
    let videoURL: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .navigationTitle("Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

struct VideoUploadView_Previews: PreviewProvider {
    static var previews: some View {
        VideoUploadView()
    }
}
import Foundation
import PhotosUI
import AVFoundation
import SwiftUI

/// Service for handling video selection, validation, and upload
@MainActor
class VideoService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedVideoURL: URL?
    @Published var videoMetadata: VideoMetadata?
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: VideoError?
    
    // MARK: - Constants
    private let maxVideoDuration: TimeInterval = 600 // 10 minutes
    private let maxVideoSize: Int64 = 500 * 1024 * 1024 // 500 MB
    private let chunkSize = 5 * 1024 * 1024 // 5 MB chunks
    
    // MARK: - Video Selection from Photos
    
    /// Process selected photo picker item
    func processVideoSelection(_ item: PhotosPickerItem?) async throws {
        guard let item = item else { return }
        
        // Load video as data
        guard let movie = try await item.loadTransferable(type: Movie.self) else {
            throw VideoError.invalidFormat
        }
        
        // Save to temporary URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        try movie.data.write(to: tempURL)
        
        // Validate and extract metadata
        try await validateAndProcessVideo(at: tempURL)
    }
    
    /// Validate video and extract metadata
    private func validateAndProcessVideo(at url: URL) async throws {
        let asset = AVAsset(url: url)
        
        // Check if it's a valid video
        guard asset.isPlayable else {
            throw VideoError.invalidFormat
        }
        
        // Get duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Check duration limit
        guard durationSeconds <= maxVideoDuration else {
            throw VideoError.tooLong(duration: durationSeconds)
        }
        
        // Get file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        // Check size limit
        guard fileSize <= maxVideoSize else {
            throw VideoError.tooLarge(size: fileSize)
        }
        
        // Get video dimensions
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw VideoError.noVideoTrack
        }
        
        let size = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        // Apply transform to get correct dimensions
        let transformedSize = size.applying(preferredTransform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)
        
        // Create metadata
        self.videoMetadata = VideoMetadata(
            url: url,
            duration: durationSeconds,
            fileSize: fileSize,
            width: Int(width),
            height: Int(height),
            format: url.pathExtension.uppercased()
        )
        
        self.selectedVideoURL = url
    }
    
    // MARK: - YouTube URL Processing
    
    /// Validate and process YouTube URL
    func processYouTubeURL(_ urlString: String) async throws -> String {
        // Validate URL format
        guard let url = URL(string: urlString),
              let host = url.host,
              (host.contains("youtube.com") || host.contains("youtu.be")) else {
            throw VideoError.invalidYouTubeURL
        }
        
        // Extract video ID
        var videoID: String?
        
        if host.contains("youtube.com") {
            // Format: https://www.youtube.com/watch?v=VIDEO_ID
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let vParam = queryItems.first(where: { $0.name == "v" }) {
                videoID = vParam.value
            }
        } else if host.contains("youtu.be") {
            // Format: https://youtu.be/VIDEO_ID
            videoID = url.lastPathComponent
        }
        
        guard let videoID = videoID, !videoID.isEmpty else {
            throw VideoError.invalidYouTubeURL
        }
        
        return videoID
    }
    
    // MARK: - Video Upload
    
    /// Upload video with progress tracking
    func uploadVideo(to endpoint: String) async throws -> VideoUploadResponse {
        guard let videoURL = selectedVideoURL else {
            throw VideoError.noVideoSelected
        }
        
        guard let metadata = videoMetadata else {
            throw VideoError.noMetadata
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            isUploading = false
        }
        
        // Determine if we need chunked upload
        if metadata.fileSize > chunkSize {
            return try await uploadVideoInChunks(videoURL: videoURL, to: endpoint)
        } else {
            return try await uploadVideoDirect(videoURL: videoURL, to: endpoint)
        }
    }
    
    /// Direct upload for small videos
    private func uploadVideoDirect(videoURL: URL, to endpoint: String) async throws -> VideoUploadResponse {
        guard let uploadURL = URL(string: "\(AppConfig.Backend.apiURL)/\(endpoint)") else {
            throw VideoError.invalidEndpoint
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // Add auth token
        if let token = try? KeychainService().retrieve(for: "backend_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        let videoData = try Data(contentsOf: videoURL)
        let formData = createMultipartFormData(
            videoData: videoData,
            boundary: boundary,
            filename: videoURL.lastPathComponent
        )
        
        // Upload with progress
        let (data, response) = try await URLSession.shared.upload(
            for: request,
            from: formData,
            delegate: UploadDelegate(progressHandler: { [weak self] progress in
                Task { @MainActor in
                    self?.uploadProgress = progress
                }
            })
        )
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw VideoError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(VideoUploadResponse.self, from: data)
        return uploadResponse
    }
    
    /// Chunked upload for large videos
    private func uploadVideoInChunks(videoURL: URL, to endpoint: String) async throws -> VideoUploadResponse {
        let videoData = try Data(contentsOf: videoURL)
        let totalChunks = Int(ceil(Double(videoData.count) / Double(chunkSize)))
        var uploadedChunks = 0
        
        let uploadID = UUID().uuidString
        
        for chunkIndex in 0..<totalChunks {
            let start = chunkIndex * chunkSize
            let end = min(start + chunkSize, videoData.count)
            let chunkData = videoData[start..<end]
            
            try await uploadChunk(
                chunkData: chunkData,
                chunkIndex: chunkIndex,
                totalChunks: totalChunks,
                uploadID: uploadID,
                endpoint: endpoint
            )
            
            uploadedChunks += 1
            uploadProgress = Double(uploadedChunks) / Double(totalChunks)
        }
        
        // Finalize upload
        return try await finalizeChunkedUpload(uploadID: uploadID, endpoint: endpoint)
    }
    
    private func uploadChunk(
        chunkData: Data,
        chunkIndex: Int,
        totalChunks: Int,
        uploadID: String,
        endpoint: String
    ) async throws {
        guard let uploadURL = URL(string: "\(AppConfig.Backend.apiURL)/\(endpoint)/chunk") else {
            throw VideoError.invalidEndpoint
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(uploadID, forHTTPHeaderField: "X-Upload-ID")
        request.setValue("\(chunkIndex)", forHTTPHeaderField: "X-Chunk-Index")
        request.setValue("\(totalChunks)", forHTTPHeaderField: "X-Total-Chunks")
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: chunkData)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw VideoError.chunkUploadFailed(chunkIndex: chunkIndex)
        }
    }
    
    private func finalizeChunkedUpload(uploadID: String, endpoint: String) async throws -> VideoUploadResponse {
        guard let uploadURL = URL(string: "\(AppConfig.Backend.apiURL)/\(endpoint)/finalize") else {
            throw VideoError.invalidEndpoint
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["upload_id": uploadID]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw VideoError.uploadFailed
        }
        
        return try JSONDecoder().decode(VideoUploadResponse.self, from: data)
    }
    
    private func createMultipartFormData(videoData: Data, boundary: String, filename: String) -> Data {
        var formData = Data()
        
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        formData.append(videoData)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return formData
    }
}

// MARK: - Supporting Types

struct VideoMetadata {
    let url: URL
    let duration: TimeInterval
    let fileSize: Int64
    let width: Int
    let height: Int
    let format: String
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var resolution: String {
        return "\(width)×\(height)"
    }
}

struct VideoUploadResponse: Codable {
    let jobId: String
    let status: String
    let message: String?
}

enum VideoError: LocalizedError {
    case invalidFormat
    case tooLong(duration: TimeInterval)
    case tooLarge(size: Int64)
    case noVideoTrack
    case invalidYouTubeURL
    case noVideoSelected
    case noMetadata
    case invalidEndpoint
    case uploadFailed
    case chunkUploadFailed(chunkIndex: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid video format. Please select a valid video file."
        case .tooLong(let duration):
            return "Video is too long (\(Int(duration)/60) minutes). Maximum duration is 10 minutes."
        case .tooLarge(let size):
            let formatter = ByteCountFormatter()
            return "Video is too large (\(formatter.string(fromByteCount: size))). Maximum size is 500 MB."
        case .noVideoTrack:
            return "No video track found in the file."
        case .invalidYouTubeURL:
            return "Invalid YouTube URL. Please enter a valid YouTube video link."
        case .noVideoSelected:
            return "No video selected."
        case .noMetadata:
            return "Video metadata not available."
        case .invalidEndpoint:
            return "Invalid upload endpoint."
        case .uploadFailed:
            return "Video upload failed. Please try again."
        case .chunkUploadFailed(let chunkIndex):
            return "Failed to upload chunk \(chunkIndex + 1). Please try again."
        }
    }
}

// MARK: - Transferable Movie Type

struct Movie: Transferable {
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .movie) { data in
            Movie(data: data)
        }
    }
}

// MARK: - Upload Delegate

class UploadDelegate: NSObject, URLSessionTaskDelegate {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progressHandler(progress)
    }
}
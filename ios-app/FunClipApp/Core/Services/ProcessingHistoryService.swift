import Foundation
import SwiftUI

/// Service for managing processing history persistence
@MainActor
class ProcessingHistoryService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var processingJobs: [ProcessingJob] = []
    
    // MARK: - Constants
    private let storageKey = "processing_history"
    private let maxHistoryItems = 50
    private let cacheExpirationDays = 30
    
    // MARK: - Initialization
    init() {
        loadHistory()
        cleanupOldJobs()
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new processing job
    func addJob(_ job: ProcessingJob) {
        processingJobs.insert(job, at: 0)
        
        // Limit history size
        if processingJobs.count > maxHistoryItems {
            processingJobs = Array(processingJobs.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    /// Update an existing job
    func updateJob(_ job: ProcessingJob) {
        if let index = processingJobs.firstIndex(where: { $0.id == job.id }) {
            processingJobs[index] = job
            saveHistory()
        }
    }
    
    /// Delete a job
    func deleteJob(_ jobId: String) {
        processingJobs.removeAll { $0.id == jobId }
        saveHistory()
        
        // Also delete cached files
        deleteCachedFiles(for: jobId)
    }
    
    /// Get job by ID
    func getJob(by id: String) -> ProcessingJob? {
        return processingJobs.first { $0.id == id }
    }
    
    /// Update job status
    func updateJobStatus(_ jobId: String, status: JobStatus, error: String? = nil) {
        if var job = getJob(by: jobId) {
            job.status = status
            job.error = error
            job.updatedAt = Date()
            
            if status == .completed || status == .failed {
                job.completedAt = Date()
            }
            
            updateJob(job)
        }
    }
    
    /// Update job progress
    func updateJobProgress(_ jobId: String, progress: Double, stage: ProcessingStage) {
        if var job = getJob(by: jobId) {
            job.progress = progress
            job.currentStage = stage
            job.updatedAt = Date()
            updateJob(job)
        }
    }
    
    /// Add clips to job
    func addClipsToJob(_ jobId: String, clips: [ProcessedClip]) {
        if var job = getJob(by: jobId) {
            job.clips = clips
            job.status = .completed
            job.completedAt = Date()
            updateJob(job)
        }
    }
    
    // MARK: - Retry Mechanism
    
    /// Retry a failed job
    func retryJob(_ jobId: String) async throws -> ProcessingJob {
        guard var job = getJob(by: jobId),
              job.status == .failed else {
            throw ProcessingError.jobNotFound
        }
        
        // Reset job for retry
        job.status = .pending
        job.progress = 0
        job.currentStage = .idle
        job.error = nil
        job.retryCount += 1
        job.updatedAt = Date()
        
        updateJob(job)
        
        // Trigger re-upload/processing
        // This would call your video upload service
        
        return job
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(processingJobs)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save processing history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            processingJobs = try decoder.decode([ProcessingJob].self, from: data)
        } catch {
            print("Failed to load processing history: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupOldJobs() {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -cacheExpirationDays,
            to: Date()
        ) ?? Date()
        
        let jobsToDelete = processingJobs.filter { job in
            if let completedAt = job.completedAt {
                return completedAt < cutoffDate
            }
            return false
        }
        
        for job in jobsToDelete {
            deleteJob(job.id)
        }
    }
    
    private func deleteCachedFiles(for jobId: String) {
        // Delete cached video files
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let jobFolder = documentsPath.appendingPathComponent("jobs/\(jobId)")
        
        try? FileManager.default.removeItem(at: jobFolder)
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> ProcessingStatistics {
        let completed = processingJobs.filter { $0.status == .completed }.count
        let failed = processingJobs.filter { $0.status == .failed }.count
        let totalClips = processingJobs.compactMap { $0.clips?.count }.reduce(0, +)
        
        let averageViralityScore = processingJobs
            .compactMap { $0.clips }
            .flatMap { $0 }
            .map { $0.viralityScore }
            .reduce(0, +) / Double(max(totalClips, 1))
        
        return ProcessingStatistics(
            totalJobs: processingJobs.count,
            completedJobs: completed,
            failedJobs: failed,
            totalClips: totalClips,
            averageViralityScore: averageViralityScore
        )
    }
}

// MARK: - Models

struct ProcessingJob: Identifiable, Codable {
    let id: String
    let videoSource: VideoSource
    var status: JobStatus
    var progress: Double
    var currentStage: ProcessingStage
    var clips: [ProcessedClip]?
    var error: String?
    var retryCount: Int
    let createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        videoSource: VideoSource,
        status: JobStatus = .pending,
        progress: Double = 0,
        currentStage: ProcessingStage = .idle,
        clips: [ProcessedClip]? = nil,
        error: String? = nil,
        retryCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.videoSource = videoSource
        self.status = status
        self.progress = progress
        self.currentStage = currentStage
        self.clips = clips
        self.error = error
        self.retryCount = retryCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}

enum VideoSource: Codable {
    case upload(fileName: String)
    case youtube(videoId: String, title: String?)
    case recording(duration: TimeInterval)
    
    var displayName: String {
        switch self {
        case .upload(let fileName):
            return fileName
        case .youtube(_, let title):
            return title ?? "YouTube Video"
        case .recording(let duration):
            return "Recording (\(Int(duration))s)"
        }
    }
    
    var icon: String {
        switch self {
        case .upload:
            return "square.and.arrow.up"
        case .youtube:
            return "play.rectangle"
        case .recording:
            return "video"
        }
    }
}

enum JobStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

struct ProcessedClip: Identifiable, Codable {
    let id: String
    let startTime: Double
    let endTime: Double
    let viralityScore: Double
    let reason: String
    let thumbnailUrl: String?
    let clipUrl: String?
    let localPath: String?
    
    var duration: Double {
        return endTime - startTime
    }
    
    var formattedDuration: String {
        return String(format: "%.1fs", duration)
    }
    
    var formattedScore: String {
        return "\(Int(viralityScore * 100))%"
    }
}

struct ProcessingStatistics {
    let totalJobs: Int
    let completedJobs: Int
    let failedJobs: Int
    let totalClips: Int
    let averageViralityScore: Double
    
    var successRate: Double {
        guard totalJobs > 0 else { return 0 }
        return Double(completedJobs) / Double(totalJobs)
    }
    
    var formattedSuccessRate: String {
        return "\(Int(successRate * 100))%"
    }
}

enum ProcessingError: LocalizedError {
    case jobNotFound
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .jobNotFound:
            return "Processing job not found"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}
#!/usr/bin/swift

import Foundation

// Test YouTube URL processing logic
func processYouTubeURL(_ urlString: String) throws -> String {
    // Validate URL format
    guard let url = URL(string: urlString),
          let host = url.host,
          (host.contains("youtube.com") || host.contains("youtu.be")) else {
        throw URLError(.badURL)
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
        throw URLError(.badURL)
    }
    
    return videoID
}

// Test cases
let testURLs = [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ",  // Standard YouTube URL
    "https://youtu.be/dQw4w9WgXcQ",                  // Short YouTube URL
    "https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s", // With timestamp
    "https://m.youtube.com/watch?v=dQw4w9WgXcQ",     // Mobile YouTube
    "https://www.youtube.com/embed/dQw4w9WgXcQ",     // Embed URL
    "invalid-url",                                    // Invalid URL
    "https://vimeo.com/123456"                       // Wrong platform
]

print("🧪 Testing YouTube URL Processing")
print(String(repeating: "=", count: 40))

for testURL in testURLs {
    print("\nTesting: \(testURL)")
    do {
        let videoID = try processYouTubeURL(testURL)
        print("✅ Success! Video ID: \(videoID)")
    } catch {
        print("❌ Failed: \(error)")
    }
}

print("\n" + String(repeating: "=", count: 40))
print("Test complete!")
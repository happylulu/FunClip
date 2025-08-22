import Foundation

/// App configuration constants
enum AppConfig {
    
    /// Supabase configuration
    enum Supabase {
        static let url = "https://ivyftvzkswuoavsfaplk.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2eWZ0dnprc3d1b2F2c2ZhcGxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUyNjk0NzcsImV4cCI6MjA3MDg0NTQ3N30.7yqgvXOXwQpVtByIlzTI8eei6rA5-1Rotn9AFS12DLY"
    }
    
    /// Backend API configuration
    enum Backend {
        static let baseURL = "http://147.182.255.74:8000"
        static let apiVersion = "v1"
        
        static var apiURL: String {
            return "\(baseURL)/api/\(apiVersion)"
        }
    }
    
    /// Deepgram configuration
    enum Deepgram {
        static let apiKey = ProcessInfo.processInfo.environment["DEEPGRAM_API_KEY"] ?? ""
    }
}
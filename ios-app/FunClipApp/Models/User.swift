import Foundation

/// User model representing authenticated user
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String
    let fullName: String?
    let avatarURL: URL?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - User Extension for Display

extension User {
    /// Display name for UI
    var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        
        // Extract name from email
        let emailPrefix = email.split(separator: "@").first ?? ""
        return String(emailPrefix).capitalized
    }
    
    /// Initials for avatar placeholder
    var initials: String {
        let names = displayName.split(separator: " ")
        
        if names.count >= 2 {
            // First and last name initials
            let first = names.first?.first ?? Character("")
            let last = names.last?.first ?? Character("")
            return "\(first)\(last)".uppercased()
        } else if let firstName = names.first {
            // Single name - use first two characters
            let chars = Array(firstName.prefix(2))
            return String(chars).uppercased()
        }
        
        return "FC" // FunClip default
    }
}
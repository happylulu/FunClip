import Foundation
import Supabase

/// Supabase client singleton for managing backend connections
final class SupabaseClient {
    
    static let shared = SupabaseClient()
    
    private(set) var client: Supabase.SupabaseClient?
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        // Load configuration from AppConfig
        let supabaseURL = AppConfig.Supabase.url
        let supabaseAnonKey = AppConfig.Supabase.anonKey
        
        guard let url = URL(string: supabaseURL) else {
            print("⚠️ Warning: Invalid Supabase URL")
            return
        }
        
        client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
        
        print("✅ Supabase client initialized")
    }
    
    /// Exchange Apple Sign In credentials for Supabase session
    func signInWithApple(identityToken: String) async throws -> AuthSession {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken
            )
        )
        
        return session
    }
    
    /// Sign in with email and password
    func signInWithEmail(_ email: String, password: String) async throws -> AuthSession {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        return session
    }
    
    /// Sign up with email and password
    func signUpWithEmail(_ email: String, password: String) async throws -> AuthSession {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        let session = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        guard let session = session.session else {
            throw SupabaseError.signUpRequiresConfirmation
        }
        
        return session
    }
    
    /// Get current session
    func currentSession() async throws -> AuthSession? {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        return try await client.auth.session
    }
    
    /// Refresh session with refresh token
    func refreshSession(_ refreshToken: String) async throws -> AuthSession {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        let session = try await client.auth.refreshSession(refreshToken: refreshToken)
        return session
    }
    
    /// Sign out
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        try await client.auth.signOut()
    }
    
    /// Exchange custom backend JWT for Supabase session
    func exchangeBackendToken(_ backendToken: String) async throws -> AuthSession {
        guard let client = client else {
            throw SupabaseError.clientNotConfigured
        }
        
        // This would typically call your custom backend endpoint to exchange tokens
        // For now, we'll use the backend token as a custom JWT
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google, // Using as generic OAuth provider
                idToken: backendToken
            )
        )
        
        return session
    }
}

// MARK: - Supabase Errors

enum SupabaseError: LocalizedError {
    case clientNotConfigured
    case signUpRequiresConfirmation
    case invalidSession
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured. Please check your credentials."
        case .signUpRequiresConfirmation:
            return "Please check your email to confirm your account."
        case .invalidSession:
            return "Your session has expired. Please sign in again."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - AuthSession Extension

extension AuthSession {
    /// Convert Supabase session to our User model
    func toUser() -> User {
        return User(
            id: user.id.uuidString,
            email: user.email ?? "",
            name: user.userMetadata["full_name"] as? String ?? 
                  user.userMetadata["name"] as? String ?? 
                  "User",
            profileImageURL: user.userMetadata["avatar_url"] as? String,
            createdAt: user.createdAt
        )
    }
}
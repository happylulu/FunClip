import Foundation
import Combine
import AuthenticationServices
import LocalAuthentication

/// AuthManager handles all authentication flows for FunClip iOS
/// Implements Epic 1: User Authentication & Onboarding
@MainActor
class AuthManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    private let supabaseClient: SupabaseClientProtocol
    private let keychainService: KeychainServiceProtocol
    private let appleSignInProvider: AppleSignInProviderProtocol
    private let biometricService: BiometricServiceProtocol
    
    // MARK: - Constants
    
    private enum KeychainKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let backendToken = "backend_token"
        static let biometricEnabled = "biometric_enabled"
        static let userID = "user_id"
    }
    
    // MARK: - Initialization
    
    init(
        supabaseClient: SupabaseClientProtocol,
        keychainService: KeychainServiceProtocol,
        appleSignInProvider: AppleSignInProviderProtocol,
        biometricService: BiometricServiceProtocol? = nil
    ) {
        self.supabaseClient = supabaseClient
        self.keychainService = keychainService
        self.appleSignInProvider = appleSignInProvider
        self.biometricService = biometricService ?? BiometricService()
    }
    
    // Convenience initializer for production
    convenience init() {
        self.init(
            supabaseClient: SupabaseClient(),
            keychainService: KeychainService(),
            appleSignInProvider: AppleSignInProvider()
        )
    }
    
    // MARK: - Sign in with Apple (P0 - 5 Story Points)
    
    /// Signs in the user with Apple ID
    /// This is required by App Store if we offer any third-party login
    func signInWithApple() async throws -> User {
        authState = .loading
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            // Step 1: Get Apple credentials
            let appleResult = try await appleSignInProvider.signIn()
            
            // Step 2: Exchange with Supabase
            let user = try await supabaseClient.signInWithApple(
                identityToken: appleResult.identityToken
            )
            
            // Step 3: Get tokens
            if let accessToken = supabaseClient.currentAccessToken {
                try keychainService.save(accessToken, for: KeychainKeys.accessToken)
            }
            
            // Step 4: Exchange for backend token
            if let backendToken = try? await exchangeForBackendToken() {
                try keychainService.save(backendToken, for: KeychainKeys.backendToken)
            }
            
            // Step 5: Update state
            self.currentUser = user
            self.isAuthenticated = true
            self.authState = .authenticated(user)
            
            // Step 6: Save user ID for biometric login
            try keychainService.save(user.id.uuidString, for: KeychainKeys.userID)
            
            return user
            
        } catch {
            authState = .unauthenticated
            throw mapToAuthError(error)
        }
    }
    
    // MARK: - Email/Password Sign In (P0 - 3 Story Points)
    
    /// Signs in the user with email and password
    func signInWithEmail(_ email: String, password: String) async throws -> User {
        authState = .loading
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            // Step 1: Sign in with Supabase
            let user = try await supabaseClient.signInWithEmail(email, password: password)
            
            // Step 2: Store tokens
            if let accessToken = supabaseClient.currentAccessToken {
                try keychainService.save(accessToken, for: KeychainKeys.accessToken)
            }
            
            // Step 3: Exchange for backend token
            if let backendToken = try? await exchangeForBackendToken() {
                try keychainService.save(backendToken, for: KeychainKeys.backendToken)
            }
            
            // Step 4: Update state
            self.currentUser = user
            self.isAuthenticated = true
            self.authState = .authenticated(user)
            
            // Step 5: Save user ID
            try keychainService.save(user.id.uuidString, for: KeychainKeys.userID)
            
            return user
            
        } catch {
            authState = .unauthenticated
            throw mapToAuthError(error)
        }
    }
    
    // MARK: - Biometric Authentication (P1 - 2 Story Points)
    
    /// Enable biometric authentication for the current user
    func enableBiometricAuth() async throws {
        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }
        
        // Verify biometrics are available
        guard biometricService.canUseBiometrics() else {
            throw AuthError.biometricsNotAvailable
        }
        
        // Authenticate to enable
        let reason = "Enable \(biometricService.biometricType.displayName) for quick access"
        let authenticated = try await biometricService.authenticate(reason: reason)
        
        if authenticated {
            try keychainService.save("true", for: KeychainKeys.biometricEnabled)
        } else {
            throw AuthError.biometricsFailed
        }
    }
    
    /// Sign in using biometrics (Face ID / Touch ID)
    func signInWithBiometrics() async throws -> User {
        // Check if biometrics are enabled
        guard let biometricEnabled = try? keychainService.retrieve(for: KeychainKeys.biometricEnabled),
              biometricEnabled == "true" else {
            throw AuthError.biometricsNotEnabled
        }
        
        authState = .loading
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        // Authenticate with biometrics
        let reason = "Sign in to FunClip"
        let authenticated = try await biometricService.authenticate(reason: reason)
        
        guard authenticated else {
            throw AuthError.biometricsFailed
        }
        
        // Retrieve stored token
        guard let token = try? keychainService.retrieve(for: KeychainKeys.accessToken) else {
            throw AuthError.tokenNotFound
        }
        
        // Validate token with Supabase
        let user = try await supabaseClient.validateToken(token)
        
        // Update state
        self.currentUser = user
        self.isAuthenticated = true
        self.authState = .authenticated(user)
        
        return user
    }
    
    // MARK: - Token Management
    
    /// Refresh the access token
    func refreshToken() async throws -> String {
        let newToken = try await supabaseClient.refreshToken()
        try keychainService.save(newToken, for: KeychainKeys.accessToken)
        
        // Also refresh backend token
        if let backendToken = try? await exchangeForBackendToken() {
            try keychainService.save(backendToken, for: KeychainKeys.backendToken)
        }
        
        return newToken
    }
    
    /// Get backend token for API calls
    func getBackendToken() async throws -> String {
        // Try to get cached backend token
        if let cachedToken = try? keychainService.retrieve(for: KeychainKeys.backendToken) {
            // TODO: Check if token is expired
            return cachedToken
        }
        
        // Exchange Supabase token for backend token
        return try await exchangeForBackendToken()
    }
    
    private func exchangeForBackendToken() async throws -> String {
        guard let supabaseToken = supabaseClient.currentAccessToken else {
            throw AuthError.tokenNotFound
        }
        
        let backendToken = try await supabaseClient.exchangeTokenForBackendJWT(supabaseToken)
        try keychainService.save(backendToken, for: KeychainKeys.backendToken)
        
        return backendToken
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async throws {
        // Clear Supabase session
        try await supabaseClient.signOut()
        
        // Clear keychain
        try keychainService.clear()
        
        // Reset state
        currentUser = nil
        isAuthenticated = false
        authState = .unauthenticated
    }
    
    // MARK: - Auto Login
    
    /// Check if user has valid session on app launch
    func checkAuthStatus() async throws {
        authState = .loading
        
        // Check for stored token
        guard let token = try? keychainService.retrieve(for: KeychainKeys.accessToken) else {
            authState = .unauthenticated
            return
        }
        
        do {
            // Validate token
            let user = try await supabaseClient.validateToken(token)
            
            // Update state
            self.currentUser = user
            self.isAuthenticated = true
            self.authState = .authenticated(user)
            
        } catch {
            // Token invalid, clear and set unauthenticated
            try? keychainService.clear()
            authState = .unauthenticated
        }
    }
    
    // MARK: - Error Handling
    
    private func mapToAuthError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        
        // Map other errors to AuthError
        return .unknownError
    }
}

// MARK: - Supporting Types

enum AuthState: Equatable {
    case unknown
    case loading
    case authenticated(User)
    case unauthenticated
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.loading, .loading),
             (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        default:
            return false
        }
    }
}

enum AuthError: LocalizedError {
    case appleSignInFailed
    case invalidCredentials
    case networkError
    case tokenExpired
    case tokenNotFound
    case biometricsFailed
    case biometricsNotAvailable
    case biometricsNotEnabled
    case notAuthenticated
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .appleSignInFailed:
            return "Sign in with Apple failed. Please try again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network error. Please check your connection."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .tokenNotFound:
            return "Authentication token not found."
        case .biometricsFailed:
            return "Biometric authentication failed."
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricsNotEnabled:
            return "Biometric authentication is not enabled."
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}
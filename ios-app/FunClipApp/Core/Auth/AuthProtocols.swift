import Foundation
import AuthenticationServices

// MARK: - Supabase Client Protocol

protocol SupabaseClientProtocol {
    func signInWithApple(identityToken: String) async throws -> User
    func signInWithEmail(_ email: String, password: String) async throws -> User
    func refreshToken() async throws -> String
    func validateToken(_ token: String) async throws -> User
    func exchangeTokenForBackendJWT(_ supabaseToken: String) async throws -> String
    func signOut() async throws
    var currentAccessToken: String? { get }
}

// MARK: - Keychain Service Protocol

protocol KeychainServiceProtocol {
    func save(_ value: String, for key: String) throws
    func retrieve(for key: String) throws -> String?
    func delete(for key: String) throws
    func clear() throws
}

// MARK: - Apple Sign In Provider Protocol

protocol AppleSignInProviderProtocol {
    func signIn() async throws -> AppleSignInResult
}

struct AppleSignInResult {
    let identityToken: String
    let authorizationCode: String
    let user: String
    let fullName: PersonNameComponents?
    let email: String?
}

// MARK: - Biometric Service Protocol

protocol BiometricServiceProtocol {
    func canUseBiometrics() -> Bool
    func authenticate(reason: String) async throws -> Bool
    var biometricType: BiometricType { get }
}

enum BiometricType {
    case none
    case touchID
    case faceID
    
    var displayName: String {
        switch self {
        case .none:
            return "Biometrics"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
}
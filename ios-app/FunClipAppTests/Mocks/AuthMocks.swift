import Foundation
import AuthenticationServices
@testable import FunClipApp

// MARK: - Mock Supabase Client

class MockSupabaseClient: SupabaseClientProtocol {
    var mockSignInWithAppleResult: Result<User, AuthError> = .success(User.mock())
    var mockSignInWithEmailResult: Result<User, AuthError> = .success(User.mock())
    var mockRefreshTokenResult: Result<String, AuthError> = .success("new_token")
    var mockValidateTokenResult: Result<User, AuthError> = .success(User.mock())
    var mockExchangeTokenResult: Result<String, AuthError> = .success("backend_token")
    var mockAccessToken: String? = "mock_access_token"
    
    var signInWithAppleWasCalled = false
    var signInWithEmailWasCalled = false
    var refreshTokenWasCalled = false
    var validateTokenWasCalled = false
    var exchangeTokenWasCalled = false
    var signOutWasCalled = false
    
    func signInWithApple(identityToken: String) async throws -> User {
        signInWithAppleWasCalled = true
        switch mockSignInWithAppleResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signInWithEmail(_ email: String, password: String) async throws -> User {
        signInWithEmailWasCalled = true
        switch mockSignInWithEmailResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func refreshToken() async throws -> String {
        refreshTokenWasCalled = true
        switch mockRefreshTokenResult {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        }
    }
    
    func validateToken(_ token: String) async throws -> User {
        validateTokenWasCalled = true
        switch mockValidateTokenResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func exchangeTokenForBackendJWT(_ supabaseToken: String) async throws -> String {
        exchangeTokenWasCalled = true
        switch mockExchangeTokenResult {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        }
    }
    
    func signOut() async throws {
        signOutWasCalled = true
    }
    
    var currentAccessToken: String? {
        return mockAccessToken
    }
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainServiceProtocol {
    var savedTokens: [String: String] = [:]
    var saveWasCalled = false
    var retrieveWasCalled = false
    var deleteWasCalled = false
    var clearWasCalled = false
    
    func save(_ value: String, for key: String) throws {
        saveWasCalled = true
        savedTokens[key] = value
    }
    
    func retrieve(for key: String) throws -> String? {
        retrieveWasCalled = true
        return savedTokens[key]
    }
    
    func delete(for key: String) throws {
        deleteWasCalled = true
        savedTokens.removeValue(forKey: key)
    }
    
    func clear() throws {
        clearWasCalled = true
        savedTokens.removeAll()
    }
}

// MARK: - Mock Apple Sign In Provider

class MockAppleSignInProvider: AppleSignInProviderProtocol {
    var mockIdentityToken: String?
    var mockAuthorizationCode: String?
    var mockUser: String = "mock_apple_user_id"
    var mockFullName: PersonNameComponents?
    var mockEmail: String?
    
    var shouldFail = false
    var signInWasCalled = false
    
    func signIn() async throws -> AppleSignInResult {
        signInWasCalled = true
        
        if shouldFail {
            throw AuthError.appleSignInFailed
        }
        
        guard let identityToken = mockIdentityToken else {
            throw AuthError.appleSignInFailed
        }
        
        return AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: mockAuthorizationCode ?? "mock_auth_code",
            user: mockUser,
            fullName: mockFullName,
            email: mockEmail
        )
    }
}

// MARK: - Mock Biometric Service

class MockBiometricService: BiometricServiceProtocol {
    var canUseBiometricsResult = true
    var authenticateResult: Result<Bool, Error> = .success(true)
    var biometricTypeResult: BiometricType = .faceID
    
    var authenticateWasCalled = false
    
    func canUseBiometrics() -> Bool {
        return canUseBiometricsResult
    }
    
    func authenticate(reason: String) async throws -> Bool {
        authenticateWasCalled = true
        switch authenticateResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
    
    var biometricType: BiometricType {
        return biometricTypeResult
    }
}

// MARK: - Test Data Structures

struct AppleSignInResult {
    let identityToken: String
    let authorizationCode: String
    let user: String
    let fullName: PersonNameComponents?
    let email: String?
}

enum BiometricType {
    case none
    case touchID
    case faceID
}

// MARK: - Auth Error for Testing

enum AuthError: Error, Equatable {
    case appleSignInFailed
    case invalidCredentials
    case networkError
    case tokenExpired
    case biometricsFailed
    case unknownError
}
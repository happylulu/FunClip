import XCTest
@testable import FunClipApp

/// Test Suite for Epic 1, Story 1: "As a new user, I want to sign up with Apple ID so I can quickly create an account"
/// Priority: P0 | Story Points: 5
class AuthManagerTests: XCTestCase {
    
    var sut: AuthManager! // System Under Test
    var mockSupabaseClient: MockSupabaseClient!
    var mockKeychainService: MockKeychainService!
    var mockAppleSignInProvider: MockAppleSignInProvider!
    
    override func setUp() {
        super.setUp()
        mockSupabaseClient = MockSupabaseClient()
        mockKeychainService = MockKeychainService()
        mockAppleSignInProvider = MockAppleSignInProvider()
        
        sut = AuthManager(
            supabaseClient: mockSupabaseClient,
            keychainService: mockKeychainService,
            appleSignInProvider: mockAppleSignInProvider
        )
    }
    
    override func tearDown() {
        sut = nil
        mockSupabaseClient = nil
        mockKeychainService = nil
        mockAppleSignInProvider = nil
        super.tearDown()
    }
    
    // MARK: - Sign in with Apple Tests
    
    func test_signInWithApple_whenSuccessful_shouldUpdateAuthState() async throws {
        // Given
        let expectedUser = User.mock()
        mockAppleSignInProvider.mockIdentityToken = "mock_apple_identity_token"
        mockSupabaseClient.mockSignInWithAppleResult = .success(expectedUser)
        
        // When
        let user = try await sut.signInWithApple()
        
        // Then
        XCTAssertEqual(sut.currentUser?.id, expectedUser.id)
        XCTAssertEqual(sut.authState, .authenticated(expectedUser))
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func test_signInWithApple_whenSuccessful_shouldStoreTokenInKeychain() async throws {
        // Given
        let expectedToken = "mock_jwt_token"
        mockAppleSignInProvider.mockIdentityToken = "mock_apple_identity_token"
        mockSupabaseClient.mockAccessToken = expectedToken
        mockSupabaseClient.mockSignInWithAppleResult = .success(User.mock())
        
        // When
        _ = try await sut.signInWithApple()
        
        // Then
        XCTAssertEqual(mockKeychainService.savedTokens["access_token"], expectedToken)
        XCTAssertTrue(mockKeychainService.saveWasCalled)
    }
    
    func test_signInWithApple_whenAppleSignInFails_shouldThrowError() async {
        // Given
        mockAppleSignInProvider.shouldFail = true
        
        // When/Then
        do {
            _ = try await sut.signInWithApple()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.appleSignInFailed)
            XCTAssertEqual(sut.authState, .unauthenticated)
        }
    }
    
    func test_signInWithApple_whenSupabaseFails_shouldThrowError() async {
        // Given
        mockAppleSignInProvider.mockIdentityToken = "mock_token"
        mockSupabaseClient.mockSignInWithAppleResult = .failure(AuthError.networkError)
        
        // When/Then
        do {
            _ = try await sut.signInWithApple()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.networkError)
            XCTAssertEqual(sut.authState, .unauthenticated)
        }
    }
    
    // MARK: - Email/Password Tests
    
    func test_signInWithEmail_whenValidCredentials_shouldAuthenticate() async throws {
        // Given
        let email = "test@example.com"
        let password = "SecurePassword123!"
        let expectedUser = User.mock(email: email)
        mockSupabaseClient.mockSignInWithEmailResult = .success(expectedUser)
        
        // When
        let user = try await sut.signInWithEmail(email, password: password)
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(sut.authState, .authenticated(expectedUser))
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func test_signInWithEmail_whenInvalidCredentials_shouldThrowError() async {
        // Given
        mockSupabaseClient.mockSignInWithEmailResult = .failure(AuthError.invalidCredentials)
        
        // When/Then
        do {
            _ = try await sut.signInWithEmail("wrong@email.com", password: "wrong")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.invalidCredentials)
            XCTAssertFalse(sut.isAuthenticated)
        }
    }
    
    // MARK: - Token Management Tests
    
    func test_refreshToken_whenTokenExpired_shouldGetNewToken() async throws {
        // Given
        let oldToken = "old_token"
        let newToken = "new_token"
        mockKeychainService.savedTokens["access_token"] = oldToken
        mockSupabaseClient.mockRefreshTokenResult = .success(newToken)
        
        // When
        let refreshedToken = try await sut.refreshToken()
        
        // Then
        XCTAssertEqual(refreshedToken, newToken)
        XCTAssertEqual(mockKeychainService.savedTokens["access_token"], newToken)
    }
    
    func test_getBackendToken_shouldExchangeSupabaseTokenForBackendJWT() async throws {
        // Given
        let supabaseToken = "supabase_token"
        let backendToken = "backend_jwt_token"
        mockSupabaseClient.mockAccessToken = supabaseToken
        mockSupabaseClient.mockExchangeTokenResult = .success(backendToken)
        
        // When
        let token = try await sut.getBackendToken()
        
        // Then
        XCTAssertEqual(token, backendToken)
        XCTAssertTrue(mockSupabaseClient.exchangeTokenWasCalled)
    }
    
    // MARK: - Biometric Authentication Tests
    
    func test_enableBiometricAuth_whenUserAuthenticated_shouldSaveToKeychain() async throws {
        // Given
        sut.currentUser = User.mock()
        sut.authState = .authenticated(User.mock())
        
        // When
        try await sut.enableBiometricAuth()
        
        // Then
        XCTAssertTrue(mockKeychainService.savedTokens["biometric_enabled"] == "true")
    }
    
    func test_signInWithBiometrics_whenEnabled_shouldAuthenticate() async throws {
        // Given
        let savedToken = "saved_token"
        mockKeychainService.savedTokens["access_token"] = savedToken
        mockKeychainService.savedTokens["biometric_enabled"] = "true"
        mockSupabaseClient.mockValidateTokenResult = .success(User.mock())
        
        // When
        let user = try await sut.signInWithBiometrics()
        
        // Then
        XCTAssertNotNil(user)
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_shouldClearAllAuthData() async throws {
        // Given
        sut.currentUser = User.mock()
        sut.authState = .authenticated(User.mock())
        mockKeychainService.savedTokens["access_token"] = "token"
        
        // When
        try await sut.signOut()
        
        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertEqual(sut.authState, .unauthenticated)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertTrue(mockKeychainService.clearWasCalled)
    }
    
    // MARK: - Auto Login Tests
    
    func test_checkAuthStatus_whenValidTokenExists_shouldAutoLogin() async throws {
        // Given
        let savedToken = "valid_token"
        mockKeychainService.savedTokens["access_token"] = savedToken
        mockSupabaseClient.mockValidateTokenResult = .success(User.mock())
        
        // When
        try await sut.checkAuthStatus()
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
    }
    
    func test_checkAuthStatus_whenNoTokenExists_shouldRemainUnauthenticated() async throws {
        // Given
        mockKeychainService.savedTokens = [:]
        
        // When
        try await sut.checkAuthStatus()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertEqual(sut.authState, .unauthenticated)
    }
}

// MARK: - Test Helpers

extension User {
    static func mock(
        id: UUID = UUID(),
        email: String = "test@example.com",
        fullName: String? = "Test User"
    ) -> User {
        User(
            id: id,
            email: email,
            fullName: fullName,
            avatarURL: nil,
            createdAt: Date()
        )
    }
}
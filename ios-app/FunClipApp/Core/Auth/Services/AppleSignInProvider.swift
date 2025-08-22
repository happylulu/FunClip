import Foundation
import AuthenticationServices
import CryptoKit

/// Provider for Sign in with Apple functionality
@MainActor
final class AppleSignInProvider: NSObject, AppleSignInProviderProtocol {
    
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    
    func signIn() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInProvider: ASAuthorizationControllerDelegate {
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.invalidCredential)
            continuation = nil
            return
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleSignInError.missingIdentityToken)
            continuation = nil
            return
        }
        
        guard let authorizationCodeData = appleIDCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleSignInError.missingAuthorizationCode)
            continuation = nil
            return
        }
        
        let result = AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            user: appleIDCredential.user,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )
        
        continuation?.resume(returning: result)
        continuation = nil
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation?.resume(throwing: AppleSignInError.userCancelled)
            case .failed:
                continuation?.resume(throwing: AppleSignInError.failed)
            case .invalidResponse:
                continuation?.resume(throwing: AppleSignInError.invalidResponse)
            case .notHandled:
                continuation?.resume(throwing: AppleSignInError.notHandled)
            case .unknown:
                continuation?.resume(throwing: AppleSignInError.unknown)
            case .notInteractive:
                continuation?.resume(throwing: AppleSignInError.notInteractive)
            @unknown default:
                continuation?.resume(throwing: AppleSignInError.unknown)
            }
        } else {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInProvider: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the current window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found for Apple Sign In presentation")
        }
        return window
    }
}

// MARK: - Apple Sign In Errors

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingIdentityToken
    case missingAuthorizationCode
    case userCancelled
    case failed
    case invalidResponse
    case notHandled
    case notInteractive
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .missingIdentityToken:
            return "Identity token is missing"
        case .missingAuthorizationCode:
            return "Authorization code is missing"
        case .userCancelled:
            return "Sign in with Apple was cancelled"
        case .failed:
            return "Sign in with Apple failed"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Authorization request not handled"
        case .notInteractive:
            return "Non-interactive authorization attempted"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
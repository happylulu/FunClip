import Foundation
import LocalAuthentication

/// Service for handling biometric authentication (Face ID / Touch ID)
final class BiometricService: BiometricServiceProtocol {
    
    private let context = LAContext()
    
    func canUseBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticate(reason: String) async throws -> Bool {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw BiometricError.notAvailable(error.localizedDescription)
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw mapLAError(error)
        } catch {
            throw BiometricError.unknown(error.localizedDescription)
        }
    }
    
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            // Treat Optic ID as Face ID for now
            return .faceID
        @unknown default:
            return .none
        }
    }
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable("Biometry is not available")
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError {
    case notAvailable(String)
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case userFallback
    case lockout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return "Biometric authentication not available: \(reason)"
        case .notEnrolled:
            return "No biometric authentication method is enrolled"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use password instead"
        case .lockout:
            return "Biometric authentication is locked due to too many failed attempts"
        case .unknown(let reason):
            return "Unknown error: \(reason)"
        }
    }
}
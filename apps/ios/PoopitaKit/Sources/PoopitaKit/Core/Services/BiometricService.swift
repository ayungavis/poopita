import Foundation
import LocalAuthentication

@MainActor
protocol BiometricService: Sendable {
    func isAvailable() -> Bool
    func method() -> AppLockMethod
    func authenticate(reason: String) async -> Bool
}

@MainActor
final class LocalAuthenticationBiometricService: BiometricService {
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func method() -> AppLockMethod {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .passcode }
        return switch context.biometryType {
        case .faceID: .faceID
        case .touchID: .touchID
        case .opticID: .opticID
        default: .passcode
        }
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

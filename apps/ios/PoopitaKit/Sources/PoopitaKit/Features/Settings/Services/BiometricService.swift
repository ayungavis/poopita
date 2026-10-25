import Foundation
import LocalAuthentication

@MainActor
protocol BiometricService: Sendable {
    func isAvailable() -> Bool
    func authenticate(reason: String) async -> Bool
}

@MainActor
final class LocalAuthenticationBiometricService: BiometricService {
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
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

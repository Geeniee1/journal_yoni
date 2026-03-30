import Foundation
import LocalAuthentication

struct BiometricAuthService {
    private let context = LAContext()

    var canEvaluate: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        var error: NSError?
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                if let authError {
                    continuation.resume(throwing: authError)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}

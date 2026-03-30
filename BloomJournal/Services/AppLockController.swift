import SwiftUI
import Combine

@MainActor
final class AppLockController: ObservableObject {
    @Published var isLocked = true
    @Published var shouldShowPrivacyShield = false
    @Published var biometricsAvailable = false
    @Published var errorMessage: String?

    private let biometricService = BiometricAuthService()
    private var hasConfigured = false
    private var isAppLockEnabled = false

    func configure() {
        guard !hasConfigured else { return }
        hasConfigured = true
        shouldShowPrivacyShield = true
    }

    func refreshBiometricAvailability() async {
        biometricsAvailable = biometricService.canEvaluate
    }

    func setAppLockEnabled(_ enabled: Bool) {
        isAppLockEnabled = enabled
        if !enabled {
            isLocked = false
            shouldShowPrivacyShield = false
            errorMessage = nil
        } else {
            isLocked = true
            shouldShowPrivacyShield = true
        }
    }

    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            shouldShowPrivacyShield = false
        case .inactive, .background:
            if isAppLockEnabled {
                isLocked = true
                shouldShowPrivacyShield = true
            }
        @unknown default:
            break
        }
    }

    func unlockIfNeeded() async {
        guard isAppLockEnabled else {
            isLocked = false
            shouldShowPrivacyShield = false
            errorMessage = nil
            return
        }

        if !biometricService.canEvaluate {
            isLocked = false
            shouldShowPrivacyShield = false
            errorMessage = nil
            return
        }

        do {
            let success = try await biometricService.authenticate(
                reason: "Unlock Yoni Journal to view your journal."
            )
            if success {
                isLocked = false
                shouldShowPrivacyShield = false
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

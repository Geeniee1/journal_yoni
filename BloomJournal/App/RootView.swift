import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var lockController: AppLockController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    private var appSettings: AppSettings? {
        settings.first
    }

    var body: some View {
        ZStack {
            AppBackground()

            MainTabView()
                .blur(radius: lockController.shouldShowPrivacyShield ? 12 : 0)
                .overlay {
                    if lockController.shouldShowPrivacyShield {
                        AppPrivacyShield()
                    }
                }

            if lockController.isLocked {
                LockedView(
                    isBiometricEnabled: appSettings?.isBiometricLockEnabled ?? false,
                    errorMessage: lockController.errorMessage,
                    unlockAction: lockController.unlockIfNeeded
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .preferredColorScheme(appSettings?.themePreference.colorScheme)
        .animation(.smooth(duration: 0.3), value: lockController.isLocked)
        .animation(.smooth(duration: 0.2), value: lockController.shouldShowPrivacyShield)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
            await lockController.refreshBiometricAvailability()
            lockController.setAppLockEnabled(appSettings?.isBiometricLockEnabled ?? false)
            await lockController.unlockIfNeeded()
        }
        .onChange(of: appSettings?.isBiometricLockEnabled ?? false) { _, isEnabled in
            lockController.setAppLockEnabled(isEnabled)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewContainer.makeShared())
        .environmentObject(AppLockController())
}

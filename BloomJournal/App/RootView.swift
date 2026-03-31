import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var lockController: AppLockController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var settings: [AppSettings]

    private var appSettings: AppSettings? {
        settings.first
    }

    private var shouldShowWelcome: Bool {
        guard let appSettings else { return false }
        return !appSettings.hasSeenWelcome && !lockController.isLocked
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

            if shouldShowWelcome, let appSettings {
                WelcomeView(
                    buyMeACoffeeURL: appSettings.buyMeACoffeeURL,
                    sourceCodeURL: appSettings.sourceCodeURL,
                    onStart: markWelcomeSeen,
                    onOpenBuyMeACoffee: {
                        openOptionalURL(appSettings.buyMeACoffeeURL)
                    },
                    onOpenSourceCode: {
                        openOptionalURL(appSettings.sourceCodeURL)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .preferredColorScheme(appSettings?.themePreference.colorScheme)
        .animation(.smooth(duration: 0.3), value: lockController.isLocked)
        .animation(.smooth(duration: 0.2), value: lockController.shouldShowPrivacyShield)
        .animation(.smooth(duration: 0.25), value: shouldShowWelcome)
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

    private func markWelcomeSeen() {
        let target = appSettings ?? {
            let created = AppSettings()
            modelContext.insert(created)
            return created
        }()

        target.hasSeenWelcome = true
        try? modelContext.save()
    }

    private func openOptionalURL(_ value: String) {
        guard let url = URL(string: value), !value.isEmpty else { return }
        openURL(url)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewContainer.makeShared())
        .environmentObject(AppLockController())
}

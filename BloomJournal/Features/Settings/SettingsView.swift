import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var lockController: AppLockController

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query private var settings: [AppSettings]

    @State private var exportPayload: ExportPayload?
    @State private var exportError: String?

    private let exportService = ExportService()

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    var body: some View {
        ScreenContainer(
            title: "Settings",
            subtitle: "Private by default, local-only, and yours to shape."
        ) {
            privacyCard
            appearanceCard
            exportCard
            aboutCard
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
            lockController.setAppLockEnabled(appSettings.isBiometricLockEnabled)
        }
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Privacy")
                .font(AppTheme.Typography.sectionTitle)

            Toggle(
                "App lock on open",
                isOn: Binding(
                    get: { appSettings.isBiometricLockEnabled },
                    set: { newValue in
                        saveSettings {
                            $0.isBiometricLockEnabled = newValue
                        }
                        lockController.setAppLockEnabled(newValue)
                    }
                )
            )

            Text("Uses Face ID or Touch ID when available.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .glassCard()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Appearance")
                .font(AppTheme.Typography.sectionTitle)

            Picker(
                "Theme",
                selection: Binding(
                    get: { appSettings.themePreference },
                    set: { value in
                        saveSettings {
                            $0.themePreference = value
                        }
                    }
                )
            ) {
                ForEach(ThemePreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            }
            .pickerStyle(.segmented)
        }
        .glassCard()
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Export")
                .font(AppTheme.Typography.sectionTitle)

            Button("Prepare JSON + CSV Export") {
                do {
                    exportPayload = try exportService.makeExport(entries: entries)
                    exportError = nil
                } catch {
                    exportError = error.localizedDescription
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            if let exportPayload {
                ShareLink("Share JSON Export", item: exportPayload.jsonURL)
                ShareLink("Share CSV Export", item: exportPayload.csvURL)
            }

            if let exportError {
                Text(exportError)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
            }
        }
        .glassCard()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("About")
                .font(AppTheme.Typography.sectionTitle)

            Button("☕ Buy Me a Coffee") {
                guard let url = URL(string: appSettings.buyMeACoffeeURL), !appSettings.buyMeACoffeeURL.isEmpty else { return }
                openURL(url)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.accent)

            Text("Version 0.1.0")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .glassCard()
    }

    private func saveSettings(_ mutate: (AppSettings) -> Void) {
        let target = settings.first ?? {
            let created = AppSettings()
            modelContext.insert(created)
            return created
        }()

        mutate(target)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewContainer.makeShared())
    .environmentObject(AppLockController())
}

import SwiftData

enum SeedDataService {
    @MainActor
    static func ensureSingletonsIfNeeded(modelContext: ModelContext?) async {
        guard let modelContext else { return }

        let profileDescriptor = FetchDescriptor<UserProfile>()
        let settingsDescriptor = FetchDescriptor<AppSettings>()

        let hasProfile = (try? modelContext.fetchCount(profileDescriptor)) ?? 0 > 0
        let hasSettings = (try? modelContext.fetchCount(settingsDescriptor)) ?? 0 > 0

        if !hasProfile {
            modelContext.insert(UserProfile())
        }
        if !hasSettings {
            modelContext.insert(AppSettings())
        }
        try? modelContext.save()
    }
}

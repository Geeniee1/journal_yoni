import Foundation
import SwiftData

enum AppContainer {
    static let shared = AppContainerFactory()
}

struct AppContainerFactory {
    let sharedModelContainer: ModelContainer

    init(inMemoryOnly: Bool = false) {
        let schema = Schema([
            JournalEntry.self,
            EntryPhoto.self,
            UserProfile.self,
            AppSettings.self,
            AchievementUnlock.self
        ])

        let modelConfiguration = ModelConfiguration(
            "YoniJournal",
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly
        )

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

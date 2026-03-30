import SwiftData
import Foundation

enum PreviewContainer {
    @MainActor
    static func makeShared() -> ModelContainer {
        let container = AppContainerFactory(inMemoryOnly: true).sharedModelContainer
        let context = container.mainContext

        let existingEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        guard existingEntries.isEmpty else { return container }

        let profile = UserProfile(displayName: "Mika", bio: "Curious, warm, and open to real chemistry.", intention: "I’m looking for playful honesty and mutual care.")
        let settings = AppSettings(isBiometricLockEnabled: false, themePreference: .light)
        let entries = SampleEntries.make()

        context.insert(profile)
        context.insert(settings)
        entries.forEach { context.insert($0) }
        try? context.save()
        return container
    }
}

enum SampleEntries {
    static func make() -> [JournalEntry] {
        [
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
                personNameOrAlias: "Ari",
                connectionType: .ongoing,
                mood: .tender,
                rating: 5,
                notes: "Soft morning after energy. We talked about boundaries and what ease feels like.",
                tags: ["emotional", "fun"]
            ),
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -9, to: .now) ?? .now,
                personNameOrAlias: "N",
                connectionType: .date,
                mood: .dreamy,
                rating: 4,
                notes: "Great chemistry, slow flirt, and a really grounding check-in afterward.",
                tags: ["first time", "fun"]
            ),
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -17, to: .now) ?? .now,
                personNameOrAlias: "June",
                connectionType: .hookup,
                mood: .playful,
                rating: 4,
                notes: "Easy, funny, and uncomplicated. A nice reminder that light can still feel meaningful.",
                tags: ["fun", "casual"]
            )
        ]
    }
}

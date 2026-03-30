import Testing
import SwiftData
@testable import BloomJournal

struct BloomJournalTests {
    @Test
    @MainActor
    func journalEntryPersistsKeyFields() throws {
        let container = AppContainerFactory(inMemoryOnly: true).sharedModelContainer
        let context = container.mainContext

        let entry = JournalEntry(
            personNameOrAlias: "Ari",
            connectionType: .ongoing,
            mood: .tender,
            rating: 5,
            notes: "A soft, grounded night.",
            tags: ["fun", "emotional"]
        )

        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.personNameOrAlias == "Ari")
        #expect(fetched.first?.tags == ["fun", "emotional"])
        #expect(fetched.first?.rating == 5)
    }

    @Test
    @MainActor
    func achievementEngineUnlocksExpectedMilestones() {
        let entries = [
            JournalEntry(personNameOrAlias: "A", connectionType: .ongoing, mood: .tender, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "B", connectionType: .ongoing, mood: .playful, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "C", connectionType: .ongoing, mood: .dreamy, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "D", connectionType: .date, mood: .electric, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "E", connectionType: .hookup, mood: .grounded, notes: "", tags: ["fun"])
        ]

        let unlocked = AchievementEngine().unlockedIDs(entries: entries)

        #expect(unlocked.contains("first-entry"))
        #expect(unlocked.contains("fun-five"))
        #expect(unlocked.contains("ongoing-story"))
    }
}

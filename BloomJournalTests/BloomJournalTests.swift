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
            rating: 8,
            notes: "A soft, grounded night.",
            tags: ["fun", "emotional"],
            wouldMeetAgain: true,
            goodKisser: true,
            greenFlags: ["communicative"],
            redFlags: ["late"]
        )

        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.personNameOrAlias == "Ari")
        #expect(fetched.first?.tags == ["fun", "emotional"])
        #expect(fetched.first?.rating == 8)
        #expect(fetched.first?.wouldMeetAgain == true)
        #expect(fetched.first?.greenFlags == ["communicative"])
    }

    @Test
    @MainActor
    func achievementEngineUnlocksExpectedMilestones() {
        let entries = [
            JournalEntry(personNameOrAlias: "A", connectionType: .ongoing, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "B", connectionType: .ongoing, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "C", connectionType: .ongoing, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "D", connectionType: .date, notes: "", tags: ["fun"]),
            JournalEntry(personNameOrAlias: "E", connectionType: .hookup, notes: "", tags: ["fun"])
        ]

        let unlocked = AchievementEngine().unlockedIDs(entries: entries)

        #expect(unlocked.contains("first-entry"))
        #expect(unlocked.contains("fun-five"))
        #expect(unlocked.contains("ongoing-story"))
    }
}

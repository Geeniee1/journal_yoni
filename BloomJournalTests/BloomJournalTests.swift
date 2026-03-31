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
            redFlags: ["late"],
            positionIDs: ["position-1", "position-3"]
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
        #expect(fetched.first?.positionIDs == ["position-1", "position-3"])
    }

    @Test
    func placeholderCatalogsExposeExpectedCounts() {
        #expect(PositionCatalog.all.count == 70)
        #expect(AchievementCatalog.all.count == 100)
        #expect(AchievementCatalog.positionAchievementIDs.contains("achievement-1"))
        #expect(!AchievementCatalog.positionAchievementIDs.contains("achievement-100"))
    }
}

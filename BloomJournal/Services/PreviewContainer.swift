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
        let unlocks = [
            AchievementUnlock(achievementID: "achievement-1"),
            AchievementUnlock(achievementID: "achievement-2"),
            AchievementUnlock(achievementID: "achievement-8")
        ]

        context.insert(profile)
        context.insert(settings)
        entries.forEach { context.insert($0) }
        unlocks.forEach { context.insert($0) }
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
                connectionType: .sexyTime,
                rating: 8,
                notes: "Soft morning after energy. We talked about boundaries and what ease feels like.",
                tags: ["emotional", "fun"],
                wouldMeetAgain: true,
                goodKisser: true,
                madeMeCum: true,
                greenFlags: ["communicative", "gentle"],
                redFlags: ["late reply"],
                positionIDs: ["position-1", "position-2"]
            ),
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
                personNameOrAlias: "Ari",
                connectionType: .date,
                rating: 7,
                notes: "More playful this time. We lingered longer and the aftercare felt easier.",
                tags: ["chemistry", "soft"],
                wouldMeetAgain: true,
                goodKisser: true,
                greenFlags: ["warm", "attentive"],
                positionIDs: ["position-3"]
            ),
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -9, to: .now) ?? .now,
                personNameOrAlias: "N",
                connectionType: .date,
                rating: 7,
                notes: "Great chemistry, slow flirt, and a really grounding check-in afterward.",
                tags: ["first time", "fun"],
                wouldMeetAgain: true,
                goodKisser: true,
                greenFlags: ["present", "asks questions"],
                positionIDs: ["position-8"]
            ),
            JournalEntry(
                entryDate: Calendar.current.date(byAdding: .day, value: -17, to: .now) ?? .now,
                personNameOrAlias: "June",
                connectionType: .hookup,
                rating: 6,
                notes: "Easy, funny, and uncomplicated. A nice reminder that light can still feel meaningful.",
                tags: ["fun", "casual"],
                goodHead: true,
                longDuration: true,
                greenFlags: ["funny"],
                redFlags: ["inconsistent"],
                positionIDs: ["position-6", "position-7"]
            )
        ]
    }
}

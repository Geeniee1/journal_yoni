import Foundation

struct AchievementEngine {
    func unlockedIDs(entries: [JournalEntry]) -> Set<String> {
        Set(AchievementCatalog.all.compactMap { definition in
            isUnlocked(definition, entries: entries) ? definition.id : nil
        })
    }

    func isUnlocked(_ definition: AchievementDefinition, entries: [JournalEntry]) -> Bool {
        switch definition.rule {
        case .manualUnlock:
            return false
        }
    }
}

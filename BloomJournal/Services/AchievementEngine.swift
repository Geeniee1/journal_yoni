import Foundation

struct AchievementEngine {
    func unlockedIDs(entries: [JournalEntry]) -> Set<String> {
        Set(AchievementCatalog.all.compactMap { definition in
            isUnlocked(definition, entries: entries) ? definition.id : nil
        })
    }

    func isUnlocked(_ definition: AchievementDefinition, entries: [JournalEntry]) -> Bool {
        switch definition.rule {
        case .totalEntries(let count):
            return entries.count >= count
        case .tagCount(let tag, let count):
            let total = entries.flatMap(\.tags).filter { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }.count
            return total >= count
        case .connectionType(let type, let count):
            return entries.filter { $0.connectionType == type }.count >= count
        }
    }
}

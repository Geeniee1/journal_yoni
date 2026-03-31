import Foundation

struct AchievementDefinition: Identifiable, Hashable {
    enum Rule: Hashable {
        case manualUnlock
    }

    let id: String
    let title: String
    let subtitle: String
    let illustrationAssetName: String?
    let symbolName: String
    let rule: Rule
}

struct PositionDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let achievementID: String
    let symbolName: String
}

enum PositionCatalog {
    private static let symbols = [
        "heart.circle.fill",
        "sparkles",
        "moon.stars.fill",
        "flame.fill",
        "bolt.heart.fill",
        "sun.max.fill",
        "drop.fill",
        "waveform.path.ecg",
        "leaf.fill",
        "star.circle.fill"
    ]

    static let all: [PositionDefinition] = (1...70).map { index in
        PositionDefinition(
            id: "position-\(index)",
            name: "Position \(index)",
            achievementID: "achievement-\(index)",
            symbolName: symbols[(index - 1) % symbols.count]
        )
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = (1...100).map { index in
        let isPositionAchievement = index <= PositionCatalog.all.count
        return AchievementDefinition(
            id: "achievement-\(index)",
            title: "Achievement \(index)",
            subtitle: isPositionAchievement
                ? "Unlocks when Position \(index) is saved in any entry."
                : "Placeholder achievement waiting for future logic.",
            illustrationAssetName: nil,
            symbolName: isPositionAchievement ? PositionCatalog.all[index - 1].symbolName : "seal.fill",
            rule: .manualUnlock
        )
    }

    static let positionAchievementIDs: Set<String> = Set(PositionCatalog.all.map(\.achievementID))
}

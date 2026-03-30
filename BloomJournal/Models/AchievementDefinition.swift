import Foundation

struct AchievementDefinition: Identifiable, Hashable {
    enum Rule: Hashable {
        case totalEntries(Int)
        case tagCount(String, Int)
        case connectionType(ConnectionType, Int)
    }

    let id: String
    let title: String
    let subtitle: String
    let illustrationAssetName: String?
    let symbolName: String
    let rule: Rule
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        .init(
            id: "first-entry",
            title: "First Entry",
            subtitle: "Capture your first connection.",
            illustrationAssetName: "achievement-first-entry",
            symbolName: "sparkles",
            rule: .totalEntries(1)
        ),
        .init(
            id: "ten-connections",
            title: "10 Connections",
            subtitle: "Log ten moments that mattered.",
            illustrationAssetName: "achievement-ten-connections",
            symbolName: "heart.circle.fill",
            rule: .totalEntries(10)
        ),
        .init(
            id: "fun-five",
            title: "Fun x5",
            subtitle: "Use the tag “fun” five times.",
            illustrationAssetName: "achievement-fun-five",
            symbolName: "party.popper.fill",
            rule: .tagCount("fun", 5)
        ),
        .init(
            id: "ongoing-story",
            title: "Ongoing Story",
            subtitle: "Track three ongoing connections.",
            illustrationAssetName: "achievement-ongoing-story",
            symbolName: "infinity.circle.fill",
            rule: .connectionType(.ongoing, 3)
        )
    ]
}

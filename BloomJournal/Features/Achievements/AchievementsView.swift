import SwiftUI
import SwiftData
import UIKit

struct AchievementsView: View {
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \AchievementUnlock.unlockedAt, order: .reverse) private var unlocks: [AchievementUnlock]

    private let engine = AchievementEngine()

    private var unlockedIDs: Set<String> {
        let persisted = Set(unlocks.map(\.achievementID))
        return persisted.union(engine.unlockedIDs(entries: entries))
    }

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
        GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
        GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
    ]

    var body: some View {
        ScreenContainer(
            title: "Achievements",
            subtitle: "\(unlockedIDs.count) of \(AchievementCatalog.all.count) unlocked so far."
        ) {
            if AchievementCatalog.all.isEmpty {
                EmptyStateCard(
                    title: "No achievements yet",
                    message: "Your achievement catalog can grow with custom illustrations later.",
                    systemImage: "sparkles"
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.medium) {
                    ForEach(AchievementCatalog.all) { achievement in
                        AchievementTile(
                            achievement: achievement,
                            isUnlocked: unlockedIDs.contains(achievement.id)
                        )
                    }
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AchievementTile: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(isUnlocked ? AppTheme.Colors.accentSoft.opacity(0.86) : Color.white.opacity(0.08))
                    .frame(height: 104)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .stroke(isUnlocked ? AppTheme.Colors.accent.opacity(0.55) : Color.white.opacity(0.18), lineWidth: 1)
                    }

                if let illustrationAssetName = achievement.illustrationAssetName,
                   UIImage(named: illustrationAssetName) != nil {
                    Image(illustrationAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    Image(systemName: achievement.symbolName)
                        .font(.system(size: 28))
                        .foregroundStyle(isUnlocked ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText.opacity(0.7))
                        .saturation(isUnlocked ? 1 : 0)
                }
            }

            Text(achievement.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .lineLimit(1)

            Text(achievement.subtitle)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .saturation(isUnlocked ? 1 : 0)
        .opacity(isUnlocked ? 1 : 0.62)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

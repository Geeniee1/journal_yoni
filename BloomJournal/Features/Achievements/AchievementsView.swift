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
        GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
    ]

    var body: some View {
        ScreenContainer(
            title: "Achievements",
            subtitle: "Small celebrations for the moments, honesty, and patterns you choose to keep."
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
                    .fill(isUnlocked ? AppTheme.Colors.accentSoft.opacity(0.8) : Color.white.opacity(0.22))
                    .frame(height: 120)

                if let illustrationAssetName = achievement.illustrationAssetName,
                   UIImage(named: illustrationAssetName) != nil {
                    Image(illustrationAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    Image(systemName: isUnlocked ? achievement.symbolName : "lock.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(isUnlocked ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                }
            }

            Text(achievement.title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(achievement.subtitle)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .opacity(isUnlocked ? 1 : 0.78)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

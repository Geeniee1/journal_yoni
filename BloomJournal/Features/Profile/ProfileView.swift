import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first
    }

    private var mostUsedTag: String {
        let frequencies = Dictionary(entries.flatMap(\.tags).map { ($0, 1) }, uniquingKeysWith: +)
        return frequencies.max(by: { $0.value < $1.value })?.key.capitalized ?? "None yet"
    }

    private var streakValue: Int {
        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.entryDate) })
        var streak = 0
        var current = Calendar.current.startOfDay(for: .now)

        while days.contains(current) {
            streak += 1
            current = Calendar.current.date(byAdding: .day, value: -1, to: current) ?? current
        }
        return streak
    }

    var body: some View {
        ScreenContainer(
            title: profile?.displayName.isEmpty == false ? profile?.displayName ?? "Profile" : "Your Profile",
            subtitle: profile?.intention.isEmpty == false ? profile?.intention ?? "" : "Shape the journal around what matters to you."
        ) {
            profileEditor

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
                StatCard(title: "Total Entries", value: "\(entries.count)", symbolName: "book.pages")
                StatCard(title: "Most Used Tag", value: mostUsedTag, symbolName: "tag.fill")
                StatCard(title: "Current Streak", value: "\(streakValue) days", symbolName: "flame.fill")
                StatCard(title: "Connections", value: "\(Set(entries.map(\.personNameOrAlias)).count)", symbolName: "person.2.fill")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
        }
    }

    private var profileEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("About You")
                .font(AppTheme.Typography.sectionTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            TextField(
                "Your name or alias",
                text: Binding(get: {
                    profile?.displayName ?? ""
                }, set: { newValue in
                    updateProfile { $0.displayName = newValue }
                })
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "What are you looking for?",
                text: Binding(get: {
                    profile?.intention ?? ""
                }, set: { newValue in
                    updateProfile { $0.intention = newValue }
                })
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "Short bio",
                text: Binding(get: {
                    profile?.bio ?? ""
                }, set: { newValue in
                    updateProfile { $0.bio = newValue }
                }),
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(3, reservesSpace: true)
        }
        .glassCard()
    }

    private func updateProfile(_ mutate: (UserProfile) -> Void) {
        let target = profile ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()

        mutate(target)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

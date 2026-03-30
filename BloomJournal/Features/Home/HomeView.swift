import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @State private var searchText = ""

    private var filteredEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            entry.personNameOrAlias.localizedCaseInsensitiveContains(query)
                || entry.notes.localizedCaseInsensitiveContains(query)
                || entry.connectionType.title.localizedCaseInsensitiveContains(query)
                || entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    var body: some View {
        NavigationStack {
            ScreenContainer(
                title: "Past Connections",
                subtitle: "Search your archive and revisit the entries you want in seconds.",
                eyebrow: "Home"
            ) {
                searchField

                if entries.isEmpty {
                    EmptyStateCard(
                        title: "No entries yet",
                        message: "Your first memory can live here. Add a connection and Yoni Journal will shape the archive around it.",
                        systemImage: "sparkles"
                    )
                } else if filteredEntries.isEmpty {
                    EmptyStateCard(
                        title: "No matching entries",
                        message: "Try searching by name, tag, mood, or a word from your notes.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        SectionHeader("Entries", subtitle: "\(filteredEntries.count) result\(filteredEntries.count == 1 ? "" : "s")")
                        listContent
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField("Search entries, names, tags, or notes", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white.opacity(0.52))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        }
    }

    private var listContent: some View {
        LazyVStack(spacing: AppTheme.Spacing.medium) {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    EntryDetailView(entry: entry)
                } label: {
                    EntryCard(entry: entry)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        delete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func delete(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

private struct EntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentSoft.opacity(0.95))
                        .frame(width: 52, height: 52)
                    Text(entry.mood.emoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    HStack {
                        Text(entry.personNameOrAlias)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }

                    Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Text(entry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(3)
                }
            }

            HStack(spacing: 10) {
                Text(entry.connectionType.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.Colors.accentSoft.opacity(0.9)))

                if let rating = entry.rating {
                    Label("\(rating)/5", systemImage: "star.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.gold)
                }

                Spacer()

                if !entry.tags.isEmpty {
                    Text(entry.tags.prefix(2).joined(separator: " · "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct EntryDetailView: View {
    let entry: JournalEntry

    var body: some View {
        ScreenContainer(title: entry.personNameOrAlias, subtitle: entry.entryDate.formatted(date: .complete, time: .shortened)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Label(entry.connectionType.title, systemImage: entry.mood.iconName)
                        .foregroundStyle(AppTheme.Colors.accent)
                    if let rating = entry.rating {
                        Spacer()
                        Label("\(rating)/5", systemImage: "star.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }

                Text(entry.notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                if !entry.tags.isEmpty {
                    FlowTagsView(tags: entry.tags)
                }
            }
            .glassCard()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FlowTagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
            }
        }
    }
}

private struct TagChip: View {
    let tag: String

    var body: some View {
        Text(tag.capitalized)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.Colors.accentSoft.opacity(0.8))
            )
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.makeShared())
        .environmentObject(AppLockController())
}

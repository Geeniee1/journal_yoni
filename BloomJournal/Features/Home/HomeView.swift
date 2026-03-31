import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @State private var searchText = ""
    @State private var selectedEntry: JournalEntry?
    @State private var entryPendingDeletion: JournalEntry?

    private var filteredEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            entry.personNameOrAlias.localizedCaseInsensitiveContains(query)
                || entry.notes.localizedCaseInsensitiveContains(query)
                || entry.connectionType.title.localizedCaseInsensitiveContains(query)
                || entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
                || entry.greenFlags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
                || entry.redFlags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
                || entry.positionIDs.contains(where: { id in
                    (PositionCatalog.all.first(where: { $0.id == id })?.name.localizedCaseInsensitiveContains(query) ?? false)
                })
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
                        message: "Try searching by name, tag, flag, or a word from your notes.",
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
            .sheet(item: $selectedEntry) { entry in
                NavigationStack {
                    EntryDetailView(
                        entry: entry,
                        onDelete: {
                            delete(entry)
                            selectedEntry = nil
                        }
                    )
                }
                .presentationDetents([.large])
            }
            .alert(
                "Delete entry?",
                isPresented: Binding(
                    get: { entryPendingDeletion != nil },
                    set: { isPresented in
                        if !isPresented {
                            entryPendingDeletion = nil
                        }
                    }
                ),
                presenting: entryPendingDeletion
            ) { entry in
                Button("Delete", role: .destructive) {
                    delete(entry)
                    if selectedEntry?.id == entry.id {
                        selectedEntry = nil
                    }
                    entryPendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    entryPendingDeletion = nil
                }
            } message: { _ in
                Text("This entry will be permanently deleted.")
            }
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
                ZStack(alignment: .topLeading) {
                    Button {
                        selectedEntry = entry
                    } label: {
                        EntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)

                    Button {
                        entryPendingDeletion = entry
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.62))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 10)
                    .padding(.top, 10)
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
                LotusRatingIcon(level: entry.rating, isSelected: true)

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

                    Text("Updated \(entry.updatedAt.formatted(date: .abbreviated, time: .shortened))")
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

                Label("\(entry.rating)/10", systemImage: "sparkles")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.gold)

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
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isShowingDeleteConfirmation = false
    let entry: JournalEntry
    let onDelete: () -> Void

    var body: some View {
        ScreenContainer(title: entry.personNameOrAlias, subtitle: entry.entryDate.formatted(date: .complete, time: .shortened)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Label(entry.connectionType.title, systemImage: "heart.text.square.fill")
                        .foregroundStyle(AppTheme.Colors.accent)
                    Spacer()
                    LotusRatingBadge(rating: entry.rating)
                }

                Text(entry.notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                if !entry.tags.isEmpty {
                    FlowTagsView(tags: entry.tags)
                }

                EntryBinarySummary(entry: entry)

                if !entry.greenFlags.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        SectionHeader("Green Flags")
                        FlowTagsView(tags: entry.greenFlags)
                    }
                }

                if !entry.redFlags.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        SectionHeader("Red Flags")
                        FlowTagsView(tags: entry.redFlags)
                    }
                }

                if !entry.positionIDs.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        SectionHeader("Positions")
                        FlowTagsView(tags: entry.positionIDs.compactMap { id in
                            PositionCatalog.all.first(where: { $0.id == id })?.name
                        })
                    }
                }
            }
            .glassCard()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                EntryEditorView(entry: entry)
            }
            .presentationDetents([.large])
        }
        .alert("Delete entry?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This entry will be permanently deleted.")
        }
    }
}

private struct EntryBinarySummary: View {
    let entry: JournalEntry

    private var enabledItems: [String] {
        var items: [String] = []
        if entry.wouldMeetAgain { items.append("Would meet again") }
        if entry.goodKisser { items.append("Good kisser") }
        if entry.goodHead { items.append("Good head") }
        if entry.longDuration { items.append("Long") }
        if entry.madeMeCum { items.append("Made me cum") }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            SectionHeader("Quick Notes")

            if enabledItems.isEmpty {
                Text("No binary notes saved for this entry yet.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                FlowTagsView(tags: enabledItems)
            }
        }
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

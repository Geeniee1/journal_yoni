import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @State private var searchText = ""
    @State private var selectedThread: PersonThreadSelection?
    @State private var entryPendingDeletion: JournalEntry?

    private var filteredThreads: [PersonThread] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let threads = personThreads
        guard !query.isEmpty else { return threads }

        return threads.filter { thread in
            thread.entries.contains { entry in
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
    }

    private var personThreads: [PersonThread] {
        Dictionary(grouping: entries) { entry in
            normalizedPersonName(for: entry.personNameOrAlias)
        }
        .compactMap { normalizedName, groupedEntries in
            guard let latestEntry = groupedEntries.max(by: { $0.updatedAt < $1.updatedAt }) else { return nil }
            let sortedEntries = groupedEntries.sorted(by: { $0.updatedAt > $1.updatedAt })
            return PersonThread(
                id: normalizedName,
                personName: latestEntry.personNameOrAlias,
                latestEntry: latestEntry,
                entries: sortedEntries
            )
        }
        .sorted(by: { $0.latestEntry.updatedAt > $1.latestEntry.updatedAt })
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
                } else if filteredThreads.isEmpty {
                    EmptyStateCard(
                        title: "No matching entries",
                        message: "Try searching by name, tag, flag, or a word from your notes.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        SectionHeader("Connections", subtitle: "\(filteredThreads.count) result\(filteredThreads.count == 1 ? "" : "s")")
                        listContent
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedThread) { selection in
                NavigationStack {
                    PersonThreadView(
                        personName: selection.personName,
                        onDeleteEntry: { entry in
                            delete(entry)
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
            ForEach(filteredThreads) { thread in
                ZStack(alignment: .topLeading) {
                    Button {
                        selectedThread = PersonThreadSelection(personName: thread.personName)
                    } label: {
                        EntryCard(thread: thread)
                    }
                    .buttonStyle(.plain)

                    Button {
                        entryPendingDeletion = thread.latestEntry
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

    private func normalizedPersonName(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "untitled-connection" : trimmed.lowercased()
    }
}

private struct EntryCard: View {
    let thread: PersonThread

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                LotusRatingIcon(level: thread.latestEntry.rating, isSelected: true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    HStack {
                        Text(thread.personName)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }

                    Text("Updated \(thread.latestEntry.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Text(thread.latestEntry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(3)
                }
            }

            HStack(spacing: 10) {
                Text(thread.latestEntry.connectionType.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.Colors.accentSoft.opacity(0.9)))

                Label("\(thread.latestEntry.rating)/10", systemImage: "sparkles")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.gold)

                Text("\(thread.entries.count) entr\(thread.entries.count == 1 ? "y" : "ies")")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Spacer()

                if !thread.latestEntry.tags.isEmpty {
                    Text(thread.latestEntry.tags.prefix(2).joined(separator: " · "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct PersonThread: Identifiable {
    let id: String
    let personName: String
    let latestEntry: JournalEntry
    let entries: [JournalEntry]
}

private struct PersonThreadSelection: Identifiable {
    let personName: String
    var id: String { personName.lowercased() }
}

private struct PersonThreadView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var allEntries: [JournalEntry]
    @State private var selectedEntry: JournalEntry?
    @State private var isShowingNewEntry = false

    let personName: String
    let onDeleteEntry: (JournalEntry) -> Void

    private var entries: [JournalEntry] {
        allEntries.filter {
            $0.personNameOrAlias.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(personName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        }
    }

    var body: some View {
        ScreenContainer(
            title: personName,
            subtitle: "View older interactions, edit them, or add a fresh entry for this person."
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Button {
                    isShowingNewEntry = true
                } label: {
                    Label("Add New Entry for \(personName)", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())

                if entries.isEmpty {
                    EmptyStateCard(
                        title: "No entries",
                        message: "This connection does not have any saved interactions yet.",
                        systemImage: "heart"
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        SectionHeader("Saved Entries", subtitle: "\(entries.count) total")

                        LazyVStack(spacing: AppTheme.Spacing.medium) {
                            ForEach(entries) { entry in
                                Button {
                                    selectedEntry = entry
                                } label: {
                                    EntryHistoryCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
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
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryDetailView(
                    entry: entry,
                    onDelete: {
                        onDeleteEntry(entry)
                        selectedEntry = nil
                    }
                )
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingNewEntry) {
            NavigationStack {
                EntryEditorView(prefilledPersonName: personName, dismissAfterSave: true)
            }
            .presentationDetents([.large])
        }
    }
}

private struct EntryHistoryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                LotusRatingIcon(level: entry.rating, isSelected: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.entryDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text(entry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            HStack(spacing: 10) {
                Text(entry.connectionType.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)

                if !entry.positionIDs.isEmpty {
                    Text("\(entry.positionIDs.count) positions")
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
    @State private var isShowingNewEntry = false
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

                Button {
                    isShowingNewEntry = true
                } label: {
                    Label("Add New Entry for \(entry.personNameOrAlias)", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PrimaryButtonStyle())

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
                        PositionPreviewRow(
                            positions: entry.positionIDs.compactMap { id in
                                PositionCatalog.all.first(where: { $0.id == id })
                            }
                        )
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
        .sheet(isPresented: $isShowingNewEntry) {
            NavigationStack {
                EntryEditorView(prefilledPersonName: entry.personNameOrAlias, dismissAfterSave: true)
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

private struct PositionPreviewRow: View {
    let positions: [PositionDefinition]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(positions) { position in
                    PositionPreviewTile(position: position)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct PositionPreviewTile: View {
    let position: PositionDefinition

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: position.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.Colors.accentSoft.opacity(0.88))
                )

            Text(position.name)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 92, alignment: .top)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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

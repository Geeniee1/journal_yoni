import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @State private var searchText = ""
    @State private var isShowingFilters = false
    @State private var sortOption: HomeSortOption = .latestJournalEntry
    @State private var selectedConnectionTypes: Set<ConnectionType> = []
    @State private var requiresWouldMeetAgain = false
    @State private var requiresGoodKisser = false
    @State private var requiresGoodHead = false
    @State private var requiresLongDuration = false
    @State private var requiresMadeMeCum = false
    @State private var requiresGreenFlags = false
    @State private var requiresRedFlags = false
    @State private var requiresNotes = false
    @State private var selectedPositionIDs: Set<String> = []
    @State private var selectedThread: PersonThreadSelection?
    @State private var entryPendingDeletion: JournalEntry?
    @State private var isSelectingThreads = false
    @State private var selectedThreadIDs: Set<String> = []
    @State private var isShowingDeleteSelectedThreadsConfirmation = false

    private var visibleThreads: [PersonThread] {
        sortOption.sorted(
            threads: personThreads
                .filter(threadMatchesFilters)
                .filter(threadMatchesSearch)
        )
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
    }

    private var activeFilterLabels: [String] {
        var labels = selectedConnectionTypes.sorted(by: { $0.title < $1.title }).map(\.title)

        if requiresWouldMeetAgain { labels.append("Would meet again") }
        if requiresGoodKisser { labels.append("Good kisser") }
        if requiresGoodHead { labels.append("Good head") }
        if requiresLongDuration { labels.append("Long") }
        if requiresMadeMeCum { labels.append("Made me cum") }
        if requiresGreenFlags { labels.append("Green flags") }
        if requiresRedFlags { labels.append("Red flags") }
        if requiresNotes { labels.append("Notes") }

        labels.append(contentsOf: selectedPositionIDs.compactMap { id in
            PositionCatalog.all.first(where: { $0.id == id })?.name
        }.sorted())

        return labels
    }

    var body: some View {
        NavigationStack {
            ScreenContainer(
                title: "Connections",
                subtitle: "Search what happened, keep upcoming plans in view, and revisit any thread in seconds.",
                eyebrow: "Home"
            ) {
                searchField
                if isSelectingThreads {
                    selectionControlsCard
                } else {
                    controlsCard
                }

                if entries.isEmpty {
                    EmptyStateCard(
                        title: "No entries yet",
                        message: "Your first memory can live here. Add a connection and Yoni Journal will shape the archive around it.",
                        systemImage: "sparkles"
                    )
                } else if visibleThreads.isEmpty {
                    ArchiveEmptyState(
                        hasFilters: !activeFilterLabels.isEmpty,
                        activeFilters: activeFilterLabels,
                        onClearFilters: clearAllFilters
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        SectionHeader(
                            "Connections",
                            subtitle: "\(visibleThreads.count) result\(visibleThreads.count == 1 ? "" : "s") • sorted by \(sortOption.title.lowercased())"
                        )
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
            .alert("Delete selected journals?", isPresented: $isShowingDeleteSelectedThreadsConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteSelectedThreads()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete every saved entry in the selected journals.")
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField("Search people, notes, tags, or positions", text: $searchText)
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

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.small) {
                Button {
                    isShowingFilters.toggle()
                } label: {
                    Label(
                        activeFilterLabels.isEmpty ? "Filters" : "Filters (\(activeFilterLabels.count))",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
                .buttonStyle(CapsuleToggleButtonStyle(isSelected: isShowingFilters || !activeFilterLabels.isEmpty))

                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(HomeSortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Sort")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                            Text(sortOption.shortTitle)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.primaryText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Capsule(style: .continuous).fill(Color.white.opacity(0.48)))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                if !activeFilterLabels.isEmpty {
                    Button("Clear") {
                        clearAllFilters()
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.warning)
                }

                if !isSelectingThreads {
                    Button("Select") {
                        isSelectingThreads = true
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }

            if !activeFilterLabels.isEmpty {
                ActiveFilterChips(labels: activeFilterLabels)
            }

            if isShowingFilters {
                filterPanel
            }
        }
        .glassCard()
    }

    private var selectionControlsCard: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Selection Mode")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text(
                        selectedThreadIDs.isEmpty
                            ? "Tap journals to mark them for deletion."
                            : "\(selectedThreadIDs.count) journal\(selectedThreadIDs.count == 1 ? "" : "s") selected"
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: AppTheme.Spacing.small) {
                Button("Cancel") {
                    isSelectingThreads = false
                    selectedThreadIDs.removeAll()
                }
                .font(AppTheme.Typography.caption.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)

                if !selectedThreadIDs.isEmpty {
                    Button("Delete (\(selectedThreadIDs.count))") {
                        isShowingDeleteSelectedThreadsConfirmation = true
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.warning)
                }
            }
        }
        .glassCard()
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(
                "Filter Archive",
                subtitle: activeFilterLabels.isEmpty
                    ? "Stack as many filters as you want."
                    : "\(activeFilterLabels.count) active"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 128), spacing: AppTheme.Spacing.small)],
                spacing: AppTheme.Spacing.small
            ) {
                ForEach(ConnectionType.editorCases) { type in
                    FilterChipButton(title: type.title, isSelected: selectedConnectionTypes.contains(type)) {
                        toggleConnectionType(type)
                    }
                }

                FilterChipButton(title: "Would meet again", isSelected: requiresWouldMeetAgain) {
                    requiresWouldMeetAgain.toggle()
                }
                FilterChipButton(title: "Good kisser", isSelected: requiresGoodKisser) {
                    requiresGoodKisser.toggle()
                }
                FilterChipButton(title: "Good head", isSelected: requiresGoodHead) {
                    requiresGoodHead.toggle()
                }
                FilterChipButton(title: "Long", isSelected: requiresLongDuration) {
                    requiresLongDuration.toggle()
                }
                FilterChipButton(title: "Made me cum", isSelected: requiresMadeMeCum) {
                    requiresMadeMeCum.toggle()
                }
                FilterChipButton(title: "Green flags", isSelected: requiresGreenFlags) {
                    requiresGreenFlags.toggle()
                }
                FilterChipButton(title: "Red flags", isSelected: requiresRedFlags) {
                    requiresRedFlags.toggle()
                }
                FilterChipButton(title: "Notes", isSelected: requiresNotes) {
                    requiresNotes.toggle()
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                SectionHeader(
                    "Positions",
                    subtitle: selectedPositionIDs.isEmpty ? "Filter by any saved position." : "\(selectedPositionIDs.count) selected"
                )

                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 4),
                        spacing: AppTheme.Spacing.small
                    ) {
                        ForEach(PositionCatalog.all) { position in
                            Button {
                                togglePositionFilter(position.id)
                            } label: {
                                FilterPositionTile(
                                    position: position,
                                    isSelected: selectedPositionIDs.contains(position.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 4)
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var listContent: some View {
        LazyVStack(spacing: AppTheme.Spacing.medium) {
            ForEach(visibleThreads) { thread in
                ZStack(alignment: .topLeading) {
                    Button {
                        if isSelectingThreads {
                            toggleThreadSelection(thread.id)
                        } else {
                            selectedThread = PersonThreadSelection(personName: thread.personName)
                        }
                    } label: {
                        EntryCard(thread: thread, isSelected: selectedThreadIDs.contains(thread.id), isSelecting: isSelectingThreads)
                    }
                    .buttonStyle(.plain)

                    if !isSelectingThreads {
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
    }

    private func delete(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func deleteSelectedThreads() {
        let entriesToDelete = personThreads
            .filter { selectedThreadIDs.contains($0.id) }
            .flatMap(\.entries)

        for entry in entriesToDelete {
            modelContext.delete(entry)
        }

        try? modelContext.save()
        selectedThreadIDs.removeAll()
        isSelectingThreads = false
    }

    private func threadMatchesSearch(_ thread: PersonThread) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return thread.entries.contains { entry in
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

    private func threadMatchesFilters(_ thread: PersonThread) -> Bool {
        let hasActiveFilters =
            !selectedConnectionTypes.isEmpty
            || requiresWouldMeetAgain
            || requiresGoodKisser
            || requiresGoodHead
            || requiresLongDuration
            || requiresMadeMeCum
            || requiresGreenFlags
            || requiresRedFlags
            || requiresNotes
            || !selectedPositionIDs.isEmpty

        guard hasActiveFilters else { return true }

        if !selectedPositionIDs.isEmpty {
            let threadPositionIDs = Set(thread.entries.flatMap(\.positionIDs))
            guard selectedPositionIDs.isSubset(of: threadPositionIDs) else {
                return false
            }
        }

        return thread.entries.contains(where: entryMatchesFilters)
    }

    private func entryMatchesFilters(_ entry: JournalEntry) -> Bool {
        if !selectedConnectionTypes.isEmpty, !selectedConnectionTypes.contains(entry.connectionType) {
            return false
        }
        if requiresWouldMeetAgain, !entry.wouldMeetAgain {
            return false
        }
        if requiresGoodKisser, !entry.goodKisser {
            return false
        }
        if requiresGoodHead, !entry.goodHead {
            return false
        }
        if requiresLongDuration, !entry.longDuration {
            return false
        }
        if requiresMadeMeCum, !entry.madeMeCum {
            return false
        }
        if requiresGreenFlags, entry.greenFlags.isEmpty {
            return false
        }
        if requiresRedFlags, entry.redFlags.isEmpty {
            return false
        }
        if requiresNotes, !hasMeaningfulNotes(entry) {
            return false
        }
        return true
    }

    private func hasMeaningfulNotes(_ entry: JournalEntry) -> Bool {
        let trimmed = entry.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "No notes yet."
    }

    private func clearAllFilters() {
        selectedConnectionTypes.removeAll()
        requiresWouldMeetAgain = false
        requiresGoodKisser = false
        requiresGoodHead = false
        requiresLongDuration = false
        requiresMadeMeCum = false
        requiresGreenFlags = false
        requiresRedFlags = false
        requiresNotes = false
        selectedPositionIDs.removeAll()
    }

    private func toggleConnectionType(_ type: ConnectionType) {
        if selectedConnectionTypes.contains(type) {
            selectedConnectionTypes.remove(type)
        } else {
            selectedConnectionTypes.insert(type)
        }
    }

    private func togglePositionFilter(_ id: String) {
        if selectedPositionIDs.contains(id) {
            selectedPositionIDs.remove(id)
        } else {
            selectedPositionIDs.insert(id)
        }
    }

    private func toggleThreadSelection(_ id: String) {
        if selectedThreadIDs.contains(id) {
            selectedThreadIDs.remove(id)
        } else {
            selectedThreadIDs.insert(id)
        }
    }

    private func normalizedPersonName(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "untitled-connection" : trimmed.lowercased()
    }
}

private struct EntryCard: View {
    let thread: PersonThread
    let isSelected: Bool
    let isSelecting: Bool

    private var isFutureThread: Bool {
        thread.latestEntry.isPlannedFutureEntry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                ZStack(alignment: .topLeading) {
                    LotusRatingIcon(level: thread.latestEntry.rating, isSelected: true, showsValueLabel: false)
                        .frame(width: 72)
                        .opacity(isFutureThread ? 0.72 : 1)

                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText.opacity(0.7))
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.92))
                            )
                            .offset(x: -6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    HStack {
                        Text(thread.personName)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(
                                isFutureThread
                                    ? AppTheme.Colors.primaryText.opacity(0.7)
                                    : AppTheme.Colors.primaryText
                            )

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }

                    Text("Updated \(thread.latestEntry.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureThread ? 0.78 : 1))

                    Text(thread.latestEntry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureThread ? 0.82 : 1))
                        .lineLimit(3)
                }
            }

            HStack(spacing: 10) {
                Text(thread.latestEntry.connectionType.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(isFutureThread ? AppTheme.Colors.secondaryText : AppTheme.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            isFutureThread
                                ? Color.white.opacity(0.32)
                                : AppTheme.Colors.accentSoft.opacity(0.9)
                        )
                    )

                Text("\(thread.entries.count) entr\(thread.entries.count == 1 ? "y" : "ies")")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureThread ? 0.82 : 1))

                Spacer()

                if !thread.latestEntry.tags.isEmpty {
                    Text(thread.latestEntry.tags.prefix(2).joined(separator: " · "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureThread ? 0.82 : 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .saturation(isFutureThread ? 0.45 : 1)
        .opacity(isFutureThread ? 0.86 : 1)
    }
}

private struct PersonThread: Identifiable {
    let id: String
    let personName: String
    let latestEntry: JournalEntry
    let entries: [JournalEntry]

    var latestJournalDate: Date {
        latestEntry.updatedAt
    }

    var initialJournalDate: Date {
        entries.map(\.entryDate).min() ?? latestEntry.entryDate
    }

    var score: Int {
        latestEntry.rating
    }

    var greenFlagCount: Int {
        entries.reduce(0) { $0 + $1.greenFlags.count }
    }

    var redFlagCount: Int {
        entries.reduce(0) { $0 + $1.redFlags.count }
    }

    var entryCount: Int {
        entries.count
    }

    var isPlannedFutureThread: Bool {
        latestEntry.isPlannedFutureEntry
    }
}

private struct PersonThreadSelection: Identifiable {
    let personName: String
    var id: String { personName.lowercased() }
}

private enum HomeSortOption: String, CaseIterable, Identifiable {
    case latestJournalEntry
    case initialJournalEntry
    case score
    case greenFlags
    case redFlags
    case entryCount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latestJournalEntry: "Latest journal entry"
        case .initialJournalEntry: "Initial journal entry"
        case .score: "Score"
        case .greenFlags: "Amount of green flags"
        case .redFlags: "Amount of red flags"
        case .entryCount: "Amount of entries"
        }
    }

    var shortTitle: String {
        switch self {
        case .latestJournalEntry: "Latest"
        case .initialJournalEntry: "Initial"
        case .score: "Score"
        case .greenFlags: "Green flags"
        case .redFlags: "Red flags"
        case .entryCount: "Entries"
        }
    }

    func sorted(threads: [PersonThread]) -> [PersonThread] {
        threads.sorted { lhs, rhs in
            switch self {
            case .latestJournalEntry:
                if lhs.latestJournalDate != rhs.latestJournalDate {
                    return lhs.latestJournalDate > rhs.latestJournalDate
                }
            case .initialJournalEntry:
                if lhs.initialJournalDate != rhs.initialJournalDate {
                    return lhs.initialJournalDate > rhs.initialJournalDate
                }
            case .score:
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
            case .greenFlags:
                if lhs.greenFlagCount != rhs.greenFlagCount {
                    return lhs.greenFlagCount > rhs.greenFlagCount
                }
            case .redFlags:
                if lhs.redFlagCount != rhs.redFlagCount {
                    return lhs.redFlagCount > rhs.redFlagCount
                }
            case .entryCount:
                if lhs.entryCount != rhs.entryCount {
                    return lhs.entryCount > rhs.entryCount
                }
            }

            return lhs.latestJournalDate > rhs.latestJournalDate
        }
    }
}

private struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CapsuleToggleButtonStyle(isSelected: isSelected))
    }
}

private struct FilterPositionTile: View {
    let position: PositionDefinition
    let isSelected: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: position.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? AppTheme.Colors.accentSoft.opacity(0.95) : Color.white.opacity(0.14))
                )

            Text(position.name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(isSelected ? AppTheme.Colors.accentSoft.opacity(0.52) : Color.white.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .stroke(isSelected ? AppTheme.Colors.accent.opacity(0.8) : Color.white.opacity(0.18), lineWidth: 1)
        }
        .saturation(isSelected ? 1 : 0)
    }
}

private struct ActiveFilterChips: View {
    let labels: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: AppTheme.Spacing.xSmall)], spacing: AppTheme.Spacing.xSmall) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.Colors.accentSoft.opacity(0.9))
                    )
            }
        }
    }
}

private struct ArchiveEmptyState: View {
    let hasFilters: Bool
    let activeFilters: [String]
    let onClearFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            EmptyStateCard(
                title: hasFilters ? "No experience in these categories yet" : "No matching entries",
                message: hasFilters
                    ? "The active categories below removed every result. Deselect any filter to broaden the archive again."
                    : "Try a different name, note, tag, or position.",
                systemImage: hasFilters ? "line.3.horizontal.decrease.circle" : "magnifyingglass"
            )

            if hasFilters {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    SectionHeader("Active Filters")
                    ActiveFilterChips(labels: activeFilters)

                    Button("Clear Filters", action: onClearFilters)
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
}

private struct PersonThreadView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var allEntries: [JournalEntry]
    @State private var selectedEntry: JournalEntry?
    @State private var isShowingNewEntry = false
    @State private var isSelectingEntries = false
    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var isShowingDeleteSelectedEntriesConfirmation = false

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
                HStack(spacing: AppTheme.Spacing.small) {
                    Button {
                        isShowingNewEntry = true
                    } label: {
                        Label("Add New Entry for \(personName)", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if isSelectingEntries {
                        Button("Cancel") {
                            isSelectingEntries = false
                            selectedEntryIDs.removeAll()
                        }
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                        if !selectedEntryIDs.isEmpty {
                            Button("Delete (\(selectedEntryIDs.count))") {
                                isShowingDeleteSelectedEntriesConfirmation = true
                            }
                            .font(AppTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.warning)
                        }
                    } else {
                        Button("Select") {
                            isSelectingEntries = true
                        }
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                    }
                }

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
                                    if isSelectingEntries {
                                        toggleEntrySelection(entry.id)
                                    } else {
                                        selectedEntry = entry
                                    }
                                } label: {
                                    EntryHistoryCard(
                                        entry: entry,
                                        isSelected: selectedEntryIDs.contains(entry.id),
                                        isSelecting: isSelectingEntries
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete selected entries?", isPresented: $isShowingDeleteSelectedEntriesConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedEntries()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete every selected entry for \(personName).")
        }
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

    private func toggleEntrySelection(_ id: UUID) {
        if selectedEntryIDs.contains(id) {
            selectedEntryIDs.remove(id)
        } else {
            selectedEntryIDs.insert(id)
        }
    }

    private func deleteSelectedEntries() {
        for entry in entries where selectedEntryIDs.contains(entry.id) {
            onDeleteEntry(entry)
        }
        selectedEntryIDs.removeAll()
        isSelectingEntries = false
    }
}

private struct EntryHistoryCard: View {
    let entry: JournalEntry
    let isSelected: Bool
    let isSelecting: Bool

    private var isFutureEntry: Bool {
        entry.isPlannedFutureEntry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                ZStack(alignment: .topLeading) {
                    LotusRatingIcon(level: entry.rating, isSelected: true, showsValueLabel: false)
                        .frame(width: 72)
                        .opacity(isFutureEntry ? 0.72 : 1)

                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText.opacity(0.7))
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.92))
                            )
                            .offset(x: -6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.entryDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(
                            isFutureEntry
                                ? AppTheme.Colors.primaryText.opacity(0.72)
                                : AppTheme.Colors.primaryText
                        )

                    Text(entry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureEntry ? 0.82 : 1))
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
                    .foregroundStyle(isFutureEntry ? AppTheme.Colors.secondaryText : AppTheme.Colors.accent)

                if !entry.positionIDs.isEmpty {
                    Text("\(entry.positionIDs.count) positions")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(isFutureEntry ? 0.82 : 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .saturation(isFutureEntry ? 0.45 : 1)
        .opacity(isFutureEntry ? 0.86 : 1)
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

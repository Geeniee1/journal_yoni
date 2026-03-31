import AVFoundation
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.updatedAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var searchText = ""
    @State private var isShowingFilters = false
    @State private var isShowingLeaderboard = false
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
    @State private var selectedTagKeywords: Set<String> = []
    @State private var selectedGreenFlagKeywords: Set<String> = []
    @State private var selectedRedFlagKeywords: Set<String> = []
    @State private var selectedThread: PersonThreadSelection?
    @State private var entryPendingDeletion: JournalEntry?
    @State private var isSelectingThreads = false
    @State private var selectedThreadIDs: Set<String> = []
    @State private var isShowingDeleteSelectedThreadsConfirmation = false

    private let photoStorage = PhotoStorageService()
    private let audioMemoStorage = AudioMemoStorageService()

    private var visibleThreads: [PersonThread] {
        sortOption.sorted(
            threads: personThreads
                .filter(threadMatchesFilters)
                .filter(threadMatchesSearch)
        )
    }

    private var preferenceProfile: UserPreferenceProfile {
        guard let profile = profiles.first else { return .defaults }
        return UserPreferenceProfile(
            attractiveRating: profile.preferredAttractiveRating,
            heightCentimeters: profile.preferredHeightCentimeters,
            goodBodyRating: profile.preferredGoodBodyRating,
            goodFaceRating: profile.preferredGoodFaceRating,
            goodKisserRating: profile.preferredGoodKisserRating,
            goodHeadRating: profile.preferredGoodHeadRating,
            lengthCentimeters: profile.preferredLengthCentimeters
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

        labels.append(contentsOf: selectedTagKeywords.sorted().map { "Tag: \($0)" })
        labels.append(contentsOf: selectedGreenFlagKeywords.sorted().map { "Green: \($0)" })
        labels.append(contentsOf: selectedRedFlagKeywords.sorted().map { "Red: \($0)" })

        return labels
    }

    private var availableTagKeywords: [String] {
        Array(Set(entries.flatMap(\.tags)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var availableGreenFlagKeywords: [String] {
        Array(Set(entries.flatMap(\.greenFlags)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var availableRedFlagKeywords: [String] {
        Array(Set(entries.flatMap(\.redFlags)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ScreenContainer(
                title: "",
                subtitle: nil,
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
            .sheet(isPresented: $isShowingLeaderboard) {
                NavigationStack {
                    LeaderboardView(threads: personThreads, preferenceProfile: preferenceProfile)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
            HStack(spacing: AppTheme.Spacing.small) {
                filtersControl
                sortControl
            }

            HStack(spacing: AppTheme.Spacing.small) {
                leaderboardControl
                controlsActions
            }

            if !activeFilterLabels.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ActiveFilterChips(labels: activeFilterLabels)
                }
                .padding(.top, 2)
                .padding(.bottom, AppTheme.Spacing.small)
            }

            if isShowingFilters {
                filterPanel
            }
        }
        .glassCard()
    }

    private var filtersControl: some View {
        Button {
            isShowingFilters.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(activeFilterLabels.isEmpty ? "Filters" : "Filters (\(activeFilterLabels.count))")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill((isShowingFilters || !activeFilterLabels.isEmpty) ? AppTheme.Colors.accentSoft.opacity(0.92) : Color.white.opacity(0.48))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke((isShowingFilters || !activeFilterLabels.isEmpty) ? AppTheme.Colors.accent.opacity(0.85) : Color.white.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var sortControl: some View {
        Menu {
            Picker("Sort", selection: $sortOption) {
                ForEach(HomeSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down.circle")
                Text("Sort: \(sortOption.shortTitle)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.48)))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var leaderboardControl: some View {
        Button {
            isShowingLeaderboard = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                Text("Leaderboard")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.48)))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var controlsActions: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
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
        .frame(minWidth: 92, alignment: .trailing)
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

            primaryFilterGrid
            positionsFilterSection
            tagKeywordFilterSection
            greenFlagKeywordFilterSection
            redFlagKeywordFilterSection
        }
    }

    private var primaryFilterGrid: some View {
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
    }

    private var positionsFilterSection: some View {
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

    private var tagKeywordFilterSection: some View {
        KeywordFilterSection(
            title: "Tags",
            subtitle: selectedTagKeywords.isEmpty
                ? "Filter by specific saved tags."
                : "\(selectedTagKeywords.count) selected",
            keywords: availableTagKeywords,
            selectedKeywords: selectedTagKeywords,
            emptyMessage: "No saved tags yet."
        ) { keyword in
            toggleTagKeyword(keyword)
        }
    }

    private var greenFlagKeywordFilterSection: some View {
        KeywordFilterSection(
            title: "Green flags",
            subtitle: selectedGreenFlagKeywords.isEmpty
                ? "Filter by specific green flag keywords."
                : "\(selectedGreenFlagKeywords.count) selected",
            keywords: availableGreenFlagKeywords,
            selectedKeywords: selectedGreenFlagKeywords,
            emptyMessage: "No saved green flags yet."
        ) { keyword in
            toggleGreenFlagKeyword(keyword)
        }
    }

    private var redFlagKeywordFilterSection: some View {
        KeywordFilterSection(
            title: "Red flags",
            subtitle: selectedRedFlagKeywords.isEmpty
                ? "Filter by specific red flag keywords."
                : "\(selectedRedFlagKeywords.count) selected",
            keywords: availableRedFlagKeywords,
            selectedKeywords: selectedRedFlagKeywords,
            emptyMessage: "No saved red flags yet."
        ) { keyword in
            toggleRedFlagKeyword(keyword)
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
        for photo in entry.photoItems {
            photoStorage.delete(photo)
        }
        if let voiceMemoFileName = entry.voiceMemoFileName {
            audioMemoStorage.delete(fileName: voiceMemoFileName)
        }
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func deleteSelectedThreads() {
        let entriesToDelete = personThreads
            .filter { selectedThreadIDs.contains($0.id) }
            .flatMap(\.entries)

        for entry in entriesToDelete {
            for photo in entry.photoItems {
                photoStorage.delete(photo)
            }
            if let voiceMemoFileName = entry.voiceMemoFileName {
                audioMemoStorage.delete(fileName: voiceMemoFileName)
            }
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
            || !selectedTagKeywords.isEmpty
            || !selectedGreenFlagKeywords.isEmpty
            || !selectedRedFlagKeywords.isEmpty

        guard hasActiveFilters else { return true }

        if !selectedPositionIDs.isEmpty {
            let threadPositionIDs = Set(thread.entries.flatMap(\.positionIDs))
            guard selectedPositionIDs.isSubset(of: threadPositionIDs) else {
                return false
            }
        }

        if !selectedTagKeywords.isEmpty {
            let threadTags = Set(thread.entries.flatMap(\.tags))
            guard selectedTagKeywords.isSubset(of: threadTags) else {
                return false
            }
        }

        if !selectedGreenFlagKeywords.isEmpty {
            let threadGreenFlags = Set(thread.entries.flatMap(\.greenFlags))
            guard selectedGreenFlagKeywords.isSubset(of: threadGreenFlags) else {
                return false
            }
        }

        if !selectedRedFlagKeywords.isEmpty {
            let threadRedFlags = Set(thread.entries.flatMap(\.redFlags))
            guard selectedRedFlagKeywords.isSubset(of: threadRedFlags) else {
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
        selectedTagKeywords.removeAll()
        selectedGreenFlagKeywords.removeAll()
        selectedRedFlagKeywords.removeAll()
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

    private func toggleTagKeyword(_ keyword: String) {
        if selectedTagKeywords.contains(keyword) {
            selectedTagKeywords.remove(keyword)
        } else {
            selectedTagKeywords.insert(keyword)
        }
    }

    private func toggleGreenFlagKeyword(_ keyword: String) {
        if selectedGreenFlagKeywords.contains(keyword) {
            selectedGreenFlagKeywords.remove(keyword)
        } else {
            selectedGreenFlagKeywords.insert(keyword)
        }
    }

    private func toggleRedFlagKeyword(_ keyword: String) {
        if selectedRedFlagKeywords.contains(keyword) {
            selectedRedFlagKeywords.remove(keyword)
        } else {
            selectedRedFlagKeywords.insert(keyword)
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

    var userExperienceAverage: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(entries.count)
    }

    var attributeAverages: PersonAttributeAverages {
        PersonAttributeAverages(
            attractive: averageScore(where: \.attractive, value: \.attractiveRating),
            heightScore: averageHeightScore,
            goodBody: averageScore(where: \.goodBody, value: \.goodBodyRating),
            goodFace: averageScore(where: \.goodFace, value: \.goodFaceRating),
            goodKisser: averageScore(where: \.goodKisser, value: \.goodKisserRating),
            goodHead: averageScore(where: \.goodHead, value: \.goodHeadRating),
            lengthScore: averageLengthScore
        )
    }

    var averageCategoryRating: Double {
        attributeAverages.averageScore
    }

    func preferenceMSE(using preferences: UserPreferenceProfile) -> Double? {
        attributeAverages.preferenceMSE(using: preferences)
    }

    private func averageScore(
        where predicate: KeyPath<JournalEntry, Bool>,
        value: KeyPath<JournalEntry, Int>
    ) -> Double? {
        let matchingValues = entries
            .filter { $0[keyPath: predicate] }
            .map { Double($0[keyPath: value]) }

        guard !matchingValues.isEmpty else { return nil }
        return matchingValues.reduce(0, +) / Double(matchingValues.count)
    }

    private var averageHeightScore: Double? {
        let heights = entries.compactMap { entry -> Double? in
            guard entry.tall, let value = entry.heightCentimeters else { return nil }
            return normalizedHeightScore(for: value)
        }
        guard !heights.isEmpty else { return nil }
        return heights.reduce(0, +) / Double(heights.count)
    }

    private var averageLengthScore: Double? {
        let lengths = entries.compactMap { entry -> Double? in
            guard entry.longDuration, let value = entry.lengthCentimeters else { return nil }
            return normalizedLengthScore(for: value)
        }
        guard !lengths.isEmpty else { return nil }
        return lengths.reduce(0, +) / Double(lengths.count)
    }
}

private struct PersonThreadSelection: Identifiable {
    let personName: String
    var id: String { personName.lowercased() }
}

private enum HomeSortOption: String, CaseIterable, Identifiable {
    case latestJournalEntry
    case initialJournalEntry
    case averageRating
    case userExperience
    case greenFlags
    case redFlags
    case entryCount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latestJournalEntry: "Latest journal entry"
        case .initialJournalEntry: "Initial journal entry"
        case .averageRating: "Average rating"
        case .userExperience: "User experience"
        case .greenFlags: "Amount of green flags"
        case .redFlags: "Amount of red flags"
        case .entryCount: "Amount of entries"
        }
    }

    var shortTitle: String {
        switch self {
        case .latestJournalEntry: "Latest"
        case .initialJournalEntry: "Initial"
        case .averageRating: "Avg rating"
        case .userExperience: "Experience"
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
            case .averageRating:
                if lhs.averageCategoryRating != rhs.averageCategoryRating {
                    return lhs.averageCategoryRating > rhs.averageCategoryRating
                }
            case .userExperience:
                if lhs.userExperienceAverage != rhs.userExperienceAverage {
                    return lhs.userExperienceAverage > rhs.userExperienceAverage
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

private struct KeywordFilterSection: View {
    let title: String
    let subtitle: String
    let keywords: [String]
    let selectedKeywords: Set<String>
    let emptyMessage: String
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            SectionHeader(title, subtitle: subtitle)

            if keywords.isEmpty {
                Text(emptyMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .padding(.horizontal, 4)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: AppTheme.Spacing.small)],
                    spacing: AppTheme.Spacing.small
                ) {
                    ForEach(keywords, id: \.self) { keyword in
                        FilterChipButton(
                            title: keyword,
                            isSelected: selectedKeywords.contains(keyword)
                        ) {
                            onToggle(keyword)
                        }
                    }
                }
            }
        }
    }
}

private struct UserPreferenceProfile {
    let attractiveRating: Int
    let heightCentimeters: Int
    let goodBodyRating: Int
    let goodFaceRating: Int
    let goodKisserRating: Int
    let goodHeadRating: Int
    let lengthCentimeters: Int

    static let defaults = UserPreferenceProfile(
        attractiveRating: 7,
        heightCentimeters: 175,
        goodBodyRating: 7,
        goodFaceRating: 7,
        goodKisserRating: 7,
        goodHeadRating: 7,
        lengthCentimeters: 15
    )
}

private struct PersonAttributeAverages {
    let attractive: Double?
    let heightScore: Double?
    let goodBody: Double?
    let goodFace: Double?
    let goodKisser: Double?
    let goodHead: Double?
    let lengthScore: Double?

    var allScores: [Double] {
        [attractive, heightScore, goodBody, goodFace, goodKisser, goodHead, lengthScore].compactMap { $0 }
    }

    var averageScore: Double {
        guard !allScores.isEmpty else { return 0 }
        return allScores.reduce(0, +) / Double(allScores.count)
    }

    func preferenceMSE(using preferences: UserPreferenceProfile) -> Double? {
        var squaredDifferences: [Double] = []

        if let attractive {
            squaredDifferences.append(pow(attractive - Double(preferences.attractiveRating), 2))
        }
        if let heightScore {
            squaredDifferences.append(pow(heightScore - normalizedHeightScore(for: preferences.heightCentimeters), 2))
        }
        if let goodBody {
            squaredDifferences.append(pow(goodBody - Double(preferences.goodBodyRating), 2))
        }
        if let goodFace {
            squaredDifferences.append(pow(goodFace - Double(preferences.goodFaceRating), 2))
        }
        if let goodKisser {
            squaredDifferences.append(pow(goodKisser - Double(preferences.goodKisserRating), 2))
        }
        if let goodHead {
            squaredDifferences.append(pow(goodHead - Double(preferences.goodHeadRating), 2))
        }
        if let lengthScore {
            squaredDifferences.append(pow(lengthScore - normalizedLengthScore(for: preferences.lengthCentimeters), 2))
        }

        guard !squaredDifferences.isEmpty else { return nil }
        return squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
    }
}

private enum LeaderboardMetric: String, CaseIterable, Identifiable {
    case preferenceMatch
    case averageRating
    case userExperience

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preferenceMatch: "Preference Match"
        case .averageRating: "Average Rating"
        case .userExperience: "User Experience"
        }
    }
}

private struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss

    let threads: [PersonThread]
    let preferenceProfile: UserPreferenceProfile

    @State private var metric: LeaderboardMetric = .preferenceMatch

    private var rankedThreads: [PersonThread] {
        threads.sorted { lhs, rhs in
            switch metric {
            case .preferenceMatch:
                return (lhs.preferenceMSE(using: preferenceProfile) ?? .greatestFiniteMagnitude)
                    < (rhs.preferenceMSE(using: preferenceProfile) ?? .greatestFiniteMagnitude)
            case .averageRating:
                return lhs.averageCategoryRating > rhs.averageCategoryRating
            case .userExperience:
                return lhs.userExperienceAverage > rhs.userExperienceAverage
            }
        }
    }

    var body: some View {
        ScreenContainer(
            title: "Leaderboard",
            subtitle: "Compare your archive by preference fit, average category rating, or overall experience."
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Picker("Leaderboard metric", selection: $metric) {
                    ForEach(LeaderboardMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(Array(rankedThreads.enumerated()), id: \.element.id) { index, thread in
                            LeaderboardRow(
                                rank: index + 1,
                                thread: thread,
                                preferenceProfile: preferenceProfile
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let thread: PersonThread
    let preferenceProfile: UserPreferenceProfile

    private var preferenceMSEText: String {
        guard let mse = thread.preferenceMSE(using: preferenceProfile) else { return "No preference data yet" }
        return String(format: "MSE %.2f", mse)
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(rank)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(thread.personName)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                HStack(spacing: 10) {
                    leaderboardMetricPill(title: "Avg", value: thread.averageCategoryRating.formatted(.number.precision(.fractionLength(1))))
                    leaderboardMetricPill(title: "Experience", value: thread.userExperienceAverage.formatted(.number.precision(.fractionLength(1))))
                }

                Text(preferenceMSEText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func leaderboardMetricPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.secondaryText)
            Text(value)
                .font(AppTheme.Typography.caption.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Colors.accentSoft.opacity(0.72))
        )
    }
}

private func normalizedHeightScore(for centimeters: Int) -> Double {
    let clamped = min(max(centimeters, 120), 230)
    return ((Double(clamped - 120) / 110.0) * 9.0) + 1.0
}

private func normalizedLengthScore(for centimeters: Int) -> Double {
    let clamped = min(max(centimeters, 0), 30)
    return ((Double(clamped) / 30.0) * 9.0) + 1.0
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
    private let audioMemoStorage = AudioMemoStorageService()
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

                if let voiceMemoFileName = entry.voiceMemoFileName {
                    VoiceMemoPlaybackCard(
                        fileURL: audioMemoStorage.audioURL(for: voiceMemoFileName),
                        duration: entry.voiceMemoDuration
                    )
                }

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
                ShareLink(item: entry.shareSummaryText) {
                    Image(systemName: "square.and.arrow.up")
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
        if entry.attractive { items.append("Attractive · \(entry.attractiveRating)/10") }
        if entry.tall {
            if let heightCentimeters = entry.heightCentimeters {
                items.append("Tall · \(heightCentimeters) cm")
            } else {
                items.append("Tall")
            }
        }
        if entry.goodBody { items.append("Good body · \(entry.goodBodyRating)/10") }
        if entry.goodFace { items.append("Good face · \(entry.goodFaceRating)/10") }
        if entry.goodKisser { items.append("Good kisser · \(entry.goodKisserRating)/10") }
        if entry.goodHead { items.append("Good head · \(entry.goodHeadRating)/10") }
        if entry.longDuration {
            if let lengthCentimeters = entry.lengthCentimeters {
                items.append("Long · \(lengthCentimeters) cm")
            } else {
                items.append("Long")
            }
        }
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

private struct VoiceMemoPlaybackCard: View {
    let fileURL: URL
    let duration: Double?

    @StateObject private var player = VoiceMemoPlayer()

    private var durationText: String {
        guard let duration else { return "Voice memo attached" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: duration) ?? "Voice memo attached"
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Button {
                player.togglePlayback(url: fileURL)
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.accentSoft.opacity(0.9))
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Voice memo")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(durationText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .glassCard()
    }
}

@MainActor
private final class VoiceMemoPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false

    private var player: AVAudioPlayer?

    func togglePlayback(url: URL) {
        if isPlaying {
            player?.stop()
            player = nil
            isPlaying = false
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.play()
            self.player = player
            isPlaying = true
        } catch {
            isPlaying = false
            player = nil
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        self.player = nil
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

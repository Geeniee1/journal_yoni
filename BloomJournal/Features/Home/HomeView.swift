import SwiftUI
import SwiftData

enum HomePresentationMode: String, CaseIterable, Identifiable {
    case list
    case calendar

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @State private var mode: HomePresentationMode = .list

    var body: some View {
        NavigationStack {
            ScreenContainer(
                title: "Past Connections",
                subtitle: "A private timeline of intimacy, tenderness, and everything in between."
            ) {
                Picker("View", selection: $mode) {
                    ForEach(HomePresentationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if entries.isEmpty {
                    EmptyStateCard(
                        title: "No entries yet",
                        message: "Your first memory can live here. Add a connection and Bloom will shape the feed around it.",
                        systemImage: "sparkles"
                    )
                } else {
                    switch mode {
                    case .list:
                        listContent
                    case .calendar:
                        CalendarFeedView(entries: entries)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var listContent: some View {
        LazyVStack(spacing: AppTheme.Spacing.medium) {
            ForEach(entries) { entry in
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
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Text(entry.mood.emoji)
                    .font(.title2)
                if let rating = entry.rating {
                    Label("\(rating)", systemImage: "star.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .frame(width: 42)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(entry.personNameOrAlias)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Text(entry.notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .lineLimit(2)

                HStack {
                    Text(entry.connectionType.title.uppercased())
                    Spacer()
                    Text(entry.tags.prefix(2).joined(separator: " · "))
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct CalendarFeedView: View {
    let entries: [JournalEntry]

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, duration: 0)
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) - 1
        let days = calendar.range(of: .day, in: .month, for: .now) ?? 1..<2

        return Array(repeating: .distantPast, count: firstWeekday) + days.compactMap {
            calendar.date(bySetting: .day, value: $0, of: .now)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                .font(AppTheme.Typography.sectionTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.Spacing.small) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                ForEach(monthDates, id: \.self) { date in
                    if date == .distantPast {
                        Color.clear.frame(height: 42)
                    } else {
                        let hasEntry = entries.contains { Calendar.current.isDate($0.entryDate, inSameDayAs: date) }
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.day()))
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            Circle()
                                .fill(hasEntry ? AppTheme.Colors.accent : .clear)
                                .frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(hasEntry ? AppTheme.Colors.accentSoft.opacity(0.7) : .white.opacity(0.001))
                        )
                    }
                }
            }
            .glassCard()
        }
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

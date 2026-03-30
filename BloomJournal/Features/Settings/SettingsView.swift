import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 7)

    private var entriesByDay: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.entryDate) }
    }

    private var monthDays: [CalendarDayValue] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) ?? DateInterval(start: displayedMonth, duration: 0)
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) - 1
        let days = calendar.range(of: .day, in: .month, for: displayedMonth) ?? 1..<2

        return Array(repeating: CalendarDayValue(date: nil), count: firstWeekday)
            + days.map { day in
                CalendarDayValue(date: calendar.date(bySetting: .day, value: day, of: displayedMonth))
            }
    }

    private var selectedEntries: [JournalEntry] {
        guard let selectedDate else { return [] }
        return entriesByDay[Calendar.current.startOfDay(for: selectedDate)] ?? []
    }

    var body: some View {
        ScreenContainer(
            title: "Calendar",
            subtitle: "Tap a day with a symbol to preview the entries you captured there.",
            eyebrow: "Archive"
        ) {
            monthHeader
            legend
            calendarGrid

            if entries.isEmpty {
                EmptyStateCard(
                    title: "No entries on the calendar yet",
                    message: "Add a journal entry and it will appear here as a heart or fire marker.",
                    systemImage: "calendar.badge.plus"
                )
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { selectedDate != nil },
            set: { isPresented in
                if !isPresented {
                    selectedDate = nil
                }
            }
        )) {
            CalendarEntriesPreview(date: selectedDate, entries: selectedEntries)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.5)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(displayedMonth.formatted(.dateTime.month(.wide)))
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                Text(displayedMonth.formatted(.dateTime.year()))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()

            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.5)))
            }
            .buttonStyle(.plain)
        }
    }

    private var legend: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            legendItem(icon: "heart.fill", title: "One entry")
            legendItem(icon: "flame.fill", title: "Multiple entries")
            Spacer()
        }
        .padding(.horizontal, 6)
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                ForEach(monthDays) { day in
                    CalendarDayCell(
                        day: day.date,
                        entries: day.date.flatMap { entriesByDay[Calendar.current.startOfDay(for: $0)] } ?? [],
                        isToday: day.date.map { Calendar.current.isDateInToday($0) } ?? false
                    ) {
                        if let date = day.date, entriesByDay[Calendar.current.startOfDay(for: date)] != nil {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private func legendItem(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(icon == "flame.fill" ? AppTheme.Colors.accentBright : AppTheme.Colors.accent)
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }
}

private struct CalendarDayValue: Identifiable {
    let id = UUID()
    let date: Date?
}

private struct CalendarDayCell: View {
    let day: Date?
    let entries: [JournalEntry]
    let isToday: Bool
    let action: () -> Void

    private var iconName: String? {
        guard !entries.isEmpty else { return nil }
        return entries.count > 1 ? "flame.fill" : "heart.fill"
    }

    private var iconColor: Color {
        entries.count > 1 ? AppTheme.Colors.accentBright : AppTheme.Colors.accent
    }

    var body: some View {
        Group {
            if let day {
                Button(action: action) {
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        if let iconName {
                            Image(systemName: iconName)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(iconColor)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(backgroundStyle)
                }
                .buttonStyle(.plain)
                .disabled(entries.isEmpty)
            } else {
                Color.clear.frame(height: 56)
            }
        }
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                entries.isEmpty
                    ? Color.white.opacity(isToday ? 0.55 : 0.22)
                    : (entries.count > 1 ? AppTheme.Colors.accentSoft.opacity(0.95) : AppTheme.Colors.accentSoft.opacity(0.72))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isToday ? AppTheme.Colors.accent : Color.white.opacity(0.35), lineWidth: isToday ? 1.5 : 1)
            }
    }
}

private struct CalendarEntriesPreview: View {
    let date: Date?
    let entries: [JournalEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if let date {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(AppTheme.Typography.display)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                    }

                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            HStack {
                                Text(entry.personNameOrAlias)
                                    .font(AppTheme.Typography.cardTitle)
                                    .foregroundStyle(AppTheme.Colors.primaryText)
                                Spacer()
                                Text(entry.connectionType.title)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }

                            Text(entry.notes)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                .lineLimit(4)

                            HStack(spacing: 10) {
                                LotusRatingBadge(rating: entry.rating)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
            .background(AppBackground())
            .navigationTitle("Entry Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension Calendar {
    func startOfMonth(for value: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: value)) ?? value
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

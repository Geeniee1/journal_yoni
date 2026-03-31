import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var lockController: AppLockController

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]
    @Query(sort: \AchievementUnlock.unlockedAt, order: .reverse) private var unlocks: [AchievementUnlock]

    @State private var exportPayload: ExportPayload?
    @State private var exportError: String?
    @State private var isShowingAvatarPicker = false
    @State private var selectedStatPreview: ProfileStatPreview?

    private let exportService = ExportService()
    private let achievementEngine = AchievementEngine()

    private var profile: UserProfile? {
        profiles.first
    }

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    private var mostUsedTag: String {
        let frequencies = Dictionary(entries.flatMap(\.tags).map { ($0, 1) }, uniquingKeysWith: +)
        return frequencies.max(by: { $0.value < $1.value })?.key.capitalized ?? "None yet"
    }

    private var totalConnections: Int {
        Set(entries.map(\.personNameOrAlias)).count
    }

    private var totalHookups: Int {
        entries.filter { $0.connectionType == .hookup }.count
    }

    private var totalSexyTimes: Int {
        entries.filter { $0.connectionType == .sexyTime }.count
    }

    private var totalDates: Int {
        entries.filter { $0.connectionType == .date }.count
    }

    private var unlockedAchievements: [AchievementDefinition] {
        let derived = achievementEngine.unlockedIDs(entries: entries)
        let persisted = Set(unlocks.map(\.achievementID))
        let combined = derived.union(persisted)
        return AchievementCatalog.all.filter { combined.contains($0.id) }
    }

    var body: some View {
        ScreenContainer(
            title: profile?.displayName.isEmpty == false ? profile?.displayName ?? "Your Profile" : "Your Profile",
            subtitle: profile?.intention.isEmpty == false ? profile?.intention ?? "" : "Shape the journal around what matters to you.",
            eyebrow: "Profile"
        ) {
            profileHero
            profileEditor
            reflectionJourney
            achievementsSection
            settingsSection
            supportSection
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
            lockController.setAppLockEnabled(appSettings.isBiometricLockEnabled)
        }
        .sheet(item: $selectedStatPreview) { preview in
            NavigationStack {
                ProfileStatPreviewSheet(preview: preview)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var profileHero: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Button {
                isShowingAvatarPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                        .frame(width: 104, height: 104)

                    Circle()
                        .fill(AppTheme.Colors.accent)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Text(profile?.displayName.isEmpty == false ? profile?.displayName ?? "" : "Yours, privately")
                    .font(AppTheme.Typography.display)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text(profile?.bio.isEmpty == false ? profile?.bio ?? "" : "A private place for desire, tenderness, memory, and honesty.")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.small)
        .glassCard()
        .sheet(isPresented: $isShowingAvatarPicker) {
            NavigationStack {
                AvatarPickerView(selectedAvatarAssetName: Binding(
                    get: { profile?.avatarAssetName },
                    set: { newValue in
                        updateProfile { $0.avatarAssetName = newValue }
                    }
                ))
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var avatarView: some View {
        Group {
            if let avatarAssetName = profile?.avatarAssetName, !avatarAssetName.isEmpty {
                ProfileAvatarImage(assetName: avatarAssetName, size: 104)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.canvasDark.opacity(0.98),
                                AppTheme.Colors.backgroundDark.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
            }
        }
    }

    private var profileEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Edit profile", subtitle: "Set the name and tone you want this journal to reflect.")

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Name or alias")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .tracking(1)

                profileField(
                    "Your name or alias",
                    text: Binding(get: {
                        profile?.displayName ?? ""
                    }, set: { newValue in
                        updateProfile { $0.displayName = newValue }
                    })
                )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Intention")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .tracking(1)

                profileField(
                    "What are you looking for?",
                    text: Binding(get: {
                        profile?.intention ?? ""
                    }, set: { newValue in
                        updateProfile { $0.intention = newValue }
                    })
                )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Bio")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .tracking(1)

                TextField(
                    "Short bio",
                    text: Binding(get: {
                        profile?.bio ?? ""
                    }, set: { newValue in
                        updateProfile { $0.bio = newValue }
                    }),
                    axis: .vertical
                )
                .lineLimit(4, reservesSpace: true)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, 14)
                .background(profileFieldBackground)
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accentSoft.opacity(0.62),
                            Color.white.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        }
        .glassCard()
    }

    private var reflectionJourney: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Archive snapshot", subtitle: "Tap a category to preview the entries inside it.")

            archiveStatGrid
        }
    }

    private var archiveStatGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
            statPreviewButton(
                title: "All Entries",
                subtitle: "\(entries.count) total entr\(entries.count == 1 ? "y" : "ies")",
                entries: entries,
                cardTitle: "Total Entries",
                cardValue: "\(entries.count)",
                symbolName: "book.pages.fill"
            )

            StatCard(title: "Most Used Tag", value: mostUsedTag, symbolName: "tag.fill")

            statPreviewButton(
                title: "Connections",
                subtitle: "\(totalConnections) saved connection\(totalConnections == 1 ? "" : "s")",
                entries: entries,
                cardTitle: "Total Connections",
                cardValue: "\(totalConnections)",
                symbolName: "person.2.fill"
            )

            statPreviewButton(
                title: "Hookups",
                subtitle: "\(totalHookups) hookup entr\(totalHookups == 1 ? "y" : "ies")",
                entries: entries.filter { $0.connectionType == .hookup },
                cardTitle: "Total Hookups",
                cardValue: "\(totalHookups)",
                symbolName: "flame.fill"
            )

            statPreviewButton(
                title: "Sexy Time",
                subtitle: "\(totalSexyTimes) sexy time entr\(totalSexyTimes == 1 ? "y" : "ies")",
                entries: entries.filter { $0.connectionType == .sexyTime },
                cardTitle: "Total Sexy Times",
                cardValue: "\(totalSexyTimes)",
                symbolName: "sparkles"
            )

            statPreviewButton(
                title: "Dates",
                subtitle: "\(totalDates) date entr\(totalDates == 1 ? "y" : "ies")",
                entries: entries.filter { $0.connectionType == .date },
                cardTitle: "Total Dates",
                cardValue: "\(totalDates)",
                symbolName: "calendar"
            )
        }
    }

    private func statPreviewButton(
        title: String,
        subtitle: String,
        entries: [JournalEntry],
        cardTitle: String,
        cardValue: String,
        symbolName: String
    ) -> some View {
        Button {
            selectedStatPreview = ProfileStatPreview(
                title: title,
                subtitle: subtitle,
                entries: entries
            )
        } label: {
            StatCard(title: cardTitle, value: cardValue, symbolName: symbolName)
        }
        .buttonStyle(.plain)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Unlocked milestones", subtitle: unlockedAchievements.isEmpty ? "Your first milestone will appear once you start logging entries." : "A few highlights from your archive so far.")

            if unlockedAchievements.isEmpty {
                EmptyStateCard(
                    title: "No milestones yet",
                    message: "Keep journaling and your wins will show up here.",
                    systemImage: "trophy"
                )
            } else {
                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(Array(unlockedAchievements.prefix(3))) { achievement in
                        HStack(spacing: AppTheme.Spacing.medium) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.Colors.accentSoft.opacity(0.92))
                                .frame(width: 58, height: 58)
                                .overlay {
                                    Image(systemName: achievement.symbolName)
                                        .foregroundStyle(AppTheme.Colors.plum)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.title)
                                    .font(AppTheme.Typography.cardTitle)
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                Text(achievement.subtitle)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "star.fill")
                                .foregroundStyle(AppTheme.Colors.gold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Settings", subtitle: "Privacy, appearance, and export now live here.")

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Toggle(
                    "App lock on open",
                    isOn: Binding(
                        get: { appSettings.isBiometricLockEnabled },
                        set: { newValue in
                            saveSettings {
                                $0.isBiometricLockEnabled = newValue
                            }
                            lockController.setAppLockEnabled(newValue)
                        }
                    )
                )

                Text("Uses Face ID or Touch ID when available.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .glassCard()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Appearance")
                    .font(AppTheme.Typography.sectionTitle)

                Picker(
                    "Theme",
                    selection: Binding(
                        get: { appSettings.themePreference },
                        set: { newValue in
                            saveSettings {
                                $0.themePreference = newValue
                            }
                        }
                    )
                ) {
                    ForEach(ThemePreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
            }
            .glassCard()

            preferenceSection

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Export")
                    .font(AppTheme.Typography.sectionTitle)

                Button("Prepare JSON + CSV Export") {
                    do {
                        exportPayload = try exportService.makeExport(entries: entries)
                        exportError = nil
                    } catch {
                        exportError = error.localizedDescription
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                if let exportPayload {
                    ShareLink("Share JSON Export", item: exportPayload.jsonURL)
                    ShareLink("Share CSV Export", item: exportPayload.csvURL)
                }

                if let exportError {
                    Text(exportError)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.warning)
                }
            }
            .glassCard()
        }
    }

    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Preferences")
                .font(AppTheme.Typography.sectionTitle)

            PreferenceStepperRow(
                title: "Attractive",
                valueText: "\(preferenceValue(\.preferredAttractiveRating))/10",
                value: profileIntBinding(\.preferredAttractiveRating),
                range: 1...10
            )

            PreferenceStepperRow(
                title: "Height",
                valueText: "\(preferenceValue(\.preferredHeightCentimeters)) cm",
                value: profileIntBinding(\.preferredHeightCentimeters),
                range: 120...230
            )

            PreferenceStepperRow(
                title: "Good body",
                valueText: "\(preferenceValue(\.preferredGoodBodyRating))/10",
                value: profileIntBinding(\.preferredGoodBodyRating),
                range: 1...10
            )

            PreferenceStepperRow(
                title: "Good face",
                valueText: "\(preferenceValue(\.preferredGoodFaceRating))/10",
                value: profileIntBinding(\.preferredGoodFaceRating),
                range: 1...10
            )

            PreferenceStepperRow(
                title: "Good kisser",
                valueText: "\(preferenceValue(\.preferredGoodKisserRating))/10",
                value: profileIntBinding(\.preferredGoodKisserRating),
                range: 1...10
            )

            PreferenceStepperRow(
                title: "Good head",
                valueText: "\(preferenceValue(\.preferredGoodHeadRating))/10",
                value: profileIntBinding(\.preferredGoodHeadRating),
                range: 1...10
            )

            PreferenceStepperRow(
                title: "Length",
                valueText: "\(preferenceValue(\.preferredLengthCentimeters)) cm",
                value: profileIntBinding(\.preferredLengthCentimeters),
                range: 0...30
            )
        }
        .glassCard()
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Support the project")

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Made with care by Geeniee")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text("This app was created as a hobby project by Geeniee. The intention was for the app to be completely free, but if you enjoy it and would like to support the creator, please consider buying them a coffee! ☕️")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Button("☕ Buy Me a Coffee") {
                    guard let url = URL(string: appSettings.buyMeACoffeeURL), !appSettings.buyMeACoffeeURL.isEmpty else { return }
                    openURL(url)
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Yoni Journal · Version 0.1.0")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accentSoft.opacity(0.90),
                                Color.white.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            }
        }
        .glassCard()
    }

    private func profileField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, 14)
            .background(profileFieldBackground)
    }

    private var profileFieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .fill(Color.white.opacity(0.56))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            }
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

    private func profileIntBinding(_ keyPath: ReferenceWritableKeyPath<UserProfile, Int>) -> Binding<Int> {
        Binding(
            get: {
                profile?[keyPath: keyPath] ?? UserProfile()[keyPath: keyPath]
            },
            set: { newValue in
                updateProfile { profile in
                    profile[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func preferenceValue(_ keyPath: KeyPath<UserProfile, Int>) -> Int {
        profile?[keyPath: keyPath] ?? UserProfile()[keyPath: keyPath]
    }

    private func saveSettings(_ mutate: (AppSettings) -> Void) {
        let target = settings.first ?? {
            let created = AppSettings()
            modelContext.insert(created)
            return created
        }()

        mutate(target)
        try? modelContext.save()
    }
}

private enum ProfileAvatarCatalog {
    static let all: [ProfileAvatarOption] = (1...11).map { index in
        ProfileAvatarOption(id: "profile-avatar-\(index)", assetName: "profile-avatar-\(index)")
    }
}

private struct ProfileAvatarOption: Identifiable, Hashable {
    let id: String
    let assetName: String
}

private struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAvatarAssetName: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.medium), count: 3)

    var body: some View {
        ScreenContainer(
            title: "Choose Avatar",
            subtitle: "Keep the default silhouette or pick one of the imported icons."
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Button {
                    selectedAvatarAssetName = nil
                    dismiss()
                } label: {
                    DefaultAvatarTile(isSelected: selectedAvatarAssetName == nil)
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.medium) {
                    ForEach(ProfileAvatarCatalog.all) { avatar in
                        Button {
                            selectedAvatarAssetName = avatar.assetName
                            dismiss()
                        } label: {
                            ProfileAvatarTile(
                                assetName: avatar.assetName,
                                isSelected: selectedAvatarAssetName == avatar.assetName
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Choose Avatar")
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

private struct DefaultAvatarTile: View {
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.canvasDark.opacity(0.98),
                            AppTheme.Colors.backgroundDark.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.white.opacity(0.82))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Default avatar")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                Text("Use the standard blank profile icon.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct ProfileAvatarImage: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
    }
}

private struct ProfileAvatarTile: View {
    let assetName: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ProfileAvatarImage(assetName: assetName, size: 78)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .padding(AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(isSelected ? AppTheme.Colors.accentSoft.opacity(0.55) : Color.white.opacity(0.14))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(isSelected ? AppTheme.Colors.accent.opacity(0.8) : Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct PreferenceStepperRow: View {
    let title: String
    let valueText: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(valueText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer(minLength: 0)

            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

private struct ProfileStatPreview: Identifiable {
    let title: String
    let subtitle: String
    let entries: [JournalEntry]

    var id: String { title }
}

private struct ProfileStatPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let preview: ProfileStatPreview

    var body: some View {
        ScreenContainer(
            title: preview.title,
            subtitle: preview.subtitle
        ) {
            if preview.entries.isEmpty {
                EmptyStateCard(
                    title: "No entries here yet",
                    message: "Once you log entries in this category, they’ll appear here.",
                    systemImage: "tray"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(preview.entries.sorted(by: { $0.entryDate > $1.entryDate })) { entry in
                            ProfilePreviewEntryCard(entry: entry)
                        }
                    }
                }
            }
        }
        .navigationTitle(preview.title)
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

private struct ProfilePreviewEntryCard: View {
    let entry: JournalEntry

    private var accentColor: Color {
        entry.isPlannedFutureEntry ? AppTheme.Colors.secondaryText : AppTheme.Colors.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                LotusRatingIcon(level: entry.rating, isSelected: true, showsValueLabel: false)
                    .frame(width: 64)
                    .opacity(entry.isPlannedFutureEntry ? 0.72 : 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.personNameOrAlias)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text(entry.entryDate.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Text(entry.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Text(entry.connectionType.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                entry.isPlannedFutureEntry
                                    ? Color.white.opacity(0.3)
                                    : AppTheme.Colors.accentSoft.opacity(0.88)
                            )
                    )

                if !entry.tags.isEmpty {
                    Text(entry.tags.prefix(2).joined(separator: " · "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .saturation(entry.isPlannedFutureEntry ? 0.45 : 1)
        .opacity(entry.isPlannedFutureEntry ? 0.86 : 1)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(PreviewContainer.makeShared())
    .environmentObject(AppLockController())
}

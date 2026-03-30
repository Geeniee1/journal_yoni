import PhotosUI
import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var personNameOrAlias = ""
    @State private var entryDate = Date.now
    @State private var connectionType: ConnectionType = .hookup
    @State private var mood: MoodOption = .tender
    @State private var rating = 4
    @State private var includeRating = true
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var tags: [String] = ["fun", "emotional"]
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingPhotoData: [Data] = []
    @State private var saveMessage: String?

    private let photoStorage = PhotoStorageService()
    private let presetTags = ["first time", "fun", "emotional", "complicated", "soft", "chemistry"]

    var body: some View {
        ScreenContainer(
            title: "Capture the Moment",
            subtitle: "Log the energy, the chemistry, and whatever you want to remember for yourself."
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                formCard
                notesCard
                actionsCard
            }
        }
        .navigationTitle("New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    pendingPhotoData.append(data)
                }
            }
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            TextField("Name or alias", text: $personNameOrAlias)
                .textFieldStyle(.roundedBorder)

            DatePicker("Date", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])

            Picker("Type", selection: $connectionType) {
                ForEach(ConnectionType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Mood")
                    .font(AppTheme.Typography.cardTitle)
                HStack {
                    ForEach(MoodOption.allCases) { option in
                        Button {
                            mood = option
                        } label: {
                            Text(option.emoji)
                                .font(.title3)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(option == mood ? AppTheme.Colors.accentSoft : Color.white.opacity(0.4))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle("Include rating", isOn: $includeRating.animation())
            if includeRating {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Rating: \(rating)/5")
                        .font(AppTheme.Typography.caption)
                    Slider(value: Binding(get: { Double(rating) }, set: { rating = Int($0.rounded()) }), in: 1...5, step: 1)
                        .tint(AppTheme.Colors.accent)
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Tags")
                .font(AppTheme.Typography.cardTitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    ForEach(presetTags, id: \.self) { tag in
                        Button {
                            addTag(tag)
                        } label: {
                            Text(tag.capitalized)
                                .font(AppTheme.Typography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AppTheme.Colors.accentSoft.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                TextField("Add a custom tag", text: $tagInput)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    addTag(tagInput)
                    tagInput = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
            }

            if !tags.isEmpty {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag.capitalized)
                            .font(AppTheme.Typography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppTheme.Colors.accentSoft))
                    }
                }
            }

            Text("Notes")
                .font(AppTheme.Typography.cardTitle)

            TextEditor(text: $notes)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                )

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Add Local Photo", systemImage: "photo.on.rectangle")
                    .font(AppTheme.Typography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .stroke(AppTheme.Colors.accent, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            if !pendingPhotoData.isEmpty {
                Text("\(pendingPhotoData.count) photo attachment\(pendingPhotoData.count == 1 ? "" : "s") prepared for local storage.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
        .glassCard()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Button {
                saveEntry()
            } label: {
                Text("Save Entry")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())

            if let saveMessage {
                Text(saveMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
        .glassCard()
    }

    private func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
    }

    private func saveEntry() {
        let entry = JournalEntry(
            entryDate: entryDate,
            personNameOrAlias: personNameOrAlias.isEmpty ? "Untitled Connection" : personNameOrAlias,
            connectionType: connectionType,
            mood: mood,
            rating: includeRating ? rating : nil,
            notes: notes.isEmpty ? "No notes yet." : notes,
            tags: tags
        )

        for data in pendingPhotoData {
            if let photo = try? photoStorage.saveImageData(data) {
                photo.entry = entry
                entry.photoItems.append(photo)
            }
        }

        modelContext.insert(entry)
        try? modelContext.save()
        saveMessage = "Saved locally on this device."
        personNameOrAlias = ""
        notes = ""
        tags = []
        pendingPhotoData = []
    }
}

#Preview {
    NavigationStack {
        EntryEditorView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

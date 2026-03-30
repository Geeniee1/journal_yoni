import PhotosUI
import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: JournalEntry?

    @State private var personNameOrAlias = ""
    @State private var entryDate = Date.now
    @State private var connectionType: ConnectionType = .hookup
    @State private var rating = 5
    @State private var notes = ""

    @State private var wouldMeetAgain = false
    @State private var goodKisser = false
    @State private var goodHead = false
    @State private var longDuration = false
    @State private var madeMeCum = false

    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var greenFlagInput = ""
    @State private var greenFlags: [String] = []
    @State private var redFlagInput = ""
    @State private var redFlags: [String] = []

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingPhotoData: [Data] = []
    @State private var saveMessage: String?
    @State private var hasLoadedEntry = false

    private let photoStorage = PhotoStorageService()
    private let presetTags = ["first time", "fun", "emotional", "complicated", "soft", "chemistry"]

    init(entry: JournalEntry? = nil) {
        self.entry = entry
    }

    private var isEditing: Bool {
        entry != nil
    }

    var body: some View {
        ScreenContainer(
            title: isEditing ? "Edit Entry" : "Capture the Moment",
            subtitle: isEditing
                ? "Update the details any time. The latest version is what your archive shows."
                : "Log the chemistry, the details, and the parts you want to remember for yourself."
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                basicsCard
                experienceCard
                notesAndFlagsCard
                actionsCard
            }
        }
        .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await SeedDataService.ensureSingletonsIfNeeded(modelContext: modelContext)
        }
        .onAppear {
            loadEntryIfNeeded()
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

    private var basicsCard: some View {
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
                Text("Tags")
                    .font(AppTheme.Typography.cardTitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        ForEach(presetTags, id: \.self) { tag in
                            Button {
                                addTag(tag, to: &tags)
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

                TagInputRow(
                    placeholder: "Add a tag",
                    input: $tagInput,
                    onAdd: {
                        addTag(tagInput, to: &tags)
                        tagInput = ""
                    }
                )

                if !tags.isEmpty {
                    EditableTagWrap(tags: tags) { tag in
                        remove(tag, from: &tags)
                    }
                }
            }
        }
        .glassCard()
    }

    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            LotusRatingPicker(rating: $rating)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Quick notes")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                ForEach(EntryBinaryPrompt.allCases) { prompt in
                    Toggle(isOn: binding(for: prompt)) {
                        Text(prompt.title)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                    }
                    .tint(.green)
                }
            }
        }
        .glassCard()
    }

    private var notesAndFlagsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
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

            FlagEditorSection(
                title: "Green flags",
                placeholder: "Add a green flag",
                input: $greenFlagInput,
                items: $greenFlags
            )

            FlagEditorSection(
                title: "Red flags",
                placeholder: "Add a red flag",
                input: $redFlagInput,
                items: $redFlags
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

            if isEditing, let entry, !entry.photoItems.isEmpty || !pendingPhotoData.isEmpty {
                Text("\(entry.photoItems.count + pendingPhotoData.count) photo attachment\(entry.photoItems.count + pendingPhotoData.count == 1 ? "" : "s") linked to this entry.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            } else if !pendingPhotoData.isEmpty {
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
                Text(isEditing ? "Save Changes" : "Save Entry")
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

    private func binding(for prompt: EntryBinaryPrompt) -> Binding<Bool> {
        switch prompt {
        case .wouldMeetAgain:
            $wouldMeetAgain
        case .goodKisser:
            $goodKisser
        case .goodHead:
            $goodHead
        case .longDuration:
            $longDuration
        case .madeMeCum:
            $madeMeCum
        }
    }

    private func loadEntryIfNeeded() {
        guard !hasLoadedEntry, let entry else { return }
        hasLoadedEntry = true
        personNameOrAlias = entry.personNameOrAlias
        entryDate = entry.entryDate
        connectionType = entry.connectionType
        rating = entry.rating
        notes = entry.notes == "No notes yet." ? "" : entry.notes
        tags = entry.tags
        wouldMeetAgain = entry.wouldMeetAgain
        goodKisser = entry.goodKisser
        goodHead = entry.goodHead
        longDuration = entry.longDuration
        madeMeCum = entry.madeMeCum
        greenFlags = entry.greenFlags
        redFlags = entry.redFlags
    }

    private func addTag(_ value: String, to items: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return }
        items.append(trimmed)
    }

    private func remove(_ value: String, from items: inout [String]) {
        items.removeAll { $0 == value }
    }

    private func saveEntry() {
        let normalizedName = personNameOrAlias.isEmpty ? "Untitled Connection" : personNameOrAlias
        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No notes yet." : notes

        let targetEntry: JournalEntry
        if let entry {
            targetEntry = entry
        } else {
            let createdEntry = JournalEntry(
                entryDate: entryDate,
                personNameOrAlias: normalizedName,
                connectionType: connectionType,
                rating: rating,
                notes: normalizedNotes,
                tags: tags,
                wouldMeetAgain: wouldMeetAgain,
                goodKisser: goodKisser,
                goodHead: goodHead,
                longDuration: longDuration,
                madeMeCum: madeMeCum,
                greenFlags: greenFlags,
                redFlags: redFlags
            )
            modelContext.insert(createdEntry)
            targetEntry = createdEntry
        }

        targetEntry.updatedAt = .now
        targetEntry.entryDate = entryDate
        targetEntry.personNameOrAlias = normalizedName
        targetEntry.connectionType = connectionType
        targetEntry.rating = rating
        targetEntry.notes = normalizedNotes
        targetEntry.tags = tags
        targetEntry.wouldMeetAgain = wouldMeetAgain
        targetEntry.goodKisser = goodKisser
        targetEntry.goodHead = goodHead
        targetEntry.longDuration = longDuration
        targetEntry.madeMeCum = madeMeCum
        targetEntry.greenFlags = greenFlags
        targetEntry.redFlags = redFlags

        for data in pendingPhotoData {
            if let photo = try? photoStorage.saveImageData(data) {
                photo.entry = targetEntry
                targetEntry.photoItems.append(photo)
            }
        }

        try? modelContext.save()

        if isEditing {
            dismiss()
        } else {
            saveMessage = "Saved locally on this device."
            personNameOrAlias = ""
            entryDate = .now
            connectionType = .hookup
            rating = 5
            notes = ""
            tags = []
            wouldMeetAgain = false
            goodKisser = false
            goodHead = false
            longDuration = false
            madeMeCum = false
            greenFlags = []
            redFlags = []
            pendingPhotoData = []
        }
    }
}

private struct TagInputRow: View {
    let placeholder: String
    @Binding var input: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            TextField(placeholder, text: $input)
                .textFieldStyle(.roundedBorder)

            Button("Add", action: onAdd)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
        }
    }
}

private struct FlagEditorSection: View {
    let title: String
    let placeholder: String
    @Binding var input: String
    @Binding var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.cardTitle)

            TagInputRow(
                placeholder: placeholder,
                input: $input,
                onAdd: {
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !items.contains(trimmed) else { return }
                    items.append(trimmed)
                    input = ""
                }
            )

            if !items.isEmpty {
                EditableTagWrap(tags: items) { tag in
                    items.removeAll { $0 == tag }
                }
            }
        }
    }
}

private struct EditableTagWrap: View {
    let tags: [String]
    let onRemove: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag.capitalized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Button {
                            onRemove(tag)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.Colors.accentSoft.opacity(0.84)))
                }
            }
        }
    }
}

#Preview("New Entry") {
    NavigationStack {
        EntryEditorView()
    }
    .modelContainer(PreviewContainer.makeShared())
}

#Preview("Edit Entry") {
    NavigationStack {
        EntryEditorView(entry: SampleEntries.make().first)
    }
    .modelContainer(PreviewContainer.makeShared())
}

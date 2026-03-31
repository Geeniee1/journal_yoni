import AVFoundation
import PhotosUI
import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: JournalEntry?
    let prefilledPersonName: String?
    let prefilledEntryDate: Date?
    let prefilledConnectionType: ConnectionType?
    let dismissAfterSave: Bool

    @State private var personNameOrAlias = ""
    @State private var entryDate = Date.now
    @State private var connectionType: ConnectionType = .hookup
    @State private var rating = 5
    @State private var notes = ""

    @State private var wouldMeetAgain = false
    @State private var attractive = false
    @State private var attractiveRating = 5
    @State private var tall = false
    @State private var heightCentimeters = 170
    @State private var goodBody = false
    @State private var goodBodyRating = 5
    @State private var goodFace = false
    @State private var goodFaceRating = 5
    @State private var goodKisser = false
    @State private var goodKisserRating = 5
    @State private var goodHead = false
    @State private var goodHeadRating = 5
    @State private var longDuration = false
    @State private var lengthCentimeters = 15
    @State private var madeMeCum = false

    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var greenFlagInput = ""
    @State private var greenFlags: [String] = []
    @State private var redFlagInput = ""
    @State private var redFlags: [String] = []
    @State private var selectedPositionIDs: Set<String> = []

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingPhotoData: [Data] = []
    @State private var hasLoadedEntry = false
    @State private var isShowingSaveCelebration = false
    @State private var isSaveButtonCelebrating = false
    @State private var existingVoiceMemoFileName: String?
    @State private var existingVoiceMemoDuration: Double?
    @State private var voiceMemoMarkedForDeletion = false
    @StateObject private var voiceMemoController = VoiceMemoRecorder()

    private let photoStorage = PhotoStorageService()
    private let audioMemoStorage = AudioMemoStorageService()

    init(
        entry: JournalEntry? = nil,
        prefilledPersonName: String? = nil,
        prefilledEntryDate: Date? = nil,
        prefilledConnectionType: ConnectionType? = nil,
        dismissAfterSave: Bool = false
    ) {
        self.entry = entry
        self.prefilledPersonName = prefilledPersonName
        self.prefilledEntryDate = prefilledEntryDate
        self.prefilledConnectionType = prefilledConnectionType
        self.dismissAfterSave = dismissAfterSave
        self._personNameOrAlias = State(initialValue: entry?.personNameOrAlias ?? prefilledPersonName ?? "")
        self._entryDate = State(initialValue: entry?.entryDate ?? prefilledEntryDate ?? .now)
        self._connectionType = State(initialValue: entry?.connectionType ?? prefilledConnectionType ?? .hookup)
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
                if isShowingSaveCelebration && !isEditing {
                    SaveConfirmationBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                basicsCard
                experienceCard
                positionsCard
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
        .onDisappear {
            voiceMemoController.discardTemporaryRecording()
        }
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            TextField("Name or alias", text: $personNameOrAlias)
                .textFieldStyle(.roundedBorder)

            DatePicker(
                connectionType == .future ? "Planned date" : "Date",
                selection: $entryDate,
                displayedComponents: [.date, .hourAndMinute]
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Type")
                    .font(AppTheme.Typography.cardTitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        ForEach(ConnectionType.editorCases) { type in
                            Button {
                                connectionType = type
                            } label: {
                                Text(type.title)
                                    .font(AppTheme.Typography.caption.weight(.semibold))
                                    .foregroundStyle(
                                        connectionType == type
                                            ? Color.white
                                            : AppTheme.Colors.primaryText
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(
                                                connectionType == type
                                                    ? AppTheme.Colors.accent
                                                    : Color.white.opacity(0.42)
                                            )
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .stroke(
                                                connectionType == type
                                                    ? AppTheme.Colors.accent.opacity(0.92)
                                                    : Color.white.opacity(0.45),
                                                lineWidth: 1
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if connectionType == .future {
                Label("Planned entries stay softer in the archive until the moment actually happens.", systemImage: "clock.badge")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Tags")
                    .font(AppTheme.Typography.cardTitle)

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

                quickNotesContent
            }
        }
        .glassCard()
    }

    private var quickNotesContent: some View {
        Group {
            QuickToggleRow(title: "Would meet again", isOn: $wouldMeetAgain)
            QuickToggleRatingRow(title: "Attractive", isOn: $attractive, rating: $attractiveRating)
            QuickToggleMeasurementRow(
                title: "Tall",
                isOn: $tall,
                value: $heightCentimeters,
                range: 120...230,
                unit: "cm"
            )
            QuickToggleRatingRow(title: "Good body", isOn: $goodBody, rating: $goodBodyRating)
            QuickToggleRatingRow(title: "Good face", isOn: $goodFace, rating: $goodFaceRating)
            QuickToggleRatingRow(title: "Good kisser", isOn: $goodKisser, rating: $goodKisserRating)
            QuickToggleRatingRow(title: "Good head", isOn: $goodHead, rating: $goodHeadRating)
            QuickToggleMeasurementRow(
                title: "Long",
                isOn: $longDuration,
                value: $lengthCentimeters,
                range: 0...30,
                unit: "cm"
            )
            QuickToggleRow(title: "Made me cum", isOn: $madeMeCum)
        }
    }

    private var notesAndFlagsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Notes")
                .font(AppTheme.Typography.cardTitle)

            voiceMemoSection

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

    private var voiceMemoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Voice memo")
                    .font(AppTheme.Typography.cardTitle)
                Spacer()
                if let duration = voiceMemoController.currentDuration {
                    Text(formattedDuration(duration))
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }

            Text("Record privately with your microphone instead of typing everything by hand. The memo stays on this device.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            HStack(spacing: AppTheme.Spacing.small) {
                Button {
                    if voiceMemoController.isRecording {
                        voiceMemoController.stopRecording()
                    } else {
                        voiceMemoController.startRecording(storage: audioMemoStorage)
                    }
                } label: {
                    Label(
                        voiceMemoController.isRecording ? "Stop Recording" : (voiceMemoController.hasMemo ? "Record Again" : "Record Voice Memo"),
                        systemImage: voiceMemoController.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    voiceMemoController.togglePlayback()
                } label: {
                    Label(voiceMemoController.isPlaying ? "Pause" : "Play", systemImage: voiceMemoController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.Colors.accent)
                .disabled(!voiceMemoController.hasMemo || voiceMemoController.isRecording)
            }

            if voiceMemoController.hasMemo {
                HStack {
                    Text(voiceMemoController.isRecording ? "Recording now…" : "Voice memo attached")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Spacer()

                    Button(role: .destructive) {
                        voiceMemoMarkedForDeletion = existingVoiceMemoFileName != nil
                        voiceMemoController.clearMemo()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                }
            }

            if let errorMessage = voiceMemoController.errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
            }
        }
    }

    private var positionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(
                "Positions",
                subtitle: selectedPositionIDs.isEmpty
                    ? "Select any positions you want to remember from this entry."
                    : "\(selectedPositionIDs.count) selected"
            )

            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 3),
                    spacing: AppTheme.Spacing.small
                ) {
                    ForEach(PositionCatalog.all) { position in
                        Button {
                            togglePosition(position.id)
                        } label: {
                            PositionSelectionTile(
                                position: position,
                                isSelected: selectedPositionIDs.contains(position.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 320)
            .padding(.trailing, 4)
        }
        .glassCard()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Button {
                saveEntry()
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: isSaveButtonCelebrating ? "checkmark.circle.fill" : "sparkles")
                        .font(.system(size: 17, weight: .bold))

                    Text(isSaveButtonCelebrating ? "Saved" : (isEditing ? "Save Changes" : "Save Entry"))
                }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(SaveEntryButtonStyle(isCelebrating: isSaveButtonCelebrating))
            .disabled(isSaveButtonCelebrating)
        }
        .glassCard()
    }

    private func loadEntryIfNeeded() {
        guard !hasLoadedEntry else { return }
        hasLoadedEntry = true

        guard let entry else {
            if personNameOrAlias.isEmpty, let prefilledPersonName {
                personNameOrAlias = prefilledPersonName
            }
            if let prefilledEntryDate {
                entryDate = prefilledEntryDate
            }
            if let prefilledConnectionType {
                connectionType = prefilledConnectionType
            }
            return
        }

        personNameOrAlias = entry.personNameOrAlias
        entryDate = entry.entryDate
        connectionType = entry.connectionType
        rating = entry.rating
        notes = entry.notes == "No notes yet." ? "" : entry.notes
        tags = entry.tags
        wouldMeetAgain = entry.wouldMeetAgain
        attractive = entry.attractive
        attractiveRating = entry.attractiveRating
        tall = entry.tall
        heightCentimeters = entry.heightCentimeters ?? 170
        goodBody = entry.goodBody
        goodBodyRating = entry.goodBodyRating
        goodFace = entry.goodFace
        goodFaceRating = entry.goodFaceRating
        goodKisser = entry.goodKisser
        goodKisserRating = entry.goodKisserRating
        goodHead = entry.goodHead
        goodHeadRating = entry.goodHeadRating
        longDuration = entry.longDuration
        lengthCentimeters = entry.lengthCentimeters ?? 15
        madeMeCum = entry.madeMeCum
        greenFlags = entry.greenFlags
        redFlags = entry.redFlags
        selectedPositionIDs = Set(entry.positionIDs)
        existingVoiceMemoFileName = entry.voiceMemoFileName
        existingVoiceMemoDuration = entry.voiceMemoDuration
        voiceMemoMarkedForDeletion = false
        if let fileName = entry.voiceMemoFileName {
            voiceMemoController.loadExistingMemo(
                url: audioMemoStorage.audioURL(for: fileName),
                duration: entry.voiceMemoDuration
            )
        } else {
            voiceMemoController.clearMemo()
        }
    }

    private func addTag(_ value: String, to items: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return }
        items.append(trimmed)
    }

    private func remove(_ value: String, from items: inout [String]) {
        items.removeAll { $0 == value }
    }

    private func togglePosition(_ id: String) {
        if selectedPositionIDs.contains(id) {
            selectedPositionIDs.remove(id)
        } else {
            selectedPositionIDs.insert(id)
        }
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
                attractive: attractive,
                attractiveRating: attractiveRating,
                tall: tall,
                heightCentimeters: tall ? heightCentimeters : nil,
                goodBody: goodBody,
                goodBodyRating: goodBodyRating,
                goodFace: goodFace,
                goodFaceRating: goodFaceRating,
                goodKisser: goodKisser,
                goodKisserRating: goodKisserRating,
                goodHead: goodHead,
                goodHeadRating: goodHeadRating,
                longDuration: longDuration,
                lengthCentimeters: longDuration ? lengthCentimeters : nil,
                madeMeCum: madeMeCum,
                greenFlags: greenFlags,
                redFlags: redFlags,
                positionIDs: Array(selectedPositionIDs).sorted()
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
        targetEntry.attractive = attractive
        targetEntry.attractiveRating = attractiveRating
        targetEntry.tall = tall
        targetEntry.heightCentimeters = tall ? heightCentimeters : nil
        targetEntry.goodBody = goodBody
        targetEntry.goodBodyRating = goodBodyRating
        targetEntry.goodFace = goodFace
        targetEntry.goodFaceRating = goodFaceRating
        targetEntry.goodKisser = goodKisser
        targetEntry.goodKisserRating = goodKisserRating
        targetEntry.goodHead = goodHead
        targetEntry.goodHeadRating = goodHeadRating
        targetEntry.longDuration = longDuration
        targetEntry.lengthCentimeters = longDuration ? lengthCentimeters : nil
        targetEntry.madeMeCum = madeMeCum
        targetEntry.greenFlags = greenFlags
        targetEntry.redFlags = redFlags
        targetEntry.positionIDs = Array(selectedPositionIDs).sorted()

        if voiceMemoController.hasTemporaryRecording,
           let temporaryURL = voiceMemoController.temporaryRecordingURL {
            if let existingVoiceMemoFileName {
                audioMemoStorage.delete(fileName: existingVoiceMemoFileName)
            }
            if let persistedFileName = try? audioMemoStorage.persistRecording(from: temporaryURL) {
                targetEntry.voiceMemoFileName = persistedFileName
                targetEntry.voiceMemoDuration = voiceMemoController.currentDuration
                existingVoiceMemoFileName = persistedFileName
                existingVoiceMemoDuration = voiceMemoController.currentDuration
                voiceMemoMarkedForDeletion = false
                voiceMemoController.promoteTemporaryMemo(
                    to: audioMemoStorage.audioURL(for: persistedFileName),
                    duration: voiceMemoController.currentDuration
                )
            }
        } else if voiceMemoMarkedForDeletion {
            if let existingVoiceMemoFileName {
                audioMemoStorage.delete(fileName: existingVoiceMemoFileName)
            }
            targetEntry.voiceMemoFileName = nil
            targetEntry.voiceMemoDuration = nil
            existingVoiceMemoFileName = nil
            existingVoiceMemoDuration = nil
            voiceMemoMarkedForDeletion = false
        } else {
            targetEntry.voiceMemoFileName = existingVoiceMemoFileName
            targetEntry.voiceMemoDuration = existingVoiceMemoDuration
        }

        for data in pendingPhotoData {
            if let photo = try? photoStorage.saveImageData(data) {
                photo.entry = targetEntry
                targetEntry.photoItems.append(photo)
            }
        }

        persistPositionUnlocks()

        try? modelContext.save()

        if isEditing || dismissAfterSave {
            dismiss()
        } else {
            resetForFreshEntry()
            celebrateSuccessfulSave()
        }
    }

    private func persistPositionUnlocks() {
        let existingUnlocks = (try? modelContext.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        let existingIDs = Set(existingUnlocks.map(\.achievementID))

        for position in PositionCatalog.all where selectedPositionIDs.contains(position.id) {
            guard !existingIDs.contains(position.achievementID) else { continue }
            modelContext.insert(AchievementUnlock(achievementID: position.achievementID))
        }
    }

    private func resetForFreshEntry() {
        personNameOrAlias = ""
        entryDate = .now
        connectionType = .hookup
        rating = 5
        notes = ""
        tagInput = ""
        tags = []
        wouldMeetAgain = false
        attractive = false
        attractiveRating = 5
        tall = false
        heightCentimeters = 170
        goodBody = false
        goodBodyRating = 5
        goodFace = false
        goodFaceRating = 5
        goodKisser = false
        goodKisserRating = 5
        goodHead = false
        goodHeadRating = 5
        longDuration = false
        lengthCentimeters = 15
        madeMeCum = false
        greenFlagInput = ""
        greenFlags = []
        redFlagInput = ""
        redFlags = []
        selectedPositionIDs = []
        selectedPhotoItem = nil
        pendingPhotoData = []
        existingVoiceMemoFileName = nil
        existingVoiceMemoDuration = nil
        voiceMemoMarkedForDeletion = false
        voiceMemoController.clearMemo()
    }

    private func celebrateSuccessfulSave() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
            isSaveButtonCelebrating = true
            isShowingSaveCelebration = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.8))
            await MainActor.run {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isSaveButtonCelebrating = false
                    isShowingSaveCelebration = false
                }
            }
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: duration) ?? "0:00"
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
                        Text(tag)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Button {
                            onRemove(tag)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.secondaryText.opacity(0.85))
                                .frame(width: 14, height: 14)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.32))
                                )
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

private struct QuickToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
        .tint(.green)
    }
}

private struct QuickToggleRatingRow: View {
    let title: String
    @Binding var isOn: Bool
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            QuickToggleRow(title: title, isOn: $isOn)

            if isOn {
                QuickScaleSelector(value: $rating)
                    .padding(.leading, 4)
            }
        }
    }
}

private struct QuickToggleMeasurementRow: View {
    let title: String
    @Binding var isOn: Bool
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            QuickToggleRow(title: title, isOn: $isOn)

            if isOn {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text("\(value) \(unit)")
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.Colors.accentSoft.opacity(0.72))
                        )

                    Stepper("", value: $value, in: range)
                        .labelsHidden()
                }
                .padding(.leading, 4)
            }
        }
    }
}

private struct QuickScaleSelector: View {
    @Binding var value: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { level in
                    Button {
                        value = level
                    } label: {
                        Text("\(level)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(value == level ? Color.white : AppTheme.Colors.primaryText)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(value == level ? AppTheme.Colors.accent : Color.white.opacity(0.46))
                            )
                            .overlay {
                                Circle()
                                    .stroke(value == level ? AppTheme.Colors.accent : Color.white.opacity(0.32), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PositionSelectionTile: View {
    let position: PositionDefinition
    let isSelected: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: position.symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AppTheme.Colors.accentSoft.opacity(0.95) : Color.white.opacity(0.16))
                )

            Text(position.name)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(isSelected ? AppTheme.Colors.accentSoft.opacity(0.55) : Color.white.opacity(0.1))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(isSelected ? AppTheme.Colors.accent.opacity(0.75) : Color.white.opacity(0.22), lineWidth: 1)
        }
        .saturation(isSelected ? 1 : 0)
    }
}

private struct SaveEntryButtonStyle: ButtonStyle {
    let isCelebrating: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.large)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isCelebrating
                                ? [
                                    Color(red: 0.988, green: 0.573, blue: 0.694),
                                    Color(red: 0.979, green: 0.723, blue: 0.451),
                                    Color(red: 0.663, green: 0.513, blue: 0.971),
                                    Color(red: 0.412, green: 0.760, blue: 0.980)
                                ]
                                : [AppTheme.Colors.accent, AppTheme.Colors.accentBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(configuration.isPressed ? 0.84 : 1)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(isCelebrating ? 0.9 : 0.18), lineWidth: isCelebrating ? 1.6 : 0)
                    .blur(radius: isCelebrating ? 0.2 : 0)
            }
            .shadow(
                color: (isCelebrating ? Color(red: 0.663, green: 0.513, blue: 0.971) : AppTheme.Colors.accent)
                    .opacity(isCelebrating ? 0.42 : 0.28),
                radius: isCelebrating ? 24 : 16,
                x: 0,
                y: isCelebrating ? 14 : 12
            )
            .scaleEffect(configuration.isPressed ? 0.98 : (isCelebrating ? 1.01 : 1))
            .animation(.smooth(duration: 0.2), value: configuration.isPressed)
            .animation(.spring(response: 0.34, dampingFraction: 0.76), value: isCelebrating)
    }
}

private struct SaveConfirmationBanner: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Entry saved")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(.white)

                Text("Fresh page ready for your next story.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.988, green: 0.573, blue: 0.694),
                            Color(red: 0.663, green: 0.513, blue: 0.971),
                            Color(red: 0.412, green: 0.760, blue: 0.980)
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
        .shadow(color: AppTheme.Colors.accent.opacity(0.28), radius: 24, x: 0, y: 14)
    }
}

@MainActor
final class VoiceMemoRecorder: NSObject, ObservableObject, @preconcurrency AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentDuration: TimeInterval?
    @Published var errorMessage: String?

    private(set) var temporaryRecordingURL: URL?

    var hasMemo: Bool {
        currentURL != nil
    }

    var hasTemporaryRecording: Bool {
        temporaryRecordingURL != nil
    }

    private var currentURL: URL?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    func loadExistingMemo(url: URL, duration: TimeInterval?) {
        stopPlayback()
        stopRecording()
        currentURL = url
        currentDuration = duration
        errorMessage = nil
    }

    func startRecording(storage: AudioMemoStorageService) {
        stopPlayback()
        errorMessage = nil

        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.errorMessage = "Microphone access is required to record a local voice memo."
                    return
                }
                self.beginRecording(storage: storage)
            }
        }
    }

    func stopRecording() {
        guard let recorder else { return }
        recorder.stop()
        currentDuration = recorder.currentTime
        self.recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func togglePlayback() {
        isPlaying ? stopPlayback() : startPlayback()
    }

    func clearMemo() {
        stopPlayback()
        stopRecording()
        discardTemporaryRecording()
        currentURL = nil
        currentDuration = nil
        errorMessage = nil
    }

    func discardTemporaryRecording() {
        if isRecording {
            stopRecording()
        }

        guard let temporaryRecordingURL else { return }
        try? FileManager.default.removeItem(at: temporaryRecordingURL)
        if currentURL == temporaryRecordingURL {
            currentURL = nil
            currentDuration = nil
        }
        self.temporaryRecordingURL = nil
    }

    func promoteTemporaryMemo(to url: URL, duration: TimeInterval?) {
        if let temporaryRecordingURL {
            try? FileManager.default.removeItem(at: temporaryRecordingURL)
        }
        temporaryRecordingURL = nil
        currentURL = url
        currentDuration = duration
        errorMessage = nil
    }

    private func beginRecording(storage: AudioMemoStorageService) {
        discardTemporaryRecording()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = storage.temporaryRecordingURL()
            let recorder = try AVAudioRecorder(
                url: url,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12_000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
            )

            recorder.record()
            self.recorder = recorder
            temporaryRecordingURL = url
            currentURL = url
            currentDuration = 0
            isRecording = true
        } catch {
            errorMessage = "Could not start recording. Please try again."
        }
    }

    private func startPlayback() {
        guard let currentURL else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: currentURL)
            player.delegate = self
            player.play()
            self.player = player
            isPlaying = true
        } catch {
            errorMessage = "Could not play this voice memo."
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        self.player = nil
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

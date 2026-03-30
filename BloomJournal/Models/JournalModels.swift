import Foundation
import SwiftUI
import SwiftData

enum ConnectionType: String, Codable, CaseIterable, Identifiable {
    case hookup
    case date
    case ongoing
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hookup: "Hookup"
        case .date: "Date"
        case .ongoing: "Ongoing"
        case .other: "Other"
        }
    }
}

enum ThemePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Auto"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum MoodOption: String, Codable, CaseIterable, Identifiable {
    case dreamy
    case playful
    case tender
    case electric
    case grounded
    case complicated

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .dreamy: "✨"
        case .playful: "😏"
        case .tender: "💗"
        case .electric: "🔥"
        case .grounded: "🌿"
        case .complicated: "🌀"
        }
    }

    var title: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .dreamy: "sparkles"
        case .playful: "smiley"
        case .tender: "heart.fill"
        case .electric: "bolt.fill"
        case .grounded: "leaf.fill"
        case .complicated: "swirl.circle.righthalf.filled"
        }
    }
}

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var entryDate: Date
    var personNameOrAlias: String
    var connectionType: ConnectionType
    var mood: MoodOption
    var rating: Int?
    var notes: String
    var tags: [String]

    @Relationship(deleteRule: .cascade, inverse: \EntryPhoto.entry)
    var photoItems: [EntryPhoto]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        entryDate: Date = .now,
        personNameOrAlias: String,
        connectionType: ConnectionType,
        mood: MoodOption,
        rating: Int? = nil,
        notes: String,
        tags: [String] = [],
        photoItems: [EntryPhoto] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entryDate = entryDate
        self.personNameOrAlias = personNameOrAlias
        self.connectionType = connectionType
        self.mood = mood
        self.rating = rating
        self.notes = notes
        self.tags = tags
        self.photoItems = photoItems
    }
}

@Model
final class EntryPhoto {
    @Attribute(.unique) var id: UUID
    var localFileName: String
    var createdAt: Date
    var entry: JournalEntry?

    init(
        id: UUID = UUID(),
        localFileName: String,
        createdAt: Date = .now,
        entry: JournalEntry? = nil
    ) {
        self.id = id
        self.localFileName = localFileName
        self.createdAt = createdAt
        self.entry = entry
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var bio: String
    var intention: String

    init(
        id: UUID = UUID(),
        displayName: String = "",
        bio: String = "",
        intention: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.intention = intention
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var isBiometricLockEnabled: Bool
    var themePreferenceRawValue: String
    var buyMeACoffeeURL: String

    var themePreference: ThemePreference {
        get { ThemePreference(rawValue: themePreferenceRawValue) ?? .system }
        set { themePreferenceRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        isBiometricLockEnabled: Bool = false,
        themePreference: ThemePreference = .system,
        buyMeACoffeeURL: String = ""
    ) {
        self.id = id
        self.isBiometricLockEnabled = isBiometricLockEnabled
        self.themePreferenceRawValue = themePreference.rawValue
        self.buyMeACoffeeURL = buyMeACoffeeURL
    }
}

@Model
final class AchievementUnlock {
    @Attribute(.unique) var id: UUID
    var achievementID: String
    var unlockedAt: Date

    init(id: UUID = UUID(), achievementID: String, unlockedAt: Date = .now) {
        self.id = id
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}

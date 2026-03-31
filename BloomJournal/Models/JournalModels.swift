import Foundation
import SwiftUI
import SwiftData

enum EntryBinaryPrompt: String, Codable, CaseIterable, Identifiable {
    case wouldMeetAgain
    case attractive
    case tall
    case goodBody
    case goodFace
    case goodKisser
    case goodHead
    case longDuration
    case madeMeCum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wouldMeetAgain: "Would meet again"
        case .attractive: "Attractive"
        case .tall: "Tall"
        case .goodBody: "Good body"
        case .goodFace: "Good face"
        case .goodKisser: "Good kisser"
        case .goodHead: "Good head"
        case .longDuration: "Long"
        case .madeMeCum: "Made me cum"
        }
    }
}

enum ConnectionType: String, Codable, CaseIterable, Identifiable {
    case hookup
    case date
    case sexyTime
    case future
    case ongoing
    case other

    var id: String { rawValue }

    static var editorCases: [ConnectionType] {
        [.hookup, .date, .sexyTime, .future]
    }

    var title: String {
        switch self {
        case .hookup: "Hookup"
        case .date: "Date"
        case .sexyTime: "Sexy Time"
        case .future: "Future"
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

enum YoniJournalSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            JournalEntry.self,
            EntryPhoto.self,
            UserProfile.self,
            AppSettings.self,
            AchievementUnlock.self
        ]
    }

    @Model
    final class JournalEntry {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var updatedAt: Date
        var entryDate: Date
        var personNameOrAlias: String
        var connectionType: ConnectionType
        var rating: Int
        var notes: String
        var tags: [String]
        var wouldMeetAgain: Bool
        var goodKisser: Bool
        var goodHead: Bool
        var longDuration: Bool
        var madeMeCum: Bool
        var greenFlags: [String]
        var redFlags: [String]

        @Relationship(deleteRule: .cascade, inverse: \EntryPhoto.entry)
        var photoItems: [EntryPhoto]

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            updatedAt: Date = .now,
            entryDate: Date = .now,
            personNameOrAlias: String,
            connectionType: ConnectionType,
            rating: Int = 5,
            notes: String,
            tags: [String] = [],
            wouldMeetAgain: Bool = false,
            goodKisser: Bool = false,
            goodHead: Bool = false,
            longDuration: Bool = false,
            madeMeCum: Bool = false,
            greenFlags: [String] = [],
            redFlags: [String] = [],
            photoItems: [EntryPhoto] = []
        ) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.entryDate = entryDate
            self.personNameOrAlias = personNameOrAlias
            self.connectionType = connectionType
            self.rating = rating
            self.notes = notes
            self.tags = tags
            self.wouldMeetAgain = wouldMeetAgain
            self.goodKisser = goodKisser
            self.goodHead = goodHead
            self.longDuration = longDuration
            self.madeMeCum = madeMeCum
            self.greenFlags = greenFlags
            self.redFlags = redFlags
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

        init(
            id: UUID = UUID(),
            isBiometricLockEnabled: Bool = false,
            themePreferenceRawValue: String = ThemePreference.system.rawValue,
            buyMeACoffeeURL: String = ""
        ) {
            self.id = id
            self.isBiometricLockEnabled = isBiometricLockEnabled
            self.themePreferenceRawValue = themePreferenceRawValue
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
}

enum YoniJournalSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            JournalEntry.self,
            EntryPhoto.self,
            UserProfile.self,
            AppSettings.self,
            AchievementUnlock.self
        ]
    }

    @Model
    final class JournalEntry {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var updatedAt: Date
        var entryDate: Date
        var personNameOrAlias: String
        var connectionType: ConnectionType
        var rating: Int
        var notes: String
        var tags: [String]
        var wouldMeetAgain: Bool
        var goodKisser: Bool
        var goodHead: Bool
        var longDuration: Bool
        var madeMeCum: Bool
        var greenFlags: [String]
        var redFlags: [String]
        var positionIDs: [String]

        @Relationship(deleteRule: .cascade, inverse: \EntryPhoto.entry)
        var photoItems: [EntryPhoto]

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            updatedAt: Date = .now,
            entryDate: Date = .now,
            personNameOrAlias: String,
            connectionType: ConnectionType,
            rating: Int = 5,
            notes: String,
            tags: [String] = [],
            wouldMeetAgain: Bool = false,
            goodKisser: Bool = false,
            goodHead: Bool = false,
            longDuration: Bool = false,
            madeMeCum: Bool = false,
            greenFlags: [String] = [],
            redFlags: [String] = [],
            positionIDs: [String] = [],
            photoItems: [EntryPhoto] = []
        ) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.entryDate = entryDate
            self.personNameOrAlias = personNameOrAlias
            self.connectionType = connectionType
            self.rating = rating
            self.notes = notes
            self.tags = tags
            self.wouldMeetAgain = wouldMeetAgain
            self.goodKisser = goodKisser
            self.goodHead = goodHead
            self.longDuration = longDuration
            self.madeMeCum = madeMeCum
            self.greenFlags = greenFlags
            self.redFlags = redFlags
            self.positionIDs = positionIDs
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

        init(
            id: UUID = UUID(),
            isBiometricLockEnabled: Bool = false,
            themePreferenceRawValue: String = ThemePreference.system.rawValue,
            buyMeACoffeeURL: String = ""
        ) {
            self.id = id
            self.isBiometricLockEnabled = isBiometricLockEnabled
            self.themePreferenceRawValue = themePreferenceRawValue
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
}

enum YoniJournalSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            JournalEntry.self,
            EntryPhoto.self,
            UserProfile.self,
            AppSettings.self,
            AchievementUnlock.self
        ]
    }

    @Model
    final class JournalEntry {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var updatedAt: Date
        var entryDate: Date
        var personNameOrAlias: String
        var connectionType: ConnectionType
        var rating: Int
        var notes: String
        var tags: [String]
        var wouldMeetAgain: Bool
        var goodKisser: Bool
        var goodHead: Bool
        var longDuration: Bool
        var madeMeCum: Bool
        var greenFlags: [String]
        var redFlags: [String]
        var positionIDs: [String]

        @Relationship(deleteRule: .cascade, inverse: \EntryPhoto.entry)
        var photoItems: [EntryPhoto]

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            updatedAt: Date = .now,
            entryDate: Date = .now,
            personNameOrAlias: String,
            connectionType: ConnectionType,
            rating: Int = 5,
            notes: String,
            tags: [String] = [],
            wouldMeetAgain: Bool = false,
            goodKisser: Bool = false,
            goodHead: Bool = false,
            longDuration: Bool = false,
            madeMeCum: Bool = false,
            greenFlags: [String] = [],
            redFlags: [String] = [],
            positionIDs: [String] = [],
            photoItems: [EntryPhoto] = []
        ) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.entryDate = entryDate
            self.personNameOrAlias = personNameOrAlias
            self.connectionType = connectionType
            self.rating = rating
            self.notes = notes
            self.tags = tags
            self.wouldMeetAgain = wouldMeetAgain
            self.goodKisser = goodKisser
            self.goodHead = goodHead
            self.longDuration = longDuration
            self.madeMeCum = madeMeCum
            self.greenFlags = greenFlags
            self.redFlags = redFlags
            self.positionIDs = positionIDs
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
        var avatarAssetName: String?

        init(
            id: UUID = UUID(),
            displayName: String = "",
            bio: String = "",
            intention: String = "",
            avatarAssetName: String? = nil
        ) {
            self.id = id
            self.displayName = displayName
            self.bio = bio
            self.intention = intention
            self.avatarAssetName = avatarAssetName
        }
    }

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: UUID
        var isBiometricLockEnabled: Bool
        var themePreferenceRawValue: String
        var buyMeACoffeeURL: String

        init(
            id: UUID = UUID(),
            isBiometricLockEnabled: Bool = false,
            themePreferenceRawValue: String = ThemePreference.system.rawValue,
            buyMeACoffeeURL: String = ""
        ) {
            self.id = id
            self.isBiometricLockEnabled = isBiometricLockEnabled
            self.themePreferenceRawValue = themePreferenceRawValue
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
}

enum YoniJournalSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(4, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            JournalEntry.self,
            EntryPhoto.self,
            UserProfile.self,
            AppSettings.self,
            AchievementUnlock.self
        ]
    }
}

enum YoniJournalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            YoniJournalSchemaV1.self,
            YoniJournalSchemaV2.self,
            YoniJournalSchemaV3.self,
            YoniJournalSchemaV4.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: YoniJournalSchemaV1.self, toVersion: YoniJournalSchemaV2.self),
            .lightweight(fromVersion: YoniJournalSchemaV2.self, toVersion: YoniJournalSchemaV3.self),
            .lightweight(fromVersion: YoniJournalSchemaV3.self, toVersion: YoniJournalSchemaV4.self)
        ]
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
    var rating: Int
    var notes: String
    var tags: [String]
    var wouldMeetAgain: Bool
    var attractive: Bool
    var attractiveRating: Int
    var tall: Bool
    var heightCentimeters: Int?
    var goodBody: Bool
    var goodBodyRating: Int
    var goodFace: Bool
    var goodFaceRating: Int
    var goodKisser: Bool
    var goodKisserRating: Int
    var goodHead: Bool
    var goodHeadRating: Int
    var longDuration: Bool
    var lengthCentimeters: Int?
    var madeMeCum: Bool
    var greenFlags: [String]
    var redFlags: [String]
    var positionIDs: [String]

    @Relationship(deleteRule: .cascade, inverse: \EntryPhoto.entry)
    var photoItems: [EntryPhoto]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        entryDate: Date = .now,
        personNameOrAlias: String,
        connectionType: ConnectionType,
        rating: Int = 5,
        notes: String,
        tags: [String] = [],
        wouldMeetAgain: Bool = false,
        attractive: Bool = false,
        attractiveRating: Int = 5,
        tall: Bool = false,
        heightCentimeters: Int? = nil,
        goodBody: Bool = false,
        goodBodyRating: Int = 5,
        goodFace: Bool = false,
        goodFaceRating: Int = 5,
        goodKisser: Bool = false,
        goodKisserRating: Int = 5,
        goodHead: Bool = false,
        goodHeadRating: Int = 5,
        longDuration: Bool = false,
        lengthCentimeters: Int? = nil,
        madeMeCum: Bool = false,
        greenFlags: [String] = [],
        redFlags: [String] = [],
        positionIDs: [String] = [],
        photoItems: [EntryPhoto] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entryDate = entryDate
        self.personNameOrAlias = personNameOrAlias
        self.connectionType = connectionType
        self.rating = rating
        self.notes = notes
        self.tags = tags
        self.wouldMeetAgain = wouldMeetAgain
        self.attractive = attractive
        self.attractiveRating = attractiveRating
        self.tall = tall
        self.heightCentimeters = heightCentimeters
        self.goodBody = goodBody
        self.goodBodyRating = goodBodyRating
        self.goodFace = goodFace
        self.goodFaceRating = goodFaceRating
        self.goodKisser = goodKisser
        self.goodKisserRating = goodKisserRating
        self.goodHead = goodHead
        self.goodHeadRating = goodHeadRating
        self.longDuration = longDuration
        self.lengthCentimeters = lengthCentimeters
        self.madeMeCum = madeMeCum
        self.greenFlags = greenFlags
        self.redFlags = redFlags
        self.positionIDs = positionIDs
        self.photoItems = photoItems
    }
}

extension JournalEntry {
    var isPlannedFutureEntry: Bool {
        connectionType == .future || entryDate > .now
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
    var avatarAssetName: String?

    init(
        id: UUID = UUID(),
        displayName: String = "",
        bio: String = "",
        intention: String = "",
        avatarAssetName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.intention = intention
        self.avatarAssetName = avatarAssetName
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

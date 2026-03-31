import Foundation
import SwiftData

enum AppContainer {
    static let shared = AppContainerFactory()
}

struct AppContainerFactory {
    let sharedModelContainer: ModelContainer

    init(inMemoryOnly: Bool = false) {
        let schema = Schema(versionedSchema: YoniJournalSchemaV4.self)

        let modelConfiguration: ModelConfiguration
        let storeURL: URL?

        if inMemoryOnly {
            storeURL = nil
            modelConfiguration = ModelConfiguration(
                "YoniJournal",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            let resolvedStoreURL = AppContainerFactory.storeURL()
            storeURL = resolvedStoreURL
            modelConfiguration = ModelConfiguration(
                "YoniJournal",
                schema: schema,
                url: resolvedStoreURL
            )
        }

        do {
            sharedModelContainer = try ModelContainer(
                for: schema,
                migrationPlan: YoniJournalMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            guard !inMemoryOnly else {
                fatalError("Failed to create in-memory ModelContainer: \(error)")
            }

            do {
                if let storeURL {
                    try AppContainerFactory.destroyStore(at: storeURL)
                }
                sharedModelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: YoniJournalMigrationPlan.self,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Failed to create ModelContainer after resetting store: \(error)")
            }
        }
    }

    private static func storeURL() -> URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = applicationSupport.appendingPathComponent("YoniJournal", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }

        return directory.appendingPathComponent("YoniJournal.store")
    }

    private static func destroyStore(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            storeURL.appendingPathExtension("wal"),
            storeURL.appendingPathExtension("shm")
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}

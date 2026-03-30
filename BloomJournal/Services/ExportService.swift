import Foundation

struct ExportPayload {
    let jsonURL: URL
    let csvURL: URL
}

struct ExportService {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func makeExport(entries: [JournalEntry]) throws -> ExportPayload {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("BloomExports", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let rows = entries.map(ExportEntry.init)
        let jsonURL = folder.appendingPathComponent("journal-export.json")
        let csvURL = folder.appendingPathComponent("journal-export.csv")

        let jsonData = try encoder.encode(rows)
        try jsonData.write(to: jsonURL, options: .atomic)
        try makeCSV(from: rows).write(to: csvURL, atomically: true, encoding: .utf8)

        return ExportPayload(jsonURL: jsonURL, csvURL: csvURL)
    }

    private func makeCSV(from rows: [ExportEntry]) -> String {
        let header = "id,date,name,type,mood,rating,tags,notes,photoCount"
        let lines = rows.map { row in
            [
                row.id.uuidString,
                row.entryDate,
                csvEscape(row.personNameOrAlias),
                row.connectionType,
                row.mood,
                row.rating.map(String.init) ?? "",
                csvEscape(row.tags.joined(separator: "|")),
                csvEscape(row.notes),
                String(row.photoCount)
            ]
            .joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

private struct ExportEntry: Codable {
    let id: UUID
    let entryDate: String
    let personNameOrAlias: String
    let connectionType: String
    let mood: String
    let rating: Int?
    let tags: [String]
    let notes: String
    let photoCount: Int

    init(entry: JournalEntry) {
        id = entry.id
        entryDate = ISO8601DateFormatter().string(from: entry.entryDate)
        personNameOrAlias = entry.personNameOrAlias
        connectionType = entry.connectionType.rawValue
        mood = entry.mood.rawValue
        rating = entry.rating
        tags = entry.tags
        notes = entry.notes
        photoCount = entry.photoItems.count
    }
}

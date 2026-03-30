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
        let header = "id,date,updatedAt,name,type,rating,wouldMeetAgain,goodKisser,goodHead,longDuration,madeMeCum,tags,greenFlags,redFlags,notes,photoCount"
        let lines = rows.map { row in
            [
                row.id.uuidString,
                row.entryDate,
                row.updatedAt,
                csvEscape(row.personNameOrAlias),
                row.connectionType,
                String(row.rating),
                String(row.wouldMeetAgain),
                String(row.goodKisser),
                String(row.goodHead),
                String(row.longDuration),
                String(row.madeMeCum),
                csvEscape(row.tags.joined(separator: "|")),
                csvEscape(row.greenFlags.joined(separator: "|")),
                csvEscape(row.redFlags.joined(separator: "|")),
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
    let updatedAt: String
    let personNameOrAlias: String
    let connectionType: String
    let rating: Int
    let wouldMeetAgain: Bool
    let goodKisser: Bool
    let goodHead: Bool
    let longDuration: Bool
    let madeMeCum: Bool
    let tags: [String]
    let greenFlags: [String]
    let redFlags: [String]
    let notes: String
    let photoCount: Int

    init(entry: JournalEntry) {
        id = entry.id
        entryDate = ISO8601DateFormatter().string(from: entry.entryDate)
        updatedAt = ISO8601DateFormatter().string(from: entry.updatedAt)
        personNameOrAlias = entry.personNameOrAlias
        connectionType = entry.connectionType.rawValue
        rating = entry.rating
        wouldMeetAgain = entry.wouldMeetAgain
        goodKisser = entry.goodKisser
        goodHead = entry.goodHead
        longDuration = entry.longDuration
        madeMeCum = entry.madeMeCum
        tags = entry.tags
        greenFlags = entry.greenFlags
        redFlags = entry.redFlags
        notes = entry.notes
        photoCount = entry.photoItems.count
    }
}

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
        let header = "id,date,updatedAt,name,type,rating,wouldMeetAgain,attractive,attractiveRating,tall,heightCentimeters,goodBody,goodBodyRating,goodFace,goodFaceRating,goodKisser,goodKisserRating,goodHead,goodHeadRating,longDuration,lengthCentimeters,madeMeCum,tags,greenFlags,redFlags,positions,notes,photoCount"
        let lines = rows.map(csvLine(for:))
        return ([header] + lines).joined(separator: "\n")
    }

    private func csvLine(for row: ExportEntry) -> String {
        csvColumns(for: row).joined(separator: ",")
    }

    private func csvColumns(for row: ExportEntry) -> [String] {
        let dimensions = [
            String(row.tall),
            row.heightCentimeters.map(String.init) ?? "",
            String(row.longDuration),
            row.lengthCentimeters.map(String.init) ?? ""
        ]

        let scoredNotes = [
            String(row.attractive),
            String(row.attractiveRating),
            String(row.goodBody),
            String(row.goodBodyRating),
            String(row.goodFace),
            String(row.goodFaceRating),
            String(row.goodKisser),
            String(row.goodKisserRating),
            String(row.goodHead),
            String(row.goodHeadRating)
        ]

        let exportedLists = [
            csvEscape(row.tags.joined(separator: "|")),
            csvEscape(row.greenFlags.joined(separator: "|")),
            csvEscape(row.redFlags.joined(separator: "|")),
            csvEscape(row.positionIDs.joined(separator: "|"))
        ]

        return [
            row.id.uuidString,
            row.entryDate,
            row.updatedAt,
            csvEscape(row.personNameOrAlias),
            row.connectionType,
            String(row.rating),
            String(row.wouldMeetAgain)
        ] + scoredNotes + dimensions + [
            String(row.madeMeCum)
        ] + exportedLists + [
            csvEscape(row.notes),
            String(row.photoCount)
        ]
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
    let attractive: Bool
    let attractiveRating: Int
    let tall: Bool
    let heightCentimeters: Int?
    let goodBody: Bool
    let goodBodyRating: Int
    let goodFace: Bool
    let goodFaceRating: Int
    let goodKisser: Bool
    let goodKisserRating: Int
    let goodHead: Bool
    let goodHeadRating: Int
    let longDuration: Bool
    let lengthCentimeters: Int?
    let madeMeCum: Bool
    let tags: [String]
    let greenFlags: [String]
    let redFlags: [String]
    let positionIDs: [String]
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
        attractive = entry.attractive
        attractiveRating = entry.attractiveRating
        tall = entry.tall
        heightCentimeters = entry.heightCentimeters
        goodBody = entry.goodBody
        goodBodyRating = entry.goodBodyRating
        goodFace = entry.goodFace
        goodFaceRating = entry.goodFaceRating
        goodKisser = entry.goodKisser
        goodKisserRating = entry.goodKisserRating
        goodHead = entry.goodHead
        goodHeadRating = entry.goodHeadRating
        longDuration = entry.longDuration
        lengthCentimeters = entry.lengthCentimeters
        madeMeCum = entry.madeMeCum
        tags = entry.tags
        greenFlags = entry.greenFlags
        redFlags = entry.redFlags
        positionIDs = entry.positionIDs
        notes = entry.notes
        photoCount = entry.photoItems.count
    }
}

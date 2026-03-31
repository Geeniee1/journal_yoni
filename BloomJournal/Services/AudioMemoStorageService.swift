import Foundation

struct AudioMemoStorageService {
    private let fileManager = FileManager.default

    private var baseURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("EntryVoiceMemos", isDirectory: true)

        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder
    }

    func temporaryRecordingURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).m4a")
    }

    func persistRecording(from temporaryURL: URL) throws -> String {
        let fileName = "\(UUID().uuidString).m4a"
        let destinationURL = baseURL.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: temporaryURL, to: destinationURL)
        return fileName
    }

    func audioURL(for fileName: String) -> URL {
        baseURL.appendingPathComponent(fileName)
    }

    func delete(fileName: String) {
        try? fileManager.removeItem(at: audioURL(for: fileName))
    }
}

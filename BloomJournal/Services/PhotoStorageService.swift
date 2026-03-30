import Foundation

struct PhotoStorageService {
    enum StorageError: Error {
        case unsupportedImageData
    }

    private let fileManager = FileManager.default

    private var baseURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("EntryPhotos", isDirectory: true)

        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    func saveImageData(_ data: Data, suggestedExtension: String = "jpg") throws -> EntryPhoto {
        guard !data.isEmpty else {
            throw StorageError.unsupportedImageData
        }

        let fileName = "\(UUID().uuidString).\(suggestedExtension)"
        let fileURL = baseURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return EntryPhoto(localFileName: fileName)
    }

    func imageURL(for photo: EntryPhoto) -> URL {
        baseURL.appendingPathComponent(photo.localFileName)
    }

    func delete(_ photo: EntryPhoto) {
        try? fileManager.removeItem(at: imageURL(for: photo))
    }
}

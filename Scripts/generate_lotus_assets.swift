import AppKit
import Foundation

let fileManager = FileManager.default
let projectRoot = URL(fileURLWithPath: "/Users/edwind/Desktop/journal_app", isDirectory: true)
let assetsRoot = projectRoot.appendingPathComponent("BloomJournal/Resources/Assets.xcassets", isDirectory: true)
let importedSourcesRoot = projectRoot.appendingPathComponent("BloomJournal/Resources/ImportedSources", isDirectory: true)

let appIconSourceURL = importedSourcesRoot.appendingPathComponent("app-icon-source.png")
let lotusSheetSourceURL = importedSourcesRoot.appendingPathComponent("lotus-ratings-source.png")
let avatarSourceFilenames = [
    "profile-avatar-source-1.png",
    "profile-avatar-source-2.png",
    "profile-avatar-source-3.png",
    "profile-avatar-source-4.png",
    "profile-avatar-source-5.png",
    "profile-avatar-source-6.png",
    "profile-avatar-source-7.png",
    "profile-avatar-source-8.png",
    "profile-avatar-source-9.png",
    "profile-avatar-source-10.png",
    "profile-avatar-source-11.png"
]

struct AppIconSpec {
    let idiom: String
    let size: String
    let scale: String
    let pixels: Int
    let filename: String
}

struct ComponentBounds {
    let minX: Int
    let minY: Int
    let maxX: Int
    let maxY: Int
    let pixelCount: Int

    var width: Int { maxX - minX + 1 }
    var height: Int { maxY - minY + 1 }
    var centerX: Double { Double(minX + maxX) / 2.0 }
    var centerY: Double { Double(minY + maxY) / 2.0 }
}

let appIconSpecs: [AppIconSpec] = [
    .init(idiom: "iphone", size: "20x20", scale: "2x", pixels: 40, filename: "app-icon-20@2x.png"),
    .init(idiom: "iphone", size: "20x20", scale: "3x", pixels: 60, filename: "app-icon-20@3x.png"),
    .init(idiom: "iphone", size: "29x29", scale: "2x", pixels: 58, filename: "app-icon-29@2x.png"),
    .init(idiom: "iphone", size: "29x29", scale: "3x", pixels: 87, filename: "app-icon-29@3x.png"),
    .init(idiom: "iphone", size: "40x40", scale: "2x", pixels: 80, filename: "app-icon-40@2x.png"),
    .init(idiom: "iphone", size: "40x40", scale: "3x", pixels: 120, filename: "app-icon-40@3x.png"),
    .init(idiom: "iphone", size: "60x60", scale: "2x", pixels: 120, filename: "app-icon-60@2x.png"),
    .init(idiom: "iphone", size: "60x60", scale: "3x", pixels: 180, filename: "app-icon-60@3x.png"),
    .init(idiom: "ipad", size: "20x20", scale: "1x", pixels: 20, filename: "app-icon-ipad-20@1x.png"),
    .init(idiom: "ipad", size: "20x20", scale: "2x", pixels: 40, filename: "app-icon-ipad-20@2x.png"),
    .init(idiom: "ipad", size: "29x29", scale: "1x", pixels: 29, filename: "app-icon-ipad-29@1x.png"),
    .init(idiom: "ipad", size: "29x29", scale: "2x", pixels: 58, filename: "app-icon-ipad-29@2x.png"),
    .init(idiom: "ipad", size: "40x40", scale: "1x", pixels: 40, filename: "app-icon-ipad-40@1x.png"),
    .init(idiom: "ipad", size: "40x40", scale: "2x", pixels: 80, filename: "app-icon-ipad-40@2x.png"),
    .init(idiom: "ipad", size: "76x76", scale: "1x", pixels: 76, filename: "app-icon-ipad-76@1x.png"),
    .init(idiom: "ipad", size: "76x76", scale: "2x", pixels: 152, filename: "app-icon-ipad-76@2x.png"),
    .init(idiom: "ipad", size: "83.5x83.5", scale: "2x", pixels: 167, filename: "app-icon-ipad-83.5@2x.png"),
    .init(idiom: "ios-marketing", size: "1024x1024", scale: "1x", pixels: 1024, filename: "app-icon-1024.png")
]

let ratingToSourceNumber = [1, 2, 3, 4, 7, 6, 8, 11, 14, 15]
enum AssetGenerationError: Error {
    case missingSourceImage(URL)
    case cgImageUnavailable(URL)
    case invalidCropRect(Int)
    case expectedDetectedIcons(Int)
}

func loadImage(from url: URL) throws -> NSImage {
    guard let image = NSImage(contentsOf: url) else {
        throw AssetGenerationError.missingSourceImage(url)
    }
    return image
}

func pngData(for image: NSImage) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw AssetGenerationError.cgImageUnavailable(URL(fileURLWithPath: image.name() ?? "unknown"))
    }
    return data
}

func writePNG(_ image: NSImage, to url: URL) throws {
    let data = try pngData(for: image)
    try data.write(to: url, options: .atomic)
}

func cgImage(from source: NSImage, url: URL) throws -> CGImage {
    var proposedRect = NSRect(origin: .zero, size: source.size)
    guard let cgImage = source.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
        throw AssetGenerationError.cgImageUnavailable(url)
    }
    return cgImage
}

func resizedPNGData(from source: CGImage, size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw AssetGenerationError.cgImageUnavailable(appIconSourceURL)
    }

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        throw AssetGenerationError.cgImageUnavailable(appIconSourceURL)
    }
    NSGraphicsContext.current = context
    context.cgContext.interpolationQuality = .high
    context.cgContext.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw AssetGenerationError.cgImageUnavailable(appIconSourceURL)
    }
    return data
}

func cropImage(_ source: CGImage, to rect: CGRect) throws -> NSImage {
    guard let cropped = source.cropping(to: rect.integral) else {
        throw AssetGenerationError.invalidCropRect(Int(rect.origin.x))
    }
    let image = NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    return image
}

func detectRingComponents(in source: CGImage) throws -> [ComponentBounds] {
    guard let dataProvider = source.dataProvider,
          let data = dataProvider.data,
          let bytes = CFDataGetBytePtr(data) else {
        throw AssetGenerationError.cgImageUnavailable(lotusSheetSourceURL)
    }

    let width = source.width
    let height = source.height
    let bytesPerRow = source.bytesPerRow
    let bytesPerPixel = source.bitsPerPixel / 8
    let backgroundThreshold = 105
    var visited = Array(repeating: false, count: width * height)
    var components: [ComponentBounds] = []

    func pixelOffset(x: Int, y: Int) -> Int {
        (y * bytesPerRow) + (x * bytesPerPixel)
    }

    func isForeground(x: Int, y: Int) -> Bool {
        let offset = pixelOffset(x: x, y: y)
        let red = Int(bytes[offset])
        let green = Int(bytes[offset + 1])
        let blue = Int(bytes[offset + 2])
        return max(red, green, blue) > backgroundThreshold
    }

    for y in 0..<height {
        for x in 0..<width {
            let index = y * width + x
            guard !visited[index], isForeground(x: x, y: y) else { continue }

            var queue = [(x: Int, y: Int)]()
            queue.reserveCapacity(1024)
            queue.append((x, y))
            visited[index] = true

            var pointer = 0
            var minX = x
            var minY = y
            var maxX = x
            var maxY = y
            var pixelCount = 0

            while pointer < queue.count {
                let point = queue[pointer]
                pointer += 1
                pixelCount += 1

                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)

                let neighbors = [
                    (point.x - 1, point.y),
                    (point.x + 1, point.y),
                    (point.x, point.y - 1),
                    (point.x, point.y + 1)
                ]

                for neighbor in neighbors {
                    guard neighbor.0 >= 0, neighbor.0 < width, neighbor.1 >= 0, neighbor.1 < height else { continue }
                    let neighborIndex = neighbor.1 * width + neighbor.0
                    guard !visited[neighborIndex], isForeground(x: neighbor.0, y: neighbor.1) else { continue }
                    visited[neighborIndex] = true
                    queue.append((neighbor.0, neighbor.1))
                }
            }

            let component = ComponentBounds(
                minX: minX,
                minY: minY,
                maxX: maxX,
                maxY: maxY,
                pixelCount: pixelCount
            )

            if component.width > 110 && component.height > 110 && component.pixelCount > 300 {
                components.append(component)
            }
        }
    }

    let sortedByPosition = components
        .sorted { lhs, rhs in
            if abs(lhs.centerY - rhs.centerY) > 40 {
                return lhs.centerY > rhs.centerY
            }
            return lhs.centerX < rhs.centerX
        }

    var rows: [[ComponentBounds]] = []
    for component in sortedByPosition {
        if let lastIndex = rows.indices.last {
            let referenceY = rows[lastIndex].map(\.centerY).reduce(0, +) / Double(rows[lastIndex].count)
            if abs(component.centerY - referenceY) < 90 {
                rows[lastIndex].append(component)
            } else {
                rows.append([component])
            }
        } else {
            rows.append([component])
        }
    }

    let flattened = rows.flatMap { row in
        row.sorted { $0.centerX < $1.centerX }
    }

    guard flattened.count >= 15 else {
        throw AssetGenerationError.expectedDetectedIcons(flattened.count)
    }

    return Array(flattened.prefix(15))
}

func writeJSON(_ object: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

func generateAppIcons() throws {
    let source = try loadImage(from: appIconSourceURL)
    let cgSource = try cgImage(from: source, url: appIconSourceURL)
    let appIconSet = assetsRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
    try fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)

    for spec in appIconSpecs {
        let data = try resizedPNGData(from: cgSource, size: spec.pixels)
        try data.write(to: appIconSet.appendingPathComponent(spec.filename), options: .atomic)
    }

    let contents: [String: Any] = [
        "images": appIconSpecs.map { spec in
            [
                "idiom": spec.idiom,
                "size": spec.size,
                "scale": spec.scale,
                "filename": spec.filename
            ]
        },
        "info": ["author": "xcode", "version": 1]
    ]
    try writeJSON(contents, to: appIconSet.appendingPathComponent("Contents.json"))
}

func generateRatingIcons() throws {
    let source = try loadImage(from: lotusSheetSourceURL)
    let cgSource = try cgImage(from: source, url: lotusSheetSourceURL)
    let detectedIcons = try detectRingComponents(in: cgSource)

    for (ratingIndex, sourceNumber) in ratingToSourceNumber.enumerated() {
        let component = detectedIcons[sourceNumber - 1]
        let padding = 28
        let squareSize = max(component.width, component.height) + (padding * 2)
        let centerX = Int(component.centerX.rounded())
        let centerY = Int(component.centerY.rounded())
        let proposedX = centerX - (squareSize / 2)
        let proposedY = centerY - (squareSize / 2)
        let clampedX = max(0, min(proposedX, cgSource.width - squareSize))
        let clampedY = max(0, min(proposedY, cgSource.height - squareSize))

        let cropRect = CGRect(
            x: clampedX,
            y: clampedY,
            width: squareSize,
            height: squareSize
        )

        let image = try cropImage(cgSource, to: cropRect)
        let assetName = "lotus-rating-\(ratingIndex + 1)"
        let filename = "\(assetName).png"
        let imageSetURL = assetsRoot.appendingPathComponent("\(assetName).imageset", isDirectory: true)
        try fileManager.createDirectory(at: imageSetURL, withIntermediateDirectories: true)
        try writePNG(image, to: imageSetURL.appendingPathComponent(filename))

        let contents: [String: Any] = [
            "images": [[
                "idiom": "universal",
                "filename": filename,
                "scale": "1x"
            ]],
            "info": ["author": "xcode", "version": 1]
        ]
        try writeJSON(contents, to: imageSetURL.appendingPathComponent("Contents.json"))
    }
}

func generateProfileAvatars() throws {
    for (avatarIndex, sourceFilename) in avatarSourceFilenames.enumerated() {
        let sourceURL = importedSourcesRoot.appendingPathComponent(sourceFilename)
        let image = try loadImage(from: sourceURL)
        let assetName = "profile-avatar-\(avatarIndex + 1)"
        let filename = "\(assetName).png"
        let imageSetURL = assetsRoot.appendingPathComponent("\(assetName).imageset", isDirectory: true)
        try fileManager.createDirectory(at: imageSetURL, withIntermediateDirectories: true)
        try writePNG(image, to: imageSetURL.appendingPathComponent(filename))

        let contents: [String: Any] = [
            "images": [[
                "idiom": "universal",
                "filename": filename,
                "scale": "1x"
            ]],
            "info": ["author": "xcode", "version": 1]
        ]
        try writeJSON(contents, to: imageSetURL.appendingPathComponent("Contents.json"))
    }
}

try generateAppIcons()
try generateRatingIcons()
try generateProfileAvatars()
print("Imported exact lotus and profile avatar assets.")

import AppKit
import Foundation

let fileManager = FileManager.default
let projectRoot = URL(fileURLWithPath: "/Users/edwind/Desktop/journal_app", isDirectory: true)
let assetsRoot = projectRoot.appendingPathComponent("BloomJournal/Resources/Assets.xcassets", isDirectory: true)
let importedSourcesRoot = projectRoot.appendingPathComponent("BloomJournal/Resources/ImportedSources", isDirectory: true)

let appIconSourceURL = importedSourcesRoot.appendingPathComponent("app-icon-source.png")
let lotusRatingSourceFilenames = [
    "lotus-rating-source-1.png",
    "lotus-rating-source-2.png",
    "lotus-rating-source-3.png",
    "lotus-rating-source-4.png",
    "lotus-rating-source-5.png",
    "lotus-rating-source-6.png",
    "lotus-rating-source-7.png",
    "lotus-rating-source-8.png",
    "lotus-rating-source-9.png",
    "lotus-rating-source-10.png"
]
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

enum AssetGenerationError: Error {
    case missingSourceImage(URL)
    case cgImageUnavailable(URL)
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
    for (ratingIndex, sourceFilename) in lotusRatingSourceFilenames.enumerated() {
        let sourceURL = importedSourcesRoot.appendingPathComponent(sourceFilename)
        let image = try loadImage(from: sourceURL)
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

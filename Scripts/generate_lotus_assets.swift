import AppKit
import Foundation

let fileManager = FileManager.default
let assetsRoot = URL(fileURLWithPath: "/Users/edwind/Desktop/journal_app/BloomJournal/Resources/Assets.xcassets", isDirectory: true)

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

func savePNG(size: Int, url: URL, drawer: @escaping (NSRect) -> Void) throws {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        drawer(rect)
        return true
    }

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AssetGeneration", code: 1)
    }

    try data.write(to: url)
}

func petalPath(center: CGPoint, width: CGFloat, height: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let bottom = CGPoint(x: center.x, y: center.y - height * 0.52)
    let top = CGPoint(x: center.x, y: center.y + height * 0.52)

    path.move(to: bottom)
    path.curve(
        to: top,
        controlPoint1: CGPoint(x: center.x - width * 0.62, y: center.y - height * 0.15),
        controlPoint2: CGPoint(x: center.x - width * 0.34, y: center.y + height * 0.34)
    )
    path.curve(
        to: bottom,
        controlPoint1: CGPoint(x: center.x + width * 0.34, y: center.y + height * 0.34),
        controlPoint2: CGPoint(x: center.x + width * 0.62, y: center.y - height * 0.15)
    )
    path.close()
    return path
}

func transform(
    path: NSBezierPath,
    rotation degrees: CGFloat,
    around center: CGPoint,
    scaleX: CGFloat = 1,
    scaleY: CGFloat = 1
) -> NSBezierPath {
    let copy = path.copy() as! NSBezierPath
    var transform = AffineTransform()
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byDegrees: degrees)
    transform.scale(x: scaleX, y: scaleY)
    transform.translate(x: -center.x, y: -center.y)
    copy.transform(using: transform)
    return copy
}

func drawGradientBackground(in rect: NSRect) {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.21, alpha: 1),
        NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.14, alpha: 1)
    ])
    gradient?.draw(in: rect, angle: -90)

    let glowRect = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.18)
    let glow = NSBezierPath(ovalIn: glowRect)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = rect.width * 0.08
    shadow.shadowColor = NSColor(calibratedRed: 0.95, green: 0.74, blue: 0.84, alpha: 0.26)
    shadow.set()
    NSColor(calibratedRed: 0.95, green: 0.74, blue: 0.84, alpha: 0.18).setFill()
    glow.fill()
    NSGraphicsContext.restoreGraphicsState()
}

func drawFilledLotus(in rect: NSRect) {
    let center = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.03)
    let basePath = petalPath(center: center, width: rect.width * 0.15, height: rect.height * 0.26)
    let outerBack = [
        transform(path: basePath, rotation: -52, around: center, scaleX: 1.16, scaleY: 1.06),
        transform(path: basePath, rotation: 52, around: center, scaleX: 1.16, scaleY: 1.06),
        transform(path: basePath, rotation: 0, around: center, scaleX: 1.06, scaleY: 1.22)
    ]
    let midFront = [
        transform(path: basePath, rotation: -28, around: center, scaleX: 1.18, scaleY: 1.10),
        transform(path: basePath, rotation: 28, around: center, scaleX: 1.18, scaleY: 1.10),
        transform(path: basePath, rotation: 0, around: center, scaleX: 0.95, scaleY: 1.00)
    ]
    let lowerPetals = [
        transform(path: basePath, rotation: -78, around: center, scaleX: 1.05, scaleY: 0.86),
        transform(path: basePath, rotation: 78, around: center, scaleX: 1.05, scaleY: 0.86)
    ]

    let layers: [(paths: [NSBezierPath], color: NSColor)] = [
        (outerBack, NSColor(calibratedRed: 0.84, green: 0.80, blue: 0.94, alpha: 0.95)),
        (midFront, NSColor(calibratedRed: 0.95, green: 0.84, blue: 0.86, alpha: 0.96)),
        (lowerPetals, NSColor(calibratedRed: 0.96, green: 0.78, blue: 0.72, alpha: 0.94))
    ]

    for layer in layers {
        for path in layer.paths {
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowBlurRadius = rect.width * 0.025
            shadow.shadowColor = layer.color.withAlphaComponent(0.38)
            shadow.set()
            layer.color.setFill()
            path.fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

func petalDistribution(for level: Int) -> (back: Int, front: Int, centerDots: Bool) {
    switch level {
    case 1: return (0, 1, false)
    case 2: return (0, 2, false)
    case 3: return (1, 2, false)
    case 4: return (1, 3, false)
    case 5: return (2, 3, false)
    case 6: return (2, 4, false)
    case 7: return (3, 4, false)
    case 8: return (3, 5, false)
    case 9: return (4, 5, true)
    default: return (5, 5, true)
    }
}

func angles(count: Int, span: CGFloat) -> [CGFloat] {
    guard count > 1 else { return [0] }
    let step = (span * 2) / CGFloat(count - 1)
    return (0..<count).map { -span + (CGFloat($0) * step) }
}

func drawOutlinedLotus(level: Int, in rect: NSRect) {
    drawGradientBackground(in: rect)

    let strokeWidth = max(2, rect.width * 0.026)
    let circleRect = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
    let border = NSBezierPath(ovalIn: circleRect)
    border.lineWidth = strokeWidth * 0.9
    NSColor(calibratedRed: 0.96, green: 0.82, blue: 0.77, alpha: 0.95).setStroke()
    border.stroke()

    let center = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.03)
    let base = petalPath(center: center, width: rect.width * 0.13, height: rect.height * 0.22)
    let distribution = petalDistribution(for: level)

    let backAngles = angles(count: distribution.back, span: 64)
    for angle in backAngles {
        let path = transform(path: base, rotation: angle, around: center, scaleX: 1.08, scaleY: 1.04)
        path.lineWidth = strokeWidth * 0.78
        NSColor(calibratedRed: 0.84, green: 0.78, blue: 0.96, alpha: 0.96).setStroke()
        path.stroke()
    }

    let frontAngles = angles(count: distribution.front, span: 48)
    for angle in frontAngles {
        let path = transform(path: base, rotation: angle, around: center, scaleX: 1.0, scaleY: 1.0)
        path.lineWidth = strokeWidth
        NSColor(calibratedRed: 0.97, green: 0.83, blue: 0.80, alpha: 0.98).setStroke()
        path.stroke()
    }

    if distribution.centerDots {
        let dotColor = NSColor(calibratedRed: 0.98, green: 0.86, blue: 0.78, alpha: 0.98)
        let dotRadius = rect.width * 0.014
        let centerRadius = rect.width * 0.055

        for index in 0..<12 {
            let angle = CGFloat(index) * (.pi * 2 / 12)
            let point = CGPoint(
                x: center.x + cos(angle) * centerRadius,
                y: center.y + sin(angle) * centerRadius
            )
            let dot = NSBezierPath(
                ovalIn: NSRect(
                    x: point.x - dotRadius,
                    y: point.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
            )
            dotColor.setFill()
            dot.fill()
        }
    }
}

func writeJSON(_ object: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

let appIconSet = assetsRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
try? fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)

for spec in appIconSpecs {
    try savePNG(size: spec.pixels, url: appIconSet.appendingPathComponent(spec.filename)) { rect in
        drawGradientBackground(in: rect)
        drawFilledLotus(in: rect)
    }
}

let appIconJSON: [String: Any] = [
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
try writeJSON(appIconJSON, to: appIconSet.appendingPathComponent("Contents.json"))

for level in 1...10 {
    let setURL = assetsRoot.appendingPathComponent("lotus-rating-\(level).imageset", isDirectory: true)
    try? fileManager.createDirectory(at: setURL, withIntermediateDirectories: true)
    let filename = "lotus-rating-\(level).png"
    try savePNG(size: 160, url: setURL.appendingPathComponent(filename)) { rect in
        drawOutlinedLotus(level: level, in: rect)
    }

    let contents: [String: Any] = [
        "images": [[
            "idiom": "universal",
            "filename": filename,
            "scale": "1x"
        ]],
        "info": ["author": "xcode", "version": 1]
    ]
    try writeJSON(contents, to: setURL.appendingPathComponent("Contents.json"))
}

print("Generated lotus icon and rating assets.")

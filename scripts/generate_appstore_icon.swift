import AppKit

// App Store Connect's 1024x1024 marketing icon must be a full square (no
// pre-rounded corners — Apple applies its own mask) and must NOT contain an
// alpha channel. This mirrors generate_icon.swift's design but square + opaque.

let size = 1024.0
let rect = NSRect(x: 0, y: 0, width: size, height: size)

// Draw directly into an alpha-free bitmap context, rather than rendering
// into a normal (alpha-carrying) NSImage and trying to flatten afterward —
// that flatten step produced a solid black image instead.
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let cgContext = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Failed to create bitmap context")
}
let nsContext = NSGraphicsContext(cgContext: cgContext, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsContext

let bgPath = NSBezierPath(rect: rect)
let gradient = NSGradient(colors: [
    NSColor(red: 0.09, green: 0.55, blue: 1.0, alpha: 1.0),   // #1690FF
    NSColor(red: 0.42, green: 0.24, blue: 0.94, alpha: 1.0),  // #6B3DF0
])!
gradient.draw(in: bgPath, angle: -60)

let ringInset = size * 0.06
let ringPath = NSBezierPath(rect: rect.insetBy(dx: ringInset, dy: ringInset))
NSColor.white.withAlphaComponent(0.08).setStroke()
ringPath.lineWidth = size * 0.01
ringPath.stroke()

let center = NSPoint(x: size / 2, y: size / 2 - size * 0.02)
let dialRadius = size * 0.30

let crownWidth = size * 0.10
let crownHeight = size * 0.07
let crownRect = NSRect(
    x: center.x - crownWidth / 2,
    y: center.y + dialRadius + size * 0.02,
    width: crownWidth,
    height: crownHeight
)
NSColor.white.setFill()
NSBezierPath(roundedRect: crownRect, xRadius: crownWidth * 0.3, yRadius: crownWidth * 0.3).fill()

let dialRect = NSRect(
    x: center.x - dialRadius,
    y: center.y - dialRadius,
    width: dialRadius * 2,
    height: dialRadius * 2
)
let ringWidth = size * 0.045
NSColor.white.setStroke()
let dialPath = NSBezierPath(ovalIn: dialRect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
dialPath.lineWidth = ringWidth
dialPath.stroke()

let progressPath = NSBezierPath()
progressPath.appendArc(
    withCenter: center,
    radius: dialRadius - ringWidth / 2,
    startAngle: 90,
    endAngle: -50,
    clockwise: true
)
NSColor.white.withAlphaComponent(0.35).setStroke()
progressPath.lineWidth = ringWidth
progressPath.lineCapStyle = .round
progressPath.stroke()

NSColor.white.setStroke()
let minuteHand = NSBezierPath()
minuteHand.move(to: center)
minuteHand.line(to: NSPoint(x: center.x, y: center.y + dialRadius * 0.62))
minuteHand.lineWidth = size * 0.028
minuteHand.lineCapStyle = .round
minuteHand.stroke()

let hourHand = NSBezierPath()
hourHand.move(to: center)
hourHand.line(to: NSPoint(x: center.x + dialRadius * 0.42, y: center.y + dialRadius * 0.10))
hourHand.lineWidth = size * 0.028
hourHand.lineCapStyle = .round
hourHand.stroke()

let hubRadius = size * 0.022
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(
    x: center.x - hubRadius, y: center.y - hubRadius,
    width: hubRadius * 2, height: hubRadius * 2
)).fill()

NSGraphicsContext.restoreGraphicsState()

guard let cgImage = cgContext.makeImage() else {
    fatalError("Failed to create CGImage")
}
let outputBitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = outputBitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024-appstore.png"
try! png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")

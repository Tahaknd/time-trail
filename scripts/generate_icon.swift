import AppKit

let size = 1024.0
let rect = NSRect(x: 0, y: 0, width: size, height: size)

let image = NSImage(size: rect.size)
image.lockFocus()

// Background: rounded-square gradient (matches the app's blue -> purple accent range)
let cornerRadius = size * 0.225 // macOS Big Sur+ icon corner radius ratio
let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
let gradient = NSGradient(colors: [
    NSColor(red: 0.09, green: 0.55, blue: 1.0, alpha: 1.0),   // #1690FF
    NSColor(red: 0.42, green: 0.24, blue: 0.94, alpha: 1.0),  // #6B3DF0
])!
gradient.draw(in: bgPath, angle: -60)

// Subtle inner glow ring for depth
let ringInset = size * 0.06
let ringPath = NSBezierPath(
    roundedRect: rect.insetBy(dx: ringInset, dy: ringInset),
    xRadius: cornerRadius * 0.8,
    yRadius: cornerRadius * 0.8
)
NSColor.white.withAlphaComponent(0.08).setStroke()
ringPath.lineWidth = size * 0.01
ringPath.stroke()

// Foreground: a bold stopwatch/clock glyph, hand-drawn (no SF Symbol dependency
// so it renders crisply and consistently regardless of the host's symbol set)
let center = NSPoint(x: size / 2, y: size / 2 - size * 0.02)
let dialRadius = size * 0.30

// Watch crown (top button)
let crownWidth = size * 0.10
let crownHeight = size * 0.07
let crownRect = NSRect(
    x: center.x - crownWidth / 2,
    y: center.y + dialRadius + size * 0.02,
    width: crownWidth,
    height: crownHeight
)
NSBezierPath(roundedRect: crownRect, xRadius: crownWidth * 0.3, yRadius: crownWidth * 0.3).fill()
NSColor.white.setFill()
NSBezierPath(roundedRect: crownRect, xRadius: crownWidth * 0.3, yRadius: crownWidth * 0.3).fill()

// Dial outer ring
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

// Progress arc (a partial ring in a lighter tone, evoking "tracked time")
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

// Clock hands
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

// Center hub
let hubRadius = size * 0.022
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(
    x: center.x - hubRadius, y: center.y - hubRadius,
    width: hubRadius * 2, height: hubRadius * 2
)).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Failed to render PNG")
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
try! png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")

import AppKit
import CoreGraphics

// Renders a 1024×1024 app icon: rounded "squircle"-ish indigo gradient tile
// with a bold white checkmark. Writes /tmp/icon_1024.png.

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size,
                          bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fputs("ctx fail\n", stderr); exit(1)
}
let S = CGFloat(size)
ctx.clear(CGRect(x: 0, y: 0, width: S, height: S))

// Rounded tile
let inset: CGFloat = 76
let rect = CGRect(x: inset, y: inset, width: S - 2*inset, height: S - 2*inset)
let radius: CGFloat = 205
let tile = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

ctx.saveGState()
ctx.addPath(tile)
ctx.clip()
let colors = [
    CGColor(red: 0.42, green: 0.51, blue: 0.99, alpha: 1.0),  // top
    CGColor(red: 0.25, green: 0.30, blue: 0.86, alpha: 1.0)   // bottom
] as CFArray
let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
// soft top highlight
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.fillEllipse(in: CGRect(x: -120, y: S*0.45, width: S+240, height: S*0.85))
ctx.restoreGState()

// Checkmark (coords: origin bottom-left, y up)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.setLineWidth(96)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 355, y: 515))
ctx.addLine(to: CGPoint(x: 470, y: 400))
ctx.addLine(to: CGPoint(x: 685, y: 650))
ctx.strokePath()

guard let img = ctx.makeImage() else { fputs("img fail\n", stderr); exit(1) }
let rep = NSBitmapImageRep(cgImage: img)
guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! data.write(to: URL(fileURLWithPath: "/tmp/icon_1024.png"))
print("wrote /tmp/icon_1024.png")

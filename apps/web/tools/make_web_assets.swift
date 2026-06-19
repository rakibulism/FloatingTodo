import AppKit

let cs = CGColorSpaceCreateDeviceRGB()

func makeContext(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    return ctx
}

func writePNG(_ ctx: CGContext, _ path: String) {
    guard let cg = ctx.makeImage() else { return }
    let rep = NSBitmapImageRep(cgImage: cg)
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path)); print("wrote \(path)")
    }
}

// Draw the rounded indigo tile + white checkmark, filling an s×s box at (x,y).
func drawTile(x: CGFloat, y: CGFloat, s: CGFloat, inset insetFrac: CGFloat = 0.074) {
    let inset = s * insetFrac
    let rect = NSRect(x: x + inset, y: y + inset, width: s - 2*inset, height: s - 2*inset)
    let radius = rect.width * 0.235
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let grad = NSGradient(starting: NSColor(srgbRed: 0.46, green: 0.54, blue: 1.0, alpha: 1),
                          ending:   NSColor(srgbRed: 0.27, green: 0.31, blue: 0.90, alpha: 1))!
    grad.draw(in: path, angle: -90)
    let w = rect.width, h = rect.height, ox = rect.minX, oy = rect.minY
    let check = NSBezierPath()
    check.lineWidth = w * 0.108
    check.lineCapStyle = .round; check.lineJoinStyle = .round
    check.move(to: NSPoint(x: ox + w*0.30,  y: oy + h*0.50))
    check.line(to: NSPoint(x: ox + w*0.445, y: oy + h*0.365))
    check.line(to: NSPoint(x: ox + w*0.70,  y: oy + h*0.655))
    NSColor.white.setStroke()
    check.stroke()
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// 1) App/web icon — 512, transparent background
do {
    let ctx = makeContext(512, 512)
    ctx.clear(CGRect(x: 0, y: 0, width: 512, height: 512))
    drawTile(x: 0, y: 0, s: 512)
    writePNG(ctx, "\(outDir)/icon.png")
}

// 2) Favicon — 128, transparent background
do {
    let ctx = makeContext(128, 128)
    ctx.clear(CGRect(x: 0, y: 0, width: 128, height: 128))
    drawTile(x: 0, y: 0, s: 128)
    writePNG(ctx, "\(outDir)/favicon.png")
}

// 3) Social / OG image — 1200×630, dark with indigo glow + wordmark
do {
    let W = 1200, H = 630
    let ctx = makeContext(W, H)
    ctx.setFillColor(NSColor(srgbRed: 0.027, green: 0.027, blue: 0.043, alpha: 1).cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let glow = [NSColor(srgbRed: 0.36, green: 0.41, blue: 1.0, alpha: 0.50).cgColor,
                NSColor(srgbRed: 0.36, green: 0.41, blue: 1.0, alpha: 0.0).cgColor] as CFArray
    let g = CGGradient(colorsSpace: cs, colors: glow, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: 300, y: 340), startRadius: 0,
                           endCenter: CGPoint(x: 300, y: 340), endRadius: 560, options: [])
    drawTile(x: 96, y: 165, s: 300)

    let title = "Today" as NSString
    title.draw(at: NSPoint(x: 470, y: 312), withAttributes: [
        .font: NSFont.systemFont(ofSize: 132, weight: .bold),
        .foregroundColor: NSColor.white,
        .kern: -3.0,
    ])
    let sub = "Floating to-dos. On top. On time." as NSString
    sub.draw(at: NSPoint(x: 476, y: 236), withAttributes: [
        .font: NSFont.systemFont(ofSize: 38, weight: .medium),
        .foregroundColor: NSColor(white: 1, alpha: 0.66),
    ])
    let url = "github.com/rakibulism/FloatingTodo" as NSString
    url.draw(at: NSPoint(x: 478, y: 168), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 24, weight: .regular),
        .foregroundColor: NSColor(srgbRed: 0.62, green: 0.67, blue: 1.0, alpha: 0.85),
    ])
    writePNG(ctx, "\(outDir)/og.png")
}

#!/usr/bin/env swift
import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let iconsetPath = "Stamp.iconset"

try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else { continue }

    // Background — dark rounded rect
    let inset = s * 0.08
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = s * 0.2
    let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.06,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
    ctx.setFillColor(CGColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0))
    ctx.addPath(bgPath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0)

    // Subtle border
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.setLineWidth(s * 0.008)
    ctx.addPath(bgPath)
    ctx.strokePath()

    // macOS window with stamp applet overlay
    let lineWidth = s * 0.016
    let dimWhite = CGColor(red: 1, green: 1, blue: 1, alpha: 0.35)

    // ── Window ──
    let winInset = s * 0.16
    let winRect = CGRect(x: winInset, y: winInset * 0.7, width: s - winInset * 2, height: s - winInset * 1.7)
    let winRadius = s * 0.06
    let winPath = CGPath(roundedRect: winRect, cornerWidth: winRadius, cornerHeight: winRadius, transform: nil)

    // Window fill — subtle dark blue
    ctx.setFillColor(CGColor(red: 0.15, green: 0.17, blue: 0.22, alpha: 1.0))
    ctx.addPath(winPath)
    ctx.fillPath()

    // Window border
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
    ctx.setLineWidth(lineWidth * 0.5)
    ctx.addPath(winPath)
    ctx.strokePath()

    // ── Title bar ──
    let titleBarY = winRect.maxY - s * 0.1
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.1))
    ctx.setLineWidth(lineWidth * 0.4)
    ctx.move(to: CGPoint(x: winRect.minX, y: titleBarY))
    ctx.addLine(to: CGPoint(x: winRect.maxX, y: titleBarY))
    ctx.strokePath()

    // ── Traffic lights with color ──
    let dotRadius = s * 0.016
    let dotY = titleBarY + (winRect.maxY - titleBarY) / 2
    let dotStartX = winRect.minX + s * 0.055
    let dotSpacing = s * 0.042
    let dotColors: [(CGFloat, CGFloat, CGFloat)] = [
        (0.94, 0.36, 0.34),  // red
        (0.98, 0.74, 0.22),  // yellow
        (0.30, 0.78, 0.35),  // green
    ]
    for i in 0..<3 {
        let dx = dotStartX + CGFloat(i) * dotSpacing
        let c = dotColors[i]
        ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 0.85))
        ctx.fillEllipse(in: CGRect(x: dx - dotRadius, y: dotY - dotRadius,
                                   width: dotRadius * 2, height: dotRadius * 2))
    }

    // ── Content lines (abstract page content) ──
    ctx.setLineCap(.round)
    let contentX = winRect.minX + s * 0.05
    let contentStartY = titleBarY - s * 0.1
    let lineH = s * 0.04
    for i in 0..<4 {
        let ly = contentStartY - CGFloat(i) * lineH
        let lw: CGFloat
        switch i {
        case 0: lw = s * 0.38
        case 1: lw = s * 0.32
        case 2: lw = s * 0.36
        default: lw = s * 0.2
        }
        ctx.setStrokeColor(dimWhite)
        ctx.setLineWidth(lineWidth * 0.4)
        ctx.move(to: CGPoint(x: contentX, y: ly))
        ctx.addLine(to: CGPoint(x: contentX + lw, y: ly))
        ctx.strokePath()
    }

    // ── Stamp applet (dark pill, bottom-right of window) ──
    let appletW = s * 0.42
    let appletH = s * 0.1
    let appletX = winRect.maxX - appletW - s * 0.04
    let appletY = winRect.minY + s * 0.05
    let appletRect = CGRect(x: appletX, y: appletY, width: appletW, height: appletH)
    let appletRadius = appletH * 0.4
    let appletPath = CGPath(roundedRect: appletRect, cornerWidth: appletRadius, cornerHeight: appletRadius, transform: nil)

    // Applet background — slightly lighter than window
    ctx.setFillColor(CGColor(red: 0.22, green: 0.24, blue: 0.3, alpha: 1.0))
    ctx.addPath(appletPath)
    ctx.fillPath()

    // Applet border
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
    ctx.setLineWidth(lineWidth * 0.3)
    ctx.addPath(appletPath)
    ctx.strokePath()

    // Applet text — simulated timestamp
    let stampFont = NSFont.monospacedDigitSystemFont(ofSize: s * 0.042, weight: .medium)
    let stampStr = NSAttributedString(string: "Mar 21, 2026  10:42", attributes: [
        .font: stampFont,
        .foregroundColor: NSColor(white: 1, alpha: 0.9),
    ])
    let stampSize = stampStr.size()
    stampStr.draw(at: NSPoint(
        x: appletX + (appletW - stampSize.width) / 2,
        y: appletY + (appletH - stampSize.height) / 2
    ))


    image.unlockFocus()

    // Write 1x
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let name = size <= 512
            ? "icon_\(size)x\(size).png"
            : "icon_512x512@2x.png"
        try? (png as NSData).write(toFile: "\(iconsetPath)/\(name)")
    }

    // Write 2x for smaller sizes
    if size <= 512, let idx = sizes.firstIndex(of: size), idx > 0 {
        let smallSize = sizes[idx - 1]
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? (png as NSData).write(toFile: "\(iconsetPath)/icon_\(smallSize)x\(smallSize)@2x.png")
        }
    }
}

// Convert to .icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath]
try task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    try? FileManager.default.removeItem(atPath: iconsetPath)
    print("Generated Stamp.icns")
} else {
    print("iconutil failed — iconset left in place for debugging")
}

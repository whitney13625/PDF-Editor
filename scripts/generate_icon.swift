#!/usr/bin/env swift
// Generates a 1024×1024 PDF Editor app icon and saves it as a PNG.
// Run: swift scripts/generate_icon.swift

import AppKit
import CoreGraphics

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "PDFEditor/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

let size = CGSize(width: 1024, height: 1024)
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024, pixelsHigh: 1024,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// ── Background (rounded rect will be applied by iOS, draw full square) ──────
let blue = CGColor(red: 0.18, green: 0.42, blue: 0.90, alpha: 1)
let darkBlue = CGColor(red: 0.10, green: 0.25, blue: 0.70, alpha: 1)
if let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [blue, darkBlue] as CFArray,
    locations: [0, 1]
) {
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 1024),
        end: CGPoint(x: 1024, y: 0),
        options: []
    )
}

// ── Page shadow ──────────────────────────────────────────────────────────────
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 32,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))

// ── White page ───────────────────────────────────────────────────────────────
let pageRect = CGRect(x: 220, y: 140, width: 460, height: 600)
let radius: CGFloat = 28
let pagePath = CGPath(roundedRect: pageRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.addPath(pagePath)
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)  // reset shadow

// ── Folded corner ────────────────────────────────────────────────────────────
let foldSize: CGFloat = 90
ctx.saveGState()
ctx.addPath(pagePath)
ctx.clip()
let foldColor = CGColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
ctx.setFillColor(foldColor)
let foldPath = CGMutablePath()
foldPath.move(to: CGPoint(x: pageRect.maxX - foldSize, y: pageRect.maxY))
foldPath.addLine(to: CGPoint(x: pageRect.maxX, y: pageRect.maxY - foldSize))
foldPath.addLine(to: CGPoint(x: pageRect.maxX, y: pageRect.maxY))
foldPath.closeSubpath()
ctx.addPath(foldPath)
ctx.fillPath()
ctx.restoreGState()

// ── Horizontal lines (content preview) ──────────────────────────────────────
let lineColor = CGColor(red: 0.82, green: 0.84, blue: 0.87, alpha: 1)
ctx.setFillColor(lineColor)
let lineX: CGFloat = 286
let lineWidth: CGFloat = 310
let lineHeight: CGFloat = 18
let lineStartY: CGFloat = 560
let lineGap: CGFloat = 50
for i in 0..<4 {
    let y = lineStartY - CGFloat(i) * lineGap
    let w = i == 3 ? lineWidth * 0.55 : lineWidth   // shorter last line
    ctx.fill(CGRect(x: lineX, y: y, width: w, height: lineHeight))
}

// ── "PDF" label ──────────────────────────────────────────────────────────────
let labelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 108),
    .foregroundColor: NSColor(cgColor: CGColor(red: 0.18, green: 0.42, blue: 0.90, alpha: 1))!,
]
let label = NSAttributedString(string: "PDF", attributes: labelAttrs)
label.draw(at: NSPoint(x: 270, y: 190))

// ── Save ─────────────────────────────────────────────────────────────────────
let png = rep.representation(using: .png, properties: [:])!
let url = URL(fileURLWithPath: outputPath)
try! FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try! png.write(to: url)
print("✓ Icon written to \(outputPath)")

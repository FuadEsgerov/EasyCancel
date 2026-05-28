#!/usr/bin/env swift
//
// render_og.swift
//
// Renders the EasyCancel social-share / Open Graph cover image
// (1200×630 sRGB PNG, opaque — no alpha).
//
// Output: web/assets/og-cover.png
//
// Runs on macOS via `swift scripts/render_og.swift`.
// Uses NSBitmapImageRep + CGContext (no UIKit), with a Y-flipped top-left
// coordinate system, falling back to system fonts. Deterministic.
//
// Design:
//   • Diagonal green gradient background  #2f9e6b → #1c7a52
//   • White circle with a white checkmark (mirrors the app icon)
//   • Bold white wordmark "EasyCancel"
//   • Tagline + semi-transparent caption line
//

import AppKit
import CoreGraphics
import CoreText
import Foundation

// MARK: - Canvas (landscape OG size)

let W = 1200
let H = 630
let canvasW = CGFloat(W)
let canvasH = CGFloat(H)

let outputPath =
    "/Users/fuadasgarov/Documents/AllProjects/EasyCancel/web/assets/og-cover.png"

// MARK: - Colour helpers

func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(srgbRed: CGFloat(r) / 255.0,
            green:   CGFloat(g) / 255.0,
            blue:    CGFloat(b) / 255.0,
            alpha:   a)
}

func hex(_ s: String, _ a: CGFloat = 1.0) -> CGColor {
    var h = s
    if h.hasPrefix("#") { h.removeFirst() }
    let v = UInt32(h, radix: 16) ?? 0
    let r = Int((v >> 16) & 0xFF)
    let g = Int((v >> 8)  & 0xFF)
    let b = Int(v & 0xFF)
    return rgb(r, g, b, a)
}

// Brand palette
let brandGreenLight = hex("#2f9e6b")   // gradient start
let brandGreenDark  = hex("#1c7a52")   // gradient end
let white           = hex("#FFFFFF")

// MARK: - Bitmap context (RGBA for drawing; flattened to RGB before PNG)

let sRGB = CGColorSpaceCreateDeviceRGB()

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: W,
    pixelsHigh: H,
    bitsPerSample: 8,
    samplesPerPixel: 4,           // RGBA (required for NSGraphicsContext drawing)
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
) else {
    fputs("Failed to allocate bitmap\n", stderr)
    exit(1)
}

guard let nsCtx = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Failed to make NSGraphicsContext\n", stderr)
    exit(1)
}

// Flip CTM so (0,0) is top-left and y grows downward.
let cg = nsCtx.cgContext
cg.translateBy(x: 0, y: canvasH)
cg.scaleBy(x: 1, y: -1)
cg.setShouldAntialias(true)
cg.interpolationQuality = .high
cg.setAllowsAntialiasing(true)

// MARK: - Gradient helpers

func makeLinearGradient(stops: [(CGFloat, CGColor)]) -> CGGradient {
    let colors = stops.map { $0.1 } as CFArray
    let locs = stops.map { $0.0 }
    return CGGradient(colorsSpace: sRGB, colors: colors, locations: locs)!
}

func makeRadialGradient(_ inner: CGColor, _ outer: CGColor) -> CGGradient {
    CGGradient(colorsSpace: sRGB,
               colors: [inner, outer] as CFArray,
               locations: [0.0, 1.0])!
}

// MARK: - Text helper (left-aligned, baseline-controlled)

func systemFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

// Draws a single line of text with its LEFT edge at `x` and its visual
// vertical CENTRE at `cy`. Returns the typographic width drawn.
@discardableResult
func drawText(_ s: String,
              x: CGFloat, cy: CGFloat,
              font: NSFont,
              color: CGColor,
              tracking: CGFloat = 0) -> CGFloat
{
    var attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color) ?? .white,
    ]
    if tracking != 0 { attrs[.kern] = tracking }

    let str = NSAttributedString(string: s, attributes: attrs)
    let line = CTLineCreateWithAttributedString(str)
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let typoWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

    // Baseline so the visual centre lands on cy.
    let textY = cy + (ascent - descent) / 2

    cg.saveGState()
    // Flip back locally so glyphs render right-way-up.
    cg.translateBy(x: 0, y: textY)
    cg.scaleBy(x: 1, y: -1)
    cg.translateBy(x: 0, y: -textY)
    cg.textPosition = CGPoint(x: x, y: textY)
    CTLineDraw(line, cg)
    cg.restoreGState()

    return typoWidth
}

// =====================================================================
// 1. Background diagonal gradient (top-left → bottom-right)
// =====================================================================
do {
    let grad = makeLinearGradient(stops: [
        (0.00, brandGreenLight),
        (1.00, brandGreenDark),
    ])
    cg.saveGState()
    cg.addRect(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
    cg.clip()
    cg.drawLinearGradient(grad,
                          start: CGPoint(x: 0, y: 0),
                          end:   CGPoint(x: canvasW, y: canvasH),
                          options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    cg.restoreGState()
}

// =====================================================================
// 2. Soft radial highlight (subtle depth, top-left quadrant)
// =====================================================================
do {
    let inner = hex("#FFFFFF", 0.10)
    let outer = hex("#FFFFFF", 0.00)
    let g = makeRadialGradient(inner, outer)
    cg.saveGState()
    cg.drawRadialGradient(g,
                          startCenter: CGPoint(x: 360, y: 300), startRadius: 0,
                          endCenter:   CGPoint(x: 360, y: 300), endRadius: 560,
                          options: [])
    cg.restoreGState()
}

// =====================================================================
// 3. Logo lockup — white circle + green checkmark (mirrors app icon)
// =====================================================================
// Generous margins. Layout: circle on the left, text block to its right.
let margin: CGFloat = 90
let circleR: CGFloat = 95
let circleCX = margin + circleR
let circleCY = canvasH / 2

do {
    // Soft drop shadow under the circle for separation from the gradient.
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10),
                 blur: 30,
                 color: hex("#0A3A26", 0.35))
    cg.beginPath()
    cg.addArc(center: CGPoint(x: circleCX, y: circleCY), radius: circleR,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.setFillColor(white)
    cg.fillPath()
    cg.restoreGState()
}

// Checkmark drawn in brand green inside the white circle.
do {
    cg.saveGState()
    cg.setLineCap(.round)
    cg.setLineJoin(.round)
    cg.setLineWidth(20)
    cg.setStrokeColor(brandGreenLight)

    // Checkmark proportioned within the circle.
    // Points relative to circle centre.
    let p1 = CGPoint(x: circleCX - 42, y: circleCY + 4)
    let p2 = CGPoint(x: circleCX - 12, y: circleCY + 36)
    let p3 = CGPoint(x: circleCX + 46, y: circleCY - 34)

    cg.beginPath()
    cg.move(to: p1)
    cg.addLine(to: p2)
    cg.addLine(to: p3)
    cg.strokePath()
    cg.restoreGState()
}

// =====================================================================
// 4. Text block (right of the logo)
// =====================================================================
let textX = circleCX + circleR + 70   // left edge of all text lines

// 4a. Wordmark "EasyCancel" — bold white
let wordmarkCY: CGFloat = 215
drawText("EasyCancel",
         x: textX, cy: wordmarkCY,
         font: systemFont(size: 96, weight: .bold),
         color: white,
         tracking: -1)

// 4b. Tagline — large, legible white
let taglineCY: CGFloat = 330
drawText("Cancel subscriptions before",
         x: textX, cy: taglineCY,
         font: systemFont(size: 46, weight: .medium),
         color: white)
drawText("you're charged again",
         x: textX, cy: taglineCY + 64,
         font: systemFont(size: 46, weight: .medium),
         color: white)

// 4c. Caption — semi-transparent white
let captionCY: CGFloat = 480
drawText("EU & UK · 14-day cooling-off · GDPR-ready",
         x: textX, cy: captionCY,
         font: systemFont(size: 28, weight: .semibold),
         color: hex("#FFFFFF", 0.78),
         tracking: 0.5)

// =====================================================================
// Encode → PNG (sRGB, opaque). Flatten RGBA → RGB so hasAlpha == no.
// =====================================================================
try? FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)

guard let src = bitmap.bitmapData else {
    fputs("Source bitmap has no data\n", stderr)
    exit(1)
}
let srcBytesPerRow = bitmap.bytesPerRow

guard let flatRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: W,
    pixelsHigh: H,
    bitsPerSample: 8,
    samplesPerPixel: 3,
    hasAlpha: false,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 24
), let dst = flatRep.bitmapData else {
    fputs("Failed to allocate flatten bitmap\n", stderr)
    exit(1)
}
let dstBytesPerRow = flatRep.bytesPerRow

for y in 0..<H {
    let srcRow = src.advanced(by: y * srcBytesPerRow)
    let dstRow = dst.advanced(by: y * dstBytesPerRow)
    for x in 0..<W {
        dstRow[x * 3 + 0] = srcRow[x * 4 + 0]   // R
        dstRow[x * 3 + 1] = srcRow[x * 4 + 1]   // G
        dstRow[x * 3 + 2] = srcRow[x * 4 + 2]   // B
        // drop alpha
    }
}

guard let pngData = flatRep.representation(using: .png,
                                           properties: [.interlaced: false]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Failed to write PNG: \(error)\n", stderr)
    exit(1)
}

print("Wrote \(outputPath)  \(flatRep.pixelsWide)x\(flatRep.pixelsHigh)  bytes=\(pngData.count)  hasAlpha=\(flatRep.hasAlpha)")

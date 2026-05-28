#!/usr/bin/env swift
//
// render_profile.swift
//
// Renders EasyCancel PROFILE assets for Instagram + TikTok as opaque
// 1080×1080 sRGB PNGs (no alpha). Deterministic, CGContext-based.
//
// Outputs (marketing/social/profile/):
//   • profile-picture.png       — checkmark logo on brand green gradient,
//                                  padded to survive a circular avatar crop.
//   • highlight-14day.png        — 14-day cooling-off
//   • highlight-howtocancel.png  — how to cancel
//   • highlight-spending.png     — spending overview
//   • highlight-privacy.png      — privacy-first
//   • highlight-about.png        — about EasyCancel
//
// The 5 highlight covers form a visually consistent set: same soft
// brand-tinted background, same centred-glyph + tiny-label layout, so they
// read cleanly as a row under the IG bio.
//
// Technique mirrors scripts/render_og.swift:
//   NSBitmapImageRep + CGContext, Y-flipped top-left coords, RGBA draw →
//   flattened to opaque RGB before PNG encode. System-font fallback.
//
// Run:  swift scripts/render_profile.swift
//

import AppKit
import CoreGraphics
import CoreText
import Foundation

// MARK: - Canvas (square, both platforms use 1:1 avatars/covers)

let SIDE = 1080
let canvas = CGFloat(SIDE)

let outDir =
    "/Users/fuadasgarov/Documents/AllProjects/EasyCancel/marketing/social/profile"

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

// Brand palette (matches the app icon + render_og.swift)
let brandGreenLight = hex("#2f9e6b")   // gradient start
let brandGreenDark  = hex("#1c7a52")   // gradient end
let white           = hex("#FFFFFF")

let sRGB = CGColorSpaceCreateDeviceRGB()

// MARK: - Bitmap / context factory

/// Allocates an RGBA bitmap + a Y-flipped (top-left origin) CGContext.
func makeContext() -> (NSBitmapImageRep, CGContext) {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: SIDE,
        pixelsHigh: SIDE,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ), let nsCtx = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fputs("Failed to allocate bitmap/context\n", stderr)
        exit(1)
    }

    let cg = nsCtx.cgContext
    cg.translateBy(x: 0, y: canvas)
    cg.scaleBy(x: 1, y: -1)
    cg.setShouldAntialias(true)
    cg.interpolationQuality = .high
    cg.setAllowsAntialiasing(true)
    return (bitmap, cg)
}

// MARK: - Gradient helpers

func makeLinearGradient(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
    CGGradient(colorsSpace: sRGB,
               colors: stops.map { $0.1 } as CFArray,
               locations: stops.map { $0.0 })!
}

func makeRadialGradient(_ inner: CGColor, _ outer: CGColor) -> CGGradient {
    CGGradient(colorsSpace: sRGB,
               colors: [inner, outer] as CFArray,
               locations: [0.0, 1.0])!
}

// MARK: - Text helper (horizontally centred at cx, visual centre at cy)

func systemFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

@discardableResult
func drawCenteredText(_ cg: CGContext,
                      _ s: String,
                      cx: CGFloat, cy: CGFloat,
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

    let x = cx - typoWidth / 2
    let textY = cy + (ascent - descent) / 2

    cg.saveGState()
    cg.translateBy(x: 0, y: textY)
    cg.scaleBy(x: 1, y: -1)
    cg.translateBy(x: 0, y: -textY)
    cg.textPosition = CGPoint(x: x, y: textY)
    CTLineDraw(line, cg)
    cg.restoreGState()

    return typoWidth
}

// MARK: - Logo: white checkmark, drawn relative to a centre + scale.

/// Draws the EasyCancel checkmark stroke centred on (cx, cy).
/// `scale` of 1.0 ≈ a checkmark that fits comfortably in a ~340pt circle.
func drawCheckmark(_ cg: CGContext,
                   cx: CGFloat, cy: CGFloat,
                   scale: CGFloat,
                   lineWidth: CGFloat,
                   color: CGColor)
{
    cg.saveGState()
    cg.setLineCap(.round)
    cg.setLineJoin(.round)
    cg.setLineWidth(lineWidth)
    cg.setStrokeColor(color)

    // Checkmark geometry (matches render_og proportions), centred & scaled.
    let p1 = CGPoint(x: cx - 92 * scale, y: cy + 8  * scale)
    let p2 = CGPoint(x: cx - 26 * scale, y: cy + 78 * scale)
    let p3 = CGPoint(x: cx + 100 * scale, y: cy - 74 * scale)

    cg.beginPath()
    cg.move(to: p1)
    cg.addLine(to: p2)
    cg.addLine(to: p3)
    cg.strokePath()
    cg.restoreGState()
}

// MARK: - Encode an RGBA bitmap to an opaque (RGB) PNG file.

func writeOpaquePNG(_ bitmap: NSBitmapImageRep, to path: String) {
    guard let src = bitmap.bitmapData else {
        fputs("Source bitmap has no data\n", stderr); exit(1)
    }
    let srcBytesPerRow = bitmap.bytesPerRow

    guard let flat = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: SIDE,
        pixelsHigh: SIDE,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 24
    ), let dst = flat.bitmapData else {
        fputs("Failed to allocate flatten bitmap\n", stderr); exit(1)
    }
    let dstBytesPerRow = flat.bytesPerRow

    for y in 0..<SIDE {
        let srcRow = src.advanced(by: y * srcBytesPerRow)
        let dstRow = dst.advanced(by: y * dstBytesPerRow)
        for x in 0..<SIDE {
            dstRow[x * 3 + 0] = srcRow[x * 4 + 0]
            dstRow[x * 3 + 1] = srcRow[x * 4 + 1]
            dstRow[x * 3 + 2] = srcRow[x * 4 + 2]
        }
    }

    guard let png = flat.representation(using: .png,
                                        properties: [.interlaced: false]) else {
        fputs("Failed to encode PNG\n", stderr); exit(1)
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
    } catch {
        fputs("Failed to write PNG: \(error)\n", stderr); exit(1)
    }
    print("Wrote \(path)  \(flat.pixelsWide)x\(flat.pixelsHigh)  bytes=\(png.count)  hasAlpha=\(flat.hasAlpha)")
}

// =====================================================================
// 1. PROFILE PICTURE — checkmark logo on brand green gradient.
//    Padded so it survives a circular avatar crop on both IG + TikTok.
// =====================================================================
func renderProfilePicture() {
    let (bitmap, cg) = makeContext()
    let cx = canvas / 2
    let cy = canvas / 2

    // Diagonal brand gradient fills the whole square (the corners get clipped
    // away by the circular avatar, so the gradient must reach the edges).
    do {
        let grad = makeLinearGradient([
            (0.00, brandGreenLight),
            (1.00, brandGreenDark),
        ])
        cg.saveGState()
        cg.addRect(CGRect(x: 0, y: 0, width: canvas, height: canvas))
        cg.clip()
        cg.drawLinearGradient(grad,
                              start: CGPoint(x: 0, y: 0),
                              end:   CGPoint(x: canvas, y: canvas),
                              options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        cg.restoreGState()
    }

    // Soft radial highlight, centred — adds depth and stays inside the crop.
    do {
        let g = makeRadialGradient(hex("#FFFFFF", 0.12), hex("#FFFFFF", 0.0))
        cg.saveGState()
        cg.drawRadialGradient(g,
                              startCenter: CGPoint(x: cx, y: cy - 40), startRadius: 0,
                              endCenter:   CGPoint(x: cx, y: cy - 40), endRadius: 560,
                              options: [])
        cg.restoreGState()
    }

    // Subtle lighter "disc" behind the checkmark (mirrors the app icon's
    // tonal circle). Kept well within the safe circular crop.
    do {
        let discR: CGFloat = 300
        cg.saveGState()
        cg.beginPath()
        cg.addArc(center: CGPoint(x: cx, y: cy), radius: discR,
                  startAngle: 0, endAngle: .pi * 2, clockwise: false)
        cg.setFillColor(hex("#FFFFFF", 0.10))
        cg.fillPath()
        cg.restoreGState()
    }

    // White checkmark, centred. Scale ~1.55 → fits comfortably inside the
    // safe zone (avatar crop radius ≈ 540; everything important < ~300 from
    // centre, so nothing important is ever clipped).
    drawCheckmark(cg,
                  cx: cx, cy: cy,
                  scale: 1.55,
                  lineWidth: 56,
                  color: white)

    writeOpaquePNG(bitmap, to: "\(outDir)/profile-picture.png")
}

// =====================================================================
// 2. STORY-HIGHLIGHT COVERS — consistent set.
//    Soft brand-tinted background + centred white glyph + tiny label.
// =====================================================================

struct Highlight {
    let file: String
    let label: String
    /// A drawing closure for the glyph, centred on (cx, cy) with the given
    /// stroke color. Drawn in white at a uniform visual weight across the set.
    let glyph: (_ cg: CGContext, _ cx: CGFloat, _ cy: CGFloat, _ color: CGColor) -> Void
}

func renderHighlight(_ h: Highlight) {
    let (bitmap, cg) = makeContext()
    let cx = canvas / 2
    let glyphCY = canvas / 2 - 60   // glyph sits a touch above centre
    let labelCY = canvas / 2 + 300  // tiny label near the lower third

    // Soft brand-tinted background: gentle vertical gradient, lighter than the
    // profile picture so the set reads as a calmer, unified row.
    do {
        let grad = makeLinearGradient([
            (0.00, hex("#3CA877")),   // soft light green
            (1.00, hex("#258B5F")),   // soft deeper green
        ])
        cg.saveGState()
        cg.addRect(CGRect(x: 0, y: 0, width: canvas, height: canvas))
        cg.clip()
        cg.drawLinearGradient(grad,
                              start: CGPoint(x: 0, y: 0),
                              end:   CGPoint(x: 0, y: canvas),
                              options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        cg.restoreGState()
    }

    // Faint radial halo behind the glyph for consistency across the set.
    do {
        let g = makeRadialGradient(hex("#FFFFFF", 0.10), hex("#FFFFFF", 0.0))
        cg.saveGState()
        cg.drawRadialGradient(g,
                              startCenter: CGPoint(x: cx, y: glyphCY), startRadius: 0,
                              endCenter:   CGPoint(x: cx, y: glyphCY), endRadius: 380,
                              options: [])
        cg.restoreGState()
    }

    // The glyph (white).
    h.glyph(cg, cx, glyphCY, white)

    // Tiny uppercase label, slightly translucent white, generous tracking.
    drawCenteredText(cg, h.label,
                     cx: cx, cy: labelCY,
                     font: systemFont(size: 64, weight: .semibold),
                     color: hex("#FFFFFF", 0.92),
                     tracking: 2.0)

    writeOpaquePNG(bitmap, to: "\(outDir)/\(h.file)")
}

// MARK: - Glyph primitives (uniform white line-art, ~consistent weight)

let glyphLine: CGFloat = 26      // shared stroke weight for the set

func strokeSetup(_ cg: CGContext, _ color: CGColor, _ width: CGFloat = glyphLine) {
    cg.setLineCap(.round)
    cg.setLineJoin(.round)
    cg.setLineWidth(width)
    cg.setStrokeColor(color)
}

// 14-day: a calendar with "14".
func glyph14Day(_ cg: CGContext, cx: CGFloat, cy: CGFloat, color: CGColor) {
    cg.saveGState()
    strokeSetup(cg, color)
    let w: CGFloat = 280, h: CGFloat = 260
    let rect = CGRect(x: cx - w/2, y: cy - h/2 + 18, width: w, height: h)
    let body = CGPath(roundedRect: rect, cornerWidth: 28, cornerHeight: 28, transform: nil)
    cg.addPath(body); cg.strokePath()
    // Top binding bar.
    cg.beginPath()
    cg.move(to: CGPoint(x: rect.minX + 14, y: rect.minY + 64))
    cg.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.minY + 64))
    cg.strokePath()
    // Two rings.
    for dx in [-70.0, 70.0] {
        cg.beginPath()
        cg.move(to: CGPoint(x: cx + CGFloat(dx), y: rect.minY - 24))
        cg.addLine(to: CGPoint(x: cx + CGFloat(dx), y: rect.minY + 28))
        cg.strokePath()
    }
    cg.restoreGState()
    // "14" filling the calendar body.
    drawCenteredText(cg, "14",
                     cx: cx, cy: cy + 50,
                     font: systemFont(size: 150, weight: .bold),
                     color: color)
}

// How to cancel: a circle with an "X" (a cancellation mark).
func glyphCancel(_ cg: CGContext, cx: CGFloat, cy: CGFloat, color: CGColor) {
    cg.saveGState()
    strokeSetup(cg, color, 30)
    let r: CGFloat = 150
    cg.beginPath()
    cg.addArc(center: CGPoint(x: cx, y: cy), radius: r,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.strokePath()
    let d: CGFloat = 64
    cg.beginPath()
    cg.move(to: CGPoint(x: cx - d, y: cy - d))
    cg.addLine(to: CGPoint(x: cx + d, y: cy + d))
    cg.move(to: CGPoint(x: cx + d, y: cy - d))
    cg.addLine(to: CGPoint(x: cx - d, y: cy + d))
    cg.strokePath()
    cg.restoreGState()
}

// Spending: a bar chart with an upper trend.
func glyphSpending(_ cg: CGContext, cx: CGFloat, cy: CGFloat, color: CGColor) {
    cg.saveGState()
    strokeSetup(cg, color)
    // Axes.
    let baseY = cy + 130
    let leftX = cx - 150
    cg.beginPath()
    cg.move(to: CGPoint(x: leftX, y: cy - 150))
    cg.addLine(to: CGPoint(x: leftX, y: baseY))
    cg.addLine(to: CGPoint(x: cx + 160, y: baseY))
    cg.strokePath()
    // Bars (filled rounded rects) of varying heights.
    let barW: CGFloat = 56
    let gap: CGFloat = 36
    let heights: [CGFloat] = [110, 170, 90]
    var bx = leftX + 44
    cg.setFillColor(color)
    for hgt in heights {
        let r = CGRect(x: bx, y: baseY - hgt, width: barW, height: hgt)
        cg.addPath(CGPath(roundedRect: r, cornerWidth: 14, cornerHeight: 14, transform: nil))
        cg.fillPath()
        bx += barW + gap
    }
    cg.restoreGState()
}

// Privacy: a padlock.
func glyphPrivacy(_ cg: CGContext, cx: CGFloat, cy: CGFloat, color: CGColor) {
    cg.saveGState()
    strokeSetup(cg, color)
    // Shackle.
    let shR: CGFloat = 70
    cg.beginPath()
    cg.addArc(center: CGPoint(x: cx, y: cy - 30),
              radius: shR,
              startAngle: .pi, endAngle: 0, clockwise: false)
    cg.strokePath()
    // Body.
    let bw: CGFloat = 220, bh: CGFloat = 170
    let body = CGRect(x: cx - bw/2, y: cy - 20, width: bw, height: bh)
    cg.setFillColor(color)
    cg.addPath(CGPath(roundedRect: body, cornerWidth: 28, cornerHeight: 28, transform: nil))
    cg.fillPath()
    // Keyhole (cut as brand-tint dot + slot).
    cg.setFillColor(hex("#258B5F"))
    cg.beginPath()
    cg.addArc(center: CGPoint(x: cx, y: cy + 50), radius: 22,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.fillPath()
    let slot = CGRect(x: cx - 9, y: cy + 50, width: 18, height: 52)
    cg.addPath(CGPath(roundedRect: slot, cornerWidth: 9, cornerHeight: 9, transform: nil))
    cg.fillPath()
    cg.restoreGState()
}

// About: the EasyCancel checkmark itself (ties the set back to the brand).
func glyphAbout(_ cg: CGContext, cx: CGFloat, cy: CGFloat, color: CGColor) {
    // Outline ring.
    cg.saveGState()
    strokeSetup(cg, color, 24)
    cg.beginPath()
    cg.addArc(center: CGPoint(x: cx, y: cy), radius: 158,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.strokePath()
    cg.restoreGState()
    // Checkmark inside.
    drawCheckmark(cg, cx: cx, cy: cy, scale: 0.95, lineWidth: 30, color: color)
}

// =====================================================================
// Render everything.
// =====================================================================
try? FileManager.default.createDirectory(
    atPath: outDir, withIntermediateDirectories: true)

renderProfilePicture()

let highlights: [Highlight] = [
    Highlight(file: "highlight-14day.png",        label: "14-DAY",  glyph: glyph14Day),
    Highlight(file: "highlight-howtocancel.png",  label: "CANCEL",  glyph: glyphCancel),
    Highlight(file: "highlight-spending.png",     label: "SPENDING", glyph: glyphSpending),
    Highlight(file: "highlight-privacy.png",      label: "PRIVACY", glyph: glyphPrivacy),
    Highlight(file: "highlight-about.png",        label: "ABOUT",   glyph: glyphAbout),
]

for h in highlights { renderHighlight(h) }

print("Done. All profile assets rendered to \(outDir)")

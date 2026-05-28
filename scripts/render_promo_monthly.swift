#!/usr/bin/env swift
//
// render_promo_monthly.swift
//
// Renders the Pro Monthly promotional image (1024×1024 sRGB PNG, opaque)
// per docs/app-store/PROMO_BRIEF_MONTHLY.md.
//
// Output: MarketingAssets/PromotedIAP/pro-monthly.png
//
// Runs on macOS via `swift scripts/render_promo_monthly.swift` from the
// EasyCancel/ directory. Uses NSBitmapImageRep + CGContext (no UIKit).
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Canvas

let canvas: CGFloat = 1024

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

// Palette (from brief §9)
let bgTealDeep      = hex("#0B3B4A")
let bgIndigoMid     = hex("#1E3A8A")
let bgIndigoDeep    = hex("#1E1B4B")
let cardSurface     = hex("#F8FAFC")
let cardBorder      = hex("#E2E8F0")
let headerTeal      = hex("#0F766E")
let accentTealLight = hex("#5EEAD4")
let weekdayMuted    = hex("#64748B")
let dayInk          = hex("#334155")
let sparkAmber      = hex("#FDE68A")
let inkOnDark       = hex("#FFFFFF")

// MARK: - Bitmap context (sRGB, opaque, no alpha — we paint a fully opaque bg)

let width  = Int(canvas)
let height = Int(canvas)

// NSGraphicsContext needs an alpha channel to draw into. We render into an
// RGBA bitmap (fully painting every pixel opaque) then strip alpha before
// encoding the PNG so the saved file has no transparency.
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,           // RGBA (required for drawing)
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

// CGContext on macOS has origin at BOTTOM-left. The brief uses TOP-left.
// We'll flip the CTM so y grows downward, matching the brief's coordinates.
let cg = nsCtx.cgContext
cg.translateBy(x: 0, y: canvas)
cg.scaleBy(x: 1, y: -1)
cg.setShouldAntialias(true)
cg.interpolationQuality = .high
cg.setAllowsAntialiasing(true)

// MARK: - Helpers (y is already top-left after the flip)

let sRGB = CGColorSpaceCreateDeviceRGB()

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

// Rounded-rect path with independent corner radii (TL, TR, BR, BL).
// (Used for the header band which needs flat bottom corners.)
func roundedRectPath(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                     tl: CGFloat, tr: CGFloat, br: CGFloat, bl: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x + tl, y: y))
    p.addLine(to: CGPoint(x: x + w - tr, y: y))
    if tr > 0 {
        p.addArc(center: CGPoint(x: x + w - tr, y: y + tr),
                 radius: tr,
                 startAngle: -.pi / 2, endAngle: 0, clockwise: false)
    }
    p.addLine(to: CGPoint(x: x + w, y: y + h - br))
    if br > 0 {
        p.addArc(center: CGPoint(x: x + w - br, y: y + h - br),
                 radius: br,
                 startAngle: 0, endAngle: .pi / 2, clockwise: false)
    }
    p.addLine(to: CGPoint(x: x + bl, y: y + h))
    if bl > 0 {
        p.addArc(center: CGPoint(x: x + bl, y: y + h - bl),
                 radius: bl,
                 startAngle: .pi / 2, endAngle: .pi, clockwise: false)
    }
    p.addLine(to: CGPoint(x: x, y: y + tl))
    if tl > 0 {
        p.addArc(center: CGPoint(x: x + tl, y: y + tl),
                 radius: tl,
                 startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: false)
    }
    p.closeSubpath()
    return p
}

// Draw text centred on (cx, cy) — cy interpreted as the visual centre.
// Because the CTM is y-flipped, text drawn through NSAttributedString will
// also be flipped. We undo just for the text by saving/restoring + flipping
// back inside a local transform.
func drawCenteredText(_ s: String,
                      cx: CGFloat, cy: CGFloat,
                      font: NSFont,
                      color: CGColor,
                      tracking: CGFloat = 0)
{
    let para = NSMutableParagraphStyle()
    para.alignment = .center

    var attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color) ?? .white,
        .paragraphStyle: para,
    ]
    if tracking != 0 {
        attrs[.kern] = tracking
    }

    let str = NSAttributedString(string: s, attributes: attrs)
    let line = CTLineCreateWithAttributedString(str)
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let typoWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

    // Position so the visual centre lands on (cx, cy).
    let textX = cx - typoWidth / 2
    let textY = cy + (ascent - descent) / 2   // baseline

    cg.saveGState()
    // Flip back for text so glyphs render right-way-up.
    cg.translateBy(x: 0, y: textY)
    cg.scaleBy(x: 1, y: -1)
    cg.translateBy(x: 0, y: -textY)
    cg.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, cg)
    cg.restoreGState()
}

func systemFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

// =====================================================================
// 1. Background diagonal gradient (TL → BR)
// =====================================================================
do {
    let grad = makeLinearGradient(stops: [
        (0.00, bgTealDeep),
        (0.55, bgIndigoMid),
        (1.00, bgIndigoDeep),
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

// =====================================================================
// 2. Radial spotlight overlay (centre 512,470 — soft white, 8% → 0%)
// =====================================================================
do {
    let inner = hex("#FFFFFF", 0.08)
    let outer = hex("#FFFFFF", 0.00)
    let g = makeRadialGradient(inner, outer)
    cg.saveGState()
    cg.drawRadialGradient(g,
                          startCenter: CGPoint(x: 512, y: 470), startRadius: 0,
                          endCenter:   CGPoint(x: 512, y: 470), endRadius: 620,
                          options: [])
    cg.restoreGState()
}

// =====================================================================
// 3 + 4. Card drop shadow + card fill + inner stroke
// =====================================================================
let cardX: CGFloat = 192
let cardY: CGFloat = 232
let cardW: CGFloat = 640
let cardH: CGFloat = 560
let cardR: CGFloat = 56

let cardPath = roundedRectPath(x: cardX, y: cardY, w: cardW, h: cardH,
                               tl: cardR, tr: cardR, br: cardR, bl: cardR)

do {
    cg.saveGState()
    // Brief says offset (0, +24) in top-left coords (i.e. shadow below the card).
    // Our CTM is flipped, so in CG-native space the offset is (0, -24). We
    // compensate by using +24 in the flipped frame.
    let shadowColor = hex("#000000", 0.35)
    cg.setShadow(offset: CGSize(width: 0, height: -24),
                 blur: 48,
                 color: shadowColor)
    cg.addPath(cardPath)
    cg.setFillColor(cardSurface)
    cg.fillPath()
    cg.restoreGState()
}

// Inner stroke (2 px, inset by 1 px)
do {
    cg.saveGState()
    let strokePath = roundedRectPath(x: cardX + 1, y: cardY + 1,
                                     w: cardW - 2, h: cardH - 2,
                                     tl: cardR - 1, tr: cardR - 1,
                                     br: cardR - 1, bl: cardR - 1)
    cg.addPath(strokePath)
    cg.setLineWidth(2)
    cg.setStrokeColor(cardBorder)
    cg.strokePath()
    cg.restoreGState()
}

// =====================================================================
// 5. Header band (teal, top-rounded only)
// =====================================================================
let headerH: CGFloat = 96
do {
    cg.saveGState()
    // Clip to whole card so the band can't bleed past rounded corners.
    cg.addPath(cardPath)
    cg.clip()

    // Rect that covers just the header band (full card width, height 96).
    cg.setFillColor(headerTeal)
    cg.fill(CGRect(x: cardX, y: cardY, width: cardW, height: headerH))
    cg.restoreGState()
}

// =====================================================================
// 6. Header text "MONTH" — centred at (512, 296)
// =====================================================================
drawCenteredText("MONTH",
                 cx: 512, cy: 296,
                 font: systemFont(size: 40, weight: .semibold),
                 color: inkOnDark,
                 tracking: 6)

// =====================================================================
// 7. Weekday row (M T W T F S S) — y centre 360
// =====================================================================
let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]
let columnXs: [CGFloat] = [260, 344, 428, 512, 596, 680, 764]
for (i, letter) in weekdayLetters.enumerated() {
    drawCenteredText(letter,
                     cx: columnXs[i], cy: 360,
                     font: systemFont(size: 22, weight: .medium),
                     color: weekdayMuted)
}

// =====================================================================
// 8. Days 2–28
// =====================================================================
let rowYs: [CGFloat] = [420, 504, 588, 672]
for row in 0..<4 {
    for col in 0..<7 {
        let day = row * 7 + col + 1
        if day == 1 { continue }       // day-1 handled later
        if day > 28 { break }
        let cx = columnXs[col]
        let cy = rowYs[row]
        drawCenteredText("\(day)",
                         cx: cx, cy: cy,
                         font: systemFont(size: 24, weight: .medium),
                         color: dayInk)
    }
}

// =====================================================================
// 9. Day-1 outer soft halo (radial gradient, 40 → 96)
// =====================================================================
do {
    let inner = hex("#5EEAD4", 0.30)
    let outer = hex("#5EEAD4", 0.00)
    let g = makeRadialGradient(inner, outer)
    cg.saveGState()
    cg.drawRadialGradient(g,
                          startCenter: CGPoint(x: 260, y: 420), startRadius: 40,
                          endCenter:   CGPoint(x: 260, y: 420), endRadius: 96,
                          options: [])
    cg.restoreGState()
}

// =====================================================================
// 10. Day-1 rings (outer halo ring r=60 @ 40%, main ring r=44 @ 100%)
// =====================================================================
do {
    // Outer halo ring
    cg.saveGState()
    cg.setLineWidth(2)
    cg.setStrokeColor(hex("#5EEAD4", 0.40))
    cg.addArc(center: CGPoint(x: 260, y: 420), radius: 60,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.strokePath()
    cg.restoreGState()

    // Main glowing ring
    cg.saveGState()
    cg.setLineWidth(4)
    cg.setStrokeColor(accentTealLight)
    cg.addArc(center: CGPoint(x: 260, y: 420), radius: 44,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.strokePath()
    cg.restoreGState()
}

// =====================================================================
// 11. Day-1 inner disc (radius 32, teal-700)
// =====================================================================
do {
    cg.saveGState()
    cg.setFillColor(headerTeal)
    cg.addArc(center: CGPoint(x: 260, y: 420), radius: 32,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.fillPath()
    cg.restoreGState()
}

// =====================================================================
// 12. Day-1 "1" numeral (white, 28 pt semibold)
// =====================================================================
drawCenteredText("1",
                 cx: 260, cy: 420,
                 font: systemFont(size: 28, weight: .semibold),
                 color: inkOnDark)

// =====================================================================
// 13. Spark circle background (r=36, white @ 18%)
// =====================================================================
do {
    cg.saveGState()
    cg.setFillColor(hex("#FFFFFF", 0.18))
    cg.addArc(center: CGPoint(x: 800, y: 264), radius: 36,
              startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.fillPath()
    cg.restoreGState()
}

// =====================================================================
// 14. Spark arrow + sparkle
// =====================================================================
do {
    cg.saveGState()
    cg.setLineWidth(5)
    cg.setLineCap(.round)
    cg.setStrokeColor(inkOnDark)

    // Shaft: (786, 282) -> (816, 252)
    cg.move(to: CGPoint(x: 786, y: 282))
    cg.addLine(to: CGPoint(x: 816, y: 252))
    // Arrowhead leg 1: (816,252) -> (816,268)
    cg.move(to: CGPoint(x: 816, y: 252))
    cg.addLine(to: CGPoint(x: 816, y: 268))
    // Arrowhead leg 2: (816,252) -> (800,252)
    cg.move(to: CGPoint(x: 816, y: 252))
    cg.addLine(to: CGPoint(x: 800, y: 252))
    cg.strokePath()
    cg.restoreGState()

    // Sparkle: 4-point star at (848,240), radius 8, amber @ 80%
    cg.saveGState()
    cg.setFillColor(hex("#FDE68A", 0.80))
    let sx: CGFloat = 848, sy: CGFloat = 240, r: CGFloat = 8, n: CGFloat = 2.2
    let star = CGMutablePath()
    star.move   (to: CGPoint(x: sx, y: sy - r))
    star.addLine(to: CGPoint(x: sx + r / n, y: sy - r / n))
    star.addLine(to: CGPoint(x: sx + r, y: sy))
    star.addLine(to: CGPoint(x: sx + r / n, y: sy + r / n))
    star.addLine(to: CGPoint(x: sx, y: sy + r))
    star.addLine(to: CGPoint(x: sx - r / n, y: sy + r / n))
    star.addLine(to: CGPoint(x: sx - r, y: sy))
    star.addLine(to: CGPoint(x: sx - r / n, y: sy - r / n))
    star.closeSubpath()
    cg.addPath(star)
    cg.fillPath()
    cg.restoreGState()
}

// =====================================================================
// 15. "PRO" wordmark + thin underline
// =====================================================================
drawCenteredText("PRO",
                 cx: 512, cy: 868,
                 font: systemFont(size: 64, weight: .semibold),
                 color: cardSurface,
                 tracking: 12)

// Underline: 2 px tall × 64 px wide, centred at (512, 884), teal-300 @ 70%
do {
    cg.saveGState()
    cg.setFillColor(hex("#5EEAD4", 0.70))
    cg.fill(CGRect(x: 512 - 32, y: 884 - 1, width: 64, height: 2))
    cg.restoreGState()
}

// =====================================================================
// Encode → PNG (sRGB, opaque)
// =====================================================================
let outputDir  = "MarketingAssets/PromotedIAP"
let outputPath = "\(outputDir)/pro-monthly.png"

try? FileManager.default.createDirectory(atPath: outputDir,
                                         withIntermediateDirectories: true)

// Flatten to an alpha-less (RGB) bitmap before PNG encoding so the saved
// file is unambiguously opaque — `sips -g hasAlpha` will report "no".
//
// NSGraphicsContext can't back an alpha-less bitmap, so we copy pixel data
// manually from the RGBA source into a fresh 24-bit RGB rep (every source
// pixel is already opaque; we just drop the A byte).
guard let src = bitmap.bitmapData else {
    fputs("Source bitmap has no data\n", stderr)
    exit(1)
}
let srcBytesPerRow = bitmap.bytesPerRow

guard let flatRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
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

for y in 0..<height {
    let srcRow = src.advanced(by: y * srcBytesPerRow)
    let dstRow = dst.advanced(by: y * dstBytesPerRow)
    for x in 0..<width {
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

let pixW = flatRep.pixelsWide
let pixH = flatRep.pixelsHigh
print("Wrote \(outputPath)  \(pixW)x\(pixH)  bytes=\(pngData.count)  hasAlpha=\(flatRep.hasAlpha)")

#!/usr/bin/env swift
//
// render_vertical.swift
//
// Renders 6 VERTICAL (Stories / Reels / TikTok) branded frames for EasyCancel.
// Each is a 1080×1920 sRGB PNG, opaque (no alpha).
//
// Output: marketing/social/vertical/V1.png .. V6.png
//
// Run from EasyCancel/ directory:  swift scripts/render_vertical.swift
//
// Technique mirrors scripts/render_promo_yearly.swift:
//   • CGContext(.noneSkipLast) → opaque sRGB, no alpha
//   • Y-flipped CTM so (0,0) is top-left, y grows downward
//   • System-font fallback via NSFontDescriptor design
//   • CGImageDestination PNG encode
//
// SAFE ZONE: all important text/elements live between SAFE_TOP (250px) and
// SAFE_BOTTOM (1920-340 = 1580px). The platform UI (caption, buttons, profile)
// overlaps the excluded bands.
//

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import AppKit

// MARK: - Canvas constants

let W = 1080
let H = 1920
let canvasW = CGFloat(W)
let canvasH = CGFloat(H)

let SAFE_TOP: CGFloat = 250          // avoid top ~250px
let SAFE_BOTTOM: CGFloat = canvasH - 340   // 1580 — avoid bottom ~340px
let SIDE_MARGIN: CGFloat = 90

let baseDir = "/Users/fuadasgarov/Documents/AllProjects/EasyCancel"
let outputDir = "\(baseDir)/marketing/social/vertical"
let assetsDir = "\(baseDir)/web/assets"

try? FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true)

func makeSRGB() -> CGColorSpace {
    guard let cs = CGColorSpace(name: CGColorSpace.sRGB) else { fatalError("no sRGB") }
    return cs
}

// MARK: - Colour helpers

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8) & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// Brand palette
let brandGreenLight: UInt32 = 0x2f9e6b
let brandGreenDark: UInt32 = 0x1c7a52
let inkColor: UInt32 = 0x10261d
let whiteHex: UInt32 = 0xFFFFFF

// MARK: - Font helper

func font(_ size: CGFloat, _ weight: NSFont.Weight,
          design: NSFontDescriptor.SystemDesign = .default) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if let d = base.fontDescriptor.withDesign(design),
       let f = NSFont(descriptor: d, size: size) {
        return f
    }
    return base
}

// MARK: - Per-frame rendering context

final class Frame {
    let ctx: CGContext

    init() {
        guard let c = CGContext(
            data: nil, width: W, height: H,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: makeSRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { fatalError("no context") }
        // Flip Y so (0,0) is top-left.
        c.translateBy(x: 0, y: canvasH)
        c.scaleBy(x: 1, y: -1)
        c.setShouldAntialias(true)
        c.setAllowsAntialiasing(true)
        c.interpolationQuality = .high
        self.ctx = c
    }

    // Build an attributed string + line, returns (line, typographic size).
    private func makeLine(_ text: String, font f: NSFont, color: CGColor,
                          tracking: CGFloat) -> (CTLine, CGSize) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: f,
            .foregroundColor: NSColor(cgColor: color) ?? .white,
            .kern: tracking,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(str)
        let b = CTLineGetBoundsWithOptions(line, [.useOpticalBounds])
        return (line, b.size)
    }

    @discardableResult
    func measureWidth(_ text: String, font f: NSFont, tracking: CGFloat = 0) -> CGFloat {
        let (_, size) = makeLine(text, font: f, color: rgb(whiteHex), tracking: tracking)
        return size.width
    }

    // Draws text whose visual centre is at (cx, cy).
    func drawCentered(_ text: String, cx: CGFloat, cy: CGFloat,
                      font f: NSFont, color: CGColor, tracking: CGFloat = 0) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: f,
            .foregroundColor: NSColor(cgColor: color) ?? .white,
            .kern: tracking,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(str)
        let bounds = CTLineGetBoundsWithOptions(line, [.useOpticalBounds])
        ctx.saveGState()
        let baselineX = cx - bounds.width / 2 - bounds.origin.x
        let baselineY = cy + bounds.height / 2 + bounds.origin.y
        ctx.translateBy(x: baselineX, y: baselineY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    // Draws text whose LEFT edge is at x and visual centre vertically at cy.
    func drawLeft(_ text: String, x: CGFloat, cy: CGFloat,
                  font f: NSFont, color: CGColor, tracking: CGFloat = 0) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: f,
            .foregroundColor: NSColor(cgColor: color) ?? .white,
            .kern: tracking,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(str)
        let bounds = CTLineGetBoundsWithOptions(line, [.useOpticalBounds])
        ctx.saveGState()
        let baselineX = x - bounds.origin.x
        let baselineY = cy + bounds.height / 2 + bounds.origin.y
        ctx.translateBy(x: baselineX, y: baselineY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    // Word-wraps `text` to fit `maxWidth`, centre-aligned, returns total height.
    @discardableResult
    func drawWrappedCentered(_ text: String, cx: CGFloat, topY: CGFloat,
                             maxWidth: CGFloat, font f: NSFont, color: CGColor,
                             lineSpacing: CGFloat, tracking: CGFloat = 0) -> CGFloat {
        let words = text.split(separator: " ").map(String.init)
        var lines: [String] = []
        var current = ""
        for w in words {
            let trial = current.isEmpty ? w : current + " " + w
            if measureWidth(trial, font: f, tracking: tracking) <= maxWidth || current.isEmpty {
                current = trial
            } else {
                lines.append(current)
                current = w
            }
        }
        if !current.isEmpty { lines.append(current) }

        // Approximate per-line height from a tall sample.
        let (_, sample) = makeLine("Ag", font: f, color: color, tracking: tracking)
        let lineH = sample.height
        var y = topY + lineH / 2
        for ln in lines {
            drawCentered(ln, cx: cx, cy: y, font: f, color: color, tracking: tracking)
            y += lineH + lineSpacing
        }
        return CGFloat(lines.count) * lineH + CGFloat(max(0, lines.count - 1)) * lineSpacing
    }

    // MARK: backgrounds

    func diagonalGradient(_ a: UInt32, _ b: UInt32) {
        let grad = CGGradient(colorsSpace: makeSRGB(),
                              colors: [rgb(a), rgb(b)] as CFArray,
                              locations: [0, 1])!
        ctx.saveGState()
        ctx.addRect(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
        ctx.clip()
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: canvasW, y: canvasH),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }

    func radialHighlight(center: CGPoint, radius: CGFloat, alpha: CGFloat) {
        let g = CGGradient(colorsSpace: makeSRGB(),
                           colors: [rgb(whiteHex, alpha), rgb(whiteHex, 0)] as CFArray,
                           locations: [0, 1])!
        ctx.saveGState()
        ctx.drawRadialGradient(g,
                               startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: radius,
                               options: [])
        ctx.restoreGState()
    }

    // White circle + green checkmark logo, centred at (cx, cy), given radius.
    func logoBadge(cx: CGFloat, cy: CGFloat, r: CGFloat,
                   ringColor: UInt32 = brandGreenLight) {
        // Drop shadow.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 26,
                      color: rgb(0x0A3A26, 0.35))
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.setFillColor(rgb(whiteHex))
        ctx.fillPath()
        ctx.restoreGState()

        // Checkmark in brand green, proportioned to the circle.
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(r * 0.20)
        ctx.setStrokeColor(rgb(ringColor))
        let p1 = CGPoint(x: cx - r * 0.44, y: cy + r * 0.04)
        let p2 = CGPoint(x: cx - r * 0.12, y: cy + r * 0.36)
        let p3 = CGPoint(x: cx + r * 0.48, y: cy - r * 0.34)
        ctx.beginPath()
        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.addLine(to: p3)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // Rounded-rect pill, optional fill + stroke. Coordinates are top-left origin.
    func pill(rect: CGRect, radius: CGFloat, fill: CGColor?, stroke: CGColor?,
              lineWidth: CGFloat = 2) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius,
                          cornerHeight: radius, transform: nil)
        if let fill = fill {
            ctx.addPath(path)
            ctx.setFillColor(fill)
            ctx.fillPath()
        }
        if let stroke = stroke {
            ctx.addPath(path)
            ctx.setStrokeColor(stroke)
            ctx.setLineWidth(lineWidth)
            ctx.strokePath()
        }
    }

    // Draw a screenshot image scaled to fit inside `rect` (aspect-fit), with a
    // rounded-corner mask and a subtle border + shadow. Centres within rect.
    func drawScreenshot(path: String, in rect: CGRect, corner: CGFloat) {
        guard let nsImg = NSImage(contentsOfFile: path),
              let cgImg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            fputs("WARN: could not load screenshot \(path)\n", stderr)
            return
        }
        let imgW = CGFloat(cgImg.width)
        let imgH = CGFloat(cgImg.height)
        let scale = min(rect.width / imgW, rect.height / imgH)
        let drawW = imgW * scale
        let drawH = imgH * scale
        let drawX = rect.midX - drawW / 2
        let drawY = rect.midY - drawH / 2
        let drawRect = CGRect(x: drawX, y: drawY, width: drawW, height: drawH)

        // Drop shadow.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40,
                      color: rgb(0x06140E, 0.45))
        let rr = CGPath(roundedRect: drawRect, cornerWidth: corner,
                        cornerHeight: corner, transform: nil)
        ctx.addPath(rr)
        ctx.setFillColor(rgb(0x06140E, 0.9))
        ctx.fillPath()
        ctx.restoreGState()

        // Clip to rounded rect & draw image (flip locally for correct orientation).
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: drawRect, cornerWidth: corner,
                           cornerHeight: corner, transform: nil))
        ctx.clip()
        ctx.saveGState()
        ctx.translateBy(x: 0, y: drawRect.maxY + drawRect.minY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cgImg, in: drawRect)
        ctx.restoreGState()
        ctx.restoreGState()

        // Crisp white-ish border.
        ctx.addPath(CGPath(roundedRect: drawRect, cornerWidth: corner,
                           cornerHeight: corner, transform: nil))
        ctx.setStrokeColor(rgb(whiteHex, 0.18))
        ctx.setLineWidth(3)
        ctx.strokePath()
    }

    // Small wordmark lockup: checkmark badge + "EasyCancel" text, centred at cx.
    func wordmarkLockup(cx: CGFloat, cy: CGFloat, badgeR: CGFloat,
                        fontSize: CGFloat) {
        let f = font(fontSize, .bold)
        let textW = measureWidth("EasyCancel", font: f, tracking: -0.5)
        let gap: CGFloat = badgeR * 0.7
        let totalW = badgeR * 2 + gap + textW
        let startX = cx - totalW / 2
        logoBadge(cx: startX + badgeR, cy: cy, r: badgeR)
        drawLeft("EasyCancel", x: startX + badgeR * 2 + gap, cy: cy,
                 font: f, color: rgb(whiteHex), tracking: -0.5)
    }

    func save(to path: String) {
        guard let image = ctx.makeImage() else { fatalError("makeImage failed") }
        let url = URL(fileURLWithPath: path)
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { fatalError("CGImageDestination failed") }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { fatalError("finalize failed") }
        print("wrote \(path) (\(image.width)x\(image.height))")
    }
}

// Shared background recipe used by most frames.
func paintBackground(_ frame: Frame, highlightTop: Bool = true) {
    frame.diagonalGradient(brandGreenLight, brandGreenDark)
    if highlightTop {
        frame.radialHighlight(center: CGPoint(x: canvasW * 0.5, y: canvasH * 0.42),
                              radius: 760, alpha: 0.10)
    }
}

// Small eyebrow pill (label above the headline).
func eyebrow(_ frame: Frame, _ text: String, cx: CGFloat, cy: CGFloat) {
    let f = font(30, .bold)
    let tw = frame.measureWidth(text.uppercased(), font: f, tracking: 3)
    let padX: CGFloat = 36
    let padY: CGFloat = 18
    let h: CGFloat = 64
    let w = tw + padX * 2
    let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
    frame.pill(rect: rect, radius: h / 2,
               fill: rgb(whiteHex, 0.16), stroke: rgb(whiteHex, 0.28), lineWidth: 2)
    _ = padY
    frame.drawCentered(text.uppercased(), cx: cx, cy: cy,
                       font: f, color: rgb(whiteHex), tracking: 3)
}

// =====================================================================
// V1 — Hook frame
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)

    let cx = canvasW / 2
    eyebrow(frame, "Wait. what?", cx: cx, cy: SAFE_TOP + 60)

    // Big scroll-stopping headline, wrapped.
    let headFont = font(96, .heavy)
    let blockTop: CGFloat = SAFE_TOP + 200
    frame.drawWrappedCentered(
        "POV: you just found subscriptions you forgot you were paying for",
        cx: cx, topY: blockTop, maxWidth: canvasW - SIDE_MARGIN * 2,
        font: headFont, color: rgb(whiteHex), lineSpacing: 14, tracking: -1)

    // Bleeding-money emoji-free accent line near lower safe area.
    let subFont = font(40, .semibold)
    frame.drawWrappedCentered(
        "Most people pay for 2 to 3 they never use.",
        cx: cx, topY: SAFE_BOTTOM - 200, maxWidth: canvasW - SIDE_MARGIN * 2,
        font: subFont, color: rgb(whiteHex, 0.85), lineSpacing: 8)

    frame.wordmarkLockup(cx: cx, cy: SAFE_BOTTOM - 30, badgeR: 26, fontSize: 40)

    frame.save(to: "\(outputDir)/V1.png")
}

// =====================================================================
// V2 — The 14-day rule
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)
    let cx = canvasW / 2

    eyebrow(frame, "Know your rights", cx: cx, cy: SAFE_TOP + 60)

    frame.drawCentered("The EU / UK", cx: cx, cy: SAFE_TOP + 190,
                       font: font(64, .semibold), color: rgb(whiteHex, 0.92))
    frame.drawCentered("cooling-off rule", cx: cx, cy: SAFE_TOP + 270,
                       font: font(64, .semibold), color: rgb(whiteHex, 0.92))

    // Huge "14" with "DAYS" beneath.
    frame.drawCentered("14", cx: cx, cy: canvasH * 0.50,
                       font: font(440, .heavy), color: rgb(whiteHex), tracking: -8)
    frame.drawCentered("DAYS", cx: cx, cy: canvasH * 0.50 + 250,
                       font: font(120, .heavy), color: rgb(whiteHex), tracking: 12)

    // Supporting copy in lower safe zone.
    frame.drawWrappedCentered(
        "You can usually cancel many online subscriptions within 14 days, no questions asked.",
        cx: cx, topY: SAFE_BOTTOM - 210, maxWidth: canvasW - SIDE_MARGIN * 2,
        font: font(38, .medium), color: rgb(whiteHex, 0.85), lineSpacing: 8)

    frame.wordmarkLockup(cx: cx, cy: SAFE_BOTTOM - 26, badgeR: 24, fontSize: 36)

    frame.save(to: "\(outputDir)/V2.png")
}

// =====================================================================
// V3 — Mini-demo frame (composite screenshot)
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)
    let cx = canvasW / 2

    eyebrow(frame, "How it works", cx: cx, cy: SAFE_TOP + 50)

    // Caption above the device shot.
    frame.drawCentered("track  →  count down  →  cancel",
                       cx: cx, cy: SAFE_TOP + 170,
                       font: font(56, .bold), color: rgb(whiteHex), tracking: -0.5)

    // Screenshot composited in the centre, inside the safe zone.
    let shotTop = SAFE_TOP + 240
    let shotRect = CGRect(x: SIDE_MARGIN, y: shotTop,
                          width: canvasW - SIDE_MARGIN * 2,
                          height: SAFE_BOTTOM - 110 - shotTop)
    frame.drawScreenshot(path: "\(assetsDir)/shot-home.png",
                         in: shotRect, corner: 44)

    frame.wordmarkLockup(cx: cx, cy: SAFE_BOTTOM - 35, badgeR: 26, fontSize: 40)

    frame.save(to: "\(outputDir)/V3.png")
}

// =====================================================================
// V4 — CTA / end card
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)
    let cx = canvasW / 2

    // Big logo badge near the top of the safe zone.
    frame.logoBadge(cx: cx, cy: SAFE_TOP + 170, r: 130)

    frame.drawCentered("EasyCancel", cx: cx, cy: SAFE_TOP + 380,
                       font: font(88, .heavy), color: rgb(whiteHex), tracking: -1)

    // Headline CTA.
    frame.drawCentered("Join the waitlist", cx: cx, cy: canvasH * 0.55,
                       font: font(110, .heavy), color: rgb(whiteHex), tracking: -1.5)

    // "link in bio" pill.
    do {
        let f = font(44, .bold)
        let txt = "link in bio"
        let tw = frame.measureWidth(txt, font: f, tracking: 0.5)
        let w = tw + 90
        let h: CGFloat = 96
        let cyPill = canvasH * 0.55 + 150
        let rect = CGRect(x: cx - w / 2, y: cyPill - h / 2, width: w, height: h)
        frame.pill(rect: rect, radius: h / 2, fill: rgb(whiteHex), stroke: nil)
        frame.drawCentered(txt, cx: cx, cy: cyPill, font: f,
                           color: rgb(brandGreenDark), tracking: 0.5)
    }

    // URL in lower safe zone.
    frame.drawCentered("easycancel.vincli.com", cx: cx, cy: SAFE_BOTTOM - 60,
                       font: font(46, .semibold), color: rgb(whiteHex, 0.95), tracking: 0.5)

    frame.save(to: "\(outputDir)/V4.png")
}

// =====================================================================
// V5 — Coming soon teaser
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)
    let cx = canvasW / 2

    eyebrow(frame, "Coming soon", cx: cx, cy: SAFE_TOP + 60)

    // Centered logo lockup.
    frame.logoBadge(cx: cx, cy: canvasH * 0.40, r: 150)

    frame.drawCentered("EasyCancel", cx: cx, cy: canvasH * 0.40 + 250,
                       font: font(96, .heavy), color: rgb(whiteHex), tracking: -1)

    frame.drawWrappedCentered(
        "is almost here.",
        cx: cx, topY: canvasH * 0.40 + 320, maxWidth: canvasW - SIDE_MARGIN * 2,
        font: font(60, .semibold), color: rgb(whiteHex, 0.92), lineSpacing: 6)

    // Subtitle in lower safe zone.
    frame.drawWrappedCentered(
        "Privacy-first subscription tracking for iPhone.",
        cx: cx, topY: SAFE_BOTTOM - 150, maxWidth: canvasW - SIDE_MARGIN * 2,
        font: font(40, .medium), color: rgb(whiteHex, 0.82), lineSpacing: 6)

    frame.drawCentered("easycancel.vincli.com", cx: cx, cy: SAFE_BOTTOM - 30,
                       font: font(34, .semibold), color: rgb(whiteHex, 0.75), tracking: 0.5)

    frame.save(to: "\(outputDir)/V5.png")
}

// =====================================================================
// V6 — "3 subscriptions to check RIGHT NOW" (list look)
// =====================================================================
do {
    let frame = Frame()
    paintBackground(frame)
    let cx = canvasW / 2

    eyebrow(frame, "Do this today", cx: cx, cy: SAFE_TOP + 50)

    frame.drawCentered("3 subscriptions to", cx: cx, cy: SAFE_TOP + 175,
                       font: font(78, .heavy), color: rgb(whiteHex), tracking: -1)
    frame.drawCentered("check RIGHT NOW", cx: cx, cy: SAFE_TOP + 265,
                       font: font(78, .heavy), color: rgb(whiteHex), tracking: -1)

    // Three list rows as cards.
    let items: [(String, String)] = [
        ("Free trials", "that quietly auto-renew"),
        ("Streaming", "you stopped watching"),
        ("App add-ons", "billed yearly, forgotten"),
    ]
    let rowsTop: CGFloat = SAFE_TOP + 370
    let rowH: CGFloat = 200
    let rowGap: CGFloat = 36
    let cardX = SIDE_MARGIN
    let cardW = canvasW - SIDE_MARGIN * 2

    for (i, item) in items.enumerated() {
        let y = rowsTop + CGFloat(i) * (rowH + rowGap)
        let rect = CGRect(x: cardX, y: y, width: cardW, height: rowH)
        // Card background.
        frame.pill(rect: rect, radius: 36,
                   fill: rgb(whiteHex, 0.14), stroke: rgb(whiteHex, 0.22), lineWidth: 2)

        // Number badge.
        let badgeR: CGFloat = 56
        let badgeCX = cardX + 60 + badgeR
        let badgeCY = y + rowH / 2
        frame.ctx.beginPath()
        frame.ctx.addArc(center: CGPoint(x: badgeCX, y: badgeCY), radius: badgeR,
                         startAngle: 0, endAngle: .pi * 2, clockwise: false)
        frame.ctx.setFillColor(rgb(whiteHex))
        frame.ctx.fillPath()
        frame.drawCentered("\(i + 1)", cx: badgeCX, cy: badgeCY,
                           font: font(64, .heavy), color: rgb(brandGreenDark))

        // Text block to the right of the badge.
        let textX = badgeCX + badgeR + 50
        frame.drawLeft(item.0, x: textX, cy: badgeCY - 32,
                       font: font(52, .bold), color: rgb(whiteHex))
        frame.drawLeft(item.1, x: textX, cy: badgeCY + 36,
                       font: font(36, .medium), color: rgb(whiteHex, 0.8))
    }

    frame.wordmarkLockup(cx: cx, cy: SAFE_BOTTOM - 30, badgeR: 24, fontSize: 36)

    frame.save(to: "\(outputDir)/V6.png")
}

print("Done — 6 vertical frames written to \(outputDir)")

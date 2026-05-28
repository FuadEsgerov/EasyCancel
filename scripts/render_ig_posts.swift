#!/usr/bin/env swift
//
// render_ig_posts.swift
//
// Renders 10 branded Instagram FEED posts for EasyCancel.
// Each is a 1080×1080 sRGB PNG, OPAQUE (no alpha), deterministic.
//
// Output: marketing/social/instagram/posts/P01.png .. P10.png
//
// Run from EasyCancel/ directory:  swift scripts/render_ig_posts.swift
//
// Technique (copied from scripts/render_promo_yearly.swift &
// scripts/render_og.swift): a single CGContext with
// CGImageAlphaInfo.noneSkipLast (opaque), Y-flipped to a top-left origin,
// CoreText for all text via CTLine, system-font fallback, and PNG export
// through CGImageDestination. Screenshots/logo composited via CGImageSource.
//
// BRAND
//   gradient #2f9e6b → #1c7a52, ink #10261d, white, checkmark-in-circle logo.
//   Tag: easycancel.vincli.com — pre-launch waitlist drive.
//

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import AppKit

// =====================================================================
// MARK: - Constants
// =====================================================================

let baseDir = "/Users/fuadasgarov/Documents/AllProjects/EasyCancel"
let outDir  = "\(baseDir)/marketing/social/instagram/posts"
let assets  = "\(baseDir)/web/assets"

try? FileManager.default.createDirectory(
    atPath: outDir, withIntermediateDirectories: true)

// NOTE: In a top-level Swift script, a `class` cannot capture script-local
// `let`/`var` bindings. So shared state (colour space, palette) lives on a
// global enum namespace `Brand` whose static members ARE global declarations
// the `Canvas` class can freely reference.

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8)  & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// =====================================================================
// MARK: - Colour palette (static globals usable from the Canvas class)
// =====================================================================

enum Brand {
    static let sRGB: CGColorSpace = {
        guard let s = CGColorSpace(name: CGColorSpace.sRGB) else {
            fatalError("no sRGB")
        }
        return s
    }()
    static let size = 1080
    static let S = CGFloat(1080)
    static let SAFE: CGFloat = 120          // Instagram safe margin

    static let greenLight = rgb(0x2f9e6b)
    static let greenDark  = rgb(0x1c7a52)
    static let ink        = rgb(0x10261d)
    static let white      = rgb(0xFFFFFF)
    static let cream      = rgb(0xF3FBF6)   // soft brand bg / near-white
    static let mint       = rgb(0xCFEEDD)   // light accent
}

let SIZE = Brand.size
let S    = Brand.S
let SAFE = Brand.SAFE

let sRGB        = Brand.sRGB
let greenLight  = Brand.greenLight
let greenDark   = Brand.greenDark
let ink         = Brand.ink
let white       = Brand.white
let cream       = Brand.cream
let mint        = Brand.mint

// =====================================================================
// MARK: - Image loading / caching
// =====================================================================

var imageCache: [String: CGImage] = [:]

func loadImage(_ name: String) -> CGImage? {
    if let c = imageCache[name] { return c }
    let path = "\(assets)/\(name)"
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        FileHandle.standardError.write(Data("WARN: could not load \(name)\n".utf8))
        return nil
    }
    imageCache[name] = img
    return img
}

// =====================================================================
// MARK: - Font helper (system, with optional rounded design)
// =====================================================================

func sysFont(_ size: CGFloat, _ weight: NSFont.Weight,
             rounded: Bool = false) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if rounded, let d = base.fontDescriptor.withDesign(.rounded),
       let f = NSFont(descriptor: d, size: size) {
        return f
    }
    return base
}

// =====================================================================
// MARK: - Per-canvas renderer
//
// We render one image at a time in its own context, then encode to PNG.
// All draw helpers are closures over the active context `ctx`.
// =====================================================================

final class Canvas {
    let ctx: CGContext

    init() {
        guard let c = CGContext(
            data: nil, width: Brand.size, height: Brand.size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: Brand.sRGB,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { fatalError("no context") }
        self.ctx = c
        // Flip Y → top-left origin, y grows downward.
        c.translateBy(x: 0, y: Brand.S)
        c.scaleBy(x: 1, y: -1)
        c.setShouldAntialias(true)
        c.setAllowsAntialiasing(true)
        c.interpolationQuality = .high
    }

    // ---- Text measurement ------------------------------------------------

    func line(_ s: String, font: NSFont, color: CGColor,
              tracking: CGFloat = 0) -> CTLine {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(cgColor: color) ?? .white,
        ]
        if tracking != 0 { attrs[.kern] = tracking }
        return CTLineCreateWithAttributedString(
            NSAttributedString(string: s, attributes: attrs))
    }

    func width(_ line: CTLine) -> CGFloat {
        var a: CGFloat = 0, d: CGFloat = 0, l: CGFloat = 0
        return CGFloat(CTLineGetTypographicBounds(line, &a, &d, &l))
    }

    // Draw a CTLine with LEFT edge at x and visual vertical CENTRE at cy.
    func draw(_ ln: CTLine, x: CGFloat, cy: CGFloat) {
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        _ = CTLineGetTypographicBounds(ln, &ascent, &descent, &leading)
        let textY = cy + (ascent - descent) / 2
        ctx.saveGState()
        ctx.translateBy(x: 0, y: textY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -textY)
        ctx.textPosition = CGPoint(x: x, y: textY)
        CTLineDraw(ln, ctx)
        ctx.restoreGState()
    }

    // Convenience: left-aligned text from a string.
    @discardableResult
    func text(_ s: String, x: CGFloat, cy: CGFloat, font: NSFont,
              color: CGColor, tracking: CGFloat = 0) -> CGFloat {
        let ln = line(s, font: font, color: color, tracking: tracking)
        draw(ln, x: x, cy: cy)
        return width(ln)
    }

    // Convenience: centred text around cx.
    @discardableResult
    func textCentered(_ s: String, cx: CGFloat, cy: CGFloat, font: NSFont,
                      color: CGColor, tracking: CGFloat = 0) -> CGFloat {
        let ln = line(s, font: font, color: color, tracking: tracking)
        let w = width(ln)
        draw(ln, x: cx - w / 2, cy: cy)
        return w
    }

    // ---- Shapes ----------------------------------------------------------

    func fillRect(_ r: CGRect, _ c: CGColor) {
        ctx.setFillColor(c); ctx.fill(r)
    }

    func roundedRect(_ r: CGRect, radius: CGFloat) -> CGPath {
        CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius,
               transform: nil)
    }

    func fillRounded(_ r: CGRect, radius: CGFloat, _ c: CGColor) {
        ctx.addPath(roundedRect(r, radius: radius))
        ctx.setFillColor(c); ctx.fillPath()
    }

    func strokeRounded(_ r: CGRect, radius: CGFloat, _ c: CGColor,
                       lineWidth: CGFloat) {
        ctx.addPath(roundedRect(r, radius: radius))
        ctx.setStrokeColor(c); ctx.setLineWidth(lineWidth); ctx.strokePath()
    }

    func fillCircle(center: CGPoint, radius: CGFloat, _ c: CGColor) {
        ctx.beginPath()
        ctx.addArc(center: center, radius: radius,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.setFillColor(c); ctx.fillPath()
    }

    // Linear gradient fill, clipped to rect.
    func gradientFill(_ rect: CGRect, stops: [(CGFloat, CGColor)],
                      start: CGPoint, end: CGPoint) {
        let g = CGGradient(colorsSpace: Brand.sRGB,
                           colors: stops.map { $0.1 } as CFArray,
                           locations: stops.map { $0.0 })!
        ctx.saveGState()
        ctx.addRect(rect); ctx.clip()
        ctx.drawLinearGradient(g, start: start, end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }

    // ---- Background presets ---------------------------------------------

    // Diagonal brand gradient + soft radial highlight (top-left).
    func brandGradientBackground() {
        gradientFill(CGRect(x: 0, y: 0, width: Brand.S, height: Brand.S),
                     stops: [(0, Brand.greenLight), (1, Brand.greenDark)],
                     start: CGPoint(x: 0, y: 0),
                     end: CGPoint(x: Brand.S, y: Brand.S))
        // subtle highlight
        let g = CGGradient(colorsSpace: Brand.sRGB,
            colors: [rgb(0xFFFFFF, 0.12), rgb(0xFFFFFF, 0)] as CFArray,
            locations: [0, 1])!
        ctx.saveGState()
        ctx.drawRadialGradient(g,
            startCenter: CGPoint(x: 330, y: 300), startRadius: 0,
            endCenter:   CGPoint(x: 330, y: 300), endRadius: 620,
            options: [])
        ctx.restoreGState()
    }

    // Soft cream background with a faint green corner wash.
    func softBackground() {
        fillRect(CGRect(x: 0, y: 0, width: Brand.S, height: Brand.S), Brand.cream)
        let g = CGGradient(colorsSpace: Brand.sRGB,
            colors: [rgb(0x2f9e6b, 0.16), rgb(0x2f9e6b, 0)] as CFArray,
            locations: [0, 1])!
        ctx.saveGState()
        ctx.drawRadialGradient(g,
            startCenter: CGPoint(x: Brand.S, y: 0), startRadius: 0,
            endCenter:   CGPoint(x: Brand.S, y: 0), endRadius: 900,
            options: [])
        ctx.restoreGState()
    }

    // ---- Logo: white circle + green checkmark --------------------------
    // Returns the radius used. `onLight` flips colours for light bgs.
    func logoBadge(center: CGPoint, radius r: CGFloat, onLight: Bool = false) {
        let disk = onLight ? Brand.greenLight : Brand.white
        let tick = onLight ? Brand.white : Brand.greenLight
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 24,
                      color: rgb(0x0A3A26, 0.30))
        fillCircle(center: center, radius: r, disk)
        ctx.restoreGState()

        ctx.saveGState()
        ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.setLineWidth(r * 0.21)
        ctx.setStrokeColor(tick)
        let p1 = CGPoint(x: center.x - r * 0.44, y: center.y + r * 0.04)
        let p2 = CGPoint(x: center.x - r * 0.12, y: center.y + r * 0.38)
        let p3 = CGPoint(x: center.x + r * 0.48, y: center.y - r * 0.36)
        ctx.beginPath()
        ctx.move(to: p1); ctx.addLine(to: p2); ctx.addLine(to: p3)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // ---- Composited screenshot with a phone-ish frame ------------------
    // Draws `name` scaled to fit within `box` (aspect-fit), rounded corners,
    // soft shadow. Returns the actual drawn rect.
    @discardableResult
    func screenshot(_ name: String, in box: CGRect, corner: CGFloat = 36,
                    shadow: Bool = true) -> CGRect {
        guard let img = loadImage(name) else { return .zero }
        let iw = CGFloat(img.width), ih = CGFloat(img.height)
        let scale = min(box.width / iw, box.height / ih)
        let w = iw * scale, h = ih * scale
        let rect = CGRect(x: box.midX - w / 2, y: box.midY - h / 2,
                          width: w, height: h)

        if shadow {
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -16), blur: 40,
                          color: rgb(0x0A2418, 0.40))
            ctx.addPath(roundedRect(rect, radius: corner))
            ctx.setFillColor(Brand.white)
            ctx.fillPath()
            ctx.restoreGState()
        }
        // Clip to rounded rect and draw the (Y-flipped) image upright.
        ctx.saveGState()
        ctx.addPath(roundedRect(rect, radius: corner))
        ctx.clip()
        ctx.saveGState()
        ctx.translateBy(x: 0, y: rect.maxY + rect.minY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(img, in: rect)
        ctx.restoreGState()
        ctx.restoreGState()
        // hairline edge
        strokeRounded(rect, radius: corner, rgb(0x0A2418, 0.10), lineWidth: 1)
        return rect
    }

    // ---- Pill (rounded tag) --------------------------------------------
    func pill(text s: String, cx: CGFloat, cy: CGFloat, font: NSFont,
              textColor: CGColor, fill: CGColor, padX: CGFloat = 28,
              padY: CGFloat = 16, tracking: CGFloat = 0.5,
              stroke: CGColor? = nil) {
        let ln = line(s, font: font, color: textColor, tracking: tracking)
        let tw = width(ln)
        var asc: CGFloat = 0, desc: CGFloat = 0, lead: CGFloat = 0
        _ = CTLineGetTypographicBounds(ln, &asc, &desc, &lead)
        let h = asc + desc + padY * 2
        let w = tw + padX * 2
        let r = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
        fillRounded(r, radius: h / 2, fill)
        if let st = stroke {
            strokeRounded(r, radius: h / 2, st, lineWidth: 2)
        }
        draw(ln, x: cx - tw / 2, cy: cy)
    }

    // ---- Footer brand tag (wordmark + tick + url) ----------------------
    // Small lockup near the bottom, centred, within safe margin.
    func footerTag(url: String = "easycancel.vincli.com",
                   onLight: Bool = false) {
        let cy: CGFloat = Brand.S - 96   // ~96px from bottom (within safe area)
        let txtColor = onLight ? Brand.ink : Brand.white
        let urlColor = onLight ? rgb(0x2f9e6b) : rgb(0xFFFFFF, 0.82)

        // mini badge + "EasyCancel" + url, centred as a group
        let badgeR: CGFloat = 22
        let wordFont = sysFont(34, .bold, rounded: true)
        let urlFont  = sysFont(26, .semibold)
        let wordLn = line("EasyCancel", font: wordFont, color: txtColor, tracking: -0.5)
        let dotLn  = line("·", font: urlFont, color: urlColor)
        let urlLn  = line(url, font: urlFont, color: urlColor, tracking: 0.5)
        let ww = width(wordLn), dw = width(dotLn), uw = width(urlLn)
        let gap: CGFloat = 14
        let badgeGap: CGFloat = 16
        let total = badgeR * 2 + badgeGap + ww + gap + dw + gap + uw
        var x = Brand.S / 2 - total / 2

        logoBadge(center: CGPoint(x: x + badgeR, y: cy), radius: badgeR,
                  onLight: onLight)
        x += badgeR * 2 + badgeGap
        draw(wordLn, x: x, cy: cy); x += ww + gap
        draw(dotLn, x: x, cy: cy);  x += dw + gap
        draw(urlLn, x: x, cy: cy)
    }

    // Top-right corner mini lockup (alt placement).
    func cornerBadge(onLight: Bool = false) {
        let r: CGFloat = 26
        let cx = Brand.S - Brand.SAFE - 70 - r
        let cy: CGFloat = Brand.SAFE + 4
        logoBadge(center: CGPoint(x: cx, y: cy), radius: r, onLight: onLight)
        let f = sysFont(30, .bold, rounded: true)
        let c = onLight ? Brand.ink : Brand.white
        text("EasyCancel", x: cx + r + 14, cy: cy, font: f, color: c, tracking: -0.5)
    }

    // ---- Multi-line headline (centred), returns total height -----------
    func headline(_ lines: [String], cxTop cy: CGFloat, cx: CGFloat,
                  font: NSFont, color: CGColor, lineGap: CGFloat,
                  tracking: CGFloat = -0.5) {
        var y = cy
        for s in lines {
            textCentered(s, cx: cx, cy: y, font: font, color: color,
                         tracking: tracking)
            y += lineGap
        }
    }

    // ---- Export ----------------------------------------------------------
    func write(to path: String) {
        guard let img = ctx.makeImage() else { fatalError("makeImage failed") }
        let url = URL(fileURLWithPath: path)
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { fatalError("CGImageDestination failed for \(path)") }
        CGImageDestinationAddImage(dest, img, nil)
        guard CGImageDestinationFinalize(dest) else {
            fatalError("finalize failed for \(path)")
        }
        FileHandle.standardOutput.write(
            Data("wrote \(path) (\(img.width)x\(img.height))\n".utf8))
    }
}

// Small helper to draw a check-row (used in checklist posts).
extension Canvas {
    func checkRow(text s: String, x: CGFloat, cy: CGFloat, font: NSFont,
                  boxColor: CGColor, textColor: CGColor,
                  checked: Bool, strike: Bool = false) {
        let boxR: CGFloat = 24
        let bcx = x + boxR
        if checked {
            fillCircle(center: CGPoint(x: bcx, y: cy), radius: boxR, boxColor)
            ctx.saveGState()
            ctx.setLineCap(.round); ctx.setLineJoin(.round)
            ctx.setLineWidth(6)
            ctx.setStrokeColor(Brand.white)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: bcx - 11, y: cy + 1))
            ctx.addLine(to: CGPoint(x: bcx - 3, y: cy + 9))
            ctx.addLine(to: CGPoint(x: bcx + 12, y: cy - 9))
            ctx.strokePath()
            ctx.restoreGState()
        } else {
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: bcx, y: cy), radius: boxR,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.setStrokeColor(boxColor); ctx.setLineWidth(4); ctx.strokePath()
        }
        let tx = x + boxR * 2 + 28
        let w = text(s, x: tx, cy: cy, font: font, color: textColor)
        if strike {
            ctx.setStrokeColor(textColor); ctx.setLineWidth(4)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: tx, y: cy))
            ctx.addLine(to: CGPoint(x: tx + w, y: cy))
            ctx.strokePath()
        }
    }
}

let cx = S / 2

// =====================================================================
// MARK: - P01  "You have 14 days to cancel"
// =====================================================================
func renderP01() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    // Eyebrow pill
    c.pill(text: "EU & UK LAW", cx: cx, cy: 250,
           font: sysFont(30, .bold), textColor: greenDark,
           fill: rgb(0xFFFFFF, 0.92), tracking: 3)

    // Big "14" then "DAYS"
    c.textCentered("14", cx: cx, cy: 470,
                   font: sysFont(360, .heavy, rounded: true),
                   color: white, tracking: -6)
    c.textCentered("DAYS TO CANCEL", cx: cx, cy: 690,
                   font: sysFont(70, .bold), color: rgb(0xEAFBF1),
                   tracking: 2)

    // Subtext (two lines, kept within safe margins)
    c.textCentered("After you subscribe online, you have a",
                   cx: cx, cy: 800, font: sysFont(36, .medium),
                   color: rgb(0xFFFFFF, 0.92))
    c.textCentered("14-day cooling-off right to change your mind.",
                   cx: cx, cy: 850, font: sysFont(36, .medium),
                   color: rgb(0xFFFFFF, 0.92))

    c.footerTag()
    c.write(to: "\(outDir)/P01.png")
}

// =====================================================================
// MARK: - P02  "Subscriptions you forgot you're paying for"
// =====================================================================
func renderP02() {
    let c = Canvas()
    c.softBackground()
    c.cornerBadge(onLight: true)

    c.headline(["Subscriptions you forgot", "you're paying for 👀"],
               cxTop: 250, cx: cx, font: sysFont(58, .heavy, rounded: true),
               color: ink, lineGap: 76)

    // Checklist card
    let card = CGRect(x: SAFE, y: 400, width: S - SAFE * 2, height: 470)
    c.ctx.saveGState()
    c.ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 34,
                    color: rgb(0x0A2418, 0.16))
    c.fillRounded(card, radius: 40, white)
    c.ctx.restoreGState()

    let rowFont = sysFont(42, .semibold)
    let lx = card.minX + 56
    let items: [(String, Bool, Bool)] = [
        ("Netflix",                 true,  false),
        ("Spotify Premium",         true,  false),
        ("That gym you don't use",  true,  true),
        ("\"Free\" trial #3",        false, false),
        ("Cloud storage x2",        true,  false),
    ]
    var y = card.minY + 70
    for (label, checked, strike) in items {
        c.checkRow(text: label, x: lx, cy: y, font: rowFont,
                   boxColor: greenLight, textColor: ink,
                   checked: checked, strike: strike)
        y += 80
    }

    c.textCentered("EasyCancel tracks them all in one place.",
                   cx: cx, cy: 920, font: sysFont(34, .medium),
                   color: rgb(0x35564A))

    c.footerTag(onLight: true)
    c.write(to: "\(outDir)/P02.png")
}

// =====================================================================
// MARK: - P03  "What are you ACTUALLY spending per month?"
// =====================================================================
func renderP03() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    // Question headline
    c.headline(["What are you", "ACTUALLY spending", "per month?"],
               cxTop: 230, cx: cx - 70, font: sysFont(56, .heavy, rounded: true),
               color: white, lineGap: 74)

    // Composite home screenshot on the right
    let box = CGRect(x: S - 470, y: 360, width: 360, height: 600)
    c.screenshot("shot-home.png", in: box)

    // Big € figure on the left
    c.text("€127", x: SAFE, cy: 560,
           font: sysFont(150, .heavy, rounded: true), color: rgb(0xEAFBF1),
           tracking: -4)
    c.text("/ month", x: SAFE + 12, cy: 660,
           font: sysFont(42, .semibold), color: rgb(0xFFFFFF, 0.85))
    c.text("on subscriptions?", x: SAFE, cy: 720,
           font: sysFont(38, .medium), color: rgb(0xFFFFFF, 0.85))

    c.footerTag()
    c.write(to: "\(outDir)/P03.png")
}

// =====================================================================
// MARK: - P04  "The free-trial auto-renew trap"
// =====================================================================
func renderP04() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    c.headline(["The free-trial", "auto-renew trap"],
               cxTop: 240, cx: cx, font: sysFont(66, .heavy, rounded: true),
               color: white, lineGap: 86)

    // "7-day free trial" card → arrow → "€59.99 charged" card
    let cardW = S - SAFE * 2
    let topCard = CGRect(x: SAFE, y: 440, width: cardW, height: 150)
    c.fillRounded(topCard, radius: 32, rgb(0xFFFFFF, 0.95))
    c.textCentered("7-day FREE trial", cx: cx, cy: topCard.midY - 14,
                   font: sysFont(50, .bold), color: greenDark)
    c.textCentered("starts today · feels free", cx: cx, cy: topCard.midY + 40,
                   font: sysFont(28, .medium), color: rgb(0x35564A))

    // Down arrow
    c.ctx.saveGState()
    c.ctx.setLineCap(.round); c.ctx.setLineJoin(.round)
    c.ctx.setLineWidth(12); c.ctx.setStrokeColor(rgb(0xEAFBF1))
    c.ctx.beginPath()
    c.ctx.move(to: CGPoint(x: cx, y: 620))
    c.ctx.addLine(to: CGPoint(x: cx, y: 700))
    c.ctx.strokePath()
    c.ctx.beginPath()
    c.ctx.move(to: CGPoint(x: cx - 26, y: 678))
    c.ctx.addLine(to: CGPoint(x: cx, y: 706))
    c.ctx.addLine(to: CGPoint(x: cx + 26, y: 678))
    c.ctx.strokePath()
    c.ctx.restoreGState()

    let botCard = CGRect(x: SAFE, y: 730, width: cardW, height: 150)
    c.fillRounded(botCard, radius: 32, rgb(0x0E5E3E))
    c.textCentered("€59.99 charged", cx: cx, cy: botCard.midY - 14,
                   font: sysFont(54, .heavy, rounded: true), color: white)
    c.textCentered("day 8 · no reminder", cx: cx, cy: botCard.midY + 42,
                   font: sysFont(28, .medium), color: rgb(0xCFEEDD))

    c.footerTag()
    c.write(to: "\(outDir)/P04.png")
}

// =====================================================================
// MARK: - P05  "How to cancel the right way" (GDPR letter)
// =====================================================================
func renderP05() {
    let c = Canvas()
    c.softBackground()
    c.cornerBadge(onLight: true)

    c.headline(["Cancel the right way", "— in writing."],
               cxTop: 240, cx: cx, font: sysFont(60, .heavy, rounded: true),
               color: ink, lineGap: 78)

    // Composite letter screenshot, centred
    let box = CGRect(x: cx - 200, y: 400, width: 400, height: 470)
    c.screenshot("shot-letter.png", in: box)

    c.pill(text: "GDPR-READY CANCELLATION LETTER", cx: cx, cy: 920,
           font: sysFont(28, .bold), textColor: white,
           fill: greenLight, tracking: 1.5)

    c.footerTag(onLight: true)
    c.write(to: "\(outDir)/P05.png")
}

// =====================================================================
// MARK: - P06  "Your data stays in the EU. No ad tracking."
// =====================================================================
func renderP06() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    // Lock glyph (rounded rect body + arc shackle) in a white circle
    let center = CGPoint(x: cx, y: 410)
    c.fillCircle(center: center, radius: 130, rgb(0xFFFFFF, 0.95))
    // shackle
    c.ctx.saveGState()
    c.ctx.setLineWidth(20); c.ctx.setStrokeColor(greenDark)
    c.ctx.setLineCap(.round)
    c.ctx.beginPath()
    c.ctx.addArc(center: CGPoint(x: center.x, y: center.y - 18), radius: 38,
                 startAngle: .pi, endAngle: 0, clockwise: false)
    c.ctx.strokePath()
    c.ctx.restoreGState()
    // body
    let body = CGRect(x: center.x - 50, y: center.y - 18, width: 100, height: 78)
    c.fillRounded(body, radius: 16, greenDark)
    // keyhole
    c.fillCircle(center: CGPoint(x: center.x, y: center.y + 14), radius: 12, white)
    c.fillRect(CGRect(x: center.x - 5, y: center.y + 18, width: 10, height: 22), white)

    c.headline(["Your data stays", "in the EU."],
               cxTop: 620, cx: cx, font: sysFont(66, .heavy, rounded: true),
               color: white, lineGap: 84)

    c.textCentered("No ad tracking. No selling your info.",
                   cx: cx, cy: 830, font: sysFont(38, .medium),
                   color: rgb(0xFFFFFF, 0.92))
    c.textCentered("Privacy-first, by design. 🇪🇺",
                   cx: cx, cy: 884, font: sysFont(38, .semibold),
                   color: rgb(0xEAFBF1))

    c.footerTag()
    c.write(to: "\(outDir)/P06.png")
}

// =====================================================================
// MARK: - P07  "Meet EasyCancel — coming soon" (logo lockup)
// =====================================================================
func renderP07() {
    let c = Canvas()
    c.brandGradientBackground()

    // Big centred logo badge
    c.logoBadge(center: CGPoint(x: cx, y: 380), radius: 150)

    // Wordmark
    c.textCentered("EasyCancel", cx: cx, cy: 620,
                   font: sysFont(96, .bold, rounded: true), color: white,
                   tracking: -1)
    c.textCentered("Cancel subscriptions before you're charged again.",
                   cx: cx, cy: 710, font: sysFont(34, .medium),
                   color: rgb(0xFFFFFF, 0.92))

    // CTA pill
    c.pill(text: "JOIN THE WAITLIST", cx: cx, cy: 820,
           font: sysFont(36, .bold), textColor: greenDark,
           fill: white, padX: 44, padY: 22, tracking: 2)

    // url tag (no footer logo here — logo is the hero)
    c.textCentered("easycancel.vincli.com  ·  link in bio",
                   cx: cx, cy: S - 96, font: sysFont(28, .semibold),
                   color: rgb(0xFFFFFF, 0.82), tracking: 0.5)
    c.write(to: "\(outDir)/P07.png")
}

// =====================================================================
// MARK: - P08  "Cancel before they cancel your budget." (hero)
// =====================================================================
func renderP08() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    c.headline(["Cancel", "before they", "cancel your", "budget."],
               cxTop: 320, cx: cx, font: sysFont(110, .heavy, rounded: true),
               color: white, lineGap: 122, tracking: -2)

    c.footerTag()
    c.write(to: "\(outDir)/P08.png")
}

// =====================================================================
// MARK: - P09  "How to cancel Netflix before the next charge"
// =====================================================================
func renderP09() {
    let c = Canvas()
    c.softBackground()
    c.cornerBadge(onLight: true)

    c.pill(text: "HOW-TO", cx: cx, cy: 230,
           font: sysFont(30, .bold), textColor: white,
           fill: greenLight, tracking: 4)

    c.headline(["How to cancel", "Netflix before", "the next charge"],
               cxTop: 350, cx: cx, font: sysFont(64, .heavy, rounded: true),
               color: ink, lineGap: 82)

    // 3 numbered steps
    let steps = [
        "Check your renewal date",
        "Cancel from Account settings",
        "Save proof you cancelled",
    ]
    var y: CGFloat = 660
    let lx = SAFE + 10
    for (i, s) in steps.enumerated() {
        let badgeC = CGPoint(x: lx + 30, y: y)
        c.fillCircle(center: badgeC, radius: 30, greenLight)
        c.textCentered("\(i + 1)", cx: badgeC.x, cy: badgeC.y,
                       font: sysFont(36, .bold), color: white)
        c.text(s, x: lx + 84, cy: y, font: sysFont(38, .semibold), color: ink)
        y += 86
    }

    c.footerTag(onLight: true)
    c.write(to: "\(outDir)/P09.png")
}

// =====================================================================
// MARK: - P10  "People waste hundreds a year on subs they forgot"
// =====================================================================
func renderP10() {
    let c = Canvas()
    c.brandGradientBackground()
    c.cornerBadge()

    c.textCentered("People waste", cx: cx, cy: 280,
                   font: sysFont(58, .bold, rounded: true), color: rgb(0xEAFBF1))

    // Shock stat
    c.textCentered("€100s", cx: cx, cy: 470,
                   font: sysFont(220, .heavy, rounded: true), color: white,
                   tracking: -6)
    c.textCentered("a year", cx: cx, cy: 620,
                   font: sysFont(58, .bold, rounded: true), color: rgb(0xEAFBF1))

    c.headline(["on subscriptions", "they forgot about."],
               cxTop: 720, cx: cx, font: sysFont(40, .medium),
               color: rgb(0xFFFFFF, 0.92), lineGap: 52, tracking: 0)

    c.pill(text: "JOIN THE WAITLIST", cx: cx, cy: 868,
           font: sysFont(34, .bold), textColor: greenDark,
           fill: white, padX: 40, padY: 20, tracking: 2)

    c.footerTag()
    c.write(to: "\(outDir)/P10.png")
}

// =====================================================================
// MARK: - Run all
// =====================================================================
renderP01()
renderP02()
renderP03()
renderP04()
renderP05()
renderP06()
renderP07()
renderP08()
renderP09()
renderP10()

print("Done — 10 Instagram posts in \(outDir)")

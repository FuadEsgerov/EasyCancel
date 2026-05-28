#!/usr/bin/env swift
// Renders MarketingAssets/PromotedIAP/pro-yearly.png (1024x1024, sRGB, opaque)
// per docs/app-store/PROMO_BRIEF_YEARLY.md.
//
// Run from EasyCancel/ directory:  swift scripts/render_promo_yearly.swift

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import AppKit

let W = 1024
let H = 1024
let outputPath = "/Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-yearly.png"

try? FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)

guard let cs = CGColorSpace(name: CGColorSpace.sRGB) else { fatalError("no sRGB") }
guard let ctx = CGContext(
    data: nil, width: W, height: H,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("no context") }

// Flip Y so (0,0) is top-left.
ctx.translateBy(x: 0, y: CGFloat(H))
ctx.scaleBy(x: 1, y: -1)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8)  & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func drawCenteredText(_ text: String, center: CGPoint, fontSize: CGFloat,
                      weight: NSFont.Weight, color: CGColor, tracking: CGFloat = 0,
                      design: NSFontDescriptor.SystemDesign = .default)
{
    let baseFont = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let font: NSFont = {
        if let descriptor = baseFont.fontDescriptor.withDesign(design),
           let f = NSFont(descriptor: descriptor, size: fontSize) {
            return f
        }
        return baseFont
    }()
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color)!,
        .kern: tracking,
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, [.useOpticalBounds])

    ctx.saveGState()
    let baselineX = center.x - bounds.width / 2 - bounds.origin.x
    let baselineY = center.y + bounds.height / 2 + bounds.origin.y
    ctx.translateBy(x: baselineX, y: baselineY)
    ctx.scaleBy(x: 1, y: -1)
    ctx.textPosition = .zero
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// ===== 1. Background diagonal gradient =====
let bgGrad = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0xFFD27A), rgb(0xF2A23A), rgb(0xB85C2A), rgb(0x6B2A4E), rgb(0x3A123A)] as CFArray,
    locations: [0.0, 0.25, 0.55, 0.80, 1.0]
)!
ctx.drawLinearGradient(
    bgGrad,
    start: .zero,
    end: CGPoint(x: W, y: H),
    options: []
)

// ===== 2. Background radial highlight =====
let warmGrad = CGGradient(
    colorsSpace: cs,
    colors: [
        CGColor(srgbRed: 1, green: 240/255, blue: 200/255, alpha: 0.18),
        CGColor(srgbRed: 1, green: 240/255, blue: 200/255, alpha: 0),
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawRadialGradient(
    warmGrad,
    startCenter: CGPoint(x: 380, y: 380), startRadius: 0,
    endCenter: CGPoint(x: 380, y: 380), endRadius: 700,
    options: []
)

let center = CGPoint(x: 512, y: 512)
let Ro: CGFloat = 300
let Ri: CGFloat = 240

// ===== 3. 12 month dots (subtle, just outside ring) =====
let dotRadius: CGFloat = 326
ctx.setFillColor(rgb(0xFFE9A8, 0.55))
for i in 0..<12 {
    let angle = -CGFloat.pi / 2 + CGFloat(i) * (.pi * 2 / 12)
    let cx = center.x + dotRadius * cos(angle)
    let cy = center.y + dotRadius * sin(angle)
    ctx.beginPath()
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: 4,
               startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.fillPath()
}

// ===== 4. Outer ring glow =====
ctx.saveGState()
ctx.setShadow(
    offset: .zero,
    blur: 18,
    color: CGColor(srgbRed: 1, green: 0.82, blue: 0.48, alpha: 0.65)
)
ctx.beginPath()
ctx.addArc(center: center, radius: Ro + 6, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.setStrokeColor(rgb(0xFFD27A, 0.55))
ctx.setLineWidth(18)
ctx.strokePath()
ctx.restoreGState()

// ===== 5. 12-segment illuminated ring =====
let segmentArc: CGFloat = (28.0 * .pi / 180.0)   // 28° drawn arc
let gapArc: CGFloat = (2.0 * .pi / 180.0)        // 2° gap (1° each side)
let segmentStep: CGFloat = segmentArc + gapArc   // 30° each

let segFill = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0xFFE9A8), rgb(0xF2A23A)] as CFArray,
    locations: [0, 1]
)!

for i in 0..<12 {
    let centerAngle = -CGFloat.pi / 2 + CGFloat(i) * segmentStep
    let a0 = centerAngle - segmentArc / 2
    let a1 = centerAngle + segmentArc / 2

    let segPath = CGMutablePath()
    let p0 = CGPoint(x: center.x + Ro * cos(a0), y: center.y + Ro * sin(a0))
    segPath.move(to: p0)
    segPath.addArc(center: center, radius: Ro, startAngle: a0, endAngle: a1, clockwise: false)
    segPath.addArc(center: center, radius: Ri, startAngle: a1, endAngle: a0, clockwise: true)
    segPath.closeSubpath()

    // Fill with radial gradient (clipped to segment).
    ctx.saveGState()
    ctx.addPath(segPath)
    ctx.clip()
    ctx.drawRadialGradient(
        segFill,
        startCenter: center, startRadius: Ri,
        endCenter: center, endRadius: Ro,
        options: []
    )
    ctx.restoreGState()

    // Hairline stroke
    ctx.addPath(segPath)
    ctx.setStrokeColor(rgb(0x3A123A, 0.35))
    ctx.setLineWidth(1)
    ctx.strokePath()
}

// ===== 6. Inner disk (behind "365") =====
let innerDiskRadius: CGFloat = Ri - 6
let innerDiskGrad = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0x2A0A2A), rgb(0x4A1A4A)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.beginPath()
ctx.addArc(center: center, radius: innerDiskRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.clip()
ctx.drawRadialGradient(
    innerDiskGrad,
    startCenter: center, startRadius: 0,
    endCenter: center, endRadius: innerDiskRadius,
    options: []
)
ctx.restoreGState()
// hairline
ctx.beginPath()
ctx.addArc(center: center, radius: innerDiskRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.setStrokeColor(rgb(0xFFE9A8, 0.20))
ctx.setLineWidth(1)
ctx.strokePath()

// ===== 7. "365" numeral (serif, light, gold) =====
drawCenteredText("365",
                 center: CGPoint(x: 512, y: 520),  // +8 optical nudge
                 fontSize: 220, weight: .light,
                 color: rgb(0xFFE9A8, 0.92),
                 tracking: -4,
                 design: .serif)

// ===== 8. Bottom "Pro Yearly" caption =====
drawCenteredText("Pro Yearly",
                 center: CGPoint(x: 512, y: 940),
                 fontSize: 36, weight: .medium,
                 color: rgb(0xFFE9A8, 0.75),
                 tracking: 1)

// ===== 9. "BEST VALUE" ribbon top-right (rotated -8°) =====
ctx.saveGState()
// Rotate the entire group around (860, 90).
ctx.translateBy(x: 860, y: 90)
ctx.rotate(by: -8 * .pi / 180)
ctx.translateBy(x: -860, y: -90)

// Drop shadow under pill
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: 4),
    blur: 8,
    color: CGColor(srgbRed: 58/255, green: 18/255, blue: 58/255, alpha: 0.40)
)
let pillRect = CGRect(x: 730, y: 62, width: 260, height: 56)
let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 28, cornerHeight: 28, transform: nil)
// Fill pill with vertical gradient
ctx.saveGState()
ctx.addPath(pillPath)
ctx.clip()
let pillGrad = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0xFFF1C8), rgb(0xFFD27A)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    pillGrad,
    start: CGPoint(x: 0, y: 62),
    end: CGPoint(x: 0, y: 118),
    options: []
)
ctx.restoreGState()
ctx.restoreGState()  // drop shadow
// Pill stroke
ctx.addPath(pillPath)
ctx.setStrokeColor(rgb(0x6B2A4E))
ctx.setLineWidth(1.5)
ctx.strokePath()

// Star glyph (5-point star at (770, 90), radius 11)
func drawStar(center sc: CGPoint, outerR: CGFloat, innerR: CGFloat, color: CGColor) {
    let path = CGMutablePath()
    for i in 0..<10 {
        let r = (i % 2 == 0) ? outerR : innerR
        let angle = -CGFloat.pi / 2 + CGFloat(i) * (.pi / 5)
        let x = sc.x + r * cos(angle)
        let y = sc.y + r * sin(angle)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath()
}
drawStar(center: CGPoint(x: 770, y: 90), outerR: 11, innerR: 5, color: rgb(0x6B2A4E))

// Label "BEST VALUE"
drawCenteredText("BEST VALUE",
                 center: CGPoint(x: 880, y: 90),
                 fontSize: 20, weight: .semibold,
                 color: rgb(0x3A123A),
                 tracking: 2)

ctx.restoreGState() // rotation

// ===== Save PNG =====
guard let cgImage = ctx.makeImage() else { fatalError("makeImage failed") }
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(
    url as CFURL, UTType.png.identifier as CFString, 1, nil
) else { fatalError("CGImageDestination failed") }
CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("finalize failed") }

print("wrote \(outputPath) (\(cgImage.width)x\(cgImage.height))")

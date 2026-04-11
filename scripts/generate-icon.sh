#!/bin/zsh
# Generate AppIcon.icns for apfelpad.
# Uses Swift Image I/O + Core Graphics (no external ImageMagick dependency).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_ICNS="$ROOT_DIR/Resources/AppIcon.icns"
WORK_DIR="$(mktemp -d)"
ICONSET="$WORK_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"

SWIFT_SRC="$WORK_DIR/make-icon.swift"
cat > "$SWIFT_SRC" <<'SWIFT'
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: make-icon <size> <out.png>\n".utf8))
    exit(1)
}
let size = Int(CommandLine.arguments[1])!
let outPath = CommandLine.arguments[2]

let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Background: pale green
ctx.setFillColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Rounded-rect clip so the icon has the macOS look-and-feel
let inset = Double(size) * 0.08
let rect = CGRect(x: inset, y: inset, width: Double(size) - 2*inset, height: Double(size) - 2*inset)
let path = CGPath(roundedRect: rect, cornerWidth: Double(size) * 0.20, cornerHeight: Double(size) * 0.20, transform: nil)

let mask = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
mask.setFillColor(red: 0.16, green: 0.49, blue: 0.22, alpha: 1.0)
mask.addPath(path)
mask.fillPath()

// Draw dark green rounded-rect accent block
let accent = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
accent.setFillColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1.0)
accent.fill(CGRect(x: 0, y: 0, width: size, height: size))
accent.setFillColor(red: 0.16, green: 0.49, blue: 0.22, alpha: 1.0)
accent.addPath(path)
accent.fillPath()

// Draw "=" glyph in pale green inside the dark block
let s = Double(size)
let barHeight = s * 0.08
let barWidth = s * 0.50
let cx = s * 0.5
let cy = s * 0.5
let gap = s * 0.10
accent.setFillColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1.0)
accent.fill(CGRect(
    x: cx - barWidth / 2,
    y: cy - gap / 2 - barHeight,
    width: barWidth,
    height: barHeight
))
accent.fill(CGRect(
    x: cx - barWidth / 2,
    y: cy + gap / 2,
    width: barWidth,
    height: barHeight
))

guard let cgImage = accent.makeImage() else {
    FileHandle.standardError.write(Data("failed to make image\n".utf8))
    exit(1)
}

let url = URL(fileURLWithPath: outPath) as CFURL
guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
    FileHandle.standardError.write(Data("failed to create destination\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(dest, cgImage, nil)
CGImageDestinationFinalize(dest)
SWIFT

for size in 16 32 64 128 256 512 1024; do
    swift "$SWIFT_SRC" $size "$ICONSET/icon_${size}x${size}.png"
done

# iconutil needs the iconset's size naming convention
# We generated the canonical file names above; now copy the @2x variants from the larger sizes
cp "$ICONSET/icon_32x32.png"     "$ICONSET/icon_16x16@2x.png"
cp "$ICONSET/icon_64x64.png"     "$ICONSET/icon_32x32@2x.png"
cp "$ICONSET/icon_256x256.png"   "$ICONSET/icon_128x128@2x.png"
cp "$ICONSET/icon_512x512.png"   "$ICONSET/icon_256x256@2x.png"
cp "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
rm "$ICONSET/icon_64x64.png" "$ICONSET/icon_1024x1024.png"

mkdir -p "$(dirname "$OUT_ICNS")"
iconutil -c icns -o "$OUT_ICNS" "$ICONSET"

rm -rf "$WORK_DIR"
print "==> Generated $OUT_ICNS"

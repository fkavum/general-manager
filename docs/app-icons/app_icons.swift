// App icon pipeline — no packages, macOS CoreGraphics only.
//
// Run from the client root:
//   swift tool/app_icons.swift generate   # Resources/AppIcon/source.png → Resources/AppIcon/icon_*.png
//   swift tool/app_icons.swift install    # Resources/AppIcon/icon_*.png → web / android / ios / macos / windows
//   swift tool/app_icons.swift all        # both (default)
//
// Resources/AppIcon/ holds one file per size/variant a platform needs, named by what it is
// (icon_1024x1024_opaque.png, icon_maskable_512x512.png, ...). To ship real artwork, replace those
// files with properly drawn ones (same names, same pixel sizes) and run `install` only.
// Resources/AppIcon/README.md lists every file and where it lands.
//
// Shared by every Flutter client. Master: general-manager/docs/app-icons/app_icons.swift — edit it there
// and push it with `docs/app-icons/icons.sh apply` (general-manager/docs/app-icons/README.md).

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let iconDir = "Resources/AppIcon"
let sourcePath = "\(iconDir)/source.png"

// Plate colour behind opaque / maskable / adaptive icons (iOS forbids alpha; masks crop to a shape).
let plate = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

enum Variant: String {
  case plain = ""                 // transparent, artwork fills the canvas
  case opaque = "_opaque"         // white plate, no alpha channel (iOS, apple-touch-icon)
  case maskable = "maskable"      // white plate, artwork inside the PWA maskable safe zone
  case adaptiveFg = "adaptive_fg" // transparent, artwork inside the Android adaptive safe zone

  // Share of the canvas the artwork's bounding square takes. Masks crop to a circle, so the
  // artwork's farthest points (usually near the square's corners) must stay inside it:
  // side ≈ safe-zone diameter / √2, plus ~10% because icon corners are rarely filled.
  var artworkScale: CGFloat {
    switch self {
    case .plain, .opaque: return 1.0
    case .maskable: return 0.62    // W3C maskable safe zone = circle of 80% diameter
    case .adaptiveFg: return 0.47  // Android adaptive: 66dp safe circle on a 108dp canvas
    }
  }

  func fileName(_ px: Int) -> String {
    switch self {
    case .plain, .opaque: return "icon_\(px)x\(px)\(rawValue).png"
    case .maskable, .adaptiveFg: return "icon_\(rawValue)_\(px)x\(px).png"
    }
  }
}

struct Master: Hashable {
  let px: Int
  let variant: Variant
  var fileName: String { variant.fileName(px) }
}

// Every platform destination → the master it is a copy of.
let installs: [(dest: String, master: Master)] = {
  var list: [(String, Master)] = []

  // Web / PWA
  list += [
    ("web/icons/icon_32x32.png", Master(px: 32, variant: .plain)),                     // favicon
    ("web/icons/icon_180x180_opaque.png", Master(px: 180, variant: .opaque)),          // apple-touch-icon
    ("web/icons/icon_192x192.png", Master(px: 192, variant: .plain)),
    ("web/icons/icon_512x512.png", Master(px: 512, variant: .plain)),
    ("web/icons/icon_maskable_192x192.png", Master(px: 192, variant: .maskable)),
    ("web/icons/icon_maskable_512x512.png", Master(px: 512, variant: .maskable)),
  ]

  // Android — legacy launcher (48dp) + adaptive foreground (108dp), per density
  let res = "android/app/src/main/res"
  for (bucket, scale) in [("mdpi", 1.0), ("hdpi", 1.5), ("xhdpi", 2.0), ("xxhdpi", 3.0), ("xxxhdpi", 4.0)] {
    list.append(("\(res)/mipmap-\(bucket)/ic_launcher.png", Master(px: Int(48 * scale), variant: .plain)))
    list.append(("\(res)/mipmap-\(bucket)/ic_launcher_foreground.png", Master(px: Int(108 * scale), variant: .adaptiveFg)))
  }

  // iOS — file names fixed by AppIcon.appiconset/Contents.json
  let ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
  for (name, px) in [
    ("20x20@1x", 20), ("20x20@2x", 40), ("20x20@3x", 60),
    ("29x29@1x", 29), ("29x29@2x", 58), ("29x29@3x", 87),
    ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120),
    ("60x60@2x", 120), ("60x60@3x", 180),
    ("76x76@1x", 76), ("76x76@2x", 152),
    ("83.5x83.5@2x", 167),
    ("1024x1024@1x", 1024),
  ] {
    list.append(("\(ios)/Icon-App-\(name).png", Master(px: px, variant: .opaque)))
  }

  // macOS — file names fixed by AppIcon.appiconset/Contents.json
  let mac = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
  for px in [16, 32, 64, 128, 256, 512, 1024] {
    list.append(("\(mac)/app_icon_\(px).png", Master(px: px, variant: .plain)))
  }
  return list
}()

// Windows .ico — PNG-compressed entries (valid since Vista), assembled from these masters.
let icoPath = "windows/runner/resources/app_icon.ico"
let icoSizes = [16, 24, 32, 48, 64, 256]

var allMasters: [Master] {
  var set = Set(installs.map { $0.master })
  icoSizes.forEach { set.insert(Master(px: $0, variant: .plain)) }
  return set.sorted { ($0.variant.rawValue, $0.px) < ($1.variant.rawValue, $1.px) }
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write("app_icons: \(message)\n".data(using: .utf8)!)
  exit(1)
}

func loadImage(_ path: String) -> CGImage {
  guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(src, 0, nil)
  else { fail("cannot read \(path)") }
  return image
}

func render(_ source: CGImage, _ master: Master) -> CGImage {
  let px = master.px
  let opaque = master.variant == .opaque || master.variant == .maskable
  let info = opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
  guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info)
  else { fail("cannot create a \(px)px context") }
  ctx.interpolationQuality = .high
  if opaque {
    ctx.setFillColor(plate)
    ctx.fill(CGRect(x: 0, y: 0, width: px, height: px))
  }
  let side = CGFloat(px) * master.variant.artworkScale
  let origin = (CGFloat(px) - side) / 2
  ctx.draw(source, in: CGRect(x: origin, y: origin, width: side, height: side))
  return ctx.makeImage()!
}

func writePNG(_ image: CGImage, _ path: String) {
  let url = URL(fileURLWithPath: path)
  guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
  else { fail("cannot write \(path)") }
  CGImageDestinationAddImage(dest, image, nil)
  guard CGImageDestinationFinalize(dest) else { fail("cannot write \(path)") }
}

func generate() {
  let source = loadImage(sourcePath)
  if source.width != source.height { fail("\(sourcePath) must be square (is \(source.width)x\(source.height))") }
  for master in allMasters {
    writePNG(render(source, master), "\(iconDir)/\(master.fileName)")
  }
  print("generated \(allMasters.count) masters in \(iconDir)/ from \(sourcePath) (\(source.width)x\(source.height))")
}

func masterPath(_ master: Master) -> String {
  let path = "\(iconDir)/\(master.fileName)"
  guard FileManager.default.fileExists(atPath: path) else { fail("missing \(path) — run `generate` or add it") }
  let image = loadImage(path)
  if image.width != master.px || image.height != master.px {
    fail("\(path) is \(image.width)x\(image.height), expected \(master.px)x\(master.px)")
  }
  return path
}

func writeIco() {
  var entries: [(px: Int, data: Data)] = []
  for px in icoSizes {
    entries.append((px, try! Data(contentsOf: URL(fileURLWithPath: masterPath(Master(px: px, variant: .plain))))))
  }
  var ico = Data()
  func le16(_ v: Int) { ico.append(contentsOf: [UInt8(v & 0xff), UInt8((v >> 8) & 0xff)]) }
  func le32(_ v: Int) { le16(v & 0xffff); le16((v >> 16) & 0xffff) }
  le16(0); le16(1); le16(entries.count)                  // ICONDIR: reserved, type=icon, count
  var offset = 6 + 16 * entries.count
  for e in entries {                                      // ICONDIRENTRY
    ico.append(UInt8(e.px >= 256 ? 0 : e.px))             // width (0 = 256)
    ico.append(UInt8(e.px >= 256 ? 0 : e.px))             // height
    ico.append(0); ico.append(0)                          // palette, reserved
    le16(1); le16(32)                                     // planes, bpp
    le32(e.data.count); le32(offset)
    offset += e.data.count
  }
  entries.forEach { ico.append($0.data) }
  try! ico.write(to: URL(fileURLWithPath: icoPath))
}

func install() {
  let fm = FileManager.default
  for (dest, master) in installs {
    let from = masterPath(master)
    try? fm.createDirectory(atPath: (dest as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    try? fm.removeItem(atPath: dest)
    do { try fm.copyItem(atPath: from, toPath: dest) } catch { fail("cannot copy \(from) → \(dest): \(error)") }
  }
  writeIco()
  print("installed \(installs.count) files + \(icoPath)")
}

guard FileManager.default.fileExists(atPath: "pubspec.yaml") else { fail("run from the client root") }
switch CommandLine.arguments.dropFirst().first ?? "all" {
case "generate": generate()
case "install": install()
case "all": generate(); install()
default: fail("usage: swift tool/app_icons.swift [generate|install|all]")
}

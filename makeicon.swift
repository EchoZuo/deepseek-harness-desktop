// makeicon.swift — 从源 PNG 生成 macOS .iconset（自动切圆角/判断背景）
// 用法: swift makeicon.swift <源PNG> <输出iconset目录>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: makeicon <src.png> <out.iconset>")
    exit(1)
}
let srcPath = args[1]
let outDir = args[2]

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: srcPath) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    print("ERROR: cannot load \(srcPath)")
    exit(1)
}
let w = img.width, h = img.height
print("source: \(w)x\(h), bitsPerPixel=\(img.bitsPerPixel), alpha=\(img.alphaInfo.rawValue)")

// 采样 NxN 块平均色
func sample(_ cx: Int, _ cy: Int) -> (Double, Double, Double) {
    guard let prov = img.dataProvider, let data = prov.data,
          let ptr = CFDataGetBytePtr(data) else { return (-1,-1,-1) }
    let bpp = img.bitsPerPixel / 8
    var r = 0.0, g = 0.0, b = 0.0
    var n = 0
    let rng = 3
    for dy in -rng...rng {
        for dx in -rng...rng {
            let x = min(max(cx + dx, 0), w - 1)
            let y = min(max(cy + dy, 0), h - 1)
            let off = y * img.bytesPerRow + x * bpp
            r += Double(ptr[off]); g += Double(ptr[off + 1]); b += Double(ptr[off + 2])
            n += 1
        }
    }
    return (r / Double(n), g / Double(n), b / Double(n))
}

// 判断四角背景是否均匀（决定能否安全切圆角）
let corners = [(0,0),(w-1,0),(0,h-1),(w-1,h-1)].map { sample($0.0, $0.1) }
for (i, c) in corners.enumerated() {
    print(String(format: "corner[%d]: rgb(%.0f, %.0f, %.0f)", i, c.0, c.1, c.2))
}
let base = corners[0]
let maxDelta = corners.map { c in
    max(abs(c.0 - base.0), abs(c.1 - base.1), abs(c.2 - base.2))
}.max() ?? 999
let uniformBG = maxDelta < 40
print("background uniform: \(uniformBG) (maxDelta=\(Int(maxDelta)))")

// 生成指定尺寸图标
func makeIcon(_ size: Int, round: Bool) -> CGImage? {
    let ctx = CGContext(data: nil, width: size, height: size,
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let ctx = ctx else { return nil }
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    if round {
        // 苹果风格 squircle 近似：圆角半径 ≈ 22.4%（Big Sur+ 图标栅格）
        let radius = CGFloat(size) * 0.2237
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
    }
    // 缩放绘制，四周留 20% 呼吸空间（与 Apple 标准一致）
    let pad = CGFloat(size) * 0.20
    let innerWidth = CGFloat(size) - 2*pad
    let innerHeight = CGFloat(size) - 2*pad
    let innerRect = CGRect(x: pad, y: pad, width: innerWidth, height: innerHeight)
    ctx.draw(img, in: innerRect)
    return ctx.makeImage()
}

func writePNG(_ img: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else {
        print("ERROR: failed to write \(path)")
        exit(1)
    }
    print("  wrote \(path)")
}

// 图标尺寸集
let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
for (name, size) in sizes {
    guard let icon = makeIcon(size, round: true) else { continue }
    writePNG(icon, to: "\(outDir)/\(name).png")
}
print("done -> \(outDir)")
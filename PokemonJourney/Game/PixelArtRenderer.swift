import UIKit
import SpriteKit

// MARK: - UIColor hex helper

extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Pixel Art Renderer

enum PixelArtRenderer {
    /// Creates a crisp pixel-art SKTexture from a string art array + color palette.
    /// Each character in the art maps to a UIColor in the palette; '.' = transparent.
    static func makeTexture(
        art: [String],
        palette: [Character: UIColor],
        pixelSize: Int
    ) -> SKTexture {
        guard !art.isEmpty, !art[0].isEmpty else { return SKTexture() }

        let cols = art[0].count
        let rows = art.count
        let w = CGFloat(cols * pixelSize)
        let h = CGFloat(rows * pixelSize)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .none
            for (row, rowStr) in art.enumerated() {
                for (col, char) in rowStr.enumerated() {
                    guard char != ".", let color = palette[char] else { continue }
                    color.setFill()
                    ctx.fill(CGRect(
                        x: CGFloat(col * pixelSize),
                        y: CGFloat(row * pixelSize),
                        width: CGFloat(pixelSize),
                        height: CGFloat(pixelSize)
                    ))
                }
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    /// Convenience: create an SKSpriteNode directly.
    static func makeSprite(
        art: [String],
        palette: [Character: UIColor],
        pixelSize: Int
    ) -> SKSpriteNode {
        let texture = makeTexture(art: art, palette: palette, pixelSize: pixelSize)
        let node = SKSpriteNode(texture: texture)
        node.texture?.filteringMode = .nearest
        return node
    }

    /// Draw a filled rounded-rectangle "dialog box" texture (RSE style).
    static func makeDialogBox(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
            // Outer dark blue border
            UIColor(hex: "#003878").setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            // Inner white fill
            UIColor(hex: "#F0F8FF").setFill()
            ctx.fill(CGRect(x: 3, y: 3, width: width - 6, height: height - 6))
        }
        return SKTexture(image: image)
    }

    /// Draw the room background (wall + floor + window + bookshelf).
    static func makeRoomTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            let wallH = size.height * 0.42

            // ── Wall ──────────────────────────────────────────────────────
            UIColor(hex: "#B8CCE0").setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: wallH))

            // Diamond pattern on wall
            UIColor(hex: "#98B8D8").setFill()
            var wx: CGFloat = 16
            while wx < size.width {
                var wy: CGFloat = 16
                while wy < wallH {
                    ctx.fill(CGRect(x: wx - 4, y: wy, width: 8, height: 1))
                    ctx.fill(CGRect(x: wx, y: wy - 4, width: 1, height: 8))
                    wy += 32
                }
                wx += 32
            }

            // Baseboard
            UIColor(hex: "#8AACC8").setFill()
            ctx.fill(CGRect(x: 0, y: wallH - 10, width: size.width, height: 8))
            UIColor(hex: "#704818").setFill()
            ctx.fill(CGRect(x: 0, y: wallH - 4, width: size.width, height: 4))

            // ── Floor ─────────────────────────────────────────────────────
            UIColor(hex: "#D4B070").setFill()
            ctx.fill(CGRect(x: 0, y: wallH, width: size.width, height: size.height - wallH))

            // Floor planks (horizontal grain lines)
            UIColor(hex: "#B89050").setFill()
            var fy = wallH + 23
            while fy < size.height {
                ctx.fill(CGRect(x: 0, y: fy, width: size.width, height: 1))
                fy += 24
            }

            // ── Window ────────────────────────────────────────────────────
            let winX = size.width / 2 - 56
            let winY: CGFloat = 8
            let winW: CGFloat = 112
            let winH: CGFloat = 96

            // Window frame
            UIColor(hex: "#604018").setFill()
            ctx.fill(CGRect(x: winX, y: winY, width: winW, height: winH))

            // Sky
            UIColor(hex: "#78C8F8").setFill()
            ctx.fill(CGRect(x: winX + 4, y: winY + 4, width: winW - 8, height: winH - 8))

            // Clouds
            UIColor.white.setFill()
            ctx.fill(CGRect(x: winX + 10, y: winY + 12, width: 28, height: 10).insetBy(dx: 0, dy: 0))
            cg.fillEllipse(in: CGRect(x: winX + 10, y: winY + 8, width: 16, height: 14))
            cg.fillEllipse(in: CGRect(x: winX + 18, y: winY + 6, width: 20, height: 18))
            cg.fillEllipse(in: CGRect(x: winX + 30, y: winY + 9, width: 14, height: 13))

            // Far cloud
            UIColor(hex: "#E8F4FF").setFill()
            cg.fillEllipse(in: CGRect(x: winX + 65, y: winY + 20, width: 14, height: 10))
            cg.fillEllipse(in: CGRect(x: winX + 70, y: winY + 16, width: 16, height: 12))

            // Trees (bottom of window)
            UIColor(hex: "#389820").setFill()
            ctx.fill(CGRect(x: winX + 4, y: winY + winH - 30, width: winW - 8, height: 26))
            UIColor(hex: "#58C838").setFill()
            cg.fillEllipse(in: CGRect(x: winX + 6, y: winY + winH - 46, width: 22, height: 28))
            cg.fillEllipse(in: CGRect(x: winX + 30, y: winY + winH - 52, width: 28, height: 34))
            cg.fillEllipse(in: CGRect(x: winX + 58, y: winY + winH - 46, width: 24, height: 30))
            cg.fillEllipse(in: CGRect(x: winX + 78, y: winY + winH - 40, width: 22, height: 26))

            // Sun
            UIColor(hex: "#F8E000").setFill()
            cg.fillEllipse(in: CGRect(x: winX + winW - 26, y: winY + 10, width: 16, height: 16))

            // Window crossbar
            UIColor(hex: "#604018").setFill()
            ctx.fill(CGRect(x: winX + 4, y: winY + winH / 2 - 2, width: winW - 8, height: 3))
            ctx.fill(CGRect(x: winX + winW / 2 - 2, y: winY + 4, width: 3, height: winH - 8))

            // ── Bookshelf (left wall) ─────────────────────────────────────
            let shelfX: CGFloat = 10
            let shelfY = wallH - 72

            // Shelf back
            UIColor(hex: "#582810").setFill()
            ctx.fill(CGRect(x: shelfX, y: shelfY, width: 52, height: 72))

            // Shelf boards
            UIColor(hex: "#784020").setFill()
            for sy in [shelfY, shelfY + 24, shelfY + 48, shelfY + 68] {
                ctx.fill(CGRect(x: shelfX, y: sy, width: 52, height: 4))
            }

            // Books (top shelf)
            let bookColors: [UIColor] = [
                UIColor(hex: "#E83028"), UIColor(hex: "#2848E8"),
                UIColor(hex: "#28A828"), UIColor(hex: "#E8A028"),
                UIColor(hex: "#A828E8")
            ]
            let bookWidths: [CGFloat] = [8, 7, 8, 9, 8]
            var bx = shelfX + 2
            for (i, bc) in bookColors.enumerated() {
                bc.setFill()
                ctx.fill(CGRect(x: bx, y: shelfY + 4, width: bookWidths[i], height: 16))
                bx += bookWidths[i] + 1
            }

            // Books (middle shelf)
            let bookColors2: [UIColor] = [
                UIColor(hex: "#48A8E8"), UIColor(hex: "#E84888"),
                UIColor(hex: "#88C828"), UIColor(hex: "#F8D028")
            ]
            bx = shelfX + 2
            for (i, bc) in bookColors2.enumerated() {
                bc.setFill()
                ctx.fill(CGRect(x: bx, y: shelfY + 28, width: [10, 8, 9, 10][i], height: 16))
                bx += [10, 8, 9, 10][i] + 1
            }

            // Plant (bottom shelf)
            UIColor(hex: "#784028").setFill()
            ctx.fill(CGRect(x: shelfX + 6, y: shelfY + 56, width: 14, height: 10))
            UIColor(hex: "#48A028").setFill()
            cg.fillEllipse(in: CGRect(x: shelfX + 4, y: shelfY + 42, width: 18, height: 16))
            UIColor(hex: "#58C038").setFill()
            cg.fillEllipse(in: CGRect(x: shelfX + 2, y: shelfY + 36, width: 14, height: 14))
            cg.fillEllipse(in: CGRect(x: shelfX + 12, y: shelfY + 38, width: 14, height: 14))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}

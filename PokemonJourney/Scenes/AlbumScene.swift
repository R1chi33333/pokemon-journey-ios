import SpriteKit
import UIKit

class AlbumScene: SKScene {

    private let gm = GameManager.shared
    private var scrollContainer: SKNode!
    private var cropNode: SKCropNode!
    private var isDragging = false
    private var lastTouchY: CGFloat = 0
    private var scrollOffset: CGFloat = 0
    private var totalContentH: CGFloat = 0

    private var tabBarH: CGFloat { 72 }
    private var headerH: CGFloat { 80 }
    private var contentY: CGFloat { tabBarH }
    private var contentH: CGFloat { size.height - tabBarH - headerH }

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = UIColor(hex: "#12122A")
        buildBackground()
        buildHeader()
        buildTabBar()
        buildCards()
    }

    // MARK: - Background

    private func buildBackground() {
        // Starfield
        for _ in 0..<60 {
            let star = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
            star.fillColor = UIColor(white: 1.0, alpha: CGFloat.random(in: 0.1...0.6))
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                    y: CGFloat.random(in: 0...size.height))
            addChild(star)
        }
    }

    // MARK: - Header

    private func buildHeader() {
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        bg.fillColor = UIColor(hex: "#0E0E20")
        bg.strokeColor = UIColor(hex: "#2A2A48")
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width/2, y: size.height - headerH/2)
        bg.zPosition = 10
        addChild(bg)

        let title = SKLabelNode(text: "⚡ Sparky 的相册")
        title.fontName = "PingFangSC-Semibold"
        title.fontSize = 15
        title.fontColor = UIColor(hex: "#F8D030")
        title.position = CGPoint(x: size.width/2, y: size.height - 30)
        title.zPosition = 11
        addChild(title)

        let count = gm.state.postcards.count
        let journeys = gm.state.sparky.totalJourneys
        let sub = SKLabelNode(text: "\(count) 张明信片  ·  共旅行 \(journeys) 次")
        sub.fontName = "PingFangSC-Regular"
        sub.fontSize = 10
        sub.fontColor = UIColor(hex: "#808098")
        sub.position = CGPoint(x: size.width/2, y: size.height - 58)
        sub.zPosition = 11
        addChild(sub)
    }

    // MARK: - Tab Bar

    private func buildTabBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: tabBarH))
        bar.fillColor = UIColor(hex: "#0E0E20")
        bar.strokeColor = UIColor(hex: "#2A2A48")
        bar.lineWidth = 1
        bar.position = CGPoint(x: size.width/2, y: tabBarH/2)
        bar.zPosition = 30
        addChild(bar)

        addTab(emoji: "🏠", label: "主页", x: size.width*0.2, active: false, name: "btn_home")
        addTab(emoji: "🌟", label: "旅行", x: size.width*0.5, active: false, name: "btn_journey")
        addTab(emoji: "📮", label: "相册", x: size.width*0.8, active: true,  name: nil)
    }

    private func addTab(emoji: String, label: String, x: CGFloat, active: Bool, name: String?) {
        if active {
            let indicator = SKShapeNode(rectOf: CGSize(width: 40, height: 3))
            indicator.fillColor = UIColor(hex: "#F8D030")
            indicator.strokeColor = .clear
            indicator.position = CGPoint(x: x, y: tabBarH - 1.5)
            indicator.zPosition = 32
            addChild(indicator)
        }
        let emj = SKLabelNode(text: emoji)
        emj.fontSize = 26
        emj.position = CGPoint(x: x, y: tabBarH*0.52)
        emj.zPosition = 31
        emj.name = name
        addChild(emj)
        let lbl = SKLabelNode(text: label)
        lbl.fontName = "PingFangSC-Semibold"
        lbl.fontSize = 9
        lbl.fontColor = active ? UIColor(hex: "#F8D030") : UIColor(hex: "#606080")
        lbl.position = CGPoint(x: x, y: 8)
        lbl.zPosition = 31
        lbl.name = name
        addChild(lbl)
    }

    // MARK: - Cards

    private func buildCards() {
        scrollContainer = SKNode()
        scrollContainer.zPosition = 5

        cropNode = SKCropNode()
        let mask = SKShapeNode(rectOf: CGSize(width: size.width, height: contentH))
        mask.fillColor = .white
        mask.position = CGPoint(x: size.width/2, y: contentY + contentH/2)
        cropNode.maskNode = mask
        cropNode.addChild(scrollContainer)
        addChild(cropNode)

        let cards = gm.state.postcards
        if cards.isEmpty {
            buildEmptyState()
            return
        }

        let cardH: CGFloat = 148
        let spacing: CGFloat = 16
        let padding: CGFloat = 12

        totalContentH = CGFloat(cards.count) * (cardH + spacing) + padding * 2
        scrollOffset = 0

        let firstCardY = contentY + totalContentH - padding - cardH

        for (i, card) in cards.enumerated() {
            let cardY = firstCardY - CGFloat(i) * (cardH + spacing)
            let cardNode = buildCard(card, atY: cardY, height: cardH)
            cardNode.alpha = 0
            cardNode.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.07),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -8, duration: 0),
                        SKAction.moveBy(x: 0, y: 8, duration: 0.2),
                    ]),
                ]),
            ]))
            scrollContainer.addChild(cardNode)
        }
    }

    private func buildCard(_ card: Postcard, atY y: CGFloat, height: CGFloat) -> SKNode {
        let loc = ALL_LOCATIONS.first { $0.id == card.locationId }
        let cardW = size.width - 32
        let node = SKNode()
        node.position = CGPoint(x: 16, y: y)

        // Postcard base texture
        let cardBase = SKSpriteNode(texture: nearestTex("postcard"),
                                    size: CGSize(width: cardW, height: height))
        cardBase.anchorPoint = CGPoint(x: 0, y: 0)
        cardBase.zPosition = 1
        node.addChild(cardBase)

        // Left color strip (location color)
        let strip = SKShapeNode(rectOf: CGSize(width: 10, height: height - 8))
        strip.fillColor = UIColor(hex: loc?.skyColor ?? "#78C8F8")
        strip.strokeColor = .clear
        strip.position = CGPoint(x: 5, y: height/2)
        strip.zPosition = 2
        node.addChild(strip)

        // Location emoji (big)
        let emj = SKLabelNode(text: loc?.emoji ?? "📮")
        emj.fontSize = 36
        emj.position = CGPoint(x: 40, y: height/2 - 6)
        emj.zPosition = 3
        node.addChild(emj)

        // Sparky mini
        let sparkyMini = SKSpriteNode(texture: nearestTex("sparky_idle_0"),
                                      size: CGSize(width: 32, height: 40))
        sparkyMini.position = CGPoint(x: cardW - 56, y: height/2 + 12)
        sparkyMini.zPosition = 3
        node.addChild(sparkyMini)

        // Divider line
        let divider = SKShapeNode(rectOf: CGSize(width: 1, height: height - 24))
        divider.fillColor = UIColor(hex: "#D4B070").withAlphaComponent(0.6)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: cardW / 2, y: height/2)
        divider.zPosition = 2
        node.addChild(divider)

        // LEFT side: Location name, message
        let nameL = SKLabelNode(text: loc?.nameZH ?? card.locationId)
        nameL.fontName = "PingFangSC-Semibold"
        nameL.fontSize = 13
        nameL.fontColor = UIColor(hex: "#403820")
        nameL.horizontalAlignmentMode = .left
        nameL.position = CGPoint(x: 72, y: height - 28)
        nameL.zPosition = 3
        node.addChild(nameL)

        // Message (first line)
        let msgLines = card.message.components(separatedBy: "\n")
        for (li, line) in msgLines.prefix(2).enumerated() {
            let msgL = SKLabelNode(text: line)
            msgL.fontName = "PingFangSC-Regular"
            msgL.fontSize = 9
            msgL.fontColor = UIColor(hex: "#706050")
            msgL.horizontalAlignmentMode = .left
            msgL.position = CGPoint(x: 72, y: height - 52 - CGFloat(li) * 16)
            msgL.zPosition = 3
            node.addChild(msgL)
        }

        // Date
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd"
        let dateL = SKLabelNode(text: "📅 \(fmt.string(from: card.date))")
        dateL.fontName = "PingFangSC-Regular"
        dateL.fontSize = 8
        dateL.fontColor = UIColor(hex: "#A09080")
        dateL.horizontalAlignmentMode = .left
        dateL.position = CGPoint(x: 72, y: 14)
        dateL.zPosition = 3
        node.addChild(dateL)

        // RIGHT side: Rewards
        let rw = card.rewards
        var rewardParts: [String] = []
        if rw.coins > 0  { rewardParts.append("💰\(rw.coins)") }
        if rw.oran > 0   { rewardParts.append("🫐×\(rw.oran)") }
        if rw.pecha > 0  { rewardParts.append("🍑×\(rw.pecha)") }
        if rw.sitrus > 0 { rewardParts.append("🍊×\(rw.sitrus)") }

        for (ri, part) in rewardParts.enumerated() {
            let rewL = SKLabelNode(text: part)
            rewL.fontName = "PingFangSC-Semibold"
            rewL.fontSize = 10
            rewL.fontColor = UIColor(hex: "#806040")
            rewL.horizontalAlignmentMode = .right
            rewL.position = CGPoint(x: cardW - 16, y: height - 28 - CGFloat(ri) * 18)
            rewL.zPosition = 3
            node.addChild(rewL)
        }

        // Stamp (top right corner)
        let stamp = SKShapeNode(rectOf: CGSize(width: 36, height: 36))
        stamp.fillColor = UIColor(hex: "#FFF8E0")
        stamp.strokeColor = UIColor(hex: "#C0A060")
        stamp.lineWidth = 1
        stamp.position = CGPoint(x: cardW - 22, y: height - 22)
        stamp.zPosition = 3
        node.addChild(stamp)
        let stampEmj = SKLabelNode(text: "⚡")
        stampEmj.fontSize = 18
        stampEmj.position = CGPoint(x: cardW - 22, y: height - 28)
        stampEmj.zPosition = 4
        node.addChild(stampEmj)

        return node
    }

    private func buildEmptyState() {
        let sparky = SKSpriteNode(texture: nearestTex("sparky_idle_2"),
                                   size: CGSize(width: 84, height: 105))
        sparky.position = CGPoint(x: size.width/2, y: contentY + contentH * 0.6)
        sparky.zPosition = 10
        addChild(sparky)
        sparky.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 1.0),
            SKAction.moveBy(x: 0, y: -4, duration: 1.0),
        ])))

        for (text, dy, col) in [
            ("还没有明信片...",      140.0, "#A0A0B8"),
            ("送 Sparky 去旅行吧！", 108.0, "#707090"),
            ("期待来自远方的回忆！",  86.0, "#707090"),
        ] {
            let lbl = SKLabelNode(text: text)
            lbl.fontName = "PingFangSC-Semibold"
            lbl.fontSize = 12
            lbl.fontColor = UIColor(hex: col)
            lbl.position = CGPoint(x: size.width/2, y: contentY + dy)
            lbl.zPosition = 10
            addChild(lbl)
        }

        let btn = makeNavButton(text: "🏠 去整理行囊", name: "btn_home")
        btn.position = CGPoint(x: size.width/2, y: contentY + 48)
        addChild(btn)
    }

    // MARK: - Scroll

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        isDragging = true
        lastTouchY = loc.y

        let name = atPoint(loc).name ?? ""
        switch name {
        case "btn_home":    goHome()
        case "btn_journey": goJourney()
        default: break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let dy = loc.y - lastTouchY
        lastTouchY = loc.y

        let maxScroll = max(0, totalContentH - contentH)
        scrollOffset = max(0, min(maxScroll, scrollOffset - dy))
        scrollContainer.position.y = -scrollOffset
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }

    // MARK: - Navigation

    private func goHome() {
        let scene = HomeScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    private func goJourney() {
        let scene = JourneyScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - Helpers

    private func nearestTex(_ name: String) -> SKTexture {
        let t = SKTexture(imageNamed: name)
        t.filteringMode = .nearest
        return t
    }

    private func makeNavButton(text: String, name: String) -> SKNode {
        let node = SKNode()
        node.zPosition = 15
        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 8)
        bg.fillColor = UIColor(hex: "#205090")
        bg.strokeColor = UIColor(hex: "#3068C0")
        bg.lineWidth = 2
        bg.name = name
        node.addChild(bg)
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "PingFangSC-Semibold"
        lbl.fontSize = 12
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        node.addChild(lbl)
        node.name = name
        return node
    }
}

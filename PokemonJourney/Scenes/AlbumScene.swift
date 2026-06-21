import SpriteKit
import UIKit

class AlbumScene: SKScene {

    private let gm = GameManager.shared
    private var scrollOffset: CGFloat = 0
    private var isDragging = false
    private var lastTouchY: CGFloat = 0
    private var cardsContainer: SKNode!
    private var totalContentH: CGFloat = 0

    private var tabBarH: CGFloat { 72 }
    private var headerH: CGFloat { 70 }
    private var contentY: CGFloat { tabBarH }
    private var contentH: CGFloat { size.height - tabBarH - headerH }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: "#1A1A2E")
        anchorPoint = .zero
        buildHeader()
        buildTabBar()
        buildCards()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        isDragging = true
        lastTouchY = loc.y

        switch atPoint(loc).name {
        case "btn_home":   goHome()
        case "btn_journey": goJourney()
        default: break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let dy = loc.y - lastTouchY
        lastTouchY = loc.y
        scrollOffset = max(0, min(max(0, totalContentH - contentH), scrollOffset - dy))
        cardsContainer?.position.y = contentY + scrollOffset
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }

    // MARK: - Build

    private func buildHeader() {
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        bg.fillColor = UIColor(hex: "#12122A")
        bg.strokeColor = UIColor(hex: "#2D2D4E")
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height - headerH / 2)
        bg.zPosition = 10
        addChild(bg)

        let title = SKLabelNode(text: "⚡ 皮卡丘的相册")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = UIColor(hex: "#F8D030")
        title.position = CGPoint(x: size.width / 2, y: size.height - 28)
        title.zPosition = 11
        addChild(title)

        let sub = SKLabelNode(text: "\(gm.state.postcards.count) 张明信片 · 总旅行 \(gm.state.pikachu.totalJourneys) 次")
        sub.fontName = "Courier"
        sub.fontSize = 9
        sub.fontColor = UIColor(hex: "#A0A0B8")
        sub.position = CGPoint(x: size.width / 2, y: size.height - 52)
        sub.zPosition = 11
        addChild(sub)
    }

    private func buildTabBar() {
        let barBg = SKShapeNode(rectOf: CGSize(width: size.width, height: tabBarH))
        barBg.fillColor = UIColor(hex: "#12122A")
        barBg.strokeColor = UIColor(hex: "#2D2D4E")
        barBg.lineWidth = 1
        barBg.position = CGPoint(x: size.width / 2, y: tabBarH / 2)
        barBg.zPosition = 30
        addChild(barBg)

        addTabItem(emoji: "🏠", label: "家",   x: size.width * 0.2, active: false, name: "btn_home")
        addTabItem(emoji: "🌟", label: "旅行", x: size.width * 0.5, active: false, name: "btn_journey")
        addTabItem(emoji: "📮", label: "相册", x: size.width * 0.8, active: true,  name: nil)
    }

    private func addTabItem(emoji: String, label: String, x: CGFloat, active: Bool, name: String?) {
        let emj = SKLabelNode(text: emoji)
        emj.fontSize = 24
        emj.position = CGPoint(x: x, y: tabBarH * 0.5 + 2)
        emj.zPosition = 31
        emj.name = name
        addChild(emj)
        let lbl = SKLabelNode(text: label)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 8
        lbl.fontColor = active ? UIColor(hex: "#F8D030") : UIColor(hex: "#707090")
        lbl.position = CGPoint(x: x, y: tabBarH * 0.12)
        lbl.zPosition = 31
        lbl.name = name
        addChild(lbl)
        if active {
            let ind = SKShapeNode(rectOf: CGSize(width: 36, height: 2))
            ind.fillColor = UIColor(hex: "#F8D030")
            ind.strokeColor = .clear
            ind.position = CGPoint(x: x, y: tabBarH - 2)
            ind.zPosition = 32
            addChild(ind)
        }
    }

    private func buildCards() {
        let postcards = gm.state.postcards
        cardsContainer = SKNode()
        cardsContainer.position = CGPoint(x: 0, y: contentY)
        cardsContainer.zPosition = 5
        addChild(cardsContainer)

        // Clip to content area
        let cropNode = SKCropNode()
        let maskShape = SKShapeNode(rectOf: CGSize(width: size.width, height: contentH))
        maskShape.fillColor = .white
        maskShape.position = CGPoint(x: size.width / 2, y: contentH / 2 + contentY)
        cropNode.maskNode = maskShape
        cropNode.addChild(cardsContainer)
        addChild(cropNode)

        if postcards.isEmpty {
            buildEmptyState()
            return
        }

        let cardH: CGFloat = 110
        let spacing: CGFloat = 12
        let startY = CGFloat(postcards.count - 1) * (cardH + spacing) + spacing
        totalContentH = startY + cardH + spacing

        for (i, card) in postcards.enumerated() {
            let cardY = startY - CGFloat(i) * (cardH + spacing)
            let cardNode = buildCard(card, atY: cardY)
            cardNode.alpha = 0
            cardNode.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.08),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -12, duration: 0),
                        SKAction.moveBy(x: 0, y: 12, duration: 0.2),
                    ]),
                ]),
            ]))
            cardsContainer.addChild(cardNode)
        }
    }

    private func buildCard(_ postcard: Postcard, atY y: CGFloat) -> SKNode {
        let location = ALL_LOCATIONS.first { $0.id == postcard.locationId }
        let cardW = size.width - 32
        let cardH: CGFloat = 100
        let node = SKNode()
        node.position = CGPoint(x: 16, y: y)

        // Card background (postcard beige)
        let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 4)
        bg.fillColor = UIColor(hex: "#F5ECD8")
        bg.strokeColor = UIColor(hex: "#D4B070")
        bg.lineWidth = 2
        bg.position = CGPoint(x: cardW / 2, y: cardH / 2)
        bg.zPosition = 1
        node.addChild(bg)

        // Location color strip on left
        let strip = SKShapeNode(rectOf: CGSize(width: 8, height: cardH - 4))
        strip.fillColor = UIColor(hex: location?.skyColor ?? "#78C8F8")
        strip.strokeColor = .clear
        strip.position = CGPoint(x: 4, y: cardH / 2)
        strip.zPosition = 2
        node.addChild(strip)

        // Location emoji
        let emj = SKLabelNode(text: location?.emoji ?? "📮")
        emj.fontSize = 28
        emj.position = CGPoint(x: 30, y: cardH / 2 - 6)
        emj.zPosition = 3
        node.addChild(emj)

        // Location name
        let nameLbl = SKLabelNode(text: location?.nameZH ?? postcard.locationId)
        nameLbl.fontName = "Courier-Bold"
        nameLbl.fontSize = 11
        nameLbl.fontColor = UIColor(hex: "#403820")
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: 56, y: cardH - 28)
        nameLbl.zPosition = 3
        node.addChild(nameLbl)

        // Message preview
        let preview = truncate(postcard.message, to: 24)
        let msgLbl = SKLabelNode(text: preview)
        msgLbl.fontName = "Courier"
        msgLbl.fontSize = 9
        msgLbl.fontColor = UIColor(hex: "#706050")
        msgLbl.horizontalAlignmentMode = .left
        msgLbl.position = CGPoint(x: 56, y: cardH - 50)
        msgLbl.zPosition = 3
        node.addChild(msgLbl)

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        let dateLbl = SKLabelNode(text: "📅 \(dateFormatter.string(from: postcard.date))")
        dateLbl.fontName = "Courier"
        dateLbl.fontSize = 8
        dateLbl.fontColor = UIColor(hex: "#909080")
        dateLbl.horizontalAlignmentMode = .left
        dateLbl.position = CGPoint(x: 56, y: 16)
        dateLbl.zPosition = 3
        node.addChild(dateLbl)

        // Stamp decoration
        let stamp = SKShapeNode(rectOf: CGSize(width: 30, height: 30))
        stamp.fillColor = UIColor(hex: "#FFF8E8")
        stamp.strokeColor = UIColor(hex: "#C0A060")
        stamp.lineWidth = 1
        stamp.position = CGPoint(x: cardW - 20, y: cardH - 20)
        stamp.zPosition = 3
        node.addChild(stamp)

        let stampEmj = SKLabelNode(text: "⚡")
        stampEmj.fontSize = 16
        stampEmj.position = CGPoint(x: 0, y: -6)
        stamp.addChild(stampEmj)

        // Rewards summary
        let rewards = postcard.rewards
        var rewardStr = ""
        if rewards.coins > 0 { rewardStr += "💰\(rewards.coins) " }
        if rewards.oran > 0 { rewardStr += "🫐×\(rewards.oran) " }
        if rewards.pecha > 0 { rewardStr += "🍑×\(rewards.pecha) " }
        if rewards.sitrus > 0 { rewardStr += "🍊×\(rewards.sitrus)" }
        if !rewardStr.isEmpty {
            let rewLbl = SKLabelNode(text: rewardStr.trimmingCharacters(in: .whitespaces))
            rewLbl.fontName = "Courier"
            rewLbl.fontSize = 8
            rewLbl.fontColor = UIColor(hex: "#806040")
            rewLbl.horizontalAlignmentMode = .right
            rewLbl.position = CGPoint(x: cardW - 12, y: 16)
            rewLbl.zPosition = 3
            node.addChild(rewLbl)
        }

        return node
    }

    private func buildEmptyState() {
        let emjLbl = SKLabelNode(text: "📮")
        emjLbl.fontSize = 72
        emjLbl.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        emjLbl.zPosition = 10
        addChild(emjLbl)

        let lbl1 = SKLabelNode(text: "还没有明信片...")
        lbl1.fontName = "Courier-Bold"
        lbl1.fontSize = 12
        lbl1.fontColor = UIColor(hex: "#A0A0B8")
        lbl1.position = CGPoint(x: size.width / 2, y: size.height * 0.43)
        lbl1.zPosition = 10
        addChild(lbl1)

        let lbl2 = SKLabelNode(text: "送皮卡丘去旅行")
        lbl2.fontName = "Courier"
        lbl2.fontSize = 10
        lbl2.fontColor = UIColor(hex: "#707090")
        lbl2.position = CGPoint(x: size.width / 2, y: size.height * 0.37)
        lbl2.zPosition = 10
        addChild(lbl2)

        let lbl3 = SKLabelNode(text: "收集来自远方的回忆！")
        lbl3.fontName = "Courier"
        lbl3.fontSize = 10
        lbl3.fontColor = UIColor(hex: "#707090")
        lbl3.position = CGPoint(x: size.width / 2, y: size.height * 0.31)
        lbl3.zPosition = 10
        addChild(lbl3)

        // Decorative pixel stars
        let starPositions: [(CGFloat, CGFloat)] = [
            (50, 0.25), (310, 0.22), (80, 0.18), (280, 0.15), (160, 0.12)
        ]
        for (sx, syFrac) in starPositions {
            let star = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            star.fillColor = UIColor(hex: "#4A4A6A")
            star.strokeColor = .clear
            star.position = CGPoint(x: sx, y: size.height * syFrac)
            star.zPosition = 5
            addChild(star)
        }

        let goBtn = makeNavButton(text: "🏠 去旅行!", name: "btn_home")
        goBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        addChild(goBtn)
    }

    private func makeNavButton(text: String, name: String) -> SKNode {
        let node = SKNode()
        node.zPosition = 15
        let bg = SKShapeNode(rectOf: CGSize(width: 160, height: 40), cornerRadius: 2)
        bg.fillColor = UIColor(hex: "#205090")
        bg.strokeColor = UIColor(hex: "#3068C0")
        bg.lineWidth = 2
        bg.name = name
        node.addChild(bg)
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 12
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        node.addChild(lbl)
        node.name = name
        return node
    }

    // MARK: - Navigation

    private func goHome() {
        let home = HomeScene(size: size)
        home.scaleMode = scaleMode
        view?.presentScene(home, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    private func goJourney() {
        let journey = JourneyScene(size: size)
        journey.scaleMode = scaleMode
        view?.presentScene(journey, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - Helpers

    private func truncate(_ s: String, to n: Int) -> String {
        s.count > n ? String(s.prefix(n)) + "..." : s
    }
}

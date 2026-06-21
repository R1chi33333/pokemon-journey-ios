import SpriteKit
import UIKit

class HomeScene: SKScene {

    private let gm = GameManager.shared
    private var pikachuNode: SKSpriteNode!
    private var blinkTime: TimeInterval = 0
    private var isBlinking = false

    // UI nodes we need to update
    private var statusLabel: SKLabelNode!
    private var oranLabel: SKLabelNode!
    private var pechaLabel: SKLabelNode!
    private var sitrusLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var sendButton: SKNode!
    private var locationPanel: SKNode?
    private var tableItemsNode: SKNode!

    // Layout constants (derived from scene size)
    private var tabBarH: CGFloat { 72 }
    private var inventoryH: CGFloat { 70 }
    private var statusBoxH: CGFloat { 54 }
    private var roomOriginY: CGFloat { tabBarH + inventoryH + statusBoxH }
    private var roomH: CGFloat { size.height - roomOriginY }
    private var tableY: CGFloat { roomOriginY + roomH * 0.32 }

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: "#1A1A2E")
        anchorPoint = .zero
        buildScene()
    }

    override func update(_ currentTime: TimeInterval) {
        // Pikachu blink every ~3 seconds
        blinkTime += 1.0 / 60.0
        if !isBlinking && blinkTime > 3.0 {
            blinkTime = 0
            isBlinking = true
            let blink = PixelArtRenderer.makeTexture(
                art: PikachuSprites.frontBlink, palette: Palettes.pikachu, pixelSize: 5)
            let normal = PixelArtRenderer.makeTexture(
                art: PikachuSprites.front, palette: Palettes.pikachu, pixelSize: 5)
            blink.filteringMode = .nearest
            normal.filteringMode = .nearest
            pikachuNode.run(
                SKAction.sequence([
                    SKAction.setTexture(blink, resize: false),
                    SKAction.wait(forDuration: 0.12),
                    SKAction.setTexture(normal, resize: false),
                    SKAction.run { [weak self] in self?.isBlinking = false }
                ])
            )
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let tapped = atPoint(loc)

        switch tapped.name {
        case "item_oran":   packOrUnpack("oran")
        case "item_pecha":  packOrUnpack("pecha")
        case "item_sitrus": packOrUnpack("sitrus")
        case "btn_send":    showLocationPanel()
        case "btn_album":   goToAlbum()
        case "btn_journey": goToJourney()
        case let s where s?.hasPrefix("loc_") == true:
            let locId = String(s!.dropFirst(4))
            confirmJourney(locationId: locId)
        case "panel_close": closeLocationPanel()
        default: break
        }
    }

    // MARK: - Build scene

    private func buildScene() {
        buildRoom()
        buildTable()
        buildPikachu()
        buildStatusBox()
        buildInventory()
        buildTabBar()
    }

    private func buildRoom() {
        let roomSize = CGSize(width: size.width, height: roomH + statusBoxH + 8)
        let roomTex = PixelArtRenderer.makeRoomTexture(size: roomSize)
        let roomBg = SKSpriteNode(texture: roomTex)
        roomBg.position = CGPoint(x: size.width / 2, y: roomOriginY - statusBoxH - 4 + roomSize.height / 2)
        roomBg.zPosition = 0
        addChild(roomBg)
    }

    private func buildTable() {
        let tw: CGFloat = size.width * 0.52
        let th: CGFloat = 64

        // Shadow under table
        let shadow = SKShapeNode(ellipseOf: CGSize(width: tw + 10, height: 12))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width / 2, y: tableY - th / 2 - 4)
        shadow.zPosition = 4
        addChild(shadow)

        // Table legs
        for dx in [-(tw / 2 - 12), tw / 2 - 12] {
            let leg = SKShapeNode(rectOf: CGSize(width: 10, height: 26))
            leg.fillColor = UIColor(hex: "#582810")
            leg.strokeColor = .clear
            leg.position = CGPoint(x: size.width / 2 + dx, y: tableY - th / 2 - 12)
            leg.zPosition = 4
            addChild(leg)
        }

        // Table surface
        let tableNode = SKShapeNode(rectOf: CGSize(width: tw, height: th), cornerRadius: 4)
        tableNode.fillColor = UIColor(hex: "#784020")
        tableNode.strokeColor = UIColor(hex: "#502010")
        tableNode.lineWidth = 2
        tableNode.position = CGPoint(x: size.width / 2, y: tableY)
        tableNode.zPosition = 5
        addChild(tableNode)

        let surface = SKShapeNode(rectOf: CGSize(width: tw - 10, height: th - 16), cornerRadius: 2)
        surface.fillColor = UIColor(hex: "#A05028")
        surface.strokeColor = .clear
        surface.position = CGPoint(x: size.width / 2, y: tableY)
        surface.zPosition = 6
        addChild(surface)

        // Shine
        let shine = SKShapeNode(rectOf: CGSize(width: tw * 0.55, height: 4))
        shine.fillColor = UIColor.white.withAlphaComponent(0.25)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: size.width / 2 - 20, y: tableY + th / 2 - 12)
        shine.zPosition = 7
        addChild(shine)

        // Pokéball decoration on table
        let pokeNode = SKShapeNode(circleOfRadius: 12)
        pokeNode.fillColor = UIColor(hex: "#E82828")
        pokeNode.strokeColor = UIColor(hex: "#1C1C1C")
        pokeNode.lineWidth = 1.5
        pokeNode.position = CGPoint(x: size.width / 2 + tw / 2 - 22, y: tableY + 4)
        pokeNode.zPosition = 8
        addChild(pokeNode)
        let pokeMid = SKShapeNode(rectOf: CGSize(width: 24, height: 2))
        pokeMid.fillColor = UIColor(hex: "#1C1C1C")
        pokeMid.strokeColor = .clear
        pokeMid.position = CGPoint(x: size.width / 2 + tw / 2 - 22, y: tableY + 4)
        pokeMid.zPosition = 9
        addChild(pokeMid)
        let pokeCenter = SKShapeNode(circleOfRadius: 4)
        pokeCenter.fillColor = UIColor.white
        pokeCenter.strokeColor = UIColor(hex: "#1C1C1C")
        pokeCenter.lineWidth = 1
        pokeCenter.position = CGPoint(x: size.width / 2 + tw / 2 - 22, y: tableY + 4)
        pokeCenter.zPosition = 10
        addChild(pokeCenter)

        // Table items container
        tableItemsNode = SKNode()
        tableItemsNode.position = CGPoint(x: size.width / 2 - tw / 2 + 20, y: tableY + 6)
        tableItemsNode.zPosition = 9
        addChild(tableItemsNode)
        refreshTableItems()
    }

    private func refreshTableItems() {
        tableItemsNode.removeAllChildren()
        let packed = gm.state.packed
        var xOff: CGFloat = 0
        let slots: [(String, String)] = [("🫐", "oran"), ("🍑", "pecha"), ("🍊", "sitrus")]
        for (emoji, id) in slots where packed[id] > 0 {
            let emj = SKLabelNode(text: emoji)
            emj.fontSize = 22
            emj.position = CGPoint(x: xOff, y: 0)
            tableItemsNode.addChild(emj)

            let cnt = SKLabelNode(text: "×\(packed[id])")
            cnt.fontName = "Courier-Bold"
            cnt.fontSize = 9
            cnt.fontColor = UIColor(hex: "#F8F8F8")
            cnt.position = CGPoint(x: xOff + 14, y: -14)
            tableItemsNode.addChild(cnt)
            xOff += 44
        }
    }

    private func buildPikachu() {
        let tex = PixelArtRenderer.makeTexture(
            art: PikachuSprites.front, palette: Palettes.pikachu, pixelSize: 5)
        tex.filteringMode = .nearest

        pikachuNode = SKSpriteNode(texture: tex)
        pikachuNode.position = CGPoint(x: size.width / 2, y: tableY + 52)
        pikachuNode.zPosition = 12

        // Bobbing
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.65),
            SKAction.moveBy(x: 0, y: -5, duration: 0.65),
        ])
        pikachuNode.run(SKAction.repeatForever(bob))

        // Entry bounce
        pikachuNode.setScale(0.5)
        pikachuNode.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.18),
            SKAction.scale(to: 0.96, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.08),
        ]))

        addChild(pikachuNode)

        // Mood bubble
        let bubble = SKShapeNode(rectOf: CGSize(width: 28, height: 22), cornerRadius: 10)
        bubble.fillColor = .white
        bubble.strokeColor = UIColor(hex: "#003878")
        bubble.lineWidth = 1.5
        bubble.position = CGPoint(x: size.width / 2 + 42, y: tableY + 96)
        bubble.zPosition = 13
        addChild(bubble)

        let moodEmoji = SKLabelNode(text: "😊")
        moodEmoji.name = "moodEmoji"
        moodEmoji.fontSize = 14
        moodEmoji.position = CGPoint(x: 0, y: -6)
        bubble.addChild(moodEmoji)
    }

    private func buildStatusBox() {
        let boxH = statusBoxH
        let boxY = tabBarH + inventoryH

        let boxBg = SKShapeNode(rectOf: CGSize(width: size.width - 24, height: boxH - 6), cornerRadius: 3)
        boxBg.fillColor = UIColor(hex: "#F0F8FF")
        boxBg.strokeColor = UIColor(hex: "#003878")
        boxBg.lineWidth = 3
        boxBg.position = CGPoint(x: size.width / 2, y: boxY + (boxH - 6) / 2)
        boxBg.zPosition = 20
        addChild(boxBg)

        statusLabel = SKLabelNode(text: gm.state.pikachu.mood.text)
        statusLabel.fontName = "Courier-Bold"
        statusLabel.fontSize = 11
        statusLabel.fontColor = UIColor(hex: "#181818")
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: size.width / 2, y: boxY + (boxH - 6) / 2 + 6)
        statusLabel.zPosition = 21
        addChild(statusLabel)

        coinsLabel = SKLabelNode(text: "旅行:0  💰\(gm.state.coins)G")
        coinsLabel.fontName = "Courier"
        coinsLabel.fontSize = 9
        coinsLabel.fontColor = UIColor(hex: "#505060")
        coinsLabel.horizontalAlignmentMode = .center
        coinsLabel.position = CGPoint(x: size.width / 2, y: boxY + 7)
        coinsLabel.zPosition = 21
        addChild(coinsLabel)
    }

    private func buildInventory() {
        let invY = tabBarH
        let invH = inventoryH

        let invBg = SKShapeNode(rectOf: CGSize(width: size.width, height: invH))
        invBg.fillColor = UIColor(hex: "#12122A")
        invBg.strokeColor = UIColor(hex: "#2D2D4E")
        invBg.lineWidth = 1
        invBg.position = CGPoint(x: size.width / 2, y: invY + invH / 2)
        invBg.zPosition = 20
        addChild(invBg)

        buildItemSlot(id: "oran", emoji: "🫐", xCenter: size.width * 0.18, y: invY + invH / 2)
        buildItemSlot(id: "pecha", emoji: "🍑", xCenter: size.width * 0.38, y: invY + invH / 2)
        buildItemSlot(id: "sitrus", emoji: "🍊", xCenter: size.width * 0.58, y: invY + invH / 2)

        // Send button in inventory row
        let sendBtnNode = makeGBAButton(
            text: sendButtonLabel,
            color: UIColor(hex: "#205090"),
            size: CGSize(width: 100, height: 36)
        )
        sendBtnNode.position = CGPoint(x: size.width * 0.82, y: invY + invH / 2)
        sendBtnNode.zPosition = 21
        sendBtnNode.name = "btn_send"
        tagChildren(of: sendBtnNode, name: "btn_send")
        sendButton = sendBtnNode
        addChild(sendBtnNode)
    }

    private func buildItemSlot(id: String, emoji: String, xCenter: CGFloat, y: CGFloat) {
        let slot = SKShapeNode(rectOf: CGSize(width: 54, height: 54), cornerRadius: 4)
        slot.fillColor = UIColor(hex: "#2D2D4E")
        slot.strokeColor = UIColor(hex: "#4A4A6A")
        slot.lineWidth = 2
        slot.position = CGPoint(x: xCenter, y: y)
        slot.zPosition = 21
        slot.name = "item_\(id)"
        addChild(slot)

        let emj = SKLabelNode(text: emoji)
        emj.fontSize = 24
        emj.position = CGPoint(x: 0, y: 2)
        emj.name = "item_\(id)"
        slot.addChild(emj)

        let count = SKLabelNode(text: "\(gm.state.inventory[id])")
        count.name = "count_\(id)"
        count.fontName = "Courier-Bold"
        count.fontSize = 9
        count.fontColor = UIColor(hex: "#F8F8F8")
        count.horizontalAlignmentMode = .center
        count.position = CGPoint(x: 0, y: -20)
        count.name = "item_\(id)"
        slot.addChild(count)
    }

    private func buildTabBar() {
        let barBg = SKShapeNode(rectOf: CGSize(width: size.width, height: tabBarH))
        barBg.fillColor = UIColor(hex: "#12122A")
        barBg.strokeColor = UIColor(hex: "#2D2D4E")
        barBg.lineWidth = 1
        barBg.position = CGPoint(x: size.width / 2, y: tabBarH / 2)
        barBg.zPosition = 30
        addChild(barBg)

        // Home tab (current)
        addTabItem(emoji: "🏠", label: "家", x: size.width * 0.2, active: true, name: nil)

        // Journey tab
        let hasJourney = !gm.state.pikachu.isHome
        addTabItem(emoji: "🌟", label: "旅行", x: size.width * 0.5,
                   active: false, name: hasJourney ? "btn_journey" : nil)

        // Album tab
        addTabItem(emoji: "📮", label: "相册", x: size.width * 0.8, active: false, name: "btn_album")

        // Journey indicator dot
        if hasJourney {
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.fillColor = UIColor(hex: "#F8D030")
            dot.strokeColor = .clear
            dot.position = CGPoint(x: size.width * 0.5 + 16, y: tabBarH - 10)
            dot.zPosition = 35
            dot.name = "btn_journey"
            addChild(dot)
        }
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
            let indicator = SKShapeNode(rectOf: CGSize(width: 36, height: 2))
            indicator.fillColor = UIColor(hex: "#F8D030")
            indicator.strokeColor = .clear
            indicator.position = CGPoint(x: x, y: tabBarH - 2)
            indicator.zPosition = 32
            addChild(indicator)
        }
    }

    // MARK: - Actions

    private func packOrUnpack(_ itemId: String) {
        let hasPacked = gm.state.packed[itemId] > 0
        let hasInvItem = gm.state.inventory[itemId] > 0

        if hasInvItem && !gm.state.pikachu.isHome == false {
            gm.packItem(itemId)
        } else if hasPacked {
            gm.unpackItem(itemId)
        } else {
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        refreshUI()
    }

    private func showLocationPanel() {
        guard gm.state.pikachu.isHome else {
            goToJourney(); return
        }
        if gm.state.packed.totalCount == 0 {
            showToast("先装入行囊物品！")
            return
        }
        locationPanel?.removeFromParent()

        let panel = SKNode()
        panel.name = "locationPanel"
        panel.zPosition = 50

        // Dim overlay
        let dim = SKShapeNode(rectOf: size)
        dim.fillColor = UIColor.black.withAlphaComponent(0.65)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.name = "panel_close"
        panel.addChild(dim)

        // Panel box
        let panelW: CGFloat = size.width - 40
        let panelH: CGFloat = 320
        let box = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 4)
        box.fillColor = UIColor(hex: "#F0F8FF")
        box.strokeColor = UIColor(hex: "#003878")
        box.lineWidth = 3
        box.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.addChild(box)

        let titleLbl = SKLabelNode(text: "选择目的地")
        titleLbl.fontName = "Courier-Bold"
        titleLbl.fontSize = 13
        titleLbl.fontColor = UIColor(hex: "#003878")
        titleLbl.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelH / 2 - 28)
        panel.addChild(titleLbl)

        let subLbl = SKLabelNode(text: "行囊:\(gm.state.packed.totalCount)个物品")
        subLbl.fontName = "Courier"
        subLbl.fontSize = 9
        subLbl.fontColor = UIColor(hex: "#606060")
        subLbl.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelH / 2 - 48)
        panel.addChild(subLbl)

        var rowY = size.height / 2 + panelH / 2 - 82
        for loc in ALL_LOCATIONS {
            let rowBg = SKShapeNode(rectOf: CGSize(width: panelW - 20, height: 52), cornerRadius: 4)
            rowBg.fillColor = UIColor(hex: "#DCE8F8")
            rowBg.strokeColor = UIColor(hex: "#A0B8D8")
            rowBg.lineWidth = 2
            rowBg.position = CGPoint(x: size.width / 2, y: rowY)
            rowBg.name = "loc_\(loc.id)"
            panel.addChild(rowBg)

            let emjLbl = SKLabelNode(text: loc.emoji)
            emjLbl.fontSize = 26
            emjLbl.position = CGPoint(x: size.width / 2 - panelW / 2 + 28, y: rowY - 10)
            emjLbl.name = "loc_\(loc.id)"
            panel.addChild(emjLbl)

            let nameLbl = SKLabelNode(text: loc.nameZH)
            nameLbl.fontName = "Courier-Bold"
            nameLbl.fontSize = 10
            nameLbl.fontColor = UIColor(hex: "#181818")
            nameLbl.horizontalAlignmentMode = .left
            nameLbl.position = CGPoint(x: size.width / 2 - panelW / 2 + 58, y: rowY + 6)
            nameLbl.name = "loc_\(loc.id)"
            panel.addChild(nameLbl)

            let durLbl = SKLabelNode(text: "\(loc.durationMinutes)分钟  \(loc.emoji)")
            durLbl.fontName = "Courier"
            durLbl.fontSize = 9
            durLbl.fontColor = UIColor(hex: "#606060")
            durLbl.horizontalAlignmentMode = .left
            durLbl.position = CGPoint(x: size.width / 2 - panelW / 2 + 58, y: rowY - 10)
            durLbl.name = "loc_\(loc.id)"
            panel.addChild(durLbl)

            rowY -= 64
        }

        let closeBtn = makeGBAButton(text: "✕ 取消", color: UIColor(hex: "#803030"),
                                      size: CGSize(width: 100, height: 34))
        closeBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - panelH / 2 + 26)
        closeBtn.name = "panel_close"
        tagChildren(of: closeBtn, name: "panel_close")
        panel.addChild(closeBtn)

        addChild(panel)
        locationPanel = panel

        // Animate in
        panel.setScale(0.85)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))
    }

    private func closeLocationPanel() {
        locationPanel?.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.scale(to: 0.9, duration: 0.15),
            ]),
            SKAction.removeFromParent(),
        ]))
        locationPanel = nil
    }

    private func confirmJourney(locationId: String) {
        closeLocationPanel()
        gm.startJourney(locationId: locationId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        goToJourney()
    }

    private func goToJourney() {
        let next = JourneyScene(size: size)
        next.scaleMode = scaleMode
        view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func goToAlbum() {
        let next = AlbumScene(size: size)
        next.scaleMode = scaleMode
        view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - UI refresh

    private func refreshUI() {
        let state = gm.state
        statusLabel?.text = state.pikachu.mood.text
        coinsLabel?.text = "旅行:\(state.pikachu.totalJourneys)  💰\(state.coins)G"

        // Rebuild inventory & table items (simplest approach)
        refreshTableItems()
    }

    private var sendButtonLabel: String {
        let packed = gm.state.packed.totalCount
        if !gm.state.pikachu.isHome { return "旅行中..." }
        return packed > 0 ? "出发!(\(packed))" : "准备行囊"
    }

    // MARK: - Helpers

    private func makeGBAButton(text: String, color: UIColor, size: CGSize) -> SKNode {
        let node = SKNode()

        let shadow = SKShapeNode(rectOf: size)
        shadow.fillColor = color.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        node.addChild(shadow)

        let bg = SKShapeNode(rectOf: size, cornerRadius: 2)
        bg.fillColor = color
        bg.strokeColor = color.withAlphaComponent(0.6)
        bg.lineWidth = 2
        node.addChild(bg)

        let lbl = SKLabelNode(text: text)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = min(10, size.width / CGFloat(text.count) * 1.2)
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .center
        node.addChild(lbl)

        return node
    }

    private func tagChildren(of node: SKNode, name: String) {
        node.children.forEach { child in
            child.name = name
            tagChildren(of: child, name: name)
        }
    }

    private func showToast(_ text: String) {
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 12
        lbl.fontColor = .white
        let bg = SKShapeNode(rectOf: CGSize(width: lbl.frame.width + 24, height: 32), cornerRadius: 8)
        bg.fillColor = UIColor.black.withAlphaComponent(0.75)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        bg.zPosition = 100
        bg.addChild(lbl)
        lbl.position = CGPoint(x: 0, y: -6)
        addChild(bg)
        bg.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent(),
        ]))
    }
}

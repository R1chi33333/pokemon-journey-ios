import SpriteKit
import UIKit

class HomeScene: SKScene {

    private let gm = GameManager.shared
    private var sparkyNode: SKSpriteNode!
    private var idleFrames: [SKTexture] = []
    private var statusLabel: SKLabelNode!
    private var moodLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var inventoryContainer: SKNode!
    private var packPanel: SKNode?
    private var locationPanel: SKNode?
    private var didLayout = false

    private let tileSize: CGFloat = 48
    private var tabBarH: CGFloat { 72 }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = UIColor(hex: "#12122A")
        buildScene()
    }

    override func update(_ currentTime: TimeInterval) {
        if let journey = gm.state.journey, journey.isComplete {
            let loc = ALL_LOCATIONS.first { $0.id == journey.locationId }
            gm.completeJourney(location: loc)
            refreshStatus()
        }
    }

    // MARK: - Build

    private func buildScene() {
        buildRoom()
        buildFurniture()
        buildSparky()
        buildStatusBox()
        buildPackButton()
        buildTabBar()
        animateSparkyEntrance()
    }

    // MARK: Room (tiled background)

    private func buildRoom() {
        let cols = Int(ceil(size.width / tileSize)) + 1
        let wallRows = 5
        let floorY = size.height - CGFloat(wallRows) * tileSize

        // Wall tiles
        let wallTex = nearestTex("room_wall")
        for row in 0..<wallRows {
            for col in 0..<cols {
                let tile = SKSpriteNode(texture: wallTex,
                                       size: CGSize(width: tileSize, height: tileSize))
                tile.anchorPoint = .zero
                tile.position = CGPoint(x: CGFloat(col)*tileSize,
                                       y: size.height - CGFloat(row+1)*tileSize)
                addChild(tile)
            }
        }

        // Baseboard strip
        let baseH: CGFloat = 12
        let base = SKShapeNode(rectOf: CGSize(width: size.width, height: baseH))
        base.fillColor = UIColor(hex: "#7A5028")
        base.strokeColor = .clear
        base.position = CGPoint(x: size.width/2, y: floorY + baseH/2)
        addChild(base)
        let baseTop = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        baseTop.fillColor = UIColor(hex: "#A06830")
        baseTop.strokeColor = .clear
        baseTop.position = CGPoint(x: size.width/2, y: floorY + baseH)
        addChild(baseTop)

        // Floor tiles
        let floorTex = nearestTex("room_floor")
        let floorRows = Int(ceil((floorY - tabBarH) / tileSize)) + 1
        for row in 0..<floorRows {
            for col in 0..<cols {
                let tile = SKSpriteNode(texture: floorTex,
                                       size: CGSize(width: tileSize, height: tileSize))
                tile.anchorPoint = .zero
                tile.position = CGPoint(x: CGFloat(col)*tileSize,
                                       y: floorY - CGFloat(row)*tileSize)
                addChild(tile)
            }
        }
    }

    private func buildFurniture() {
        let wallBottomY = size.height - 5 * tileSize

        // Window (right side of wall)
        let winTex = nearestTex("window")
        let winW: CGFloat = 144, winH: CGFloat = 120
        let window = SKSpriteNode(texture: winTex, size: CGSize(width: winW, height: winH))
        window.anchorPoint = CGPoint(x: 0, y: 0)
        window.position = CGPoint(x: size.width - winW - 24, y: wallBottomY - winH + 12)
        window.zPosition = 2
        addChild(window)

        // Bookshelf (left side of wall)
        let shelfTex = nearestTex("bookshelf")
        let shelfW: CGFloat = 120, shelfH: CGFloat = 168
        let shelf = SKSpriteNode(texture: shelfTex, size: CGSize(width: shelfW, height: shelfH))
        shelf.anchorPoint = CGPoint(x: 0, y: 0)
        shelf.position = CGPoint(x: 20, y: wallBottomY - shelfH + 12)
        shelf.zPosition = 2
        addChild(shelf)

        // Table (center, in front of Sparky)
        let tableTex = nearestTex("table")
        let tableW: CGFloat = 192, tableH: CGFloat = 72
        let table = SKSpriteNode(texture: tableTex, size: CGSize(width: tableW, height: tableH))
        table.anchorPoint = CGPoint(x: 0.5, y: 0)
        table.position = CGPoint(x: size.width/2, y: wallBottomY + 30)
        table.zPosition = 3
        addChild(table)

        // Items on table
        let tableItems: [(String, CGFloat)] = [("item_oran", -56), ("item_coin", 0), ("item_pecha", 56)]
        for (name, dx) in tableItems {
            let itemSprite = SKSpriteNode(texture: nearestTex(name),
                                          size: CGSize(width: 36, height: 36))
            itemSprite.position = CGPoint(x: size.width/2 + dx, y: wallBottomY + 68)
            itemSprite.zPosition = 4
            addChild(itemSprite)
        }
    }

    private func buildSparky() {
        // Build idle animation frames
        idleFrames = (0...3).map { nearestTex("sparky_idle_\($0)") }

        let firstFrame = idleFrames[0]
        let sparkyW: CGFloat = 84, sparkyH: CGFloat = 105

        sparkyNode = SKSpriteNode(texture: firstFrame,
                                   size: CGSize(width: sparkyW, height: sparkyH))
        sparkyNode.position = CGPoint(x: size.width/2, y: size.height - 5*tileSize + 20)
        sparkyNode.zPosition = 10

        let spriteForMood = gm.state.sparky.mood.idleSprite
        let moodTex = nearestTex(spriteForMood)
        sparkyNode.texture = moodTex

        addChild(sparkyNode)
        startIdleAnimation()

        // Shadow under feet
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 50, height: 10))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width/2, y: size.height - 5*tileSize + 6)
        shadow.zPosition = 9
        addChild(shadow)
    }

    private func startIdleAnimation() {
        sparkyNode.removeAction(forKey: "idle")
        let mood = gm.state.sparky.mood
        switch mood {
        case .tired:
            let frames = [nearestTex("sparky_sleep_0"), nearestTex("sparky_sleep_1")]
            let anim = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.animate(with: frames, timePerFrame: 1.2),
                ])
            )
            sparkyNode.run(anim, withKey: "idle")
        case .excited, .happy:
            let happyTex = nearestTex("sparky_happy")
            sparkyNode.texture = happyTex
            let bounce = SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 6, duration: 0.2),
                SKAction.moveBy(x: 0, y: -6, duration: 0.2),
            ]))
            sparkyNode.run(bounce, withKey: "idle")
        default:
            let anim = SKAction.repeatForever(SKAction.sequence([
                SKAction.animate(with: idleFrames, timePerFrame: 0.18),
                SKAction.wait(forDuration: 2.5),
            ]))
            sparkyNode.run(anim, withKey: "idle")
        }
        // Subtle floating bob
        let bob = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.2),
            SKAction.moveBy(x: 0, y: -3, duration: 1.2),
        ]))
        sparkyNode.run(bob, withKey: "bob")
    }

    private func buildStatusBox() {
        let boxY: CGFloat = tabBarH + 4
        let boxH: CGFloat = 72
        let box = SKShapeNode(rectOf: CGSize(width: size.width - 24, height: boxH), cornerRadius: 8)
        box.fillColor = UIColor(hex: "#1C1C3A")
        box.strokeColor = UIColor(hex: "#3A3A60")
        box.lineWidth = 1.5
        box.position = CGPoint(x: size.width/2, y: boxY + boxH/2)
        box.zPosition = 20
        addChild(box)

        // Sparky mini portrait
        let portrait = SKSpriteNode(texture: nearestTex("sparky_idle_0"),
                                     size: CGSize(width: 44, height: 55))
        portrait.position = CGPoint(x: 12 + 44/2, y: boxY + boxH/2)
        portrait.zPosition = 21
        addChild(portrait)

        // Name / mood
        let nameL = SKLabelNode(text: "⚡ Sparky")
        nameL.fontName = "PingFangSC-Semibold"
        nameL.fontSize = 13
        nameL.fontColor = UIColor(hex: "#F8D030")
        nameL.horizontalAlignmentMode = .left
        nameL.position = CGPoint(x: 66, y: boxY + boxH/2 + 14)
        nameL.zPosition = 21
        addChild(nameL)

        moodLabel = SKLabelNode(text: gm.state.sparky.mood.text)
        moodLabel.fontName = "PingFangSC-Regular"
        moodLabel.fontSize = 10
        moodLabel.fontColor = UIColor(hex: "#C0C0E0")
        moodLabel.horizontalAlignmentMode = .left
        moodLabel.position = CGPoint(x: 66, y: boxY + boxH/2 - 4)
        moodLabel.zPosition = 21
        addChild(moodLabel)

        // Coins
        let coinIcon = SKSpriteNode(texture: nearestTex("item_coin"), size: CGSize(width: 20, height: 20))
        coinIcon.position = CGPoint(x: 66, y: boxY + boxH/2 - 22)
        coinIcon.zPosition = 21
        addChild(coinIcon)

        coinsLabel = SKLabelNode(text: "\(gm.state.coins)")
        coinsLabel.fontName = "PingFangSC-Semibold"
        coinsLabel.fontSize = 10
        coinsLabel.fontColor = UIColor(hex: "#F8D030")
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: 82, y: boxY + boxH/2 - 26)
        coinsLabel.zPosition = 21
        addChild(coinsLabel)

        // Journey status on right
        buildJourneyStatus(inBox: box, boxY: boxY, boxH: boxH)
    }

    private func buildJourneyStatus(inBox box: SKShapeNode, boxY: CGFloat, boxH: CGFloat) {
        if let journey = gm.state.journey {
            let loc = ALL_LOCATIONS.first { $0.id == journey.locationId }
            let statusText = journey.isComplete ? "旅行完成！点击查看" :
                             "旅行中: \(journey.formattedTimeRemaining)"
            statusLabel = SKLabelNode(text: statusText)
            statusLabel.fontName = "PingFangSC-Regular"
            statusLabel.fontSize = 9
            statusLabel.fontColor = journey.isComplete ? UIColor(hex: "#F8D030") : UIColor(hex: "#90D0F0")
            statusLabel.horizontalAlignmentMode = .right
            statusLabel.position = CGPoint(x: size.width - 26, y: boxY + boxH/2 - 4)
            statusLabel.zPosition = 21
            addChild(statusLabel)
            let emjL = SKLabelNode(text: loc?.emoji ?? "🌟")
            emjL.fontSize = 22
            emjL.position = CGPoint(x: size.width - 36, y: boxY + boxH/2 + 10)
            emjL.zPosition = 21
            addChild(emjL)
        } else {
            statusLabel = SKLabelNode(text: "在家休息中")
            statusLabel.fontName = "PingFangSC-Regular"
            statusLabel.fontSize = 9
            statusLabel.fontColor = UIColor(hex: "#707090")
            statusLabel.horizontalAlignmentMode = .right
            statusLabel.position = CGPoint(x: size.width - 26, y: boxY + boxH/2 - 4)
            statusLabel.zPosition = 21
            addChild(statusLabel)
        }
    }

    private func buildPackButton() {
        // Only show if no active journey
        guard gm.state.journey == nil else { return }

        let btnW: CGFloat = size.width - 32
        let btnH: CGFloat = 48
        let btnY = tabBarH + 108

        let bg = SKSpriteNode(texture: nearestTex("btn_yellow"),
                              size: CGSize(width: btnW, height: btnH))
        bg.position = CGPoint(x: size.width/2, y: btnY)
        bg.zPosition = 20
        bg.name = "btn_pack"
        addChild(bg)

        let lbl = SKLabelNode(text: "🎒  整理行囊，出发！")
        lbl.fontName = "PingFangSC-Semibold"
        lbl.fontSize = 14
        lbl.fontColor = UIColor(hex: "#1C1C1C")
        lbl.verticalAlignmentMode = .center
        lbl.position = CGPoint(x: size.width/2, y: btnY)
        lbl.zPosition = 21
        lbl.name = "btn_pack"
        addChild(lbl)
    }

    private func buildTabBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: tabBarH))
        bar.fillColor = UIColor(hex: "#0E0E20")
        bar.strokeColor = UIColor(hex: "#2A2A48")
        bar.lineWidth = 1
        bar.position = CGPoint(x: size.width/2, y: tabBarH/2)
        bar.zPosition = 30
        addChild(bar)

        addTab(emoji: "🏠", label: "主页",   x: size.width*0.2, active: true,  name: nil)
        addTab(emoji: "🌟", label: "旅行",   x: size.width*0.5, active: false, name: "btn_journey")
        addTab(emoji: "📮", label: "相册",   x: size.width*0.8, active: false, name: "btn_album")
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

    // MARK: - Animations

    private func animateSparkyEntrance() {
        sparkyNode.setScale(0.1)
        sparkyNode.alpha = 0
        sparkyNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.4),
                SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.3),
                    SKAction.scale(to: 0.95, duration: 0.1),
                    SKAction.scale(to: 1.0,  duration: 0.1),
                ]),
            ]),
        ]))
    }

    // MARK: - Pack Panel

    private func showPackPanel() {
        packPanel?.removeFromParent()

        let panelW = size.width - 24
        let panelH: CGFloat = 320
        let panelY = tabBarH + 96

        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = 40
        overlay.name = "overlay_pack"

        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 12)
        panel.fillColor = UIColor(hex: "#1C1C3A")
        panel.strokeColor = UIColor(hex: "#4A4A80")
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width/2, y: panelY + panelH/2)
        panel.zPosition = 41
        overlay.addChild(panel)

        // Title
        let title = SKLabelNode(text: "🎒 整理行囊")
        title.fontName = "PingFangSC-Semibold"
        title.fontSize = 15
        title.fontColor = UIColor(hex: "#F8D030")
        title.position = CGPoint(x: 0, y: panelH/2 - 30)
        title.zPosition = 42
        panel.addChild(title)

        let sub = SKLabelNode(text: "最多携带 \(gm.state.packed.maxSlots) 件物品")
        sub.fontName = "PingFangSC-Regular"
        sub.fontSize = 10
        sub.fontColor = UIColor(hex: "#9090B8")
        sub.position = CGPoint(x: 0, y: panelH/2 - 52)
        sub.zPosition = 42
        panel.addChild(sub)

        // Packed slots preview
        buildPackedSlots(in: panel, panelH: panelH)

        // Available items grid
        buildItemGrid(in: panel, panelH: panelH)

        // Go button
        let goBtn = makeButton(text: "出发！→", color: UIColor(hex: "#205090"), w: 200, h: 44)
        goBtn.position = CGPoint(x: 0, y: -(panelH/2 - 38))
        goBtn.zPosition = 42
        goBtn.name = "btn_go"
        tagNames(goBtn, name: "btn_go")
        panel.addChild(goBtn)

        // Close X
        let closeBtn = SKLabelNode(text: "✕")
        closeBtn.fontName = "PingFangSC-Semibold"
        closeBtn.fontSize = 16
        closeBtn.fontColor = UIColor(hex: "#707090")
        closeBtn.position = CGPoint(x: panelW/2 - 20, y: panelH/2 - 28)
        closeBtn.zPosition = 42
        closeBtn.name = "btn_close_pack"
        panel.addChild(closeBtn)

        packPanel = overlay
        addChild(overlay)

        // Animate in
        panel.setScale(0.8)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))
    }

    private func buildPackedSlots(in panel: SKShapeNode, panelH: CGFloat) {
        let slotY = panelH/2 - 90
        for i in 0..<gm.state.packed.maxSlots {
            let slot = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 6)
            let isFilled = i < gm.state.packed.items.count
            slot.fillColor = isFilled ? UIColor(hex: "#2A2A50") : UIColor(hex: "#16162E")
            slot.strokeColor = UIColor(hex: "#4A4A80")
            slot.lineWidth = 1.5
            let xOff = CGFloat(i - 1) * 68
            slot.position = CGPoint(x: xOff, y: slotY)
            slot.zPosition = 42
            panel.addChild(slot)

            if isFilled {
                let itemId = gm.state.packed.items[i]
                if let def = ALL_ITEMS.first(where: { $0.id == itemId }) {
                    let icon = SKSpriteNode(texture: nearestTex(def.iconName),
                                           size: CGSize(width: 40, height: 40))
                    icon.position = CGPoint(x: xOff, y: slotY)
                    icon.zPosition = 43
                    icon.name = "unpack_\(itemId)"
                    panel.addChild(icon)
                }
            } else {
                let placeholder = SKLabelNode(text: "+")
                placeholder.fontName = "PingFangSC-Regular"
                placeholder.fontSize = 20
                placeholder.fontColor = UIColor(hex: "#3A3A60")
                placeholder.verticalAlignmentMode = .center
                placeholder.position = CGPoint(x: xOff, y: slotY)
                placeholder.zPosition = 42
                panel.addChild(placeholder)
            }
        }
    }

    private func buildItemGrid(in panel: SKShapeNode, panelH: CGFloat) {
        let startY = panelH/2 - 165
        let cols = 4
        let allItems = ALL_ITEMS.filter { gm.state.inventory[$0.id] > 0 }

        for (idx, def) in allItems.enumerated() {
            let col = idx % cols
            let row = idx / cols
            let xOff = CGFloat(col - cols/2) * 64 + 32
            let yOff = startY - CGFloat(row) * 64

            let cell = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 6)
            let isPacked = gm.state.packed.contains(def.id)
            cell.fillColor = isPacked ? UIColor(hex: "#1A3A2A") : UIColor(hex: "#202040")
            cell.strokeColor = isPacked ? UIColor(hex: "#40A860") : UIColor(hex: "#404068")
            cell.lineWidth = 1.5
            cell.position = CGPoint(x: xOff, y: yOff)
            cell.zPosition = 42
            cell.name = "pack_\(def.id)"
            panel.addChild(cell)

            let icon = SKSpriteNode(texture: nearestTex(def.iconName),
                                    size: CGSize(width: 34, height: 34))
            icon.position = CGPoint(x: xOff, y: yOff + 6)
            icon.zPosition = 43
            icon.name = "pack_\(def.id)"
            panel.addChild(icon)

            let qty = SKLabelNode(text: "×\(gm.state.inventory[def.id])")
            qty.fontName = "PingFangSC-Regular"
            qty.fontSize = 8
            qty.fontColor = UIColor(hex: "#A0A0C0")
            qty.position = CGPoint(x: xOff, y: yOff - 20)
            qty.zPosition = 43
            qty.name = "pack_\(def.id)"
            panel.addChild(qty)
        }

        if allItems.isEmpty {
            let empty = SKLabelNode(text: "背包是空的...")
            empty.fontName = "PingFangSC-Regular"
            empty.fontSize = 11
            empty.fontColor = UIColor(hex: "#606080")
            empty.position = CGPoint(x: 0, y: startY - 20)
            empty.zPosition = 42
            panel.addChild(empty)
        }
    }

    // MARK: - Location Panel

    private func showLocationPanel() {
        locationPanel?.removeFromParent()

        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.55)
        overlay.strokeColor = .clear
        overlay.zPosition = 40
        overlay.name = "overlay_location"

        let panelW = size.width - 24
        let panelH = min(CGFloat(ALL_LOCATIONS.count) * 80 + 90, size.height - 200)
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 12)
        panel.fillColor = UIColor(hex: "#1C1C3A")
        panel.strokeColor = UIColor(hex: "#4A4A80")
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width/2, y: tabBarH + 88 + panelH/2)
        panel.zPosition = 41
        overlay.addChild(panel)

        let title = SKLabelNode(text: "✈️  选择目的地")
        title.fontName = "PingFangSC-Semibold"
        title.fontSize = 14
        title.fontColor = UIColor(hex: "#F8D030")
        title.position = CGPoint(x: 0, y: panelH/2 - 30)
        title.zPosition = 42
        panel.addChild(title)

        let closeBtn = SKLabelNode(text: "✕")
        closeBtn.fontName = "PingFangSC-Semibold"
        closeBtn.fontSize = 16
        closeBtn.fontColor = UIColor(hex: "#707090")
        closeBtn.position = CGPoint(x: panelW/2 - 20, y: panelH/2 - 28)
        closeBtn.zPosition = 42
        closeBtn.name = "btn_close_location"
        panel.addChild(closeBtn)

        for (i, loc) in ALL_LOCATIONS.enumerated() {
            let rowY = panelH/2 - 72 - CGFloat(i) * 80
            buildLocationRow(loc, in: panel, y: rowY, width: panelW)
        }

        locationPanel = overlay
        addChild(overlay)

        panel.setScale(0.85)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))
    }

    private func buildLocationRow(_ loc: Location, in panel: SKShapeNode, y: CGFloat, width: CGFloat) {
        let rowW = width - 32
        let row = SKShapeNode(rectOf: CGSize(width: rowW, height: 70), cornerRadius: 8)
        row.fillColor = UIColor(hex: "#222244")
        row.strokeColor = UIColor(hex: "#383870")
        row.lineWidth = 1
        row.position = CGPoint(x: 0, y: y)
        row.zPosition = 42
        row.name = "loc_\(loc.id)"
        panel.addChild(row)

        let emj = SKLabelNode(text: loc.emoji)
        emj.fontSize = 28
        emj.position = CGPoint(x: -(rowW/2 - 30), y: y - 6)
        emj.zPosition = 43
        emj.name = "loc_\(loc.id)"
        panel.addChild(emj)

        let nameL = SKLabelNode(text: loc.nameZH)
        nameL.fontName = "PingFangSC-Semibold"
        nameL.fontSize = 13
        nameL.fontColor = .white
        nameL.horizontalAlignmentMode = .left
        nameL.position = CGPoint(x: -(rowW/2 - 64), y: y + 12)
        nameL.zPosition = 43
        nameL.name = "loc_\(loc.id)"
        panel.addChild(nameL)

        let desc = SKLabelNode(text: loc.description)
        desc.fontName = "PingFangSC-Regular"
        desc.fontSize = 9
        desc.fontColor = UIColor(hex: "#9090B8")
        desc.horizontalAlignmentMode = .left
        desc.position = CGPoint(x: -(rowW/2 - 64), y: y - 6)
        desc.zPosition = 43
        desc.name = "loc_\(loc.id)"
        panel.addChild(desc)

        let mins = loc.durationMinutes < 60 ?
            "\(Int(loc.durationMinutes))分钟" : "\(Int(loc.durationMinutes/60))小时"
        let timeL = SKLabelNode(text: "⏱ \(mins)  💰\(loc.rewardCoins)")
        timeL.fontName = "PingFangSC-Regular"
        timeL.fontSize = 9
        timeL.fontColor = UIColor(hex: "#F8D030")
        timeL.horizontalAlignmentMode = .right
        timeL.position = CGPoint(x: rowW/2 - 8, y: y - 20)
        timeL.zPosition = 43
        timeL.name = "loc_\(loc.id)"
        panel.addChild(timeL)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let nodeName = atPoint(loc).name ?? ""

        // Overlay dismissal
        if nodeName == "overlay_pack" || nodeName == "btn_close_pack" {
            packPanel?.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent(),
            ]))
            packPanel = nil
            return
        }
        if nodeName == "overlay_location" || nodeName == "btn_close_location" {
            locationPanel?.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent(),
            ]))
            locationPanel = nil
            return
        }

        // Pack panel actions
        if nodeName.hasPrefix("pack_") {
            let itemId = String(nodeName.dropFirst(5))
            if gm.state.packed.isFull { haptic(.light); return }
            haptic(.light)
            gm.packItem(itemId)
            refreshPackPanel()
            return
        }
        if nodeName.hasPrefix("unpack_") {
            let itemId = String(nodeName.dropFirst(7))
            haptic(.light)
            gm.unpackItem(itemId)
            refreshPackPanel()
            return
        }
        if nodeName == "btn_go" {
            packPanel?.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.1),
                SKAction.removeFromParent(),
            ]))
            packPanel = nil
            showLocationPanel()
            return
        }

        // Location selection
        if nodeName.hasPrefix("loc_") {
            let locId = String(nodeName.dropFirst(4))
            hapticNotify(.success)
            confirmJourney(locationId: locId)
            return
        }

        // Main buttons
        switch nodeName {
        case "btn_pack":
            haptic(.medium)
            showPackPanel()
        case "btn_journey":
            goToJourney()
        case "btn_album":
            goToAlbum()
        default:
            break
        }
    }

    private func confirmJourney(locationId: String) {
        locationPanel?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent(),
        ]))
        locationPanel = nil
        gm.startJourney(locationId: locationId)
        goToJourney()
    }

    // MARK: - Navigation

    private func goToJourney() {
        let scene = JourneyScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func goToAlbum() {
        let scene = AlbumScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - Refresh

    private func refreshStatus() {
        moodLabel?.text = gm.state.sparky.mood.text
        coinsLabel?.text = "\(gm.state.coins)"
        startIdleAnimation()
    }

    private func refreshPackPanel() {
        guard let panel = packPanel else { return }
        panel.removeFromParent()
        packPanel = nil
        showPackPanel()
    }

    // MARK: - Helpers

    private func nearestTex(_ name: String) -> SKTexture {
        let t = SKTexture(imageNamed: name)
        t.filteringMode = .nearest
        return t
    }

    private func makeButton(text: String, color: UIColor, w: CGFloat, h: CGFloat) -> SKNode {
        let node = SKNode()
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 6)
        bg.fillColor = color
        bg.strokeColor = color.withAlphaComponent(0.5)
        bg.lineWidth = 2
        node.addChild(bg)
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "PingFangSC-Semibold"
        lbl.fontSize = 13
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)
        return node
    }

    private func tagNames(_ node: SKNode, name: String) {
        for child in node.children {
            child.name = name
            tagNames(child, name: name)
        }
    }
}

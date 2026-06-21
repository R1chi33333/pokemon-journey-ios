import SpriteKit
import UIKit

class JourneyScene: SKScene {

    private let gm = GameManager.shared
    private var sparkyWalker: SKSpriteNode!
    private var walkFrames: [SKTexture] = []
    private var walkTime: TimeInterval = 0
    private var walkFrame = 0

    private var bgLayers: [SKNode] = []    // parallax layers (far→near)
    private var bgSpeeds: [CGFloat] = []

    private var timerLabel: SKLabelNode!
    private var progressFill: SKSpriteNode!
    private var progressW: CGFloat = 0
    private var returnPanel: SKNode?
    private var didReturn = false

    private var tabBarH: CGFloat { 72 }
    private var skyH: CGFloat { size.height * 0.42 }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = UIColor(hex: "#1A1A2E")

        let location = ALL_LOCATIONS.first { $0.id == (gm.state.journey?.locationId ?? "") }
        buildBackground(for: location)
        buildSparkyWalker()
        buildUI(location: location)

        if gm.state.journey == nil {
            buildNoJourneyState()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let journey = gm.state.journey else { return }

        // Walk animation
        walkTime += 1.0/60.0
        if walkTime > 0.14 {
            walkTime = 0
            walkFrame = (walkFrame + 1) % walkFrames.count
            sparkyWalker?.texture = walkFrames[walkFrame]
        }

        // Parallax scroll
        for (i, layer) in bgLayers.enumerated() {
            for child in layer.children {
                child.position.x -= bgSpeeds[i]
                // Wrap around when off-screen left
                if child.position.x < -child.frame.width {
                    child.position.x += CGFloat(layer.children.count) * child.frame.width
                }
            }
        }

        // Update timer
        timerLabel?.text = journey.isComplete ? "✅ 旅行完成！" : journey.formattedTimeRemaining
        progressFill?.xScale = max(0.001, CGFloat(journey.progress))

        // Auto-trigger return
        if journey.isComplete && !didReturn {
            didReturn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handleReturn()
            }
        }
    }

    // MARK: - Background

    private func buildBackground(for location: Location?) {
        let theme = location?.tileTheme ?? "forest"
        let skyColorHex = location?.skyColor ?? "#78C8F8"

        switch theme {
        case "forest": buildForestBG(skyColor: skyColorHex)
        case "beach":  buildBeachBG(skyColor: skyColorHex)
        case "cave":   buildCaveBG()
        case "snow":   buildSnowBG(skyColor: skyColorHex)
        default:       buildForestBG(skyColor: skyColorHex)
        }
    }

    private func buildForestBG(skyColor: String) {
        // Layer 0: Sky (static)
        let skyNode = SKShapeNode(rectOf: CGSize(width: size.width, height: skyH))
        skyNode.fillColor = UIColor(hex: skyColor)
        skyNode.strokeColor = .clear
        skyNode.position = CGPoint(x: size.width/2, y: size.height - skyH/2)
        skyNode.zPosition = 0
        addChild(skyNode)

        // Sun
        let sun = SKShapeNode(circleOfRadius: 20)
        sun.fillColor = UIColor(hex: "#F8E040")
        sun.strokeColor = UIColor(hex: "#F8C000")
        sun.lineWidth = 3
        sun.position = CGPoint(x: size.width * 0.78, y: size.height - 48)
        sun.zPosition = 1
        addChild(sun)

        // Layer 1: Far trees (slow parallax)
        let farLayer = buildTileLayer(
            texName: "tree_top", tileW: 48, tileH: 48,
            y: size.height - skyH + 12, zPos: 2, speed: 0.4
        )
        bgLayers.append(farLayer)
        bgSpeeds.append(0.4)

        // Layer 2: Mid ground (grass tiles)
        let groundH = size.height - skyH - tabBarH
        let groundLayer = buildScrollingGround(
            tileNames: ["grass", "grass_light", "grass"],
            y: tabBarH, height: groundH
        )
        bgLayers.append(groundLayer)
        bgSpeeds.append(0)   // ground doesn't scroll

        // Layer 3: Near trees (fast parallax)
        let nearLayer = buildTileLayer(
            texName: "tree_base", tileW: 64, tileH: 64,
            y: size.height - skyH - 12, zPos: 4, speed: 1.2
        )
        bgLayers.append(nearLayer)
        bgSpeeds.append(1.2)

        // Path (static center path)
        buildPath()
    }

    private func buildBeachBG(skyColor: String) {
        // Sky
        let skyNode = SKShapeNode(rectOf: CGSize(width: size.width, height: skyH))
        skyNode.fillColor = UIColor(hex: skyColor)
        skyNode.strokeColor = .clear
        skyNode.position = CGPoint(x: size.width/2, y: size.height - skyH/2)
        skyNode.zPosition = 0
        addChild(skyNode)

        // Sun
        let sun = SKShapeNode(circleOfRadius: 22)
        sun.fillColor = UIColor(hex: "#FFF060")
        sun.strokeColor = UIColor(hex: "#F8D020")
        sun.lineWidth = 3
        sun.position = CGPoint(x: size.width*0.75, y: size.height - 50)
        sun.zPosition = 1
        addChild(sun)

        // Water (animated)
        let waterLayer = buildTileLayer(
            texName: "water_0", tileW: 48, tileH: 48,
            y: size.height - skyH, zPos: 2, speed: 0.8
        )
        bgLayers.append(waterLayer)
        bgSpeeds.append(0.8)

        // Sand
        let sandH = size.height - skyH - tabBarH - 48
        let sandLayer = buildScrollingGround(
            tileNames: ["sand"],
            y: tabBarH, height: sandH + 48
        )
        bgLayers.append(sandLayer)
        bgSpeeds.append(0)

        buildPath()
    }

    private func buildCaveBG() {
        // Dark cave
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        bg.fillColor = UIColor(hex: "#1A1620")
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.zPosition = 0
        addChild(bg)

        // Wall tiles on top
        let wallLayer = buildTileLayer(
            texName: "cave_wall", tileW: 48, tileH: 48,
            y: size.height - 96, zPos: 2, speed: 0.3
        )
        bgLayers.append(wallLayer)
        bgSpeeds.append(0.3)

        // Crystal layer
        let crystalLayer = buildTileLayer(
            texName: "crystal", tileW: 48, tileH: 48,
            y: size.height - skyH + 24, zPos: 3, speed: 0.6
        )
        bgLayers.append(crystalLayer)
        bgSpeeds.append(0.6)

        // Floor
        let floorH = size.height - skyH - tabBarH
        let floorLayer = buildScrollingGround(
            tileNames: ["cave_floor"],
            y: tabBarH, height: floorH
        )
        bgLayers.append(floorLayer)
        bgSpeeds.append(0)

        buildPath()
    }

    private func buildSnowBG(skyColor: String) {
        let skyNode = SKShapeNode(rectOf: CGSize(width: size.width, height: skyH))
        skyNode.fillColor = UIColor(hex: skyColor)
        skyNode.strokeColor = .clear
        skyNode.position = CGPoint(x: size.width/2, y: size.height - skyH/2)
        skyNode.zPosition = 0
        addChild(skyNode)

        // Mountain silhouettes
        let mtLayer = buildTileLayer(
            texName: "mountain_bg", tileW: 48, tileH: 48,
            y: size.height - skyH, zPos: 2, speed: 0.2
        )
        bgLayers.append(mtLayer)
        bgSpeeds.append(0.2)

        let snowLayer = buildScrollingGround(
            tileNames: ["snow"],
            y: tabBarH, height: size.height - skyH - tabBarH
        )
        bgLayers.append(snowLayer)
        bgSpeeds.append(0)

        buildPath()
    }

    private func buildTileLayer(texName: String, tileW: CGFloat, tileH: CGFloat,
                                 y: CGFloat, zPos: CGFloat, speed: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.zPosition = zPos
        addChild(layer)

        let count = Int(ceil(size.width / tileW)) + 3
        let tex = nearestTex(texName)
        for i in 0..<count {
            let tile = SKSpriteNode(texture: tex, size: CGSize(width: tileW, height: tileH))
            tile.anchorPoint = CGPoint(x: 0, y: 0)
            tile.position = CGPoint(x: CGFloat(i) * tileW, y: y)
            layer.addChild(tile)
        }
        return layer
    }

    private func buildScrollingGround(tileNames: [String], y: CGFloat, height: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.zPosition = 3
        addChild(layer)

        let tileW: CGFloat = 48
        let tileH: CGFloat = 48
        let cols = Int(ceil(size.width / tileW)) + 1
        let rows = Int(ceil(height / tileH)) + 1

        for row in 0..<rows {
            for col in 0..<cols {
                let texName = tileNames[(row + col) % tileNames.count]
                let tile = SKSpriteNode(texture: nearestTex(texName),
                                        size: CGSize(width: tileW, height: tileH))
                tile.anchorPoint = CGPoint(x: 0, y: 0)
                tile.position = CGPoint(x: CGFloat(col)*tileW, y: y + CGFloat(row)*tileH)
                layer.addChild(tile)
            }
        }
        return layer
    }

    private func buildPath() {
        // Dirt path running through center bottom
        let pathW: CGFloat = 80
        let pathY = tabBarH
        let pathH = size.height - skyH - tabBarH + 40

        let pathBg = SKShapeNode(rectOf: CGSize(width: pathW, height: pathH))
        pathBg.fillColor = UIColor(hex: "#C8A860")
        pathBg.strokeColor = .clear
        pathBg.position = CGPoint(x: size.width/2, y: pathY + pathH/2)
        pathBg.zPosition = 4.5
        addChild(pathBg)

        // Dashes
        var dashY = pathY + 16
        while dashY < pathY + pathH - 16 {
            let dash = SKShapeNode(rectOf: CGSize(width: 6, height: 14))
            dash.fillColor = UIColor(hex: "#F0D090")
            dash.strokeColor = .clear
            dash.position = CGPoint(x: size.width/2, y: dashY)
            dash.zPosition = 4.6
            addChild(dash)
            dashY += 28
        }
    }

    // MARK: - Sparky Walker

    private func buildSparkyWalker() {
        walkFrames = (0..<6).map { nearestTex("sparky_walk_\($0)") }

        sparkyWalker = SKSpriteNode(texture: walkFrames[0],
                                    size: CGSize(width: 72, height: 84))
        let groundY = size.height - skyH
        sparkyWalker.position = CGPoint(x: size.width * 0.35, y: groundY + 42)
        sparkyWalker.zPosition = 10

        addChild(sparkyWalker)

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 44, height: 8))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: sparkyWalker.position.x, y: groundY + 4)
        shadow.zPosition = 9
        addChild(shadow)
    }

    // MARK: - UI

    private func buildUI(location: Location?) {
        guard let _ = gm.state.journey else { return }

        let infoPanelH: CGFloat = 210
        let infoPanelY = tabBarH + 4

        let panel = SKShapeNode(rectOf: CGSize(width: size.width - 24, height: infoPanelH),
                                cornerRadius: 10)
        panel.fillColor = UIColor(hex: "#E8F4FF").withAlphaComponent(0.95)
        panel.strokeColor = UIColor(hex: "#003878")
        panel.lineWidth = 3
        panel.position = CGPoint(x: size.width/2, y: infoPanelY + infoPanelH/2)
        panel.zPosition = 20
        addChild(panel)

        // Location name
        let nameLbl = SKLabelNode(text: "\(location?.emoji ?? "🌟")  \(location?.nameZH ?? "旅行中")")
        nameLbl.fontName = "PingFangSC-Semibold"
        nameLbl.fontSize = 16
        nameLbl.fontColor = UIColor(hex: "#003878")
        nameLbl.position = CGPoint(x: size.width/2, y: infoPanelY + infoPanelH - 36)
        nameLbl.zPosition = 21
        addChild(nameLbl)

        // Timer
        timerLabel = SKLabelNode(text: gm.state.journey?.formattedTimeRemaining ?? "--")
        timerLabel.fontName = "PingFangSC-Semibold"
        timerLabel.fontSize = 22
        timerLabel.fontColor = UIColor(hex: "#003878")
        timerLabel.position = CGPoint(x: size.width/2, y: infoPanelY + infoPanelH - 80)
        timerLabel.zPosition = 21
        addChild(timerLabel)

        // Progress bar
        let barW = size.width - 64
        let barH: CGFloat = 16
        let barY = infoPanelY + infoPanelH - 118

        let barBg = SKSpriteNode(texture: nearestTex("progress_bg"),
                                  size: CGSize(width: barW, height: barH))
        barBg.position = CGPoint(x: size.width/2, y: barY)
        barBg.zPosition = 21
        addChild(barBg)

        progressW = barW - 4
        let fill = SKSpriteNode(color: UIColor(hex: "#F8D030"),
                                size: CGSize(width: progressW, height: barH - 4))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: size.width/2 - progressW/2, y: barY)
        fill.xScale = CGFloat(gm.state.journey?.progress ?? 0)
        fill.zPosition = 22
        progressFill = fill
        addChild(fill)

        // Reward preview
        if let loc = location {
            let rewardLbl = SKLabelNode(text: "预计奖励: 💰~\(loc.rewardCoins)  🫐×2")
            rewardLbl.fontName = "PingFangSC-Regular"
            rewardLbl.fontSize = 10
            rewardLbl.fontColor = UIColor(hex: "#405070")
            rewardLbl.position = CGPoint(x: size.width/2, y: infoPanelY + infoPanelH - 152)
            rewardLbl.zPosition = 21
            addChild(rewardLbl)
        }

        // Home button
        let homeBtn = makeButton(text: "🏠 回家等待", color: UIColor(hex: "#205090"), w: 180, h: 40)
        homeBtn.position = CGPoint(x: size.width/2, y: infoPanelY + 28)
        homeBtn.zPosition = 21
        homeBtn.name = "btn_home"
        tagNames(homeBtn, name: "btn_home")
        addChild(homeBtn)

        // Tab bar
        buildTabBar()
    }

    private func buildNoJourneyState() {
        let box = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 140), cornerRadius: 10)
        box.fillColor = UIColor(hex: "#E8F4FF").withAlphaComponent(0.92)
        box.strokeColor = UIColor(hex: "#003878")
        box.lineWidth = 3
        box.position = CGPoint(x: size.width/2, y: size.height/2)
        box.zPosition = 20
        addChild(box)

        let txt = SKLabelNode(text: "⚡ Sparky 还在家里哦")
        txt.fontName = "PingFangSC-Semibold"
        txt.fontSize = 13
        txt.fontColor = UIColor(hex: "#003878")
        txt.position = CGPoint(x: size.width/2, y: size.height/2 + 28)
        txt.zPosition = 21
        addChild(txt)

        let sub = SKLabelNode(text: "回主页整理行囊再出发！")
        sub.fontName = "PingFangSC-Regular"
        sub.fontSize = 11
        sub.fontColor = UIColor(hex: "#507090")
        sub.position = CGPoint(x: size.width/2, y: size.height/2)
        sub.zPosition = 21
        addChild(sub)

        let homeBtn = makeButton(text: "🏠 回主页", color: UIColor(hex: "#205090"), w: 180, h: 44)
        homeBtn.position = CGPoint(x: size.width/2, y: size.height/2 - 40)
        homeBtn.zPosition = 21
        homeBtn.name = "btn_home"
        tagNames(homeBtn, name: "btn_home")
        addChild(homeBtn)

        buildTabBar()
    }

    private func buildTabBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: tabBarH))
        bar.fillColor = UIColor(hex: "#0E0E20")
        bar.strokeColor = UIColor(hex: "#2A2A48")
        bar.lineWidth = 1
        bar.position = CGPoint(x: size.width/2, y: tabBarH/2)
        bar.zPosition = 30
        addChild(bar)

        addTab(emoji: "🏠", label: "主页", x: size.width*0.2, active: false, name: "btn_home")
        addTab(emoji: "🌟", label: "旅行", x: size.width*0.5, active: true,  name: nil)
        addTab(emoji: "📮", label: "相册", x: size.width*0.8, active: false, name: "btn_album")
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

    // MARK: - Return Panel

    private func handleReturn() {
        guard returnPanel == nil else { return }

        let loc = ALL_LOCATIONS.first { $0.id == (gm.state.journey?.locationId ?? "") }
        gm.completeJourney(location: loc)

        let panelW = size.width - 24
        let panelH: CGFloat = 300
        let panelY = tabBarH + 60

        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.6)
        overlay.strokeColor = .clear
        overlay.zPosition = 50

        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 14)
        panel.fillColor = UIColor(hex: "#F5ECD8")
        panel.strokeColor = UIColor(hex: "#D4B070")
        panel.lineWidth = 3
        panel.position = CGPoint(x: size.width/2, y: panelY + panelH/2)
        panel.zPosition = 51
        overlay.addChild(panel)

        // Title
        let title = SKLabelNode(text: "⚡ Sparky 回来了！")
        title.fontName = "PingFangSC-Semibold"
        title.fontSize = 16
        title.fontColor = UIColor(hex: "#403820")
        title.position = CGPoint(x: 0, y: panelH/2 - 36)
        title.zPosition = 52
        panel.addChild(title)

        // Happy Sparky
        let sparkyImg = SKSpriteNode(texture: nearestTex("sparky_happy"),
                                     size: CGSize(width: 72, height: 90))
        sparkyImg.position = CGPoint(x: 0, y: panelH/2 - 110)
        sparkyImg.zPosition = 52
        panel.addChild(sparkyImg)
        sparkyImg.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.3),
            SKAction.moveBy(x: 0, y: -6, duration: 0.3),
        ])))

        // Location
        let locEmoji = loc?.emoji ?? "🌟"
        let locName  = loc?.nameZH ?? "远方"
        let locLbl = SKLabelNode(text: "\(locEmoji) 来自 \(locName)")
        locLbl.fontName = "PingFangSC-Regular"
        locLbl.fontSize = 11
        locLbl.fontColor = UIColor(hex: "#706050")
        locLbl.position = CGPoint(x: 0, y: panelH/2 - 172)
        locLbl.zPosition = 52
        panel.addChild(locLbl)

        // Rewards
        let lastCard = gm.state.postcards.first
        if let card = lastCard {
            let rw = card.rewards
            var parts: [String] = []
            if rw.coins > 0  { parts.append("💰\(rw.coins)") }
            if rw.oran > 0   { parts.append("🫐×\(rw.oran)") }
            if rw.pecha > 0  { parts.append("🍑×\(rw.pecha)") }
            if rw.sitrus > 0 { parts.append("🍊×\(rw.sitrus)") }
            let rewardStr = parts.isEmpty ? "平安归来！" : parts.joined(separator: "  ")
            let rewLbl = SKLabelNode(text: rewardStr)
            rewLbl.fontName = "PingFangSC-Semibold"
            rewLbl.fontSize = 12
            rewLbl.fontColor = UIColor(hex: "#805030")
            rewLbl.position = CGPoint(x: 0, y: panelH/2 - 200)
            rewLbl.zPosition = 52
            panel.addChild(rewLbl)

            if !card.message.isEmpty {
                let msg = String(card.message.prefix(28))
                let msgLbl = SKLabelNode(text: "\u{201C}\(msg)\u{201D}")
                msgLbl.fontName = "PingFangSC-Regular"
                msgLbl.fontSize = 9
                msgLbl.fontColor = UIColor(hex: "#706050")
                msgLbl.position = CGPoint(x: 0, y: panelH/2 - 222)
                msgLbl.zPosition = 52
                panel.addChild(msgLbl)
            }
        }

        // Buttons
        let homeBtn = makeButton(text: "🏠 回家", color: UIColor(hex: "#205090"), w: 140, h: 44)
        homeBtn.position = CGPoint(x: -78, y: -(panelH/2 - 36))
        homeBtn.zPosition = 52
        homeBtn.name = "btn_home_return"
        tagNames(homeBtn, name: "btn_home_return")
        panel.addChild(homeBtn)

        let albumBtn = makeButton(text: "📮 看明信片", color: UIColor(hex: "#406820"), w: 150, h: 44)
        albumBtn.position = CGPoint(x: 80, y: -(panelH/2 - 36))
        albumBtn.zPosition = 52
        albumBtn.name = "btn_album_return"
        tagNames(albumBtn, name: "btn_album_return")
        panel.addChild(albumBtn)

        returnPanel = overlay
        addChild(overlay)
        panel.setScale(0.7)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.sequence([
                SKAction.scale(to: 1.08, duration: 0.25),
                SKAction.scale(to: 0.96, duration: 0.1),
                SKAction.scale(to: 1.0,  duration: 0.1),
            ]),
        ]))
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        switch atPoint(loc).name ?? "" {
        case "btn_home", "btn_home_return":
            goHome()
        case "btn_album", "btn_album_return":
            goAlbum()
        default:
            break
        }
    }

    // MARK: - Navigation

    private func goHome() {
        let scene = HomeScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    private func goAlbum() {
        let scene = AlbumScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
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
        lbl.fontSize = 12
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

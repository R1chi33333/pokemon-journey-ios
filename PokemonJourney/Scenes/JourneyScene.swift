import SpriteKit
import UIKit

class JourneyScene: SKScene {

    private let gm = GameManager.shared
    private var walkFrame = 0
    private var walkTime: TimeInterval = 0
    private var pikachuWalker: SKSpriteNode!
    private var timerLabel: SKLabelNode!
    private var progressFill: SKSpriteNode!
    private var progressW: CGFloat = 0
    private var didReturn = false

    private var tabBarH: CGFloat { 72 }
    private var skyH: CGFloat { size.height * 0.38 }
    private var groundY: CGFloat { size.height - skyH }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: "#1A1A2E")
        anchorPoint = .zero

        guard let journey = gm.state.journey else {
            buildNoJourneyUI()
            return
        }

        let location = ALL_LOCATIONS.first { $0.id == journey.locationId }
        buildBackground(location: location)
        buildWalker()
        buildUI(location: location)
        buildTabBar()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let journey = gm.state.journey else { return }

        // Walk animation frames
        walkTime += 1.0 / 60.0
        if walkTime >= 0.18 {
            walkTime = 0
            walkFrame = (walkFrame + 1) % 2
            let art = walkFrame == 0 ? PikachuSprites.walkA : PikachuSprites.walkB
            let tex = PixelArtRenderer.makeTexture(art: art, palette: Palettes.pikachu, pixelSize: 5)
            tex.filteringMode = .nearest
            pikachuWalker?.texture = tex
        }

        // Timer update
        if journey.isComplete && !didReturn {
            didReturn = true
            handleReturn()
            return
        }

        let remaining = journey.timeRemaining
        let mins = Int(remaining / 60)
        let secs = Int(remaining.truncatingRemainder(dividingBy: 60))
        timerLabel?.text = String(format: "%d:%02d", mins, secs)

        // Progress bar
        let prog = CGFloat(journey.progress)
        progressFill?.xScale = max(0.001, prog)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        switch atPoint(loc).name {
        case "btn_home":  goHome()
        case "btn_album": goAlbum()
        case "btn_home2": goHome()
        default: break
        }
    }

    // MARK: - Build

    private func buildBackground(location: Location?) {
        let skyColor = UIColor(hex: location?.skyColor ?? "#78C8F8")
        let groundColor = UIColor(hex: location?.groundColor ?? "#58C838")
        let locId = location?.id ?? "viridian_forest"

        // Sky
        let sky = SKShapeNode(rectOf: CGSize(width: size.width, height: skyH))
        sky.fillColor = skyColor
        sky.strokeColor = .clear
        sky.position = CGPoint(x: size.width / 2, y: size.height - skyH / 2)
        sky.zPosition = 0
        addChild(sky)

        // Ground
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height - skyH))
        ground.fillColor = groundColor
        ground.strokeColor = .clear
        ground.position = CGPoint(x: size.width / 2, y: (size.height - skyH) / 2)
        ground.zPosition = 0
        addChild(ground)

        // Path/road
        let path = SKShapeNode(rectOf: CGSize(width: size.width, height: 36))
        path.fillColor = UIColor(hex: "#D4B070")
        path.strokeColor = .clear
        path.position = CGPoint(x: size.width / 2, y: groundY + 18)
        path.zPosition = 1
        addChild(path)

        // Dashed path marks
        let dashColor = UIColor(hex: "#C0A050")
        for i in 0..<8 {
            let dash = SKShapeNode(rectOf: CGSize(width: 28, height: 4))
            dash.fillColor = dashColor
            dash.strokeColor = .clear
            dash.position = CGPoint(x: CGFloat(i) * 52 + 26, y: groundY + 18)
            dash.zPosition = 2
            addChild(dash)
        }

        // Location-specific scenery
        addScenery(locId: locId, skyColor: skyColor)
    }

    private func addScenery(locId: String, skyColor: UIColor) {
        switch locId {
        case "viridian_forest":
            addForestScenery()
        case "cerulean_cape":
            addOceanScenery()
        case "mt_moon":
            addCaveScenery()
        default:
            addForestScenery()
        }
    }

    private func addForestScenery() {
        // Clouds
        for (cx, cy) in [(80.0, 0.88), (220.0, 0.92), (310.0, 0.85)] {
            addCloud(x: cx, yFrac: cy)
        }
        // Trees
        for (tx, scale) in [(30.0, 1.0), (95.0, 1.2), (170.0, 0.9), (250.0, 1.1),
                             (310.0, 1.0), (360.0, 0.85)] {
            addTree(x: CGFloat(tx), baseY: groundY + 36, scale: CGFloat(scale))
        }
    }

    private func addOceanScenery() {
        // Sun
        let sun = SKShapeNode(circleOfRadius: 28)
        sun.fillColor = UIColor(hex: "#F8D800")
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 60, y: size.height - 56)
        sun.zPosition = 1
        addChild(sun)
        // Waves
        for i in 0..<10 {
            let wave = SKShapeNode(rectOf: CGSize(width: 34, height: 8), cornerRadius: 4)
            wave.fillColor = UIColor(hex: "#5898F8")
            wave.strokeColor = .clear
            wave.position = CGPoint(x: CGFloat(i) * 40 + 20, y: groundY + CGFloat(i % 2) * 6 + 24)
            wave.zPosition = 3
            addChild(wave)
        }
        // Lighthouse
        let tower = SKShapeNode(rectOf: CGSize(width: 18, height: 60))
        tower.fillColor = .white
        tower.strokeColor = UIColor(hex: "#C0C0C0")
        tower.lineWidth = 1
        tower.position = CGPoint(x: 44, y: size.height - skyH * 0.45)
        tower.zPosition = 2
        addChild(tower)
        let cap = SKShapeNode(rectOf: CGSize(width: 22, height: 14))
        cap.fillColor = UIColor(hex: "#E83028")
        cap.strokeColor = .clear
        cap.position = CGPoint(x: 44, y: size.height - skyH * 0.45 + 37)
        cap.zPosition = 2
        addChild(cap)
    }

    private func addCaveScenery() {
        // Stars
        for (sx, sy) in [(40.0, 0.95), (110.0, 0.9), (200.0, 0.93), (280.0, 0.88), (340.0, 0.91)] {
            let star = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat(sx), y: size.height * CGFloat(sy))
            star.zPosition = 1
            addChild(star)
        }
        // Moon
        let moon = SKShapeNode(circleOfRadius: 22)
        moon.fillColor = UIColor(hex: "#F8F8D0")
        moon.strokeColor = .clear
        moon.position = CGPoint(x: size.width - 52, y: size.height - 44)
        moon.zPosition = 1
        addChild(moon)
        let moonShadow = SKShapeNode(circleOfRadius: 18)
        moonShadow.fillColor = UIColor(hex: "#181828")
        moonShadow.strokeColor = .clear
        moonShadow.position = CGPoint(x: size.width - 44, y: size.height - 40)
        moonShadow.zPosition = 2
        addChild(moonShadow)
        // Stalactites
        for (sx, sh) in [(50.0, 40.0), (130.0, 56.0), (200.0, 34.0), (280.0, 48.0), (340.0, 38.0)] {
            let stala = SKShapeNode(rectOf: CGSize(width: 14, height: CGFloat(sh)))
            stala.fillColor = UIColor(hex: "#404060")
            stala.strokeColor = .clear
            stala.position = CGPoint(x: CGFloat(sx), y: size.height - CGFloat(sh) / 2)
            stala.zPosition = 2
            addChild(stala)
        }
        // Glowing crystals
        for (cx, cc) in [(60.0, "#80F8A0"), (180.0, "#A060F8"), (300.0, "#80F8A0")] {
            let crystal = SKShapeNode(circleOfRadius: 10)
            crystal.fillColor = UIColor(hex: cc).withAlphaComponent(0.7)
            crystal.glowWidth = 4
            crystal.strokeColor = UIColor(hex: cc)
            crystal.lineWidth = 1
            crystal.position = CGPoint(x: CGFloat(cx), y: groundY + 60)
            crystal.zPosition = 3
            addChild(crystal)
        }
    }

    private func addCloud(x: Double, yFrac: Double) {
        let cloud = SKNode()
        for (dx, dy, r) in [(-12.0, 0.0, 10.0), (0.0, 4.0, 14.0), (12.0, 0.0, 10.0)] {
            let c = SKShapeNode(circleOfRadius: CGFloat(r))
            c.fillColor = UIColor.white.withAlphaComponent(0.9)
            c.strokeColor = .clear
            c.position = CGPoint(x: CGFloat(dx), y: CGFloat(dy))
            cloud.addChild(c)
        }
        cloud.position = CGPoint(x: CGFloat(x), y: size.height * CGFloat(yFrac))
        cloud.zPosition = 1
        addChild(cloud)
    }

    private func addTree(x: CGFloat, baseY: CGFloat, scale: CGFloat) {
        let trunk = SKShapeNode(rectOf: CGSize(width: 10 * scale, height: 28 * scale))
        trunk.fillColor = UIColor(hex: "#604018")
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: x, y: baseY + 14 * scale)
        trunk.zPosition = 2
        addChild(trunk)

        let leaf = SKShapeNode(circleOfRadius: 18 * scale)
        leaf.fillColor = UIColor(hex: "#58C038")
        leaf.strokeColor = UIColor(hex: "#389820")
        leaf.lineWidth = 1
        leaf.position = CGPoint(x: x, y: baseY + 36 * scale + 18 * scale)
        leaf.zPosition = 2
        addChild(leaf)

        let leaf2 = SKShapeNode(circleOfRadius: 12 * scale)
        leaf2.fillColor = UIColor(hex: "#78D858")
        leaf2.strokeColor = .clear
        leaf2.position = CGPoint(x: x - 6 * scale, y: baseY + 48 * scale + 18 * scale)
        leaf2.zPosition = 3
        addChild(leaf2)
    }

    private func buildWalker() {
        let tex = PixelArtRenderer.makeTexture(
            art: PikachuSprites.walkA, palette: Palettes.pikachu, pixelSize: 5)
        tex.filteringMode = .nearest

        pikachuWalker = SKSpriteNode(texture: tex)
        pikachuWalker.position = CGPoint(x: -80, y: groundY + 50)
        pikachuWalker.zPosition = 10

        let walkAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveTo(x: size.width + 80, duration: 4.5),
                SKAction.moveTo(x: -80, duration: 0),
            ])
        )
        pikachuWalker.run(walkAction)
        addChild(pikachuWalker)
    }

    private func buildUI(location: Location?) {
        let panelY: CGFloat = tabBarH + 8
        let panelH: CGFloat = size.height - skyH - groundY + skyH - tabBarH - 16
        // Adjust: info panel in bottom portion
        let infoPanelH: CGFloat = min(260, size.height * 0.35)
        let infoPanelY: CGFloat = tabBarH + 8

        let panelBg = SKShapeNode(
            rectOf: CGSize(width: size.width - 24, height: infoPanelH), cornerRadius: 4)
        panelBg.fillColor = UIColor(hex: "#F0F8FF")
        panelBg.strokeColor = UIColor(hex: "#003878")
        panelBg.lineWidth = 3
        panelBg.position = CGPoint(x: size.width / 2, y: infoPanelY + infoPanelH / 2)
        panelBg.zPosition = 20
        addChild(panelBg)

        let titleLbl = SKLabelNode(text: "\(location?.emoji ?? "🌟") \(location?.nameZH ?? "旅行中")")
        titleLbl.fontName = "Courier-Bold"
        titleLbl.fontSize = 14
        titleLbl.fontColor = UIColor(hex: "#003878")
        titleLbl.position = CGPoint(x: size.width / 2, y: infoPanelY + infoPanelH - 28)
        titleLbl.zPosition = 21
        addChild(titleLbl)

        let descLbl = SKLabelNode(text: location?.description ?? "")
        descLbl.fontName = "Courier"
        descLbl.fontSize = 9
        descLbl.fontColor = UIColor(hex: "#505060")
        descLbl.numberOfLines = 2
        descLbl.preferredMaxLayoutWidth = size.width - 40
        descLbl.position = CGPoint(x: size.width / 2, y: infoPanelY + infoPanelH - 52)
        descLbl.zPosition = 21
        addChild(descLbl)

        // Timer
        let timerRowY = infoPanelY + infoPanelH * 0.55
        let timerPrompt = SKLabelNode(text: "剩余时间:")
        timerPrompt.fontName = "Courier-Bold"
        timerPrompt.fontSize = 10
        timerPrompt.fontColor = UIColor(hex: "#183888")
        timerPrompt.horizontalAlignmentMode = .right
        timerPrompt.position = CGPoint(x: size.width / 2 - 4, y: timerRowY)
        timerPrompt.zPosition = 21
        addChild(timerPrompt)

        timerLabel = SKLabelNode(text: "0:00")
        timerLabel.fontName = "Courier-Bold"
        timerLabel.fontSize = 22
        timerLabel.fontColor = UIColor(hex: "#E83030")
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: size.width / 2 + 6, y: timerRowY)
        timerLabel.zPosition = 21
        addChild(timerLabel)

        // Progress bar track
        let progressBgH: CGFloat = 12
        let progressBgW = size.width - 48
        let progressBg = SKShapeNode(
            rectOf: CGSize(width: progressBgW, height: progressBgH), cornerRadius: 4)
        progressBg.fillColor = UIColor(hex: "#C8D8E8")
        progressBg.strokeColor = UIColor(hex: "#A0B8C8")
        progressBg.lineWidth = 1
        let progressY = infoPanelY + infoPanelH * 0.32
        progressBg.position = CGPoint(x: size.width / 2, y: progressY)
        progressBg.zPosition = 21
        addChild(progressBg)

        progressW = progressBgW - 4
        let prog = PixelArtRenderer.self  // just to compile
        _ = prog.self
        let fill = SKSpriteNode(color: UIColor(hex: "#F8D030"),
                                size: CGSize(width: progressW, height: progressBgH - 4))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -(progressW / 2), y: 0)
        fill.xScale = CGFloat(gm.state.journey?.progress ?? 0)
        fill.zPosition = 22
        progressBg.addChild(fill)
        progressFill = fill

        // Home button
        let homeBtn = makeButton(text: "🏠 返回家", color: UIColor(hex: "#205090"),
                                  btnSize: CGSize(width: 130, height: 36))
        homeBtn.position = CGPoint(x: size.width / 2, y: infoPanelY + 22)
        homeBtn.zPosition = 21
        homeBtn.name = "btn_home"
        tagChildNames(homeBtn, name: "btn_home")
        addChild(homeBtn)
    }

    private func buildNoJourneyUI() {
        let box = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 120), cornerRadius: 4)
        box.fillColor = UIColor(hex: "#F0F8FF")
        box.strokeColor = UIColor(hex: "#003878")
        box.lineWidth = 3
        box.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        box.zPosition = 10
        addChild(box)

        let lbl = SKLabelNode(text: "皮卡丘在家里！")
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 13
        lbl.fontColor = UIColor(hex: "#181818")
        lbl.position = CGPoint(x: 0, y: 14)
        box.addChild(lbl)

        let sub = SKLabelNode(text: "去准备旅行吧~")
        sub.fontName = "Courier"
        sub.fontSize = 10
        sub.fontColor = UIColor(hex: "#606060")
        sub.position = CGPoint(x: 0, y: -14)
        box.addChild(sub)

        let btn = makeButton(text: "🏠 返回家", color: UIColor(hex: "#205090"),
                              btnSize: CGSize(width: 160, height: 40))
        btn.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        btn.zPosition = 10
        btn.name = "btn_home2"
        tagChildNames(btn, name: "btn_home2")
        addChild(btn)

        buildTabBar()
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
        addTabItem(emoji: "🌟", label: "旅行", x: size.width * 0.5, active: true,  name: nil)
        addTabItem(emoji: "📮", label: "相册", x: size.width * 0.8, active: false, name: "btn_album")
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

    // MARK: - Return handling

    private func handleReturn() {
        guard let journey = gm.state.journey else { return }
        let location = ALL_LOCATIONS.first { $0.id == journey.locationId }
        gm.completeJourney(location: location)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showReturnPanel()
    }

    private func showReturnPanel() {
        let state = gm.state
        let panel = SKNode()
        panel.zPosition = 50

        let dim = SKShapeNode(rectOf: size)
        dim.fillColor = UIColor.black.withAlphaComponent(0.7)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.addChild(dim)

        let box = SKShapeNode(rectOf: CGSize(width: size.width - 32, height: 300), cornerRadius: 4)
        box.fillColor = UIColor(hex: "#F0F8FF")
        box.strokeColor = UIColor(hex: "#003878")
        box.lineWidth = 3
        box.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.addChild(box)

        let title = SKLabelNode(text: "皮卡丘回来了！⚡")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = UIColor(hex: "#003878")
        title.position = CGPoint(x: 0, y: 116)
        box.addChild(title)

        // Pikachu face
        let pikaTex = PixelArtRenderer.makeTexture(
            art: PikachuSprites.front, palette: Palettes.pikachu, pixelSize: 4)
        pikaTex.filteringMode = .nearest
        let pikaNode = SKSpriteNode(texture: pikaTex)
        pikaNode.position = CGPoint(x: 0, y: 56)
        box.addChild(pikaNode)
        pikaNode.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.5),
            SKAction.moveBy(x: 0, y: -4, duration: 0.5),
        ])))

        // Rewards preview
        if let last = state.postcards.first {
            let msg = SKLabelNode(text: "📮 收到新明信片！")
            msg.fontName = "Courier-Bold"
            msg.fontSize = 10
            msg.fontColor = UIColor(hex: "#505060")
            msg.position = CGPoint(x: 0, y: -12)
            box.addChild(msg)

            let msgText = SKLabelNode(text: truncate(last.message, to: 18))
            msgText.fontName = "Courier"
            msgText.fontSize = 9
            msgText.fontColor = UIColor(hex: "#707080")
            msgText.position = CGPoint(x: 0, y: -32)
            box.addChild(msgText)
        }

        let rewardRow = buildRewardRow(coins: state.coins)
        rewardRow.position = CGPoint(x: 0, y: -64)
        box.addChild(rewardRow)

        let homeBtn = makeButton(text: "🏠 返回家", color: UIColor(hex: "#205090"),
                                  btnSize: CGSize(width: 130, height: 36))
        homeBtn.name = "btn_home"
        tagChildNames(homeBtn, name: "btn_home")
        homeBtn.position = CGPoint(x: -72, y: -120)
        box.addChild(homeBtn)

        let albumBtn = makeButton(text: "📮 相册", color: UIColor(hex: "#503080"),
                                   btnSize: CGSize(width: 130, height: 36))
        albumBtn.name = "btn_album"
        tagChildNames(albumBtn, name: "btn_album")
        albumBtn.position = CGPoint(x: 72, y: -120)
        box.addChild(albumBtn)

        addChild(panel)
        panel.setScale(0.7)
        panel.alpha = 0
        panel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25),
        ]))
    }

    private func buildRewardRow(_ rewards: [String: Int] = [:], coins: Int) -> SKNode {
        let node = SKNode()
        let items: [(String, String)] = [("💰", "\(coins)G"), ("📮", "明信片")]
        for (i, (emoji, label)) in items.enumerated() {
            let emj = SKLabelNode(text: emoji)
            emj.fontSize = 22
            emj.position = CGPoint(x: CGFloat(i - 1) * 70 + 35, y: 6)
            node.addChild(emj)
            let lbl = SKLabelNode(text: label)
            lbl.fontName = "Courier"
            lbl.fontSize = 9
            lbl.fontColor = UIColor(hex: "#505060")
            lbl.position = CGPoint(x: CGFloat(i - 1) * 70 + 35, y: -12)
            node.addChild(lbl)
        }
        return node
    }

    // MARK: - Navigation

    private func goHome() {
        let home = HomeScene(size: size)
        home.scaleMode = scaleMode
        view?.presentScene(home, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    private func goAlbum() {
        let album = AlbumScene(size: size)
        album.scaleMode = scaleMode
        view?.presentScene(album, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - Helpers

    private func makeButton(text: String, color: UIColor, btnSize: CGSize) -> SKNode {
        let node = SKNode()
        let shadow = SKShapeNode(rectOf: btnSize)
        shadow.fillColor = color.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        node.addChild(shadow)
        let bg = SKShapeNode(rectOf: btnSize, cornerRadius: 2)
        bg.fillColor = color
        bg.strokeColor = color.withAlphaComponent(0.6)
        bg.lineWidth = 2
        node.addChild(bg)
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 11
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)
        return node
    }

    private func tagChildNames(_ node: SKNode, name: String) {
        node.children.forEach { child in
            child.name = name
            tagChildNames(child, name: name)
        }
    }

    private func truncate(_ s: String, to n: Int) -> String {
        s.count > n ? String(s.prefix(n)) + "..." : s
    }
}

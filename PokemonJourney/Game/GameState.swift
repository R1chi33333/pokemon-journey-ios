import Foundation

// MARK: - Models

struct GameState: Codable {
    var pikachu: PikachuState
    var journey: JourneyState?
    var inventory: Inventory
    var packed: PackedItems
    var postcards: [Postcard]
    var coins: Int

    static let initial = GameState(
        pikachu: PikachuState(isHome: true, mood: .happy, totalJourneys: 0, happiness: 80),
        journey: nil,
        inventory: Inventory(oran: 5, pecha: 3, sitrus: 2),
        packed: PackedItems(),
        postcards: [],
        coins: 20
    )
}

struct PikachuState: Codable {
    var isHome: Bool
    var mood: PikachuMood
    var totalJourneys: Int
    var happiness: Int
}

enum PikachuMood: String, Codable {
    case happy, excited, sleepy, curious, ready

    var text: String {
        switch self {
        case .happy:   return "皮卡丘很开心！"
        case .excited: return "皮卡丘超兴奋！⚡"
        case .sleepy:  return "皮卡丘有点困..."
        case .curious: return "皮卡丘在想什么呢..."
        case .ready:   return "皮卡丘准备出发了！"
        }
    }
}

struct JourneyState: Codable {
    let locationId: String
    let startTime: Date
    let endTime: Date
    let packed: PackedItems

    var isComplete: Bool { Date() >= endTime }

    var progress: Double {
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, min(1, elapsed / total))
    }

    var timeRemaining: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }
}

struct Inventory: Codable {
    var oran: Int
    var pecha: Int
    var sitrus: Int

    subscript(id: String) -> Int {
        get {
            switch id {
            case "oran": return oran
            case "pecha": return pecha
            case "sitrus": return sitrus
            default: return 0
            }
        }
        set {
            switch id {
            case "oran": oran = newValue
            case "pecha": pecha = newValue
            case "sitrus": sitrus = newValue
            default: break
            }
        }
    }
}

struct PackedItems: Codable {
    var oran: Int = 0
    var pecha: Int = 0
    var sitrus: Int = 0

    var totalCount: Int { oran + pecha + sitrus }

    subscript(id: String) -> Int {
        get {
            switch id {
            case "oran": return oran
            case "pecha": return pecha
            case "sitrus": return sitrus
            default: return 0
            }
        }
        set {
            switch id {
            case "oran": oran = newValue
            case "pecha": pecha = newValue
            case "sitrus": sitrus = newValue
            default: break
            }
        }
    }
}

struct Postcard: Codable, Identifiable {
    let id: UUID
    let locationId: String
    let message: String
    let date: Date
    let rewards: PostcardRewards

    init(locationId: String, message: String, date: Date = Date(), rewards: PostcardRewards) {
        self.id = UUID()
        self.locationId = locationId
        self.message = message
        self.date = date
        self.rewards = rewards
    }
}

struct PostcardRewards: Codable {
    var oran: Int
    var pecha: Int
    var sitrus: Int
    var coins: Int
}

// MARK: - Static Game Data

struct Location {
    let id: String
    let nameZH: String
    let nameJP: String
    let emoji: String
    let description: String
    let durationMinutes: Int
    let rewardBerries: [String: ClosedRange<Int>]
    let rewardCoins: ClosedRange<Int>
    let postcardChance: Double
    let wallColor: String
    let groundColor: String
    let skyColor: String
}

let ALL_LOCATIONS: [Location] = [
    Location(
        id: "viridian_forest",
        nameZH: "常磐森林",
        nameJP: "トキワの森",
        emoji: "🌲",
        description: "虫虫宝可梦们的乐园，皮卡丘最爱的地方！",
        durationMinutes: 3,
        rewardBerries: ["oran": 1...3, "pecha": 0...1],
        rewardCoins: 5...15,
        postcardChance: 0.9,
        wallColor: "#78C8F8",
        groundColor: "#58C838",
        skyColor: "#389820"
    ),
    Location(
        id: "cerulean_cape",
        nameZH: "华蓝海岬",
        nameJP: "ハナダのみさき",
        emoji: "🌊",
        description: "碧蓝的大海，浪花中有神秘的宝可梦！",
        durationMinutes: 10,
        rewardBerries: ["sitrus": 1...2, "pecha": 0...1],
        rewardCoins: 10...25,
        postcardChance: 0.95,
        wallColor: "#48A8F8",
        groundColor: "#2870E8",
        skyColor: "#F0E898"
    ),
    Location(
        id: "mt_moon",
        nameZH: "月亮山",
        nameJP: "ふじさん",
        emoji: "🌙",
        description: "充满神秘月之石的深邃洞窟",
        durationMinutes: 20,
        rewardBerries: ["oran": 2...4, "sitrus": 1...2],
        rewardCoins: 20...40,
        postcardChance: 1.0,
        wallColor: "#181828",
        groundColor: "#303048",
        skyColor: "#606080"
    ),
]

let POSTCARD_MESSAGES: [String: [String]] = [
    "viridian_forest": [
        "这里的虫虫宝可梦好可爱！我遇到了独角虫！",
        "森林里好凉快，我在树荫下睡了一觉~",
        "捡到了一颗发光的石头，给你带回来了！",
        "在这里遇到了比雕！它盘旋在高空好帅！",
    ],
    "cerulean_cape": [
        "海浪好好听，我在沙滩上睡着了...",
        "看到了鲤鱼王在跳水！好壮观！",
        "海风凉凉的，我的毛发都蓬起来了！",
        "捡到了一个漂亮的贝壳，送给你！",
    ],
    "mt_moon": [
        "洞穴里好深好黑，但是月之石在发光！",
        "遇到了化石，好古老的气息！",
        "在这里见到了超梦的壁画！好神秘！",
        "小拨拨一直跟着我，我给它唱了首歌。",
    ],
]

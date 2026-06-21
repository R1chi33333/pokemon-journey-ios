import Foundation
import UIKit

// MARK: - Enums

enum SparkyMood: String, Codable {
    case excited, happy, normal, tired, lonely

    var text: String {
        switch self {
        case .excited: return "好开心！出发冒险！⚡"
        case .happy:   return "我回来啦！好好玩~"
        case .normal:  return "有什么想去的地方吗？"
        case .tired:   return "有点累了...想睡觉"
        case .lonely:  return "好久没有出去了..."
        }
    }

    var idleSprite: String {
        switch self {
        case .excited: return "sparky_happy"
        case .happy:   return "sparky_happy"
        case .normal:  return "sparky_idle_0"
        case .tired:   return "sparky_sleep_0"
        case .lonely:  return "sparky_idle_2"
        }
    }
}

// MARK: - Items

struct ItemDef {
    let id: String
    let nameZH: String
    let iconName: String
    let description: String
}

let ALL_ITEMS: [ItemDef] = [
    ItemDef(id:"oran",     nameZH:"奥兰果", iconName:"item_oran",      description:"Sparky最喜欢的浆果"),
    ItemDef(id:"pecha",    nameZH:"蜜桃果", iconName:"item_pecha",     description:"让Sparky心情好"),
    ItemDef(id:"sitrus",   nameZH:"吉利果", iconName:"item_sitrus",    description:"恢复活力"),
    ItemDef(id:"umbrella", nameZH:"雨伞",   iconName:"item_umbrella",  description:"下雨天保护Sparky"),
    ItemDef(id:"hat",      nameZH:"帽子",   iconName:"item_hat",       description:"增加金币奖励"),
    ItemDef(id:"map",      nameZH:"地图",   iconName:"item_map",       description:"发现更多地点"),
    ItemDef(id:"compass",  nameZH:"指南针", iconName:"item_compass",   description:"缩短旅行时间10%"),
    ItemDef(id:"clover",   nameZH:"幸运草", iconName:"item_clover",    description:"提高浆果奖励"),
]

// MARK: - Locations

struct Location: Codable {
    let id: String
    let nameZH: String
    let emoji: String
    let description: String
    let durationMinutes: Double
    let rewardCoins: Int
    let postcardChance: Double
    let skyColor: String
    let groundColor: String
    let tileTheme: String
}

let ALL_LOCATIONS: [Location] = [
    Location(id:"viridian", nameZH:"常磐森林", emoji:"🌲",
             description:"宁静的绿色森林，满地橡果",
             durationMinutes:3,   rewardCoins:8,  postcardChance:0.75,
             skyColor:"#78C8F8", groundColor:"#48A830", tileTheme:"forest"),
    Location(id:"cerulean", nameZH:"华蓝海岬", emoji:"🌊",
             description:"蔚蓝的海岸，浪花扑来",
             durationMinutes:10,  rewardCoins:15, postcardChance:0.65,
             skyColor:"#A0D8F8", groundColor:"#E8D090", tileTheme:"beach"),
    Location(id:"mt_moon",  nameZH:"月亮山",   emoji:"🌙",
             description:"神秘的洞穴，水晶闪闪发光",
             durationMinutes:20,  rewardCoins:25, postcardChance:0.55,
             skyColor:"#303050", groundColor:"#605850", tileTheme:"cave"),
    Location(id:"cherry",   nameZH:"樱花谷",   emoji:"🌸",
             description:"粉色花瓣漫天飞舞",
             durationMinutes:60,  rewardCoins:40, postcardChance:0.50,
             skyColor:"#F8D8E8", groundColor:"#90C870", tileTheme:"forest"),
    Location(id:"snowpeak", nameZH:"雪白峰",   emoji:"🏔",
             description:"山顶积雪，能看到整个世界",
             durationMinutes:120, rewardCoins:60, postcardChance:0.40,
             skyColor:"#C8DCF8", groundColor:"#E8F0FF", tileTheme:"snow"),
]

let POSTCARD_MESSAGES: [String: [String]] = [
    "viridian": ["在森林里找到了好多橡果！\n松鼠们都来抢~","树林里好凉快，睡了一个午觉！","迷路了一会儿，但风景太美了！"],
    "cerulean": ["海浪好大！脚趾头都湿了~","捡到了一个漂亮的贝壳！","夕阳把大海染成了金色..."],
    "mt_moon":  ["洞穴里有发光的水晶！","遇到一只胆小的超音蝠！","找到了一块神秘的陨石！"],
    "cherry":   ["花瓣像雪一样飘落...","树下野餐，好幸福！"],
    "snowpeak": ["山顶好冷！但星空真的好美！","踩着雪发出嘎吱声，太有趣了！"],
]

// MARK: - Data Models

struct PostcardRewards: Codable {
    var coins: Int = 0
    var oran: Int = 0
    var pecha: Int = 0
    var sitrus: Int = 0
}

struct Postcard: Codable, Identifiable {
    let id: UUID
    let locationId: String
    let message: String
    let date: Date
    let rewards: PostcardRewards
}

struct JourneyState: Codable {
    var locationId: String
    var startTime: Date
    var endTime: Date
    var packedItems: [String]

    var isComplete: Bool { Date() >= endTime }

    var progress: Double {
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, max(0.0, elapsed / total))
    }

    var timeRemaining: TimeInterval { max(0, endTime.timeIntervalSinceNow) }

    var formattedTimeRemaining: String {
        let t = Int(timeRemaining)
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        if h > 0 { return String(format: "%d时%02d分", h, m) }
        if m > 0 { return String(format: "%d分%02d秒", m, s) }
        return String(format: "%d秒", s)
    }
}

struct Inventory: Codable {
    var items: [String: Int] = [
        "oran":3, "pecha":2, "sitrus":1,
        "umbrella":1, "hat":0, "map":0, "compass":0, "clover":0,
    ]
    subscript(_ id: String) -> Int {
        get { items[id] ?? 0 }
        set { items[id] = newValue }
    }
}

struct PackedItems: Codable {
    var items: [String] = []
    let maxSlots: Int = 3
    var isFull: Bool { items.count >= maxSlots }
    mutating func pack(_ id: String) { if !items.contains(id) && !isFull { items.append(id) } }
    mutating func unpack(_ id: String) { items.removeAll { $0 == id } }
    func contains(_ id: String) -> Bool { items.contains(id) }
}

struct SparkyState: Codable {
    var mood: SparkyMood = .normal
    var totalJourneys: Int = 0
}

struct GameState: Codable {
    var sparky: SparkyState = SparkyState()
    var journey: JourneyState? = nil
    var inventory: Inventory = Inventory()
    var packed: PackedItems = PackedItems()
    var postcards: [Postcard] = []
    var coins: Int = 0
}

import UIKit

// MARK: - Color Palettes

enum Palettes {
    static let pikachu: [Character: UIColor] = [
        ".": .clear,
        "B": UIColor(hex: "#1C1C1C"),
        "b": UIColor(hex: "#383838"),
        "Y": UIColor(hex: "#F8C800"),
        "y": UIColor(hex: "#FCE858"),
        "D": UIColor(hex: "#C89800"),
        "d": UIColor(hex: "#906000"),
        "W": UIColor(hex: "#F8F8F8"),
        "R": UIColor(hex: "#E03048"),
        "r": UIColor(hex: "#B82030"),
        "N": UIColor(hex: "#282010"),
    ]
}

// MARK: - Pikachu Sprites

enum PikachuSprites {
    // 16 cols × 20 rows — front view, sitting
    static let front: [String] = [
        "....BB....BB....",  //  0 ear tips
        "...BYYB..BYYB...",  //  1 ears
        "...BYYB..BYYB...",  //  2 ears
        "....BB....BB....",  //  3 ear base
        "..BYYYYYYYYYYB..",  //  4 head top
        ".BYYYYYYYYYYYYB.",  //  5 head wide
        ".BYBByYYYYBByYb.",  //  6 eyes
        ".BYBWyYYYYBWyYb.",  //  7 eye whites (W = shine)
        ".BYBByYYYYBByYb.",  //  8 eyes bottom
        ".BYYYYYYYYYYYYB.",  //  9 between eyes and cheeks
        ".BYRRYYYYYYRRYB.",  // 10 cheeks
        ".BYRRYYYYYYRRYb.",  // 11 cheeks lower
        ".BYYYYNYYNYYYYb.",  // 12 nose dots
        ".BYYYYYYYYYYYYB.",  // 13 lower face
        "..BYYYYYYYYYYB..",  // 14 body
        "..BYYYYYYYYYYB..",  // 15 body
        "..BYYYYYYYYYYB..",  // 16 body
        "..BYYBd..dBYYB..",  // 17 legs
        "...BBB....BBB...",  // 18 feet
        "................",  // 19 empty
    ]

    // Blink variant (row 7: replace W with Y for closed eyes)
    static let frontBlink: [String] = {
        var art = front
        art[7] = art[7].replacingOccurrences(of: "W", with: "Y")
        return art
    }()

    // 12 cols × 16 rows — walk side view, frame 1
    static let walkA: [String] = [
        "...BYYYYB...",  //  0 head
        "..BYYYYYYB..",  //  1
        ".BYBByYYYYb.",  //  2 eye
        ".BYBWyYYYYb.",  //  3 eye shine
        ".BYBByYYYYb.",  //  4
        ".BYRRYYYYYb.",  //  5 cheek
        ".BYYYYYYYYb.",  //  6
        ".BYYYYYYYYb.",  //  7 body
        ".BYYYYYYYYb.",  //  8
        ".BYYBd..Bdb.",  //  9
        "..BBd....dB.",  // 10 legs
        "...Bd....dB.",  // 11
        "....BB..BB..",  // 12 feet
        "............",  // 13
        "............",  // 14
        "............",  // 15
    ]

    // 12 cols × 16 rows — walk side view, frame 2
    static let walkB: [String] = [
        "...BYYYYB...",  //  0 head
        "..BYYYYYYB..",  //  1
        ".BYBByYYYYb.",  //  2 eye
        ".BYBWyYYYYb.",  //  3 eye shine
        ".BYBByYYYYb.",  //  4
        ".BYRRYYYYYb.",  //  5 cheek
        ".BYYYYYYYYb.",  //  6
        ".BYYYYYYYYb.",  //  7 body
        ".BYYYYYYYYb.",  //  8
        "..BYYBddBdb.",  //  9 alternate legs
        "...BBBd.dBB.",  // 10
        "....Bdd.dB..",  // 11
        ".....BB.BB..",  // 12 feet alternate
        "............",  // 13
        "............",  // 14
        "............",  // 15
    ]

    // Happy expression (front, eyes slightly raised)
    static let happy: [String] = front
}

// MARK: - Item Sprites

enum ItemSprites {
    // 8×8 Pokéball
    static let pokeball: [String] = [
        "..BRRB..",
        ".BRRRR b",
        "BRRRRRRb",
        "BWWWWWW b",
        "BWWBbWW b",
        "BWWWWWW b",
        ".bbbbbb b",
        "..bbbb..",
    ]

    // Simple 6×6 berry (used for all berries, color set via tint)
    static let berry: [String] = [
        "..BB..",
        ".BYYb.",
        "BYYYYb",
        "BYYYYb",
        ".bYYb.",
        "..bb..",
    ]

    // 8×6 coin
    static let coin: [String] = [
        ".BYYY.",
        "BYyYYb",
        "BYYYYb",
        "BYyYYb",
        ".bYYb.",
        "..bb..",
    ]

    static let berryPalette: [Character: UIColor] = [
        ".": .clear,
        "B": UIColor(hex: "#1C1C1C"),
        "b": UIColor(hex: "#383838"),
        "Y": UIColor(hex: "#F8C800"),
        "y": UIColor(hex: "#FCE858"),
    ]

    static let coinPalette: [Character: UIColor] = [
        ".": .clear,
        "B": UIColor(hex: "#1C1C1C"),
        "b": UIColor(hex: "#383838"),
        "Y": UIColor(hex: "#F8D030"),
        "y": UIColor(hex: "#FCE858"),
    ]
}

import Foundation

enum GameStorage {
    private static let key = "pokemon_journey_save_v1"

    static func save(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> GameState {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let state = try? JSONDecoder().decode(GameState.self, from: data)
        else { return .initial }
        return state
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

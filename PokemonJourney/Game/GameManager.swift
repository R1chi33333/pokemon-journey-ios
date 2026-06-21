import Foundation

@MainActor
final class GameManager {
    static let shared = GameManager()
    private init() { load() }

    private(set) var state: GameState = .initial

    // MARK: - Persistence

    func load() {
        state = GameStorage.load()
        // Auto-complete any journey that ended while app was closed
        if let journey = state.journey, journey.isComplete {
            let location = ALL_LOCATIONS.first { $0.id == journey.locationId }
            completeJourney(location: location)
        }
    }

    private func save() {
        GameStorage.save(state)
    }

    // MARK: - Actions

    func packItem(_ itemId: String) {
        guard state.inventory[itemId] > 0 else { return }
        state.inventory[itemId] -= 1
        state.packed[itemId] += 1
        save()
    }

    func unpackItem(_ itemId: String) {
        guard state.packed[itemId] > 0 else { return }
        state.packed[itemId] -= 1
        state.inventory[itemId] += 1
        save()
    }

    func startJourney(locationId: String) {
        guard state.pikachu.isHome,
              state.packed.totalCount > 0,
              let location = ALL_LOCATIONS.first(where: { $0.id == locationId }) else { return }

        let now = Date()
        let duration = TimeInterval(location.durationMinutes * 60)

        state.journey = JourneyState(
            locationId: locationId,
            startTime: now,
            endTime: now.addingTimeInterval(duration),
            packed: state.packed
        )
        state.packed = PackedItems()
        state.pikachu.isHome = false
        state.pikachu.mood = .excited
        save()
    }

    func completeJourney(location: Location?) {
        guard let location else { return }

        let rewards = generateRewards(for: location)

        // Add rewards to inventory
        state.inventory.oran += rewards.oran
        state.inventory.pecha += rewards.pecha
        state.inventory.sitrus += rewards.sitrus
        state.coins += rewards.coins

        // Add postcard
        let messages = POSTCARD_MESSAGES[location.id] ?? ["旅途愉快！"]
        let message = messages.randomElement() ?? "皮卡丘带着快乐回来了！"
        let postcard = Postcard(locationId: location.id, message: message, rewards: rewards)
        state.postcards.insert(postcard, at: 0)

        // Update Pikachu
        state.pikachu.isHome = true
        state.pikachu.mood = .happy
        state.pikachu.totalJourneys += 1
        state.pikachu.happiness = min(100, state.pikachu.happiness + 10)
        state.journey = nil
        save()
    }

    // MARK: - Helpers

    private func generateRewards(for location: Location) -> PostcardRewards {
        var oran = 0, pecha = 0, sitrus = 0
        for (berry, range) in location.rewardBerries {
            let count = Int.random(in: range)
            switch berry {
            case "oran": oran = count
            case "pecha": pecha = count
            case "sitrus": sitrus = count
            default: break
            }
        }
        let coins = Int.random(in: location.rewardCoins)
        return PostcardRewards(oran: oran, pecha: pecha, sitrus: sitrus, coins: coins)
    }
}

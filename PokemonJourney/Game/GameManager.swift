import Foundation

@MainActor
final class GameManager {
    static let shared = GameManager()
    private init() { load() }

    private(set) var state: GameState = GameState()

    func load() {
        state = GameStorage.load()
        if let journey = state.journey, journey.isComplete {
            completeJourney(location: ALL_LOCATIONS.first { $0.id == journey.locationId })
        }
    }

    private func save() { GameStorage.save(state) }

    // MARK: - Pack / Unpack

    func packItem(_ itemId: String) {
        guard state.inventory[itemId] > 0, !state.packed.isFull else { return }
        state.inventory[itemId] -= 1
        state.packed.pack(itemId)
        save()
    }

    func unpackItem(_ itemId: String) {
        guard state.packed.contains(itemId) else { return }
        state.packed.unpack(itemId)
        state.inventory[itemId] += 1
        save()
    }

    // MARK: - Journey

    func startJourney(locationId: String) {
        guard state.journey == nil,
              let location = ALL_LOCATIONS.first(where: { $0.id == locationId }) else { return }

        let now = Date()
        var duration = TimeInterval(location.durationMinutes * 60)
        if state.packed.contains("compass") { duration *= 0.9 }

        state.journey = JourneyState(
            locationId: locationId,
            startTime: now,
            endTime: now.addingTimeInterval(duration),
            packedItems: state.packed.items
        )
        state.packed = PackedItems()
        state.sparky.mood = .excited
        save()
    }

    func completeJourney(location: Location?) {
        guard let location = location else {
            state.journey = nil
            save()
            return
        }

        let rewards = generateRewards(for: location, packed: state.journey?.packedItems ?? [])
        state.inventory[rewards.oran > 0 ? "oran" : "sitrus"] += 0  // no-op, rewards go to postcard
        state.coins += rewards.coins

        // Return packed items
        if let packed = state.journey?.packedItems {
            for itemId in packed { state.inventory[itemId] += 1 }
        }

        // Add postcard (chance-based)
        if Double.random(in: 0...1) < location.postcardChance {
            let messages = POSTCARD_MESSAGES[location.id] ?? ["旅途愉快！"]
            let message = messages.randomElement() ?? "Sparky带着快乐回来了！"
            let card = Postcard(id: UUID(), locationId: location.id,
                                message: message, date: Date(), rewards: rewards)
            state.postcards.insert(card, at: 0)
        }

        state.sparky.mood = .happy
        state.sparky.totalJourneys += 1
        state.journey = nil
        save()
    }

    // MARK: - Helpers

    private func generateRewards(for location: Location, packed: [String]) -> PostcardRewards {
        var rewards = PostcardRewards()
        rewards.coins = Int.random(in: (location.rewardCoins / 2)...location.rewardCoins)
        if packed.contains("hat")    { rewards.coins = Int(Double(rewards.coins) * 1.5) }
        rewards.oran   = Int.random(in: 0...2)
        rewards.pecha  = packed.contains("pecha")  ? Int.random(in: 0...2) : 0
        rewards.sitrus = packed.contains("sitrus") ? (Bool.random() ? 1 : 0) : 0
        if packed.contains("clover") {
            rewards.oran   += 1
            rewards.pecha  = max(rewards.pecha, 1)
        }
        return rewards
    }
}

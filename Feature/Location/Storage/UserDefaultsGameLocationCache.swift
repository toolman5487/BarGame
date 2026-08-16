//
//  UserDefaultsGameLocationCache.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

actor UserDefaultsGameLocationCache: GameLocationCaching {

    private enum Key {
        static let snapshot = "gameLocation.cachedSnapshot"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func snapshot() -> GameCurrentLocationSnapshot? {
        guard let data = userDefaults.data(forKey: Key.snapshot) else {
            return nil
        }
        return try? JSONDecoder().decode(
            GameCurrentLocationSnapshot.self,
            from: data
        )
    }

    func save(_ snapshot: GameCurrentLocationSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Key.snapshot)
    }

    func removeSnapshot() {
        userDefaults.removeObject(forKey: Key.snapshot)
    }
}

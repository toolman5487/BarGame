//
//  GameDetailSection.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailSection: Equatable, Sendable {

    case rules([GameDetailRule])
    case start

    static func standard(for gameID: DiceGameID) -> [GameDetailSection] {
        [
            .rules(GameDetailRuleCatalog.rules(for: gameID)),
            .start,
        ]
    }

    var headerTitle: String? {
        switch self {
        case .rules:
            return "遊戲規則"

        case .start:
            return nil
        }
    }
}

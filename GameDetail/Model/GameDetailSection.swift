//
//  GameDetailSection.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailSection: Equatable, Sendable {

    case rules([GameDetailRule])
    case settings
    case start

    static func standard(for gameID: GameID) -> [GameDetailSection] {
        [
            .rules(GameDetailRuleCatalog.rules(for: gameID)),
            .settings,
            .start,
        ]
    }

    var headerTitle: String? {
        switch self {
        case .rules:
            return "遊戲規則"

        case .settings:
            return "遊戲設定"

        case .start:
            return nil
        }
    }
}

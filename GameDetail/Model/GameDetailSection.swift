//
//  GameDetailSection.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailSection: Equatable, Sendable {

    case rules([GameDetailRule])
    case settings([GameDetailSetting])

    static func standard(for gameID: DiceGameID) -> [GameDetailSection] {
        var sections: [GameDetailSection] = [
            .rules(GameDetailRuleCatalog.rules(for: gameID)),
        ]
        let settings = GameDetailSetting.standard(for: gameID)

        if !settings.isEmpty {
            sections.append(.settings(settings))
        }

        return sections
    }

    var headerTitle: String? {
        switch self {
        case .rules:
            return "遊戲規則"

        case .settings:
            return "遊戲設定"
        }
    }
}

//
//  GameDetailRuleCatalog.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailRuleCatalog {

    static func rules(for gameID: GameID) -> [GameDetailRule] {
        switch gameID {
        case .dice:
            return [
                GameDetailRule(step: 1, text: "選擇要使用的骰子數量"),
                GameDetailRule(step: 2, text: "搖動手機擲出骰子"),
                GameDetailRule(step: 3, text: "鎖定骰子並查看結果"),
            ]

        case .playingCards,
             .roulette,
             .sicBo,
             .blackjack,
             .bingo:
            return []
        }
    }
}

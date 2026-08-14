//
//  MainHomeSnapshot.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

// MARK: - Section

nonisolated enum MainHomeSection: Equatable, Sendable {

    case dicePreview
    case gameResults([GameOverview])
    case gameList([DiceGame])

    var headerTitle: String {
        switch self {
        case .dicePreview:
            return ""

        case .gameResults:
            return "遊戲戰績"

        case .gameList:
            return "遊戲列表"
        }
    }
}

// MARK: - Snapshot

nonisolated struct MainHomeSnapshot: Equatable, Sendable {

    let sections: [MainHomeSection]

    var games: [DiceGame] {
        sections.flatMap { section in
            switch section {
            case .gameList(let games):
                return games

            case .dicePreview, .gameResults:
                return []
            }
        }
    }

    func updatingGameResults(
        _ gameOverviews: [GameOverview]
    ) -> MainHomeSnapshot {
        MainHomeSnapshot(
            sections: sections.map { section in
                switch section {
                case .gameResults:
                    return .gameResults(gameOverviews)

                case .dicePreview, .gameList:
                    return section
                }
            }
        )
    }
}

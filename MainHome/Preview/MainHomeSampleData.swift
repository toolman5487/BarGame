//
//  MainHomeSampleData.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum MainHomeSampleData {

    static let standardSnapshot = MainHomeSnapshot(
        sections: [
            .dicePreview,
            .gameResults(gameOverviews),
            .gameList(games),
        ]
    )

    private static let games = DiceGameCatalog.firstPhaseVerbalGames

    private static let gameOverviews: [GameOverview] = [
        GameOverview(
            game: DiceGame(id: .liarsDice),
            statistics: GameStatistics(wins: 15, losses: 5)
        ),
        GameOverview(
            game: DiceGame(id: .mia),
            statistics: GameStatistics(wins: 9, losses: 3)
        ),
        GameOverview(
            game: DiceGame(id: .dicePoker),
            statistics: GameStatistics(wins: 6, losses: 7)
        ),
        GameOverview(
            game: DiceGame(id: .highLow),
            statistics: GameStatistics(wins: 10, losses: 6)
        ),
        GameOverview(
            game: DiceGame(id: .oddEven),
            statistics: GameStatistics(wins: 15, losses: 9)
        ),
        GameOverview(
            game: DiceGame(id: .sevenElevenDouble),
            statistics: GameStatistics(wins: 8, losses: 2)
        ),
    ]
}

extension MainHomeConfiguration {

    nonisolated static let standard = MainHomeConfiguration(
        snapshot: MainHomeSampleData.standardSnapshot
    )
}

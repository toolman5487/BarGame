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
            statistics: GameStatistics(wins: 12, draws: 3, losses: 5)
        ),
        GameOverview(
            game: DiceGame(id: .mia),
            statistics: GameStatistics(wins: 8, draws: 1, losses: 3)
        ),
        GameOverview(
            game: DiceGame(id: .dicePoker),
            statistics: GameStatistics(wins: 4, draws: 2, losses: 7)
        ),
        GameOverview(
            game: DiceGame(id: .highLow),
            statistics: GameStatistics(wins: 6, draws: 4, losses: 6)
        ),
        GameOverview(
            game: DiceGame(id: .oddEven),
            statistics: GameStatistics(wins: 15, draws: 0, losses: 9)
        ),
        GameOverview(
            game: DiceGame(id: .sevenElevenDouble),
            statistics: GameStatistics(wins: 3, draws: 5, losses: 2)
        ),
    ]
}

extension MainHomeConfiguration {

    nonisolated static let standard = MainHomeConfiguration(
        snapshot: MainHomeSampleData.standardSnapshot
    )
}

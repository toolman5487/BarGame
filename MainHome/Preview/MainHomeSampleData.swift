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

    private static let dice = DiceGame(id: .dice, title: "骰子")
    private static let playingCards = DiceGame(id: .playingCards, title: "啤牌")
    private static let roulette = DiceGame(id: .roulette, title: "輪盤")
    private static let sicBo = DiceGame(id: .sicBo, title: "骰寶")
    private static let blackjack = DiceGame(id: .blackjack, title: "二十一點")
    private static let bingo = DiceGame(id: .bingo, title: "賓果")

    private static let games: [DiceGame] = [
        dice,
        playingCards,
        roulette,
        sicBo,
        blackjack,
        bingo,
    ]

    private static let gameOverviews: [GameOverview] = [
        GameOverview(
            game: dice,
            statistics: GameStatistics(wins: 12, draws: 3, losses: 5)
        ),
        GameOverview(
            game: playingCards,
            statistics: GameStatistics(wins: 8, draws: 1, losses: 3)
        ),
        GameOverview(
            game: roulette,
            statistics: GameStatistics(wins: 4, draws: 2, losses: 7)
        ),
        GameOverview(
            game: sicBo,
            statistics: GameStatistics(wins: 6, draws: 4, losses: 6)
        ),
        GameOverview(
            game: blackjack,
            statistics: GameStatistics(wins: 15, draws: 0, losses: 9)
        ),
        GameOverview(
            game: bingo,
            statistics: GameStatistics(wins: 3, draws: 5, losses: 2)
        ),
    ]
}

extension MainHomeConfiguration {

    nonisolated static let standard = MainHomeConfiguration(
        snapshot: MainHomeSampleData.standardSnapshot
    )
}

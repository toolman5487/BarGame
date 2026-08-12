//
//  GameStatistics.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated struct GameStatistics: Equatable, Sendable {

    let wins: Int
    let draws: Int
    let losses: Int

    var completedGames: Int {
        wins + draws + losses
    }

    var winRate: Double {
        guard completedGames > 0 else { return 0 }
        return Double(wins) / Double(completedGames)
    }
}

nonisolated struct GameOverview: Identifiable, Equatable, Sendable {

    var id: DiceGameID { game.id }

    let game: DiceGame
    let statistics: GameStatistics
}

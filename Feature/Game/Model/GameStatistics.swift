//
//  GameStatistics.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated struct GameStatistics: Equatable, Sendable {

    static let zero = GameStatistics(wins: 0, losses: 0)

    let wins: Int
    let losses: Int

    var completedGames: Int {
        wins + losses
    }

    var winRate: Double {
        guard completedGames > 0 else { return 0 }
        return Double(wins) / Double(completedGames)
    }
}

nonisolated protocol GameStatisticsReading: Sendable {

    func statistics(
        for gameIDs: [DiceGameID]
    ) async throws -> [DiceGameID: GameStatistics]
}

nonisolated struct GameOverview: Identifiable, Equatable, Sendable {

    var id: DiceGameID { game.id }

    let game: DiceGame
    let statistics: GameStatistics
}

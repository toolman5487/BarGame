//
//  GameDetailStatistics.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

// MARK: - Statistics

nonisolated struct GameDetailStatistics: Equatable, Sendable {

    let wins: Int
    let losses: Int
    let draws: Int
    let totalPoints: Int
    let currentStreak: MatchOutcomeStreak

    init(statistics: GameStatistics) {
        guard statistics.completedGames > 0,
              let currentStreak = statistics.currentStreak
        else {
            preconditionFailure("Statistics require completed games and a streak")
        }

        wins = statistics.wins
        losses = statistics.losses
        draws = statistics.draws
        totalPoints = statistics.totalPoints
        self.currentStreak = currentStreak
    }

    var completedGames: Int {
        wins + losses + draws
    }

    var winRate: Double {
        guard completedGames > 0 else { return 0 }
        return Double(wins) / Double(completedGames)
    }

    var averagePoints: Double {
        guard completedGames > 0 else { return 0 }
        return Double(totalPoints) / Double(completedGames)
    }
}

// MARK: - State

nonisolated enum GameDetailStatisticsState: Equatable, Sendable {

    case loading
    case empty
    case content(GameDetailStatistics)
    case error(message: String)

    init(statistics: GameStatistics) {
        guard statistics.completedGames > 0,
              let _ = statistics.currentStreak
        else {
            self = .empty
            return
        }
        self = .content(GameDetailStatistics(statistics: statistics))
    }
}

//
//  GameStatistics.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum MatchOutcomeStreak: Equatable, Sendable {

    case win(Int)
    case loss(Int)
    case draw(Int)

    var displayText: String {
        switch self {
        case .win(let count):
            return "\(count) 連勝"

        case .loss(let count):
            return "\(count) 連敗"

        case .draw(let count):
            return "\(count) 連和"
        }
    }
}

nonisolated struct GameStatistics: Equatable, Sendable {

    static let zero = GameStatistics(
        wins: 0,
        losses: 0,
        draws: 0,
        totalPoints: 0,
        currentStreak: nil
    )

    let wins: Int
    let losses: Int
    let draws: Int
    let totalPoints: Int
    let currentStreak: MatchOutcomeStreak?

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

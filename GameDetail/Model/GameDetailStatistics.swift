//
//  GameDetailStatistics.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

// MARK: - Streak

nonisolated enum GameDetailStreak: Equatable, Sendable {

    case win(Int)
    case loss(Int)

    var displayText: String {
        switch self {
        case .win(let count):
            return "\(count) 連勝"

        case .loss(let count):
            return "\(count) 連敗"
        }
    }
}

// MARK: - Statistics

nonisolated struct GameDetailStatistics: Equatable, Sendable {

    let wins: Int
    let losses: Int
    let scoredPoints: Int
    let concededPoints: Int
    let currentStreak: GameDetailStreak

    init(records: [GameDetailRecentRecord]) {
        precondition(!records.isEmpty, "Statistics require at least one record")

        var wins = 0
        var losses = 0
        var scoredPoints = 0
        var concededPoints = 0

        records.forEach { record in
            switch record.outcome {
            case .win:
                wins += 1

            case .loss:
                losses += 1
            }

            scoredPoints += record.playerScore
            concededPoints += record.opponentScore
        }

        self.wins = wins
        self.losses = losses
        self.scoredPoints = scoredPoints
        self.concededPoints = concededPoints
        currentStreak = Self.makeCurrentStreak(from: records)
    }

    var completedGames: Int {
        wins + losses
    }

    var winRate: Double {
        guard completedGames > 0 else { return 0 }
        return Double(wins) / Double(completedGames)
    }

    var scoreDifference: Int {
        scoredPoints - concededPoints
    }

    private static func makeCurrentStreak(
        from records: [GameDetailRecentRecord]
    ) -> GameDetailStreak {
        let outcome = records[0].outcome
        let count = records.prefix { $0.outcome == outcome }.count

        switch outcome {
        case .win:
            return .win(count)

        case .loss:
            return .loss(count)
        }
    }
}

// MARK: - State

nonisolated enum GameDetailStatisticsState: Equatable, Sendable {

    case empty
    case content(GameDetailStatistics)
    case error(message: String)

    init(recentRecordsState: GameDetailRecentRecordsState) {
        switch recentRecordsState {
        case .empty:
            self = .empty

        case .content(let records):
            let recentRecords = Array(
                records.prefix(GameDetailRecentRecordsState.maximumRecordCount)
            )
            guard !recentRecords.isEmpty else {
                self = .empty
                return
            }
            self = .content(GameDetailStatistics(records: recentRecords))

        case .error(let message):
            self = .error(message: message)
        }
    }
}

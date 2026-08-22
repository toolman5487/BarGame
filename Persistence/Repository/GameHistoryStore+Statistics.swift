//
//  GameHistoryStore+Statistics.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation

extension GameHistoryStore: GameStatisticsReading {

    func statistics(
        for gameIDs: [DiceGameID]
    ) throws -> [DiceGameID: GameStatistics] {
        let requestedGameIDs = Set(gameIDs)
        guard !requestedGameIDs.isEmpty else { return [:] }

        var statisticsByGameID = Dictionary(
            uniqueKeysWithValues: requestedGameIDs.map { ($0, GameStatistics.zero) }
        )
        let records = try records(matching: DiceGameRecordQuery())
        let recordsByGameID = Dictionary(
            grouping: records.filter { requestedGameIDs.contains($0.gameID) },
            by: \.gameID
        )

        for gameID in requestedGameIDs {
            statisticsByGameID[gameID] = Self.makeStatistics(
                from: recordsByGameID[gameID] ?? []
            )
        }

        return statisticsByGameID
    }

    private static func makeStatistics(
        from records: [DiceGameMatchRecord]
    ) -> GameStatistics {
        guard !records.isEmpty else { return .zero }

        var wins = 0
        var losses = 0
        var draws = 0
        var totalPoints = 0

        for record in records {
            switch record.outcome {
            case .win:
                wins += 1

            case .loss:
                losses += 1

            case .draw:
                draws += 1
            }

            totalPoints += record.totalPoints
        }

        return GameStatistics(
            wins: wins,
            losses: losses,
            draws: draws,
            totalPoints: totalPoints,
            currentStreak: makeCurrentStreak(from: records)
        )
    }

    private static func makeCurrentStreak(
        from records: [DiceGameMatchRecord]
    ) -> MatchOutcomeStreak? {
        guard let outcome = records.first?.outcome else { return nil }
        let count = records.prefix { $0.outcome == outcome }.count

        switch outcome {
        case .win:
            return .win(count)

        case .loss:
            return .loss(count)

        case .draw:
            return .draw(count)
        }
    }
}

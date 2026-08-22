//
//  MatchDetailPresentation.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Foundation

nonisolated struct MatchDetailPresentation: Equatable, Sendable {

    let winScoreText: String
    let lossScoreText: String
    let metrics: [MatchDetailMetric]
    let progression: [MatchDetailProgressionItem]
    let rounds: [MatchDetailRoundItem]
    let pointDistribution: [MatchDetailPointDistributionItem]
    let information: MatchDetailInformation

    init(record: DiceGameMatchRecord) {
        let orderedRounds = record.rounds.sorted { $0.sequence < $1.sequence }
        let confirmedRolls = orderedRounds.compactMap(\.latestConfirmedRoll)
        let diceValues = confirmedRolls.flatMap { roll in
            roll.dice
                .sorted { $0.index < $1.index }
                .map(\.faceValue)
        }

        winScoreText = String(record.roundWins)
        lossScoreText = String(record.roundLosses)
        metrics = [
            MatchDetailMetric(
                title: "回合",
                value: String(orderedRounds.count)
            ),
            MatchDetailMetric(
                title: "勝率",
                value: Self.percentageText(
                    numerator: record.roundWins,
                    denominator: orderedRounds.count
                )
            ),
            MatchDetailMetric(
                title: "平均骰點",
                value: Self.averageText(values: diceValues)
            ),
            MatchDetailMetric(
                title: "最長連勝",
                value: String(Self.longestWinStreak(in: orderedRounds))
            ),
        ]
        var cumulativeDifference = 0
        progression = orderedRounds.map {
            switch $0.outcome {
            case .win:
                cumulativeDifference += 1

            case .loss:
                cumulativeDifference -= 1
            }

            return MatchDetailProgressionItem(
                id: $0.id,
                sequence: $0.sequence,
                outcome: $0.outcome,
                cumulativeDifference: cumulativeDifference
            )
        }
        rounds = orderedRounds.compactMap(MatchDetailRoundItem.init)
        pointDistribution = (1...6).map { faceValue in
            MatchDetailPointDistributionItem(
                faceValue: faceValue,
                count: diceValues.count { $0 == faceValue }
            )
        }
        information = MatchDetailInformation(record: record)
    }

    private static func percentageText(
        numerator: Int,
        denominator: Int
    ) -> String {
        guard denominator > 0 else { return "0%" }
        let percentage = Double(numerator) / Double(denominator) * 100
        return "\(Int(percentage.rounded()))%"
    }

    private static func averageText(values: [Int]) -> String {
        guard !values.isEmpty else { return "—" }
        let average = Double(values.reduce(0, +)) / Double(values.count)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    private static func longestWinStreak(
        in rounds: [DiceGameRoundRecord]
    ) -> Int {
        var longestStreak = 0
        var currentStreak = 0

        for round in rounds {
            switch round.outcome {
            case .win:
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)

            case .loss:
                currentStreak = 0
            }
        }

        return longestStreak
    }

}

nonisolated struct MatchDetailMetric: Equatable, Sendable {

    let title: String
    let value: String
}

nonisolated struct MatchDetailProgressionItem: Equatable, Identifiable, Sendable {

    let id: UUID
    let sequence: Int
    let outcome: RoundOutcome
    let cumulativeDifference: Int

    var cumulativeDifferenceText: String {
        guard cumulativeDifference > 0 else {
            return String(cumulativeDifference)
        }
        return "+\(cumulativeDifference)"
    }
}

nonisolated struct MatchDetailRoundItem: Equatable, Identifiable, Sendable {

    let id: UUID
    let sequenceText: String
    let outcome: RoundOutcome
    let diceText: String
    let pointsText: String
    let timeText: String

    init?(round: DiceGameRoundRecord) {
        guard let roll = round.latestConfirmedRoll else { return nil }
        let values = roll.dice
            .sorted { $0.index < $1.index }
            .map(\.faceValue)

        id = round.id
        sequenceText = "第 \(round.sequence) 回合"
        outcome = round.outcome
        diceText = values.map(String.init).joined(separator: " · ")
        pointsText = "\(values.reduce(0, +)) 點"
        timeText = roll.rolledAt.formatted(.dateTime.hour().minute())
    }
}

nonisolated struct MatchDetailPointDistributionItem: Equatable, Identifiable, Sendable {

    var id: Int { faceValue }

    let faceValue: Int
    let count: Int
}

nonisolated enum MatchDetailMapState: Equatable, Sendable {

    case located(GameCoordinate)
    case notRecorded
}

nonisolated struct MatchDetailInformation: Equatable, Sendable {

    let areaText: String
    let detailAddressText: String
    let startedAtText: String
    let mapState: MatchDetailMapState

    init(record: DiceGameMatchRecord) {
        let location = record.sessionContext.event.location
        areaText = location?.area ?? "未記錄區域"
        detailAddressText = location?.detailAddress ?? "未記錄詳細地址"
        startedAtText = record.sessionContext.startedAt.formatted(
            .dateTime.year().month().day().hour().minute()
        )
        if let coordinate = location?.coordinate,
           coordinate.isValid {
            mapState = .located(coordinate)
        } else {
            mapState = .notRecorded
        }
    }
}

nonisolated enum MatchDetailSection: Equatable, Sendable {

    case summary
    case metrics
    case progression
    case rounds
    case pointDistribution
    case information

    var title: String? {
        switch self {
        case .summary:
            return nil

        case .metrics:
            return "數據分析"

        case .progression:
            return "勝敗走勢"

        case .rounds:
            return "每回合"

        case .pointDistribution:
            return "點數分布"

        case .information:
            return "時間與地點"
        }
    }
}

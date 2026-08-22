//
//  RoundDetailPresentation.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation

nonisolated struct RoundDetailPresentation: Equatable, Sendable {

    let navigationTitle: String
    let outcome: RoundOutcome
    let totalPointsText: String
    let dice: [RoundDetailDieItem]
    let distribution: [RoundDetailDistributionItem]
    let information: [RoundDetailInformationItem]

    init?(
        record: DiceGameMatchRecord,
        round: DiceGameRoundRecord
    ) {
        guard let roll = round.latestConfirmedRoll else { return nil }

        let orderedDice = roll.dice.sorted { $0.index < $1.index }
        let values = orderedDice.map(\.faceValue)

        navigationTitle = "第 \(round.sequence) 回合"
        outcome = round.outcome
        totalPointsText = String(values.reduce(0, +))
        dice = orderedDice.map {
            RoundDetailDieItem(
                id: $0.id,
                index: $0.index,
                faceValue: $0.faceValue
            )
        }
        distribution = record.gameID.allowedFaceValues.map { faceValue in
            RoundDetailDistributionItem(
                faceValue: faceValue,
                count: values.count { $0 == faceValue }
            )
        }
        information = [
            RoundDetailInformationItem(
                title: "遊戲",
                value: record.gameID.title
            ),
            RoundDetailInformationItem(
                title: "骰子數量",
                value: "\(orderedDice.count) 顆"
            ),
            RoundDetailInformationItem(
                title: "記錄時間",
                value: roll.rolledAt.formatted(
                    .dateTime.year().month().day().hour().minute()
                )
            ),
        ]
    }
}

nonisolated struct RoundDetailDieItem: Equatable, Identifiable, Sendable {

    let id: UUID
    let index: Int
    let faceValue: Int
}

nonisolated struct RoundDetailDistributionItem: Equatable, Identifiable, Sendable {

    var id: Int { faceValue }

    let faceValue: Int
    let count: Int
}

nonisolated struct RoundDetailInformationItem: Equatable, Sendable {

    let title: String
    let value: String
}

nonisolated enum RoundDetailSection: Equatable, Sendable {

    case summary
    case diceResult
    case distribution
    case information

    var title: String? {
        switch self {
        case .summary:
            return nil

        case .diceResult:
            return "骰子結果"

        case .distribution:
            return "點數分布"

        case .information:
            return "回合資訊"
        }
    }
}

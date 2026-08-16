//
//  DiceGameMatchRecord.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import Foundation

nonisolated enum DiceRollStatus: String, Codable, Equatable, Sendable {

    case intermediate
    case confirmed
    case cancelled
}

nonisolated enum DiceGameMatchRecordError: Error, Equatable, Sendable {

    case missingConfirmedRoll(UUID)
}

// MARK: - Die

nonisolated struct DiceRollDieRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let index: Int
    let faceValue: Int
    let wasHeld: Bool
}

// MARK: - Roll

nonisolated struct DiceRollRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let sequence: Int
    let rolledAt: Date
    let status: DiceRollStatus
    let sidesPerDie: Int
    let dice: [DiceRollDieRecord]

    var result: DiceRollResult {
        DiceRollResult(
            values: dice
                .sorted { $0.index < $1.index }
                .map(\.faceValue)
        )
    }

    init(
        id: UUID = UUID(),
        sequence: Int,
        rolledAt: Date,
        status: DiceRollStatus,
        sidesPerDie: Int,
        dice: [DiceRollDieRecord]
    ) {
        self.id = id
        self.sequence = sequence
        self.rolledAt = rolledAt
        self.status = status
        self.sidesPerDie = sidesPerDie
        self.dice = dice
    }

    init(
        id: UUID = UUID(),
        sequence: Int,
        rolledAt: Date,
        status: DiceRollStatus,
        sidesPerDie: Int,
        result: DiceRollResult
    ) {
        self.init(
            id: id,
            sequence: sequence,
            rolledAt: rolledAt,
            status: status,
            sidesPerDie: sidesPerDie,
            dice: result.values.enumerated().map { index, faceValue in
                DiceRollDieRecord(
                    id: UUID(),
                    index: index,
                    faceValue: faceValue,
                    wasHeld: false
                )
            }
        )
    }
}

// MARK: - Round

nonisolated struct DiceGameRoundRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let sequence: Int
    let startedAt: Date
    let endedAt: Date?
    let diceRolls: [DiceRollRecord]

    var latestConfirmedRoll: DiceRollRecord? {
        diceRolls
            .filter { $0.status == .confirmed }
            .max { $0.sequence < $1.sequence }
    }

    init(
        id: UUID = UUID(),
        sequence: Int,
        startedAt: Date,
        endedAt: Date?,
        diceRolls: [DiceRollRecord]
    ) {
        self.id = id
        self.sequence = sequence
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.diceRolls = diceRolls
    }
}

// MARK: - Match

nonisolated struct DiceGameMatchRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let sessionContext: GameSessionContext
    let gameID: DiceGameID
    let outcome: GameOutcome
    let rounds: [DiceGameRoundRecord]
    let playedAt: Date

    var latestConfirmedRoll: DiceRollRecord? {
        rounds
            .sorted { $0.sequence > $1.sequence }
            .lazy
            .compactMap(\.latestConfirmedRoll)
            .first
    }

    init(
        id: UUID,
        sessionContext: GameSessionContext,
        gameID: DiceGameID,
        outcome: GameOutcome,
        rounds: [DiceGameRoundRecord],
        playedAt: Date
    ) {
        self.id = id
        self.sessionContext = sessionContext
        self.gameID = gameID
        self.outcome = outcome
        self.rounds = rounds
        self.playedAt = playedAt
    }
}

nonisolated enum DiceGameRecordSortOrder: Equatable, Sendable {

    case newest
    case oldest
}

nonisolated struct DiceGameRecordQuery: Equatable, Sendable {

    let gameID: DiceGameID?
    let outcome: GameOutcome?
    let dateInterval: DateInterval?
    let limit: Int?
    let sortOrder: DiceGameRecordSortOrder

    init(
        gameID: DiceGameID? = nil,
        outcome: GameOutcome? = nil,
        dateInterval: DateInterval? = nil,
        limit: Int? = nil,
        sortOrder: DiceGameRecordSortOrder = .newest
    ) {
        self.gameID = gameID
        self.outcome = outcome
        self.dateInterval = dateInterval
        self.limit = limit.map { max($0, 0) }
        self.sortOrder = sortOrder
    }
}

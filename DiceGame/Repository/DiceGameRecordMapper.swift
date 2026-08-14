//
//  DiceGameRecordMapper.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

nonisolated enum DiceGameRecordMapper {

    static func validate(_ record: DiceGameMatchRecord) throws {
        guard record.sessionContext.identity == record.gameID.identity else {
            throw DiceGameRecordStoreError.gameIdentityMismatch(record.id)
        }
        guard !record.diceResult.values.isEmpty,
              record.diceResult.values.allSatisfy(
                record.gameID.allowedFaceValues.contains
              ) else {
            throw DiceGameRecordStoreError.invalidDiceValues
        }
    }

    static func makeStoredMatch(
        from record: DiceGameMatchRecord,
        sequence: Int,
        session: StoredGameSession
    ) -> StoredGameMatch {
        let dice = makeDiceResults(from: record.diceResult.values)
        let roll = StoredDiceRoll(
            id: UUID(),
            sequence: 1,
            rolledAt: record.playedAt,
            statusRawValue: DiceRollStatus.confirmed.rawValue,
            diceCount: dice.count,
            sidesPerDie: record.gameID.allowedFaceValues.upperBound,
            dice: dice
        )
        let round = StoredGameRound(
            id: UUID(),
            sequence: 1,
            startedAt: record.playedAt,
            endedAt: record.playedAt,
            diceRolls: [roll]
        )
        return StoredGameMatch(
            id: record.id,
            sequence: sequence,
            outcomeRawValue: record.outcome.rawValue,
            playedAt: record.playedAt,
            session: session,
            rounds: [round]
        )
    }

    static func makeRecord(
        from match: StoredGameMatch,
        sessionContext: GameSessionContext
    ) throws -> DiceGameMatchRecord {
        guard let gameID = DiceGameID(rawValue: sessionContext.identity.variantID),
              gameID.identity == sessionContext.identity,
              let outcome = GameOutcome(rawValue: match.outcomeRawValue),
              let round = match.rounds.min(by: { $0.sequence < $1.sequence }),
              let roll = round.diceRolls.min(by: { $0.sequence < $1.sequence }),
              DiceRollStatus(rawValue: roll.statusRawValue) != nil else {
            throw DiceGameRecordStoreError.invalidStoredRecord(match.id)
        }

        let values = roll.dice
            .sorted { $0.index < $1.index }
            .map(\.faceValue)
        guard !values.isEmpty else {
            throw DiceGameRecordStoreError.invalidStoredRecord(match.id)
        }

        return DiceGameMatchRecord(
            id: match.id,
            sessionContext: sessionContext,
            gameID: gameID,
            outcome: outcome,
            diceResult: DiceRollResult(values: values),
            playedAt: match.playedAt
        )
    }

    static func replaceDiceResults(
        in roll: StoredDiceRoll,
        with values: [Int],
        modelContext: ModelContext
    ) {
        roll.dice.forEach(modelContext.delete)
        roll.dice.removeAll()
        roll.dice.append(contentsOf: makeDiceResults(from: values))
        roll.diceCount = values.count
    }

    private static func makeDiceResults(
        from values: [Int]
    ) -> [StoredDieResult] {
        values.enumerated().map { index, faceValue in
            StoredDieResult(
                id: UUID(),
                index: index,
                faceValue: faceValue,
                wasHeld: false
            )
        }
    }
}

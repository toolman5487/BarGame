//
//  DiceGameRecordMapper.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

nonisolated enum DiceGameRecordMapper {

    static func makeStoredMatch(
        from record: DiceGameMatchRecord,
        sequence: Int,
        session: StoredGameSession
    ) -> StoredGameMatch {
        return StoredGameMatch(
            id: record.id,
            sequence: sequence,
            outcomeRawValue: record.outcome.rawValue,
            playedAt: record.playedAt,
            session: session,
            rounds: record.rounds
                .sorted { $0.sequence < $1.sequence }
                .map(makeStoredRound)
        )
    }

    static func makeRecord(
        from match: StoredGameMatch,
        sessionContext: GameSessionContext
    ) throws -> DiceGameMatchRecord {
        guard let gameID = DiceGameID(rawValue: sessionContext.identity.variantID),
              gameID.identity == sessionContext.identity,
              let storedOutcome = MatchOutcome(
                  rawValue: match.outcomeRawValue
              ) else {
            throw DiceGameRecordStoreError.invalidStoredRecord(match.id)
        }

        let record = DiceGameMatchRecord(
            id: match.id,
            sessionContext: sessionContext,
            gameID: gameID,
            rounds: try match.rounds
                .sorted { $0.sequence < $1.sequence }
                .map { try makeRound(from: $0, matchID: match.id) },
            playedAt: match.playedAt
        )
        try DiceGameRecordValidator.validate(record)
        guard record.outcome == storedOutcome else {
            throw DiceGameRecordStoreError.invalidStoredRecord(match.id)
        }
        return record
    }

    static func makeStoredRound(
        from record: DiceGameRoundRecord
    ) -> StoredGameRound {
        StoredGameRound(
            id: record.id,
            sequence: record.sequence,
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            outcomeRawValue: record.outcome.rawValue,
            diceRolls: record.diceRolls
                .sorted { $0.sequence < $1.sequence }
                .map(makeStoredRoll)
        )
    }

    static func makeStoredRoll(
        from record: DiceRollRecord
    ) -> StoredDiceRoll {
        StoredDiceRoll(
            id: record.id,
            sequence: record.sequence,
            rolledAt: record.rolledAt,
            statusRawValue: record.status.rawValue,
            diceCount: record.dice.count,
            sidesPerDie: record.sidesPerDie,
            dice: record.dice
                .sorted { $0.index < $1.index }
                .map(makeStoredDie)
        )
    }

    static func makeStoredDie(
        from record: DiceRollDieRecord
    ) -> StoredDieResult {
        StoredDieResult(
            id: record.id,
            index: record.index,
            faceValue: record.faceValue,
            wasHeld: record.wasHeld
        )
    }

    private static func makeRound(
        from round: StoredGameRound,
        matchID: UUID
    ) throws -> DiceGameRoundRecord {
        guard let outcome = RoundOutcome(rawValue: round.outcomeRawValue) else {
            throw DiceGameRecordStoreError.invalidStoredRecord(matchID)
        }

        return DiceGameRoundRecord(
            id: round.id,
            sequence: round.sequence,
            startedAt: round.startedAt,
            endedAt: round.endedAt,
            outcome: outcome,
            diceRolls: try round.diceRolls
                .sorted { $0.sequence < $1.sequence }
                .map { try makeRoll(from: $0, matchID: matchID) }
        )
    }

    private static func makeRoll(
        from roll: StoredDiceRoll,
        matchID: UUID
    ) throws -> DiceRollRecord {
        guard let status = DiceRollStatus(rawValue: roll.statusRawValue),
              roll.diceCount == roll.dice.count else {
            throw DiceGameRecordStoreError.invalidStoredRecord(matchID)
        }

        return DiceRollRecord(
            id: roll.id,
            sequence: roll.sequence,
            rolledAt: roll.rolledAt,
            status: status,
            sidesPerDie: roll.sidesPerDie,
            dice: roll.dice
                .sorted { $0.index < $1.index }
                .map {
                    DiceRollDieRecord(
                        id: $0.id,
                        index: $0.index,
                        faceValue: $0.faceValue,
                        wasHeld: $0.wasHeld
                    )
                }
        )
    }

}

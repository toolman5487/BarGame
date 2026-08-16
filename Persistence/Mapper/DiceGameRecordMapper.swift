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

        guard !record.rounds.isEmpty,
              Set(record.rounds.map(\.id)).count == record.rounds.count,
              Set(record.rounds.map(\.sequence)).count == record.rounds.count,
              record.rounds.allSatisfy({ $0.sequence > 0 }) else {
            throw DiceGameRecordStoreError.invalidMatchStructure(record.id)
        }

        for round in record.rounds {
            guard !round.diceRolls.isEmpty,
                  Set(round.diceRolls.map(\.id)).count == round.diceRolls.count,
                  Set(round.diceRolls.map(\.sequence)).count
                    == round.diceRolls.count,
                  round.diceRolls.allSatisfy({ $0.sequence > 0 }),
                  round.latestConfirmedRoll != nil else {
                throw DiceGameRecordStoreError.invalidMatchStructure(record.id)
            }

            for roll in round.diceRolls {
                let dice = roll.dice
                guard roll.sidesPerDie
                        == record.gameID.allowedFaceValues.upperBound,
                      !dice.isEmpty,
                      Set(dice.map(\.id)).count == dice.count,
                      Set(dice.map(\.index)) == Set(dice.indices),
                      dice.allSatisfy({ die in
                          record.gameID.allowedFaceValues.contains(
                              die.faceValue
                          )
                      }) else {
                    throw DiceGameRecordStoreError.invalidDiceValues
                }
            }
        }

        guard record.latestConfirmedRoll != nil else {
            throw DiceGameRecordStoreError.invalidMatchStructure(record.id)
        }
    }

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
              let outcome = GameOutcome(rawValue: match.outcomeRawValue) else {
            throw DiceGameRecordStoreError.invalidStoredRecord(match.id)
        }

        let record = DiceGameMatchRecord(
            id: match.id,
            sessionContext: sessionContext,
            gameID: gameID,
            outcome: outcome,
            rounds: try match.rounds
                .sorted { $0.sequence < $1.sequence }
                .map { try makeRound(from: $0, matchID: match.id) },
            playedAt: match.playedAt
        )
        try validate(record)
        return record
    }

    static func updateStoredMatch(
        _ match: StoredGameMatch,
        from record: DiceGameMatchRecord,
        modelContext: ModelContext
    ) {
        match.outcomeRawValue = record.outcome.rawValue
        match.playedAt = record.playedAt
        synchronizeRounds(
            in: match,
            with: record.rounds,
            modelContext: modelContext
        )
    }

    private static func makeStoredRound(
        from record: DiceGameRoundRecord
    ) -> StoredGameRound {
        StoredGameRound(
            id: record.id,
            sequence: record.sequence,
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            diceRolls: record.diceRolls
                .sorted { $0.sequence < $1.sequence }
                .map(makeStoredRoll)
        )
    }

    private static func makeStoredRoll(
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

    private static func makeStoredDie(
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
        DiceGameRoundRecord(
            id: round.id,
            sequence: round.sequence,
            startedAt: round.startedAt,
            endedAt: round.endedAt,
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

    private static func synchronizeRounds(
        in match: StoredGameMatch,
        with records: [DiceGameRoundRecord],
        modelContext: ModelContext
    ) {
        let recordIDs = Set(records.map(\.id))
        let removedRounds = match.rounds.filter { !recordIDs.contains($0.id) }
        match.rounds.removeAll { !recordIDs.contains($0.id) }
        removedRounds.forEach(modelContext.delete)

        let roundsByID = Dictionary(
            uniqueKeysWithValues: match.rounds.map { ($0.id, $0) }
        )
        for record in records.sorted(by: { $0.sequence < $1.sequence }) {
            if let round = roundsByID[record.id] {
                round.sequence = record.sequence
                round.startedAt = record.startedAt
                round.endedAt = record.endedAt
                synchronizeRolls(
                    in: round,
                    with: record.diceRolls,
                    modelContext: modelContext
                )
            } else {
                match.rounds.append(makeStoredRound(from: record))
            }
        }
    }

    private static func synchronizeRolls(
        in round: StoredGameRound,
        with records: [DiceRollRecord],
        modelContext: ModelContext
    ) {
        let recordIDs = Set(records.map(\.id))
        let removedRolls = round.diceRolls.filter { !recordIDs.contains($0.id) }
        round.diceRolls.removeAll { !recordIDs.contains($0.id) }
        removedRolls.forEach(modelContext.delete)

        let rollsByID = Dictionary(
            uniqueKeysWithValues: round.diceRolls.map { ($0.id, $0) }
        )
        for record in records.sorted(by: { $0.sequence < $1.sequence }) {
            if let roll = rollsByID[record.id] {
                roll.sequence = record.sequence
                roll.rolledAt = record.rolledAt
                roll.statusRawValue = record.status.rawValue
                roll.diceCount = record.dice.count
                roll.sidesPerDie = record.sidesPerDie
                synchronizeDice(
                    in: roll,
                    with: record.dice,
                    modelContext: modelContext
                )
            } else {
                round.diceRolls.append(makeStoredRoll(from: record))
            }
        }
    }

    private static func synchronizeDice(
        in roll: StoredDiceRoll,
        with records: [DiceRollDieRecord],
        modelContext: ModelContext
    ) {
        let recordIDs = Set(records.map(\.id))
        let removedDice = roll.dice.filter { !recordIDs.contains($0.id) }
        roll.dice.removeAll { !recordIDs.contains($0.id) }
        removedDice.forEach(modelContext.delete)

        let diceByID = Dictionary(
            uniqueKeysWithValues: roll.dice.map { ($0.id, $0) }
        )
        for record in records.sorted(by: { $0.index < $1.index }) {
            if let die = diceByID[record.id] {
                die.index = record.index
                die.faceValue = record.faceValue
                die.wasHeld = record.wasHeld
            } else {
                roll.dice.append(makeStoredDie(from: record))
            }
        }
    }
}

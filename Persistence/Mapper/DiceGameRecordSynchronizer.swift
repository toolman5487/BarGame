//
//  DiceGameRecordSynchronizer.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation
import SwiftData

nonisolated enum DiceGameRecordSynchronizer {

    static func update(
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
                round.outcomeRawValue = record.outcome.rawValue
                synchronizeRolls(
                    in: round,
                    with: record.diceRolls,
                    modelContext: modelContext
                )
            } else {
                match.rounds.append(
                    DiceGameRecordMapper.makeStoredRound(from: record)
                )
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
                round.diceRolls.append(
                    DiceGameRecordMapper.makeStoredRoll(from: record)
                )
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
                roll.dice.append(
                    DiceGameRecordMapper.makeStoredDie(from: record)
                )
            }
        }
    }
}

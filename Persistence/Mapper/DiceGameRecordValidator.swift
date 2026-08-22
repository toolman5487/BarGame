//
//  DiceGameRecordValidator.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation

nonisolated enum DiceGameRecordValidator {

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

        let allRolls = record.rounds.flatMap(\.diceRolls)
        let allDice = allRolls.flatMap(\.dice)
        guard Set(allRolls.map(\.id)).count == allRolls.count,
              Set(allDice.map(\.id)).count == allDice.count else {
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
                      record.gameID.dicePreset.allowedDiceCount.contains(
                          dice.count
                      ),
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
}

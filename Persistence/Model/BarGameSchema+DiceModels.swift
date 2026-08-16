//
//  BarGameSchema+DiceModels.swift
//  BarGame
//
//  Created by Codex on 2026/8/16.
//

import Foundation
import SwiftData

extension BarGameSchema {

    @Model
    nonisolated final class DiceRoll {

        @Attribute(.unique)
        var id: UUID

        var sequence: Int
        var rolledAt: Date
        var statusRawValue: String
        var diceCount: Int
        var sidesPerDie: Int
        var round: GameRound?

        @Relationship(deleteRule: .cascade, inverse: \BarGameSchema.DieResult.roll)
        var dice: [DieResult]

        init(
            id: UUID,
            sequence: Int,
            rolledAt: Date,
            statusRawValue: String,
            diceCount: Int,
            sidesPerDie: Int,
            round: GameRound? = nil,
            dice: [DieResult] = []
        ) {
            self.id = id
            self.sequence = sequence
            self.rolledAt = rolledAt
            self.statusRawValue = statusRawValue
            self.diceCount = diceCount
            self.sidesPerDie = sidesPerDie
            self.round = round
            self.dice = dice
        }
    }

    @Model
    nonisolated final class DieResult {

        @Attribute(.unique)
        var id: UUID

        var index: Int
        var faceValue: Int
        var wasHeld: Bool
        var roll: DiceRoll?

        init(
            id: UUID,
            index: Int,
            faceValue: Int,
            wasHeld: Bool,
            roll: DiceRoll? = nil
        ) {
            self.id = id
            self.index = index
            self.faceValue = faceValue
            self.wasHeld = wasHeld
            self.roll = roll
        }
    }
}

typealias StoredDiceRoll = BarGameSchema.DiceRoll
typealias StoredDieResult = BarGameSchema.DieResult

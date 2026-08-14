//
//  DiceGameMatchRecord.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import Foundation

nonisolated struct DiceGameMatchRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let gameID: DiceGameID
    let outcome: GameOutcome
    let diceResult: DiceRollResult
    let playedAt: Date
}

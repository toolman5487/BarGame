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

nonisolated struct DiceGameMatchRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let sessionContext: GameSessionContext
    let gameID: DiceGameID
    let outcome: GameOutcome
    let diceResult: DiceRollResult
    let playedAt: Date

    init(
        id: UUID,
        sessionContext: GameSessionContext,
        gameID: DiceGameID,
        outcome: GameOutcome,
        diceResult: DiceRollResult,
        playedAt: Date
    ) {
        self.id = id
        self.sessionContext = sessionContext
        self.gameID = gameID
        self.outcome = outcome
        self.diceResult = diceResult
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

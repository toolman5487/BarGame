//
//  BarGameSchemaV1+CoreModels.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

extension BarGameSchemaV1 {

    @Model
    nonisolated final class GameEvent {

        @Attribute(.unique)
        var id: UUID

        var startedAt: Date
        var endedAt: Date?
        var timeZoneIdentifier: String
        var locationName: String?
        var locality: String?

        @Relationship(deleteRule: .cascade, inverse: \BarGameSchemaV1.GameSession.event)
        var sessions: [GameSession]

        init(
            id: UUID,
            startedAt: Date,
            endedAt: Date? = nil,
            timeZoneIdentifier: String,
            locationName: String? = nil,
            locality: String? = nil,
            sessions: [GameSession] = []
        ) {
            self.id = id
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.timeZoneIdentifier = timeZoneIdentifier
            self.locationName = locationName
            self.locality = locality
            self.sessions = sessions
        }
    }

    @Model
    nonisolated final class GameSession {

        @Attribute(.unique)
        var id: UUID

        var categoryID: String
        var gameTypeID: String
        var variantID: String
        var rulesVersion: Int
        var startedAt: Date
        var endedAt: Date?
        var event: GameEvent?

        @Relationship(deleteRule: .cascade, inverse: \BarGameSchemaV1.GameMatch.session)
        var matches: [GameMatch]

        init(
            id: UUID,
            categoryID: String,
            gameTypeID: String,
            variantID: String,
            rulesVersion: Int,
            startedAt: Date,
            endedAt: Date? = nil,
            event: GameEvent? = nil,
            matches: [GameMatch] = []
        ) {
            self.id = id
            self.categoryID = categoryID
            self.gameTypeID = gameTypeID
            self.variantID = variantID
            self.rulesVersion = rulesVersion
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.event = event
            self.matches = matches
        }
    }

    @Model
    nonisolated final class GameMatch {

        @Attribute(.unique)
        var id: UUID

        var sequence: Int
        var outcomeRawValue: String
        var playedAt: Date
        var session: GameSession?

        @Relationship(deleteRule: .cascade, inverse: \BarGameSchemaV1.GameRound.match)
        var rounds: [GameRound]

        init(
            id: UUID,
            sequence: Int,
            outcomeRawValue: String,
            playedAt: Date,
            session: GameSession? = nil,
            rounds: [GameRound] = []
        ) {
            self.id = id
            self.sequence = sequence
            self.outcomeRawValue = outcomeRawValue
            self.playedAt = playedAt
            self.session = session
            self.rounds = rounds
        }
    }

    @Model
    nonisolated final class GameRound {

        @Attribute(.unique)
        var id: UUID

        var sequence: Int
        var startedAt: Date
        var endedAt: Date?
        var match: GameMatch?

        @Relationship(deleteRule: .cascade, inverse: \BarGameSchemaV1.DiceRoll.round)
        var diceRolls: [DiceRoll]

        init(
            id: UUID,
            sequence: Int,
            startedAt: Date,
            endedAt: Date? = nil,
            match: GameMatch? = nil,
            diceRolls: [DiceRoll] = []
        ) {
            self.id = id
            self.sequence = sequence
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.match = match
            self.diceRolls = diceRolls
        }
    }
}

typealias StoredGameEvent = BarGameSchemaV1.GameEvent
typealias StoredGameSession = BarGameSchemaV1.GameSession
typealias StoredGameMatch = BarGameSchemaV1.GameMatch
typealias StoredGameRound = BarGameSchemaV1.GameRound

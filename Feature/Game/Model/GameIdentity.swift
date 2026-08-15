//
//  GameIdentity.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation

nonisolated enum GameCategoryID: String, Codable, Hashable, Sendable {

    case dice
}

nonisolated enum GameTypeID: String, Codable, Hashable, Sendable {

    case standard
    case bluffing
    case combination
    case comparison
    case prediction
    case target
}

nonisolated struct GameIdentity: Codable, Equatable, Hashable, Sendable {

    let categoryID: GameCategoryID
    let typeID: GameTypeID
    let variantID: String
}

nonisolated struct GameEventContext: Equatable, Sendable {

    let id: UUID
    let startedAt: Date
    let timeZoneIdentifier: String
    let location: GameLocationSnapshot?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        timeZoneIdentifier: String = TimeZone.current.identifier,
        location: GameLocationSnapshot? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.location = location
    }
}

nonisolated struct GameSessionContext: Equatable, Sendable {

    let id: UUID
    let event: GameEventContext
    let identity: GameIdentity
    let rulesVersion: Int
    let startedAt: Date

    init(
        id: UUID = UUID(),
        event: GameEventContext,
        identity: GameIdentity,
        rulesVersion: Int,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.event = event
        self.identity = identity
        self.rulesVersion = max(rulesVersion, 1)
        self.startedAt = startedAt
    }
}

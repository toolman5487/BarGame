//
//  BarGameSchema.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import SwiftData

nonisolated enum BarGameSchema: VersionedSchema {

    static let versionIdentifier = Schema.Version(1, 0, 0)

    static let models: [any PersistentModel.Type] = [
        GameEvent.self,
        GameSession.self,
        GameMatch.self,
        GameRound.self,
        DiceRoll.self,
        DieResult.self,
    ]
}

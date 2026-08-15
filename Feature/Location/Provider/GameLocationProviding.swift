//
//  GameLocationProviding.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated protocol GameLocationProviding: Sendable {

    func authorizationState() -> GameLocationAuthorizationState
    func currentLocationSnapshot() async throws -> GameLocationSnapshot
}

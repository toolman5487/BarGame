//
//  GameLocationCaching.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated protocol GameLocationCaching: Sendable {

    func snapshot() async -> GameLocationSnapshot?
    func save(_ snapshot: GameLocationSnapshot) async
    func removeSnapshot() async
}

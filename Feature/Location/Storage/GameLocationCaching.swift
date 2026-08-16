//
//  GameLocationCaching.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated protocol GameLocationCaching: Sendable {

    func snapshot() async -> GameCurrentLocationSnapshot?
    func save(_ snapshot: GameCurrentLocationSnapshot) async
    func removeSnapshot() async
}

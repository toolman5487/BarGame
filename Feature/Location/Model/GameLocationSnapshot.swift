//
//  GameLocationSnapshot.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated struct GameLocationSnapshot: Codable, Equatable, Sendable {

    let name: String
    let locality: String?
}

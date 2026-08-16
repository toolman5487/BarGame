//
//  GameCurrentLocationSnapshot.swift
//  BarGame
//
//  Created by Codex on 2026/8/16.
//

import Foundation

nonisolated struct GameCoordinate: Codable, Equatable, Sendable {

    let latitude: Double
    let longitude: Double
}

nonisolated struct GameCurrentLocationSnapshot: Codable, Equatable, Sendable {

    let coordinate: GameCoordinate
    let place: GameLocationSnapshot
    let horizontalAccuracy: Double
    let capturedAt: Date
}

nonisolated enum GameCurrentLocationState: Equatable, Sendable {

    case idle
    case refreshing(cachedSnapshot: GameCurrentLocationSnapshot?)
    case located(GameCurrentLocationSnapshot)
    case failed(
        cachedSnapshot: GameCurrentLocationSnapshot?,
        error: GameLocationProviderError?
    )

    var snapshot: GameCurrentLocationSnapshot? {
        switch self {
        case .idle:
            return nil

        case .refreshing(let cachedSnapshot):
            return cachedSnapshot

        case .located(let snapshot):
            return snapshot

        case .failed(let cachedSnapshot, _):
            return cachedSnapshot
        }
    }
}

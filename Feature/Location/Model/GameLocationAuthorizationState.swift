//
//  GameLocationAuthorizationState.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated enum GameLocationAuthorizationState: Equatable, Sendable {

    case notDetermined
    case authorized
    case denied
    case restricted
    case servicesDisabled
}

//
//  GameHistoryStore.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

nonisolated enum GameHistoryStoreError: Error, Equatable, Sendable {

    case eventContextMismatch(UUID)
    case sessionContextMismatch(UUID)
    case invalidStoredSession(UUID)
}

@ModelActor
actor GameHistoryStore {}

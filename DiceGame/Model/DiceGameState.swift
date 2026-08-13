//
//  DiceGameState.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Foundation

// MARK: - View Mode

nonisolated enum DiceGameViewMode: Sendable {

    case perspective
    case topDown
}

// MARK: - Control

nonisolated enum DiceGameControl: Int, CaseIterable, Sendable {

    case lock
    case action
    case exit
}

// MARK: - Configuration

nonisolated struct DiceGameConfiguration: Sendable {

    static let standard = DiceGameConfiguration(
        title: "骰子",
        initialDiceCount: 1,
        maximumDiceCount: 8,
        unlockedHintText: "搖晃手機讓骰子晃動",
        lockedHintText: "骰子已鎖定"
    )

    let title: String
    let initialDiceCount: Int
    let maximumDiceCount: Int
    let unlockedHintText: String
    let lockedHintText: String

    var initialState: DiceGameState {
        DiceGameState(
            viewMode: .perspective,
            isDiceLocked: false
        )
    }
}

// MARK: - State

nonisolated struct DiceGameState: Equatable, Sendable {

    let viewMode: DiceGameViewMode
    let isDiceLocked: Bool

    func isEnabled(_ control: DiceGameControl) -> Bool {
        switch control {
        case .lock:
            return viewMode == .perspective
        case .action:
            return true
        case .exit:
            return true
        }
    }
}

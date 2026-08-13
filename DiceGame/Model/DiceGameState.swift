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

    case action
    case exit
}

// MARK: - Configuration

nonisolated struct DiceGameConfiguration: Sendable {

    static let standard = DiceGameConfiguration(
        title: "骰子",
        initialDiceCount: 1,
        maximumDiceCount: 8
    )

    let title: String
    let initialDiceCount: Int
    let maximumDiceCount: Int

    var initialState: DiceGameState {
        DiceGameState(
            viewMode: .perspective,
            isDiceLocked: false,
            result: nil
        )
    }
}

// MARK: - Result

nonisolated struct DiceRollResult: Equatable, Sendable {

    let values: [Int]

    var total: Int {
        values.reduce(0, +)
    }

    func count(of value: Int) -> Int {
        values.count { $0 == value }
    }
}

// MARK: - State

nonisolated struct DiceGameState: Equatable, Sendable {

    let viewMode: DiceGameViewMode
    let isDiceLocked: Bool
    let result: DiceRollResult?
}

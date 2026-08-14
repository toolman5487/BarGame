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

// MARK: - Configuration

nonisolated enum DiceCountState: Equatable, Sendable {

    case defaulted(diceCount: Int)
    case empty
    case configured(diceCount: Int)

    init(
        resolving diceCount: Int?,
        default defaultDiceCount: Int,
        within allowedRange: ClosedRange<Int>
    ) {
        switch diceCount {
        case nil:
            self = .defaulted(
                diceCount: Self.clamped(defaultDiceCount, to: allowedRange)
            )

        case 0:
            self = .empty

        case .some(let diceCount):
            self = .configured(
                diceCount: Self.clamped(diceCount, to: allowedRange)
            )
        }
    }

    func limited(to allowedRange: ClosedRange<Int>) -> DiceCountState {
        switch self {
        case .defaulted(let diceCount):
            return .defaulted(
                diceCount: Self.clamped(diceCount, to: allowedRange)
            )

        case .empty:
            return .empty

        case .configured(let diceCount):
            return .configured(
                diceCount: Self.clamped(diceCount, to: allowedRange)
            )
        }
    }

    private static func clamped(
        _ diceCount: Int,
        to allowedRange: ClosedRange<Int>
    ) -> Int {
        min(max(diceCount, allowedRange.lowerBound), allowedRange.upperBound)
    }
}

nonisolated struct DiceGameConfiguration: Sendable {

    static let standard = DiceGameConfiguration(
        title: "骰子",
        initialDiceCount: 1,
        maximumDiceCount: 8,
        hintText: "搖晃手機讓骰子晃動"
    )

    let title: String
    let initialDiceCountState: DiceCountState
    let maximumDiceCount: Int
    let hintText: String

    init(
        title: String,
        initialDiceCount: Int?,
        maximumDiceCount: Int,
        hintText: String
    ) {
        let validatedMaximumDiceCount = max(maximumDiceCount, 1)
        self.init(
            title: title,
            initialDiceCountState: DiceCountState(
                resolving: initialDiceCount,
                default: 1,
                within: 1...validatedMaximumDiceCount
            ),
            maximumDiceCount: validatedMaximumDiceCount,
            hintText: hintText
        )
    }

    init(
        title: String,
        initialDiceCountState: DiceCountState,
        maximumDiceCount: Int,
        hintText: String
    ) {
        let validatedMaximumDiceCount = max(maximumDiceCount, 1)
        self.title = title
        self.initialDiceCountState = initialDiceCountState.limited(
            to: 1...validatedMaximumDiceCount
        )
        self.maximumDiceCount = validatedMaximumDiceCount
        self.hintText = hintText
    }

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

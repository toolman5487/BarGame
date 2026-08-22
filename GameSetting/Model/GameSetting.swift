//
//  GameSetting.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

// MARK: - Setting

nonisolated enum GameSetting: Equatable, Sendable {

    case diceCount(value: Int, allowedRange: ClosedRange<Int>)

    static func standard(for gameID: DiceGameID) -> [GameSetting] {
        let preset = gameID.dicePreset

        return [
            .diceCount(
                value: preset.defaultDiceCount,
                allowedRange: preset.allowedDiceCount
            ),
        ]
    }

    func applying(_ change: GameSettingChange) -> GameSetting {
        switch (self, change) {
        case (.diceCount(_, let allowedRange), .diceCount(let value)):
            return .diceCount(
                value: min(max(value, allowedRange.lowerBound), allowedRange.upperBound),
                allowedRange: allowedRange
            )
        }
    }
}

// MARK: - Change

nonisolated enum GameSettingChange: Equatable, Sendable {

    case diceCount(Int)
}

// MARK: - Dice Settings

nonisolated struct DiceGameSettings: Equatable, Sendable {

    static let standard = DiceGameSettings(
        initialDiceCount: 1,
        maximumDiceCount: 8
    )

    let initialDiceCountState: DiceCountState
    let maximumDiceCount: Int

    init(initialDiceCount: Int?, maximumDiceCount: Int) {
        let validatedMaximumDiceCount = max(maximumDiceCount, 1)
        initialDiceCountState = DiceCountState(
            resolving: initialDiceCount,
            default: 1,
            within: 1...validatedMaximumDiceCount
        )
        self.maximumDiceCount = validatedMaximumDiceCount
    }
}

// MARK: - Launch Configuration

nonisolated enum GameLaunchConfiguration: Equatable, Sendable {

    case dice(
        gameID: DiceGameID,
        settings: DiceGameSettings,
        location: GameLocationSnapshot?
    )
}

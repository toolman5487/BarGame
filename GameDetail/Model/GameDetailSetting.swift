//
//  GameDetailSetting.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

// MARK: - Setting

nonisolated enum GameDetailSetting: Equatable, Sendable {

    case diceCount(value: Int, allowedRange: ClosedRange<Int>)

    static func standard(for gameID: DiceGameID) -> [GameDetailSetting] {
        switch gameID {
        case .dice:
            return [
                .diceCount(value: 1, allowedRange: 1...8),
            ]

        case .playingCards, .roulette, .sicBo, .blackjack, .bingo:
            return []
        }
    }

    func applying(_ change: GameDetailSettingChange) -> GameDetailSetting {
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

nonisolated enum GameDetailSettingChange: Equatable, Sendable {

    case diceCount(Int)
}

// MARK: - Dice Settings

nonisolated struct DiceGameSettings: Equatable, Sendable {

    static let standard = DiceGameSettings(
        initialDiceCount: 1,
        maximumDiceCount: 8
    )

    let initialDiceCount: Int
    let maximumDiceCount: Int

    init(initialDiceCount: Int, maximumDiceCount: Int) {
        let validatedMaximumDiceCount = max(maximumDiceCount, 1)
        self.initialDiceCount = min(
            max(initialDiceCount, 1),
            validatedMaximumDiceCount
        )
        self.maximumDiceCount = validatedMaximumDiceCount
    }
}

// MARK: - Launch Configuration

nonisolated enum GameLaunchConfiguration: Equatable, Sendable {

    case dice(DiceGameSettings)
    case unavailable(DiceGameID)
}

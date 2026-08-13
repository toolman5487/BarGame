//
//  DiceGame.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

// MARK: - DiceGameID

nonisolated enum DiceGameID: String, CaseIterable, Codable, Hashable, Sendable {

    case dice
    case liarsDice
    case mia
    case dicePoker
    case highLow
    case oddEven
    case sevenElevenDouble
}

// MARK: - DiceGame

nonisolated struct DiceGame: Identifiable, Equatable, Sendable {

    let id: DiceGameID
    let title: String

    init(id: DiceGameID, title: String? = nil) {
        self.id = id
        self.title = title ?? id.title
    }
}

// MARK: - Dice Game Preset

nonisolated struct DiceGamePreset: Equatable, Sendable {

    let defaultDiceCount: Int
    let allowedDiceCount: ClosedRange<Int>

    init(
        defaultDiceCount: Int,
        allowedDiceCount: ClosedRange<Int>
    ) {
        self.allowedDiceCount = allowedDiceCount
        self.defaultDiceCount = min(
            max(defaultDiceCount, allowedDiceCount.lowerBound),
            allowedDiceCount.upperBound
        )
    }
}

extension DiceGameID {

    nonisolated var title: String {
        switch self {
        case .dice:
            return "骰子"
        case .liarsDice:
            return "吹牛"
        case .mia:
            return "Mia"
        case .dicePoker:
            return "骰子撲克"
        case .highLow:
            return "比大小"
        case .oddEven:
            return "猜單雙"
        case .sevenElevenDouble:
            return "7／11／Double"
        }
    }

    nonisolated var dicePreset: DiceGamePreset {
        switch self {
        case .dice:
            return DiceGamePreset(
                defaultDiceCount: 1,
                allowedDiceCount: 1...8
            )

        case .liarsDice:
            return DiceGamePreset(
                defaultDiceCount: 5,
                allowedDiceCount: 1...5
            )

        case .mia, .oddEven, .sevenElevenDouble:
            return DiceGamePreset(
                defaultDiceCount: 2,
                allowedDiceCount: 2...2
            )

        case .dicePoker:
            return DiceGamePreset(
                defaultDiceCount: 5,
                allowedDiceCount: 5...5
            )

        case .highLow:
            return DiceGamePreset(
                defaultDiceCount: 2,
                allowedDiceCount: 1...8
            )

        }
    }
}

// MARK: - Catalog

nonisolated enum DiceGameCatalog {

    static let firstPhaseVerbalGames: [DiceGame] = [
        DiceGame(id: .liarsDice),
        DiceGame(id: .mia),
        DiceGame(id: .dicePoker),
        DiceGame(id: .highLow),
        DiceGame(id: .oddEven),
        DiceGame(id: .sevenElevenDouble),
    ]
}

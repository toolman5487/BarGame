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
    case playingCards
    case roulette
    case sicBo
    case blackjack
    case bingo
}

// MARK: - DiceGame

nonisolated struct DiceGame: Identifiable, Equatable, Sendable {

    let id: DiceGameID
    let title: String
}

//
//  Game.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

// MARK: - GameID

nonisolated enum GameID: String, CaseIterable, Codable, Hashable, Sendable {

    case dice
    case playingCards
    case roulette
    case sicBo
    case blackjack
    case bingo
}

// MARK: - Game

nonisolated struct Game: Identifiable, Equatable, Sendable {

    let id: GameID
    let title: String
}

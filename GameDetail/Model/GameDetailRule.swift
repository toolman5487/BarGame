//
//  GameDetailRule.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated struct GameDetailRule: Identifiable, Equatable, Sendable {

    var id: Int { step }

    let step: Int
    let text: String
}

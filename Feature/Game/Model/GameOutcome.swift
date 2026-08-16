//
//  GameOutcome.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import Foundation

nonisolated enum RoundOutcome: String, Codable, Equatable, Sendable {

    case win
    case loss
}

nonisolated enum MatchOutcome: String, Codable, Equatable, Sendable {

    case win
    case loss
    case draw

    init(roundOutcomes: some Sequence<RoundOutcome>) {
        var wins = 0
        var losses = 0

        for outcome in roundOutcomes {
            switch outcome {
            case .win:
                wins += 1

            case .loss:
                losses += 1
            }
        }

        if wins > losses {
            self = .win
        } else if wins < losses {
            self = .loss
        } else {
            self = .draw
        }
    }
}

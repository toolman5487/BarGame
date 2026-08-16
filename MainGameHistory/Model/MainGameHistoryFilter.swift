//
//  MainGameHistoryFilter.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

// MARK: - Filter

nonisolated struct MainGameHistoryFilter: Equatable, Sendable {

    static let standard = MainGameHistoryFilter()

    let gameID: DiceGameID?
    let outcome: MatchOutcome?
    let sortOrder: DiceGameRecordSortOrder

    init(
        gameID: DiceGameID? = nil,
        outcome: MatchOutcome? = nil,
        sortOrder: DiceGameRecordSortOrder = .newest
    ) {
        self.gameID = gameID
        self.outcome = outcome
        self.sortOrder = sortOrder
    }

    var gameTitle: String {
        gameID?.title ?? "全部遊戲"
    }

    var hasActiveConditions: Bool {
        gameID != nil || outcome != nil
    }

    func applying(_ change: MainGameHistoryFilterChange) -> MainGameHistoryFilter {
        switch change {
        case .game(let gameID):
            return MainGameHistoryFilter(
                gameID: gameID,
                outcome: outcome,
                sortOrder: sortOrder
            )

        case .outcome(let outcome):
            return MainGameHistoryFilter(
                gameID: gameID,
                outcome: outcome,
                sortOrder: sortOrder
            )

        case .sortOrder(let sortOrder):
            return MainGameHistoryFilter(
                gameID: gameID,
                outcome: outcome,
                sortOrder: sortOrder
            )
        }
    }

    var query: DiceGameRecordQuery {
        DiceGameRecordQuery(
            gameID: gameID,
            outcome: outcome,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Change

nonisolated enum MainGameHistoryFilterChange: Equatable, Sendable {

    case game(DiceGameID?)
    case outcome(MatchOutcome?)
    case sortOrder(DiceGameRecordSortOrder)
}

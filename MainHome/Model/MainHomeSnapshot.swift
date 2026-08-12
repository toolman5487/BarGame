//
//  MainHomeSnapshot.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

// MARK: - Section

nonisolated enum MainHomeSection: Equatable, Sendable {

    case dicePreview
    case gameResults([GameOverview])
    case gameList([Game])

    var headerTitle: String {
        switch self {
        case .dicePreview:
            return ""

        case .gameResults:
            return "遊戲戰績"

        case .gameList:
            return "遊戲列表"
        }
    }
}

// MARK: - Snapshot

nonisolated struct MainHomeSnapshot: Equatable, Sendable {

    let sections: [MainHomeSection]
}

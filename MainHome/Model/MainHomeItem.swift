//
//  MainHomeItem.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/9.
//

import Foundation

// MARK: - Item

nonisolated enum MainHomeItem: Int, CaseIterable, Sendable {

    case dicePreview
    case gameList
}

// MARK: - Section

nonisolated struct MainHomeSection: Equatable, Sendable {

    let headerTitle: String
    let items: [MainHomeItem]
}

// MARK: - Sections

extension MainHomeSection {

    static let standard: [MainHomeSection] = [
        MainHomeSection(
            headerTitle: "",
            items: [.dicePreview]
        ),
        MainHomeSection(
            headerTitle: "遊戲列表",
            items: [.gameList]
        ),
    ]
}

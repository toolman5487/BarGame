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
    case gameResults
}

// MARK: - Game

nonisolated struct MainHomeGame: Equatable, Sendable {

    let title: String
}

// MARK: - Game Result

nonisolated struct MainHomeGameResult: Equatable, Sendable {

    let title: String
    let detail: String
}

// MARK: - Section

nonisolated struct MainHomeSection: Equatable, Sendable {

    let headerTitle: String
    let items: [MainHomeItem]
}

// MARK: - Content

nonisolated struct MainHomeContent: Equatable, Sendable {

    let sections: [MainHomeSection]
    let games: [MainHomeGame]
    let results: [MainHomeGameResult]
}

// MARK: - Configuration

nonisolated struct MainHomeConfiguration: Sendable {

    /// 預設：戰績為空
    static let standard = MainHomeConfiguration(
        sections: MainHomeSection.standard,
        games: MainHomeGame.standardList,
        results: MainHomeGameResult.emptyList
    )

    let sections: [MainHomeSection]
    let games: [MainHomeGame]
    let results: [MainHomeGameResult]

    var initialContent: MainHomeContent {
        MainHomeContent(
            sections: sections,
            games: games,
            results: results
        )
    }
}

// MARK: - State

nonisolated enum MainHomeState: Equatable, Sendable {

    case idle
    case ready(MainHomeContent)
}

// MARK: - Sections

extension MainHomeSection {

    nonisolated static let standard: [MainHomeSection] = [
        MainHomeSection(
            headerTitle: "",
            items: [.dicePreview]
        ),
        MainHomeSection(
            headerTitle: "遊戲列表",
            items: [.gameList]
        ),
        MainHomeSection(
            headerTitle: "遊戲戰績",
            items: [.gameResults]
        ),
    ]
}

// MARK: - Games

extension MainHomeGame {

    nonisolated static let standardList: [MainHomeGame] = [
        MainHomeGame(title: "骰子"),
        MainHomeGame(title: "啤牌"),
        MainHomeGame(title: "輪盤"),
        MainHomeGame(title: "骰寶"),
        MainHomeGame(title: "二十一點"),
        MainHomeGame(title: "賓果"),
        MainHomeGame(title: "骰子"),
        MainHomeGame(title: "啤牌"),
        MainHomeGame(title: "輪盤"),
        MainHomeGame(title: "骰寶"),
        MainHomeGame(title: "二十一點"),
        MainHomeGame(title: "賓果"),
        MainHomeGame(title: "骰子"),
        MainHomeGame(title: "啤牌"),
        MainHomeGame(title: "輪盤"),
        MainHomeGame(title: "骰寶"),
        MainHomeGame(title: "二十一點"),
        MainHomeGame(title: "賓果")
    ]
}

// MARK: - Results

extension MainHomeGameResult {

    /// 空戰績
    nonisolated static let emptyList: [MainHomeGameResult] = []
}

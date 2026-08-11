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

nonisolated enum MainHomeFailure: Error, Equatable, Sendable {

    enum ConfigurationReason: Equatable, Sendable {
        case emptySections
        case emptySectionItems
        case missingGames
    }

    case contentUnavailable(reason: ConfigurationReason)
    case loadFailed

    var title: String {
        switch self {
        case .contentUnavailable:
            return "首頁暫時無法顯示"

        case .loadFailed:
            return "暫時無法載入首頁"
        }
    }

    var message: String {
        switch self {
        case .contentUnavailable:
            return "內容準備時發生問題，請稍後再回來看看。"

        case .loadFailed:
            return "請輕觸畫面重新載入；若仍無法顯示，請稍後再試。"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .contentUnavailable:
            return false

        case .loadFailed:
            return true
        }
    }

    var logDescription: String {
        switch self {
        case .contentUnavailable(let reason):
            return "MainHome configuration error: \(reason)"

        case .loadFailed:
            return "MainHome content loading failed"
        }
    }
}

nonisolated enum MainHomeState: Equatable, Sendable {

    case idle
    case loading
    case ready(MainHomeContent)
    case failed(MainHomeFailure)

    var content: MainHomeContent? {
        if case .ready(let content) = self {
            return content
        }
        return nil
    }

    var failure: MainHomeFailure? {
        if case .failed(let failure) = self {
            return failure
        }
        return nil
    }
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

    nonisolated static let emptyList: [MainHomeGameResult] = []
}

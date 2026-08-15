//
//  MainGameHistoryState.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

// MARK: - Empty Reason

nonisolated enum MainGameHistoryEmptyReason: Equatable, Sendable {

    case noRecords
    case noFilterResults

    var title: String {
        switch self {
        case .noRecords:
            return "尚無戰績"

        case .noFilterResults:
            return "沒有符合條件的戰績"
        }
    }

    var message: String {
        switch self {
        case .noRecords:
            return "完成一場遊戲後會顯示在這裡"

        case .noFilterResults:
            return "請調整遊戲、結果或時間篩選"
        }
    }
}

// MARK: - Failure

nonisolated enum MainGameHistoryFailure: Error, Equatable, Sendable {

    case loadFailed

    var title: String {
        "無法載入戰績"
    }

    var message: String {
        "請輕觸畫面重試"
    }
}

// MARK: - Content State

nonisolated enum MainGameHistoryContentState: Equatable, Sendable {

    case idle
    case loading
    case empty(MainGameHistoryEmptyReason)
    case records([MainGameHistoryRecordItem])
    case failed(MainGameHistoryFailure)
}

// MARK: - View State

nonisolated struct MainGameHistoryViewState: Equatable, Sendable {

    static let initial = MainGameHistoryViewState(
        filter: .standard,
        contentState: .idle
    )

    let filter: MainGameHistoryFilter
    let contentState: MainGameHistoryContentState

    var records: [MainGameHistoryRecordItem] {
        guard case .records(let records) = contentState else {
            return []
        }
        return records
    }
}

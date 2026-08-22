//
//  RoundDetailState.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation

nonisolated enum RoundDetailFailure: Error, Equatable, Sendable {

    case matchNotFound
    case roundNotFound
    case invalidRoundData
    case loadFailed

    var title: String {
        switch self {
        case .matchNotFound:
            return "找不到這場戰績"

        case .roundNotFound:
            return "找不到這個回合"

        case .invalidRoundData:
            return "回合資料不完整"

        case .loadFailed:
            return "無法載入回合詳情"
        }
    }

    var message: String {
        switch self {
        case .matchNotFound, .roundNotFound:
            return "這筆紀錄可能已被移除"

        case .invalidRoundData:
            return "這個回合沒有可顯示的骰子結果"

        case .loadFailed:
            return "請輕觸畫面重試"
        }
    }

    var canRetry: Bool {
        self == .loadFailed
    }
}

nonisolated enum RoundDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case content(RoundDetailPresentation)
    case failed(RoundDetailFailure)
}

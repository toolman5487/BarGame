//
//  MatchDetailState.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Foundation

nonisolated enum MatchDetailFailure: Error, Equatable, Sendable {

    case recordNotFound
    case loadFailed

    var title: String {
        switch self {
        case .recordNotFound:
            return "找不到這場戰績"

        case .loadFailed:
            return "無法載入戰績"
        }
    }

    var message: String {
        switch self {
        case .recordNotFound:
            return "這筆紀錄可能已被移除"

        case .loadFailed:
            return "請輕觸畫面重試"
        }
    }
}

nonisolated enum MatchDetailViewState: Equatable, Sendable {

    case idle
    case loading
    case content(MatchDetailPresentation)
    case failed(MatchDetailFailure)
}

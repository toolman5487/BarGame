//
//  MainHomeState.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

// MARK: - Failure

nonisolated enum MainHomeFailure: Error, Equatable, Sendable {

    enum ConfigurationReason: Equatable, Sendable {
        case emptySections
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

// MARK: - State

nonisolated enum MainHomeState: Equatable, Sendable {

    case idle
    case loading
    case ready(MainHomeSnapshot)
    case failed(MainHomeFailure)

    var snapshot: MainHomeSnapshot? {
        if case .ready(let snapshot) = self {
            return snapshot
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

// MARK: - Location State

nonisolated enum MainHomeLocationState: Equatable, Sendable {

    case idle
    case refreshing
    case failed
}

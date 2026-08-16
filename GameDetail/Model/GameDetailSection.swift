//
//  GameDetailSection.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailSection: Equatable, Sendable {

    case rules([GameDetailRule])
    case settings([GameDetailSetting])
    case location(GameDetailLocationState)
    case statistics(GameDetailStatisticsState)
    case recentRecords(GameDetailRecentRecordsState)

    static func standard(for gameID: DiceGameID) -> [GameDetailSection] {
        var sections: [GameDetailSection] = []
        let settings = GameDetailSetting.standard(for: gameID)
        let recentRecordsState = GameDetailRecentRecordsState.loading

        sections.append(
            .statistics(.loading)
        )

        if !settings.isEmpty {
            sections.append(.settings(settings))
        }

        sections.append(.location(.notRequested))
        sections.append(.recentRecords(recentRecordsState))
        sections.append(.rules(GameDetailRuleCatalog.rules(for: gameID)))

        return sections
    }

    var headerTitle: String? {
        switch self {
        case .rules:
            return "遊戲規則"

        case .settings:
            return "遊戲設定"

        case .location:
            return "賽局地點"

        case .statistics:
            return nil

        case .recentRecords:
            return "近十場紀錄"
        }
    }
}

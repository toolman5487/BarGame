//
//  GameSettingSection.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameSettingSection: Equatable, Sendable {

    case rules([GameSettingRule])
    case settings([GameSetting])
    case location(GameSettingLocationState)
    case statistics(GameSettingStatisticsState)
    case recentRecords(GameSettingRecentRecordsState)

    static func standard(for gameID: DiceGameID) -> [GameSettingSection] {
        var sections: [GameSettingSection] = []
        let settings = GameSetting.standard(for: gameID)
        let recentRecordsState = GameSettingRecentRecordsState.loading

        sections.append(
            .statistics(.loading)
        )

        if !settings.isEmpty {
            sections.append(.settings(settings))
        }

        sections.append(.location(.notRequested))
        sections.append(.recentRecords(recentRecordsState))
        sections.append(.rules(GameSettingRuleCatalog.rules(for: gameID)))

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

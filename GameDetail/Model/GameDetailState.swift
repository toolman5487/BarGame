//
//  GameDetailState.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

nonisolated struct GameDetailState: Equatable, Sendable {

    let sections: [GameDetailSection]

    var isLocationRequestInProgress: Bool {
        for section in sections {
            guard case .location(let state) = section else { continue }
            return state.isRequestInProgress
        }

        return false
    }

    func updatingRecords(
        recentRecordsState: GameDetailRecentRecordsState,
        statisticsState: GameDetailStatisticsState
    ) -> GameDetailState {
        GameDetailState(
            sections: sections.map { section in
                switch section {
                case .statistics:
                    return .statistics(statisticsState)

                case .recentRecords:
                    return .recentRecords(recentRecordsState)

                case .rules, .settings, .location:
                    return section
                }
            }
        )
    }

    func applying(_ change: GameDetailSettingChange) -> GameDetailState {
        GameDetailState(
            sections: sections.map { section in
                switch section {
                case .rules:
                    return section

                case .statistics:
                    return section

                case .recentRecords:
                    return section

                case .location:
                    return section

                case .settings(let settings):
                    return .settings(
                        settings.map { $0.applying(change) }
                    )
                }
            }
        )
    }

    func updatingLocationState(
        _ locationState: GameDetailLocationState
    ) -> GameDetailState {
        GameDetailState(
            sections: sections.map { section in
                switch section {
                case .location:
                    return .location(locationState)

                case .rules:
                    return section

                case .settings:
                    return section

                case .statistics:
                    return section

                case .recentRecords:
                    return section
                }
            }
        )
    }

    func launchConfiguration(for gameID: DiceGameID) -> GameLaunchConfiguration {
        let preset = gameID.dicePreset
        let presetSettings = DiceGameSettings(
            initialDiceCount: preset.defaultDiceCount,
            maximumDiceCount: preset.allowedDiceCount.upperBound
        )
        return .dice(
            gameID: gameID,
            settings: diceGameSettings ?? presetSettings,
            location: locationSnapshot
        )
    }

    private var locationSnapshot: GameLocationSnapshot? {
        for section in sections {
            guard case .location(let state) = section else { continue }
            return state.snapshot
        }

        return nil
    }

    private var diceGameSettings: DiceGameSettings? {
        for section in sections {
            guard case .settings(let settings) = section else { continue }

            for setting in settings {
                guard case .diceCount(let value, let allowedRange) = setting else {
                    continue
                }

                return DiceGameSettings(
                    initialDiceCount: value,
                    maximumDiceCount: allowedRange.upperBound
                )
            }
        }

        return nil
    }
}

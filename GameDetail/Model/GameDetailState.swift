//
//  GameDetailState.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

nonisolated struct GameDetailState: Equatable, Sendable {

    let sections: [GameDetailSection]

    func applying(_ change: GameDetailSettingChange) -> GameDetailState {
        GameDetailState(
            sections: sections.map { section in
                switch section {
                case .rules, .statistics, .recentRecords:
                    return section

                case .settings(let settings):
                    return .settings(
                        settings.map { $0.applying(change) }
                    )
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
            settings: diceGameSettings ?? presetSettings
        )
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

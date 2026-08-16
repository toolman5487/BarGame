//
//  MainHomeSampleData.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum MainHomeSampleData {

    static let standardSnapshot = MainHomeSnapshot(
        sections: [
            .dicePreview,
            .currentLocation,
            .gameResults([]),
            .gameList(games),
        ]
    )

    private static let games = DiceGameCatalog.firstPhaseVerbalGames
}

extension MainHomeConfiguration {

    nonisolated static let standard = MainHomeConfiguration(
        snapshot: MainHomeSampleData.standardSnapshot
    )
}

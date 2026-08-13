//
//  GameDetailRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

// MARK: - GameDetailRoute

nonisolated enum GameDetailRoute: Equatable, Sendable {
    case startGame(GameLaunchConfiguration)
}

// MARK: - GameDetailRouting

@MainActor
protocol GameDetailRouting: AnyObject {
    func route(to route: GameDetailRoute)
}

// MARK: - GameDetailRouter

@MainActor
final class GameDetailRouter: BaseRouter, GameDetailRouting {

    func route(to route: GameDetailRoute) {
        switch route {
        case .startGame(let configuration):
            showGame(using: configuration)
        }
    }

    private func showGame(using launchConfiguration: GameLaunchConfiguration) {
        switch launchConfiguration {
        case .dice(let gameID, let settings):
            let standardConfiguration = DiceGameConfiguration.standard
            let configuration = DiceGameConfiguration(
                title: gameID.title,
                initialDiceCount: settings.initialDiceCount,
                maximumDiceCount: settings.maximumDiceCount,
                hintText: standardConfiguration.hintText
            )
            let destination = DiceGameViewController(configuration: configuration)
            show(destination, using: .fullScreen)
        }
    }
}

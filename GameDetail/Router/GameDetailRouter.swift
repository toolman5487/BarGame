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
        case .dice(let settings):
            let standardConfiguration = DiceGameConfiguration.standard
            let configuration = DiceGameConfiguration(
                title: standardConfiguration.title,
                initialDiceCount: settings.initialDiceCount,
                maximumDiceCount: settings.maximumDiceCount,
                unlockedHintText: standardConfiguration.unlockedHintText,
                lockedHintText: standardConfiguration.lockedHintText
            )
            let destination = DiceGameViewController(configuration: configuration)
            show(destination, using: .fullScreen)

        case .unavailable:
            showUnavailableGameAlert()
        }
    }

    private func showUnavailableGameAlert() {
        showAlert(
            title: "即將推出",
            message: "這款遊戲還在準備中。"
        )
    }
}

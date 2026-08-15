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

    private let screenBuilder: any AppScreenBuilding

    init(
        sourceViewController: UIViewController,
        screenBuilder: any AppScreenBuilding
    ) {
        self.screenBuilder = screenBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func route(to route: GameDetailRoute) {
        switch route {
        case .startGame(let configuration):
            showGame(using: configuration)
        }
    }

    private func showGame(using launchConfiguration: GameLaunchConfiguration) {
        let destination = screenBuilder.makeGameViewController(
            for: launchConfiguration
        )
        let navigationController = UINavigationController(
            rootViewController: destination
        )
        show(navigationController, using: .fullScreen)
    }
}

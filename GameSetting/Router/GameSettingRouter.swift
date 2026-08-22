//
//  GameSettingRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

// MARK: - GameSettingRoute

nonisolated enum GameSettingRoute: Equatable, Sendable {
    case startGame(GameLaunchConfiguration)
}

// MARK: - GameSettingRouting

@MainActor
protocol GameSettingRouting: AnyObject {
    func route(to route: GameSettingRoute)
}

// MARK: - GameSettingRouter

@MainActor
final class GameSettingRouter: BaseRouter, GameSettingRouting {

    private let screenBuilder: any AppScreenBuilding

    init(
        sourceViewController: UIViewController,
        screenBuilder: any AppScreenBuilding
    ) {
        self.screenBuilder = screenBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func route(to route: GameSettingRoute) {
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

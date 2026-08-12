//
//  GameDetailRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

// MARK: - GameDetailRoute

nonisolated enum GameDetailRoute: Equatable, Sendable {
    case startGame(GameID)
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
        case .startGame(let gameID):
            showGame(for: gameID)
        }
    }

    private func showGame(for gameID: GameID) {
        switch gameID {
        case .dice:
            let destination = DiceGameViewController()
            destination.hidesBottomBarWhenPushed = true
            show(destination, using: .push)

        case .playingCards:
            showUnavailableGameAlert()

        case .roulette:
            showUnavailableGameAlert()

        case .sicBo:
            showUnavailableGameAlert()

        case .blackjack:
            showUnavailableGameAlert()

        case .bingo:
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

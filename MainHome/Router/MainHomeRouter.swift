//
//  MainHomeRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

// MARK: - Route

nonisolated enum MainHomeRoute: Equatable, Sendable {

    case game(Game)
}

// MARK: - Protocol

@MainActor
protocol MainHomeRouting: AnyObject {

    func route(to route: MainHomeRoute)
}

// MARK: - Router

@MainActor
final class MainHomeRouter: BaseRouter, MainHomeRouting {

    func route(to route: MainHomeRoute) {
        switch route {
        case .game(let game):
            let destination = makeGameViewController(for: game)
            destination.hidesBottomBarWhenPushed = true
            show(destination, using: .push)
        }
    }

    // MARK: - Private

    private func makeGameViewController(for game: Game) -> UIViewController {
        switch game.id {
        case .dice:
            return GameDetailViewController(game: game)

        case .playingCards:
            return GameDetailViewController(game: game)

        case .roulette:
            return GameDetailViewController(game: game)

        case .sicBo:
            return GameDetailViewController(game: game)

        case .blackjack:
            return GameDetailViewController(game: game)

        case .bingo:
            return GameDetailViewController(game: game)
        }
    }
}

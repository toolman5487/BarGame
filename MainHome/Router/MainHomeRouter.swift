//
//  MainHomeRouter.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

// MARK: - Route

nonisolated enum MainHomeRoute: Equatable, Sendable {

    case game(DiceGame)
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

    private func makeGameViewController(for game: DiceGame) -> UIViewController {
        GameDetailViewController(game: game)
    }
}

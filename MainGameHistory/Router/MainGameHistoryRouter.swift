//
//  MainGameHistoryRouter.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Foundation
import UIKit

nonisolated enum MainGameHistoryRoute: Equatable, Sendable {

    case matchDetail(
        recordID: UUID,
        gameID: DiceGameID,
        outcome: MatchOutcome
    )
}

@MainActor
protocol MainGameHistoryRouting: AnyObject {

    func route(to route: MainGameHistoryRoute)
}

@MainActor
final class MainGameHistoryRouter: BaseRouter, MainGameHistoryRouting {

    private let screenBuilder: any AppScreenBuilding

    init(
        sourceViewController: UIViewController,
        screenBuilder: any AppScreenBuilding
    ) {
        self.screenBuilder = screenBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func route(to route: MainGameHistoryRoute) {
        switch route {
        case .matchDetail(let recordID, let gameID, let outcome):
            let destination = screenBuilder.makeMatchDetailViewController(
                recordID: recordID,
                gameID: gameID,
                outcome: outcome
            )
            destination.hidesBottomBarWhenPushed = true
            show(destination, using: .push)
        }
    }
}

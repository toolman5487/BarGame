//
//  MatchDetailRouter.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation
import UIKit

nonisolated enum MatchDetailRoute: Equatable, Sendable {

    case roundDetail(matchID: UUID, roundID: UUID)
}

@MainActor
protocol MatchDetailRouting: AnyObject {

    func route(to route: MatchDetailRoute)
}

@MainActor
final class MatchDetailRouter: BaseRouter, MatchDetailRouting {

    private let screenBuilder: any AppScreenBuilding

    init(
        sourceViewController: UIViewController,
        screenBuilder: any AppScreenBuilding
    ) {
        self.screenBuilder = screenBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func route(to route: MatchDetailRoute) {
        switch route {
        case .roundDetail(let matchID, let roundID):
            let destination = screenBuilder.makeRoundDetailViewController(
                matchID: matchID,
                roundID: roundID
            )
            destination.hidesBottomBarWhenPushed = true
            show(destination, using: .push)
        }
    }
}

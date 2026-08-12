//
//  GameDetailViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

@MainActor
final class GameDetailViewController: DetailBaseViewController {

    // MARK: - Dependencies

    private let game: Game

    // MARK: - Lifecycle

    init(game: Game) {
        self.game = game
        super.init(title: game.title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

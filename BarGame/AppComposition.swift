//
//  AppComposition.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import SwiftData
import UIKit

@MainActor
protocol AppScreenBuilding: AnyObject {

    func makeRootViewController(for item: MainTabItem) -> UIViewController
    func makeGameDetailViewController(for game: DiceGame) -> UIViewController
    func makeGameViewController(
        for launchConfiguration: GameLaunchConfiguration
    ) -> UIViewController
}

@MainActor
final class AppComposition: AppScreenBuilding {

    // MARK: - Dependencies

    private let gameHistoryStore: GameHistoryStore

    // MARK: - Lifecycle

    init(modelContainer: ModelContainer = AppModelContainer.shared) {
        gameHistoryStore = GameHistoryStore(modelContainer: modelContainer)
    }

    // MARK: - Root

    func makeMainTabBarController(
        configuration: MainTabBarConfiguration = .standard
    ) -> MainTabBarController {
        MainTabBarController(
            viewModel: MainTabBarViewModel(configuration: configuration),
            screenBuilder: self
        )
    }

    // MARK: - AppScreenBuilding

    func makeRootViewController(for item: MainTabItem) -> UIViewController {
        switch item.tab {
        case .home:
            return makeMainHomeViewController(title: item.title)

        case .pageA:
            return ViewController(title: item.title)

        case .pageB:
            return ViewController(title: item.title)

        case .pageC:
            return ViewController(title: item.title)
        }
    }

    func makeGameDetailViewController(for game: DiceGame) -> UIViewController {
        let initialState = GameDetailState(
            sections: GameDetailSection.standard(for: game.id)
        )
        let viewModel = GameDetailViewModel(
            gameID: game.id,
            initialState: initialState,
            recordStore: gameHistoryStore
        )
        return GameDetailViewController(
            title: game.title,
            initialState: initialState,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    func makeGameViewController(
        for launchConfiguration: GameLaunchConfiguration
    ) -> UIViewController {
        switch launchConfiguration {
        case .dice(let gameID, let settings):
            let standardConfiguration = DiceGameConfiguration.standard
            let configuration = DiceGameConfiguration(
                gameID: gameID,
                title: gameID.title,
                initialDiceCountState: settings.initialDiceCountState,
                maximumDiceCount: settings.maximumDiceCount,
                hintText: standardConfiguration.hintText
            )
            return makeDiceGameViewController(configuration: configuration)
        }
    }

    // MARK: - Private

    private func makeMainHomeViewController(title: String) -> UIViewController {
        let viewModel = MainHomeViewModel(
            configuration: .standard,
            statisticsReader: gameHistoryStore
        )
        return MainHomeViewController(
            title: title,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    private func makeDiceGameViewController(
        configuration: DiceGameConfiguration
    ) -> UIViewController {
        DiceGameViewController(
            configuration: configuration,
            recordStore: gameHistoryStore
        )
    }
}

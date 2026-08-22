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
    func makeGameSettingViewController(for game: DiceGame) -> UIViewController
    func makeMatchDetailViewController(
        recordID: UUID,
        gameID: DiceGameID,
        outcome: MatchOutcome
    ) -> UIViewController
    func makeRoundDetailViewController(
        matchID: UUID,
        roundID: UUID
    ) -> UIViewController
    func makeGameViewController(
        for launchConfiguration: GameLaunchConfiguration
    ) -> UIViewController
}

@MainActor
final class AppComposition: AppScreenBuilding {

    // MARK: - Dependencies

    private let gameHistoryStore: GameHistoryStore
    private let gameLocationProvider: any GameLocationProviding
    private let gameLocationCache: any GameLocationCaching
    private let gameLocationCoordinator: GameLocationCoordinator

    // MARK: - Lifecycle

    init(
        modelContainer: ModelContainer = AppModelContainer.shared,
        gameLocationProvider: any GameLocationProviding =
            CoreLocationGameLocationProvider(),
        gameLocationCache: any GameLocationCaching =
            UserDefaultsGameLocationCache()
    ) {
        gameHistoryStore = GameHistoryStore(modelContainer: modelContainer)
        self.gameLocationProvider = gameLocationProvider
        self.gameLocationCache = gameLocationCache
        gameLocationCoordinator = GameLocationCoordinator(
            locationProvider: gameLocationProvider,
            locationCache: gameLocationCache
        )
    }

    // MARK: - Root

    func refreshLocationOnLaunch() {
        gameLocationCoordinator.refreshLocationOnLaunch()
    }

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

        case .gameHistory:
            return makeMainGameHistoryViewController(title: item.title)

        case .pageB:
            return ViewController(title: item.title)

        case .pageC:
            return ViewController(title: item.title)
        }
    }

    func makeGameSettingViewController(for game: DiceGame) -> UIViewController {
        let initialState = GameSettingState(
            sections: GameSettingSection.standard(for: game.id)
        )
        let viewModel = GameSettingViewModel(
            gameID: game.id,
            initialState: initialState,
            recordStore: gameHistoryStore,
            statisticsReader: gameHistoryStore,
            locationCoordinator: gameLocationCoordinator
        )
        return GameSettingViewController(
            title: game.title,
            initialState: initialState,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    func makeMatchDetailViewController(
        recordID: UUID,
        gameID: DiceGameID,
        outcome: MatchOutcome
    ) -> UIViewController {
        let viewModel = MatchDetailViewModel(
            recordID: recordID,
            recordStore: gameHistoryStore,
            locationGeocoder: MapKitMatchDetailLocationGeocoder()
        )
        return MatchDetailViewController(
            matchID: recordID,
            gameID: gameID,
            outcome: outcome,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    func makeRoundDetailViewController(
        matchID: UUID,
        roundID: UUID
    ) -> UIViewController {
        let viewModel = RoundDetailViewModel(
            matchID: matchID,
            roundID: roundID,
            recordStore: gameHistoryStore
        )
        return RoundDetailViewController(viewModel: viewModel)
    }

    func makeGameViewController(
        for launchConfiguration: GameLaunchConfiguration
    ) -> UIViewController {
        switch launchConfiguration {
        case .dice(let gameID, let settings, let location):
            let standardConfiguration = DiceGameConfiguration.standard
            let configuration = DiceGameConfiguration(
                gameID: gameID,
                title: gameID.title,
                initialDiceCountState: settings.initialDiceCountState,
                maximumDiceCount: settings.maximumDiceCount,
                hintText: standardConfiguration.hintText
            )
            return makeDiceGameViewController(
                configuration: configuration,
                location: location
            )
        }
    }

    // MARK: - Private

    private func makeMainHomeViewController(title: String) -> UIViewController {
        let viewModel = MainHomeViewModel(
            configuration: .standard,
            statisticsReader: gameHistoryStore,
            locationCoordinator: gameLocationCoordinator
        )
        return MainHomeViewController(
            title: title,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    private func makeMainGameHistoryViewController(
        title: String
    ) -> UIViewController {
        let viewModel = MainGameHistoryViewModel(
            recordStore: gameHistoryStore
        )
        return MainGameHistoryViewController(
            title: title,
            viewModel: viewModel,
            screenBuilder: self
        )
    }

    private func makeDiceGameViewController(
        configuration: DiceGameConfiguration,
        location: GameLocationSnapshot?
    ) -> UIViewController {
        DiceGameViewController(
            configuration: configuration,
            location: location,
            recordStore: gameHistoryStore
        )
    }
}

//
//  GameDetailViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Combine
import Foundation

// MARK: - Input

struct GameDetailViewModelInput {

    let settingChange: AnyPublisher<GameDetailSettingChange, Never>
    let startGame: AnyPublisher<Void, Never>
}

// MARK: - Output

struct GameDetailViewModelOutput {

    let state: AnyPublisher<GameDetailState, Never>
    let launchConfiguration: AnyPublisher<GameLaunchConfiguration, Never>
}

// MARK: - Protocol

@MainActor
protocol GameDetailViewModeling: AnyObject {

    func transform(input: GameDetailViewModelInput) -> GameDetailViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class GameDetailViewModel: GameDetailViewModeling {

    private let gameID: DiceGameID
    private let stateSubject: CurrentValueSubject<GameDetailState, Never>
    private let launchConfigurationSubject = PassthroughSubject<
        GameLaunchConfiguration,
        Never
    >()
    private var cancellables = Set<AnyCancellable>()

    private var state: GameDetailState {
        stateSubject.value
    }

    init(gameID: DiceGameID, initialState: GameDetailState) {
        self.gameID = gameID
        stateSubject = CurrentValueSubject(initialState)
    }

    func transform(input: GameDetailViewModelInput) -> GameDetailViewModelOutput {
        cancellables.removeAll()

        input.settingChange
            .sink { [weak self] change in
                self?.updateSetting(with: change)
            }
            .store(in: &cancellables)

        input.startGame
            .sink { [weak self] in
                self?.prepareGameLaunch()
            }
            .store(in: &cancellables)

        return GameDetailViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            launchConfiguration: launchConfigurationSubject.eraseToAnyPublisher()
        )
    }

    private func updateSetting(with change: GameDetailSettingChange) {
        let updatedState = state.applying(change)
        guard updatedState != state else { return }
        stateSubject.send(updatedState)
    }

    private func prepareGameLaunch() {
        launchConfigurationSubject.send(
            state.launchConfiguration(for: gameID)
        )
    }
}

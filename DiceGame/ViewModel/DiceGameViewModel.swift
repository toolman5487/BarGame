//
//  DiceGameViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import Foundation

// MARK: - Input

struct DiceGameViewModelInput {

    let confirmedResult: AnyPublisher<DiceRollResult, Never>
    let shakeMotion: AnyPublisher<Void, Never>
}

// MARK: - Output

struct DiceGameViewModelOutput {

    let state: AnyPublisher<DiceGameState, Never>
    let command: AnyPublisher<DiceGameViewCommand, Never>
}

// MARK: - Command

enum DiceGameViewCommand {

    case shakeDice
}

// MARK: - Protocol

@MainActor
protocol DiceGameViewModeling: AnyObject {

    func transform(input: DiceGameViewModelInput) -> DiceGameViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class DiceGameViewModel: DiceGameViewModeling {

    // MARK: - Properties

    private let stateSubject: CurrentValueSubject<DiceGameState, Never>
    private let commandSubject = PassthroughSubject<DiceGameViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()

    private var state: DiceGameState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(initialState: DiceGameState) {
        stateSubject = CurrentValueSubject(initialState)
    }

    // MARK: - Public

    func transform(input: DiceGameViewModelInput) -> DiceGameViewModelOutput {
        cancellables.removeAll()

        input.confirmedResult
            .sink { [weak self] result in
                self?.confirmDiceResult(result)
            }
            .store(in: &cancellables)

        input.shakeMotion
            .sink { [weak self] in
                self?.handleShakeMotion()
            }
            .store(in: &cancellables)

        return DiceGameViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            command: commandSubject.eraseToAnyPublisher()
        )
    }

    // MARK: - Actions

    private func handleShakeMotion() {
        guard !state.isDiceLocked else { return }
        commandSubject.send(.shakeDice)
    }

    // MARK: - State Updates

    private func confirmDiceResult(_ result: DiceRollResult) {
        guard !state.isDiceLocked else { return }
        updateState(
            DiceGameState(
                viewMode: .topDown,
                isDiceLocked: true,
                result: result
            )
        )
    }

    private func updateState(_ updatedState: DiceGameState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}

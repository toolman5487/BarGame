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

    let selectedControl: AnyPublisher<DiceGameControl, Never>
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

        input.selectedControl
            .sink { [weak self] control in
                self?.handleSelectedControl(control)
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

    private func handleSelectedControl(_ control: DiceGameControl) {
        switch control {
        case .lock:
            guard state.viewMode == .perspective else { return }
            updateState(
                DiceGameState(
                    viewMode: state.viewMode,
                    isDiceLocked: !state.isDiceLocked
                )
            )

        case .action:
            updateViewMode()

        case .exit:
            break
        }
    }

    private func handleShakeMotion() {
        guard !state.isDiceLocked else { return }
        commandSubject.send(.shakeDice)
    }

    // MARK: - State Updates

    private func updateViewMode() {
        let updatedState: DiceGameState

        switch state.viewMode {
        case .perspective:
            updatedState = DiceGameState(
                viewMode: .topDown,
                isDiceLocked: true
            )

        case .topDown:
            updatedState = DiceGameState(
                viewMode: .perspective,
                isDiceLocked: false
            )
        }

        updateState(updatedState)
    }

    private func updateState(_ updatedState: DiceGameState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}

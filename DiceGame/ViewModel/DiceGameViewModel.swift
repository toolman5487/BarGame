//
//  DiceGameViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import Foundation
import Observation

// MARK: - Input / Output

struct DiceGameViewModelInput {

    let selectedControl: AnyPublisher<DiceGameControl, Never>
    let shakeMotion: AnyPublisher<Void, Never>
}

struct DiceGameViewModelOutput {

    let command: AnyPublisher<DiceGameViewCommand, Never>
}

// MARK: - Command

enum DiceGameViewCommand {

    case addDice
    case shakeDice
}

// MARK: - Protocol

@MainActor
protocol DiceGameViewModeling: AnyObject {

    var state: DiceGameState { get }

    func transform(input: DiceGameViewModelInput) -> DiceGameViewModelOutput
}

// MARK: - ViewModel

@Observable
@MainActor
final class DiceGameViewModel: DiceGameViewModeling {

    // MARK: - Properties

    private(set) var state: DiceGameState
    private let combineBinding: DiceGameCombineBinding

    // MARK: - Lifecycle

    init(initialState: DiceGameState) {
        state = initialState
        combineBinding = DiceGameCombineBinding()
    }

    // MARK: - Public

    func transform(input: DiceGameViewModelInput) -> DiceGameViewModelOutput {
        let selectedControlCancellable = input.selectedControl
            .sink { [weak self] control in
                self?.handleSelectedControl(control)
            }

        let shakeMotionCancellable = input.shakeMotion
            .sink { [weak self] in
                self?.handleShakeMotion()
            }

        combineBinding.replaceCancellables(
            with: [selectedControlCancellable, shakeMotionCancellable]
        )
        return combineBinding.output
    }

    // MARK: - Actions

    private func handleSelectedControl(_ control: DiceGameControl) {
        switch control {
        case .lock:
            guard state.viewMode == .perspective else { return }
            updateState(
                DiceGameState(
                    viewMode: state.viewMode,
                    isDiceLocked: !state.isDiceLocked,
                    diceCount: state.diceCount,
                    maximumDiceCount: state.maximumDiceCount
                )
            )

        case .add:
            guard state.canAddDice else { return }
            updateState(
                DiceGameState(
                    viewMode: state.viewMode,
                    isDiceLocked: state.isDiceLocked,
                    diceCount: state.diceCount + 1,
                    maximumDiceCount: state.maximumDiceCount
                )
            )
            combineBinding.send(command: .addDice)

        case .action:
            updateViewMode()
        }
    }

    private func handleShakeMotion() {
        guard !state.isDiceLocked else { return }
        combineBinding.send(command: .shakeDice)
    }

    // MARK: - State Updates

    private func updateViewMode() {
        let updatedState: DiceGameState

        switch state.viewMode {
        case .perspective:
            updatedState = DiceGameState(
                viewMode: .topDown,
                isDiceLocked: true,
                diceCount: state.diceCount,
                maximumDiceCount: state.maximumDiceCount
            )

        case .topDown:
            updatedState = DiceGameState(
                viewMode: .perspective,
                isDiceLocked: false,
                diceCount: state.diceCount,
                maximumDiceCount: state.maximumDiceCount
            )
        }

        updateState(updatedState)
    }

    private func updateState(_ updatedState: DiceGameState) {
        guard state != updatedState else { return }
        state = updatedState
    }
}

// MARK: - Combine Binding

@MainActor
private final class DiceGameCombineBinding {

    private let commandSubject = PassthroughSubject<DiceGameViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()

    var output: DiceGameViewModelOutput {
        DiceGameViewModelOutput(
            command: commandSubject.eraseToAnyPublisher()
        )
    }

    func replaceCancellables(with cancellables: [AnyCancellable]) {
        self.cancellables = Set(cancellables)
    }

    func send(command: DiceGameViewCommand) {
        commandSubject.send(command)
    }
}

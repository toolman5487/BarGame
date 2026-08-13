//
//  DiceGameViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import Foundation

// MARK: - View State

nonisolated struct DiceGameViewState: Equatable, Sendable {

    let game: DiceGameState
    let result: DiceGameResultViewState
}

nonisolated struct DiceGameResultViewState: Equatable, Sendable {

    enum Presentation: Equatable, Sendable {
        case collapsed
        case expanded
    }

    struct Item: Equatable, Sendable {

        let title: String
        let countText: String
    }

    let hintText: String
    let totalText: String?
    let items: [Item]
    let presentation: Presentation
}

// MARK: - Input

struct DiceGameViewModelInput {

    let confirmedResult: AnyPublisher<DiceRollResult, Never>
    let resultExpansionToggle: AnyPublisher<Void, Never>
    let shakeMotion: AnyPublisher<Void, Never>
}

// MARK: - Output

struct DiceGameViewModelOutput {

    let state: AnyPublisher<DiceGameViewState, Never>
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

    private let stateSubject: CurrentValueSubject<DiceGameViewState, Never>
    private let commandSubject = PassthroughSubject<DiceGameViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()

    private var state: DiceGameViewState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(initialState: DiceGameViewState) {
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

        input.resultExpansionToggle
            .sink { [weak self] in
                self?.toggleResultExpansion()
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
        guard !state.game.isDiceLocked else { return }
        commandSubject.send(.shakeDice)
    }

    private func toggleResultExpansion() {
        guard state.game.result != nil else { return }

        let updatedPresentation: DiceGameResultViewState.Presentation

        switch state.result.presentation {
        case .collapsed:
            updatedPresentation = .expanded
        case .expanded:
            updatedPresentation = .collapsed
        }

        updateState(
            DiceGameViewState(
                game: state.game,
                result: DiceGameResultViewState(
                    hintText: state.result.hintText,
                    totalText: state.result.totalText,
                    items: state.result.items,
                    presentation: updatedPresentation
                )
            )
        )
    }

    // MARK: - State Updates

    private func confirmDiceResult(_ result: DiceRollResult) {
        guard !state.game.isDiceLocked else { return }
        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .topDown,
                    isDiceLocked: true,
                    result: result
                ),
                result: makeExpandedResultState(
                    from: result,
                    hintText: state.result.hintText
                )
            )
        )
    }

    private func makeExpandedResultState(
        from result: DiceRollResult,
        hintText: String
    ) -> DiceGameResultViewState {
        let items = (1...6).map { faceValue in
            DiceGameResultViewState.Item(
                title: "\(faceValue) 點",
                countText: "\(result.count(of: faceValue)) 顆"
            )
        }
        return DiceGameResultViewState(
            hintText: hintText,
            totalText: "總和點數：\(result.total)",
            items: items,
            presentation: .expanded
        )
    }

    private func updateState(_ updatedState: DiceGameViewState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}

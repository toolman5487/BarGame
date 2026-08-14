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

    var primaryAction: DiceGamePrimaryAction {
        switch game.roundPhase {
        case .ready:
            return .confirmResult(isEnabled: true)

        case .capturingResult:
            return .confirmResult(isEnabled: false)

        case .showingResult:
            return .startNextRound(isEnabled: true)

        case .selectingOutcome, .savingOutcome:
            return .startNextRound(isEnabled: false)
        }
    }
}

nonisolated enum DiceGamePrimaryAction: Equatable, Sendable {

    case confirmResult(isEnabled: Bool)
    case startNextRound(isEnabled: Bool)
}

nonisolated enum DiceGameResultViewState: Equatable, Sendable {

    enum Presentation: Equatable, Sendable {
        case collapsed
        case expanded
    }

    struct Item: Equatable, Sendable {

        let title: String
        let countText: String
    }

    struct ResultContent: Equatable, Sendable {

        let collapsedText: String
        let totalText: String
        let items: [Item]
    }

    case awaitingResult(hintText: String)
    case showingResult(content: ResultContent, presentation: Presentation)

    var presentation: Presentation {
        switch self {
        case .awaitingResult:
            return .collapsed
        case .showingResult(_, let presentation):
            return presentation
        }
    }
}

// MARK: - Input

struct DiceGameViewModelInput {

    let primaryActionTapped: AnyPublisher<Void, Never>
    let capturedResult: AnyPublisher<DiceRollResult, Never>
    let outcomeSelected: AnyPublisher<GameOutcome, Never>
    let outcomeSelectionCancelled: AnyPublisher<Void, Never>
    let resultExpansionToggle: AnyPublisher<Void, Never>
    let shakeMotion: AnyPublisher<Void, Never>
}

// MARK: - Output

struct DiceGameViewModelOutput {

    let state: AnyPublisher<DiceGameViewState, Never>
    let command: AnyPublisher<DiceGameViewCommand, Never>
}

// MARK: - Command

enum DiceGameSceneCommand {

    case shakeDice
    case prepareNextRound
}

enum DiceGameViewCommand {

    case captureDiceResult
    case presentOutcomeSelection
    case updateScene(DiceGameSceneCommand)
    case showError(DiceGameViewError)
}

nonisolated enum DiceGameViewError: Error, Sendable {

    case recordSaveFailed

    var title: String {
        switch self {
        case .recordSaveFailed:
            return "無法儲存比賽結果"
        }
    }

    var message: String {
        switch self {
        case .recordSaveFailed:
            return "請稍後再試，上一局結果仍會保留。"
        }
    }
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

    private let gameID: DiceGameID
    private let sessionContext: GameSessionContext
    private let hintText: String
    private let recordStore: any DiceGameRecordStoring
    private let stateSubject: CurrentValueSubject<DiceGameViewState, Never>
    private let commandSubject = PassthroughSubject<DiceGameViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var saveRecordTask: Task<Void, Never>?

    private var state: DiceGameViewState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(
        gameID: DiceGameID,
        sessionContext: GameSessionContext,
        hintText: String,
        initialState: DiceGameViewState,
        recordStore: any DiceGameRecordStoring
    ) {
        self.gameID = gameID
        self.sessionContext = sessionContext
        self.hintText = hintText
        self.recordStore = recordStore
        stateSubject = CurrentValueSubject(initialState)
    }

    deinit {
        saveRecordTask?.cancel()
    }

    // MARK: - Public

    func transform(input: DiceGameViewModelInput) -> DiceGameViewModelOutput {
        cancellables.removeAll()

        input.primaryActionTapped
            .sink { [weak self] in
                self?.handlePrimaryAction()
            }
            .store(in: &cancellables)

        input.capturedResult
            .sink { [weak self] result in
                self?.captureDiceResult(result)
            }
            .store(in: &cancellables)

        input.outcomeSelected
            .sink { [weak self] outcome in
                self?.selectOutcome(outcome)
            }
            .store(in: &cancellables)

        input.outcomeSelectionCancelled
            .sink { [weak self] in
                self?.cancelOutcomeSelection()
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

    private func handlePrimaryAction() {
        switch state.game.roundPhase {
        case .ready:
            updateState(
                DiceGameViewState(
                    game: DiceGameState(
                        viewMode: .perspective,
                        roundPhase: .capturingResult
                    ),
                    result: state.result
                )
            )
            commandSubject.send(.captureDiceResult)

        case .showingResult(let result):
            updateState(
                DiceGameViewState(
                    game: DiceGameState(
                        viewMode: .topDown,
                        roundPhase: .selectingOutcome(result)
                    ),
                    result: state.result
                )
            )
            commandSubject.send(.presentOutcomeSelection)

        case .capturingResult, .selectingOutcome, .savingOutcome:
            return
        }
    }

    private func handleShakeMotion() {
        guard case .ready = state.game.roundPhase else { return }
        commandSubject.send(.updateScene(.shakeDice))
    }

    private func toggleResultExpansion() {
        guard
            case .showingResult(let content, let presentation) = state.result
        else {
            return
        }

        let updatedPresentation: DiceGameResultViewState.Presentation

        switch presentation {
        case .collapsed:
            updatedPresentation = .expanded
        case .expanded:
            updatedPresentation = .collapsed
        }

        updateState(
            DiceGameViewState(
                game: state.game,
                result: .showingResult(
                    content: content,
                    presentation: updatedPresentation
                )
            )
        )
    }

    // MARK: - State Updates

    private func captureDiceResult(_ result: DiceRollResult) {
        guard case .capturingResult = state.game.roundPhase else { return }
        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .topDown,
                    roundPhase: .showingResult(result)
                ),
                result: makeExpandedResultState(from: result)
            )
        )
    }

    private func selectOutcome(_ outcome: GameOutcome) {
        guard case .selectingOutcome(let result) = state.game.roundPhase else {
            return
        }

        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .topDown,
                    roundPhase: .savingOutcome(
                        result: result,
                        outcome: outcome
                    )
                ),
                result: state.result
            )
        )

        saveRecordTask?.cancel()
        let record = DiceGameMatchRecord(
            id: UUID(),
            sessionContext: sessionContext,
            gameID: gameID,
            outcome: outcome,
            diceResult: result,
            playedAt: Date()
        )
        saveRecordTask = Task { [weak self, recordStore] in
            do {
                try await recordStore.insert(record)
                try Task.checkCancellation()
                self?.startNextRound()
            } catch is CancellationError {
                return
            } catch {
                self?.handleRecordSaveFailure(result: result)
            }
        }
    }

    private func cancelOutcomeSelection() {
        guard case .selectingOutcome(let result) = state.game.roundPhase else {
            return
        }

        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .topDown,
                    roundPhase: .showingResult(result)
                ),
                result: state.result
            )
        )
    }

    private func startNextRound() {
        guard case .savingOutcome = state.game.roundPhase else { return }

        commandSubject.send(.updateScene(.prepareNextRound))
        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .perspective,
                    roundPhase: .ready
                ),
                result: .awaitingResult(hintText: hintText)
            )
        )
    }

    private func handleRecordSaveFailure(result: DiceRollResult) {
        guard case .savingOutcome = state.game.roundPhase else { return }

        updateState(
            DiceGameViewState(
                game: DiceGameState(
                    viewMode: .topDown,
                    roundPhase: .showingResult(result)
                ),
                result: state.result
            )
        )
        commandSubject.send(.showError(.recordSaveFailed))
    }

    private func makeExpandedResultState(
        from result: DiceRollResult
    ) -> DiceGameResultViewState {
        let items = (1...6).map { faceValue in
            DiceGameResultViewState.Item(
                title: "\(faceValue) 點",
                countText: "\(result.count(of: faceValue)) 顆"
            )
        }
        return .showingResult(
            content: DiceGameResultViewState.ResultContent(
                collapsedText: "點擊查看骰子結果",
                totalText: "總和點數：\(result.total)",
                items: items
            ),
            presentation: .expanded
        )
    }

    private func updateState(_ updatedState: DiceGameViewState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}

//
//  DiceGameViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import Foundation
import SnapKit
import UIKit

@MainActor
final class DiceGameViewController: StandardBaseViewController {

    // MARK: - Types

    struct ScreenContent {

        let title: String
        let initialState: DiceGameViewState
        let diceGameViewConfiguration: DiceGameViewConfiguration
    }

    private enum Metrics {
        static let edgeInset: CGFloat = 16
    }

    // MARK: - Dependencies

    private let screenContent: ScreenContent
    private let viewModel: any DiceGameViewModeling
    private lazy var router = BaseRouter(sourceViewController: self)

    // MARK: - State

    private let primaryActionTappedSubject = PassthroughSubject<Void, Never>()
    private let capturedResultSubject = PassthroughSubject<DiceRollResult, Never>()
    private let outcomeSelectedSubject = PassthroughSubject<GameOutcome, Never>()
    private let outcomeSelectionCancelledSubject = PassthroughSubject<Void, Never>()
    private let resultExpansionToggleSubject = PassthroughSubject<Void, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: DiceGameViewState

    // MARK: - UI Elements

    private let diceGameView: DiceGameView
    private let resultView: DiceGameResultView
    private let primaryActionBottomBar = DiceGameBottomBar()
    private lazy var exitBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.down.right.and.arrow.up.left"),
        primaryAction: UIAction { [weak self] _ in
            self?.showExitConfirmation()
        }
    )

    // MARK: - Lifecycle

    init(
        screenContent: ScreenContent,
        viewModel: any DiceGameViewModeling
    ) {
        self.screenContent = screenContent
        self.viewModel = viewModel
        diceGameView = DiceGameView(
            configuration: screenContent.diceGameViewConfiguration
        )
        resultView = DiceGameResultView()
        renderedState = screenContent.initialState
        super.init()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    // MARK: - UIResponder

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        shakeMotionSubject.send()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        view.addSubview(diceGameView)
        view.addSubview(resultView)
        view.addSubview(primaryActionBottomBar)
        setupPrimaryAction()
        setupResultViewActions()
    }

    override func setLayout() {
        diceGameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        resultView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.bottom
                .lessThanOrEqualTo(primaryActionBottomBar.snp.top)
                .offset(-Metrics.edgeInset)
        }

        primaryActionBottomBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func setAppearance() {
        configureResultView()
        configureBottomBar()
    }

    override func setNavigation() {
        title = screenContent.title
        navigationItem.rightBarButtonItem = exitBarButtonItem
    }

    override func bind() {
        let input = DiceGameViewModelInput(
            primaryActionTapped: primaryActionTappedSubject.eraseToAnyPublisher(),
            capturedResult: capturedResultSubject.eraseToAnyPublisher(),
            outcomeSelected: outcomeSelectedSubject.eraseToAnyPublisher(),
            outcomeSelectionCancelled: outcomeSelectionCancelledSubject
                .eraseToAnyPublisher(),
            resultExpansionToggle: resultExpansionToggleSubject
                .eraseToAnyPublisher(),
            shakeMotion: shakeMotionSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)

        output.command
            .sink { [weak self] command in
                self?.execute(command)
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup

    private func setupPrimaryAction() {
        primaryActionBottomBar.tapHandler = { [weak self] in
            self?.primaryActionTappedSubject.send()
        }
    }

    private func setupResultViewActions() {
        resultView.onExpansionToggle = { [weak self] in
            self?.resultExpansionToggleSubject.send()
        }
    }

    // MARK: - State Updates

    private func apply(_ state: DiceGameViewState) {
        diceGameView.configure(with: state.game)

        if renderedState != state {
            renderedState = state
            configureResultView()
            configureBottomBar()
        }
    }

    // MARK: - UI Configuration

    private func configureResultView() {
        resultView.configure(with: renderedState.result)
    }

    private func configureBottomBar() {
        primaryActionBottomBar.configure(with: renderedState.primaryAction)
    }

    // MARK: - Actions

    private func captureDiceResult() {
        let result = diceGameView.lockAndCaptureResult()
        capturedResultSubject.send(result)
    }

    private func showOutcomeSelection() {
        let alert = UIAlertController(
            title: "這場比賽結果",
            message: "請選擇這場比賽的勝負",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "勝利", style: .default) { [weak self] _ in
                self?.outcomeSelectedSubject.send(.win)
            }
        )
        alert.addAction(
            UIAlertAction(title: "失敗", style: .default) { [weak self] _ in
                self?.outcomeSelectedSubject.send(.loss)
            }
        )
        alert.addAction(
            UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
                self?.outcomeSelectionCancelledSubject.send()
            }
        )
        router.show(alert, using: .present)
    }

    private func execute(_ command: DiceGameViewCommand) {
        switch command {
        case .captureDiceResult:
            captureDiceResult()

        case .presentOutcomeSelection:
            showOutcomeSelection()

        case .updateScene(let sceneCommand):
            diceGameView.execute(sceneCommand)

        case .showError(let error):
            router.showAlert(title: error.title, message: error.message)
        }
    }

    private func showExitConfirmation() {
        router.showConfirmationAlert(
            title: "結束賽局？",
            message: "確定要結束目前的賽局並離開嗎？",
            actionTitle: "結束賽局"
        ) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - Composition

extension DiceGameViewController {

    convenience init(
        configuration: DiceGameConfiguration,
        recordStore: any DiceGameRecordStoring
    ) {
        let startedAt = Date()
        let eventContext = GameEventContext(startedAt: startedAt)
        let sessionContext = GameSessionContext(
            event: eventContext,
            identity: configuration.gameID.identity,
            rulesVersion: configuration.gameID.currentRulesVersion,
            startedAt: startedAt
        )
        let initialGameState = configuration.initialState
        let initialState = DiceGameViewState(
            game: initialGameState,
            result: .awaitingResult(hintText: configuration.hintText)
        )
        let viewModel = DiceGameViewModel(
            gameID: configuration.gameID,
            sessionContext: sessionContext,
            hintText: configuration.hintText,
            initialState: initialState,
            recordStore: recordStore
        )

        self.init(
            screenContent: ScreenContent(
                title: configuration.title,
                initialState: initialState,
                diceGameViewConfiguration: DiceGameViewConfiguration(
                    initialState: initialGameState,
                    gameDiceView: GameDiceViewConfiguration(
                        initialDiceCountState: configuration.initialDiceCountState,
                        maximumDiceCount: configuration.maximumDiceCount
                    )
                )
            ),
            viewModel: viewModel
        )
    }
}

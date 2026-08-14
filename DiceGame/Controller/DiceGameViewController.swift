//
//  DiceGameViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import SnapKit
import UIKit

@MainActor
final class DiceGameViewController: StandardBaseViewController {

    // MARK: - Types

    struct Configuration {

        let title: String
        let initialState: DiceGameViewState
        let contentView: DiceGameView.Configuration
    }

    private enum Metrics {
        static let edgeInset: CGFloat = 16
    }

    // MARK: - Dependencies

    private let configuration: Configuration
    private let viewModel: any DiceGameViewModeling
    private lazy var router = BaseRouter(sourceViewController: self)

    // MARK: - State

    private let confirmedResultSubject = PassthroughSubject<DiceRollResult, Never>()
    private let resultExpansionToggleSubject = PassthroughSubject<Void, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: DiceGameViewState

    // MARK: - UI Elements

    private let diceGameView: DiceGameView
    private let resultView: DiceGameResultView
    private let confirmBottomBar = DiceGameBottomBar()
    private lazy var exitBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.down.right.and.arrow.up.left"),
        primaryAction: UIAction { [weak self] _ in
            self?.showExitConfirmation()
        }
    )

    // MARK: - Lifecycle

    init(
        configuration: Configuration,
        viewModel: any DiceGameViewModeling
    ) {
        self.configuration = configuration
        self.viewModel = viewModel
        diceGameView = DiceGameView(configuration: configuration.contentView)
        resultView = DiceGameResultView()
        renderedState = configuration.initialState
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
        view.addSubview(confirmBottomBar)
        setupConfirmAction()
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
                .lessThanOrEqualTo(confirmBottomBar.snp.top)
                .offset(-Metrics.edgeInset)
        }

        confirmBottomBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func setAppearance() {
        configureResultView()
        configureConfirmButton()
    }

    override func setNavigation() {
        title = configuration.title
        navigationItem.rightBarButtonItem = exitBarButtonItem
    }

    override func bind() {
        let input = DiceGameViewModelInput(
            confirmedResult: confirmedResultSubject.eraseToAnyPublisher(),
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
            .sink { [weak diceGameView] command in
                diceGameView?.execute(command)
            }
            .store(in: &cancellables)
    }

    // MARK: - Setup

    private func setupConfirmAction() {
        confirmBottomBar.tapHandler = { [weak self] in
            self?.confirmDiceResult()
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
            configureConfirmButton()
        }
    }

    // MARK: - UI Configuration

    private func configureResultView() {
        resultView.configure(with: renderedState.result)
    }

    private func configureConfirmButton() {
        confirmBottomBar.isEnabled = !renderedState.game.isDiceLocked
    }

    // MARK: - Actions

    private func confirmDiceResult() {
        let result = diceGameView.lockAndCaptureResult()
        confirmedResultSubject.send(result)
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

    convenience init(configuration: DiceGameConfiguration = .standard) {
        let initialGameState = configuration.initialState
        let initialState = DiceGameViewState(
            game: initialGameState,
            result: .awaitingResult(hintText: configuration.hintText)
        )
        let viewModel = DiceGameViewModel(initialState: initialState)

        self.init(
            configuration: Configuration(
                title: configuration.title,
                initialState: initialState,
                contentView: DiceGameView.Configuration(
                    initialState: initialGameState,
                    gameDiceView: GameDiceView.Configuration(
                        initialDiceCountState: configuration.initialDiceCountState,
                        maximumDiceCount: configuration.maximumDiceCount
                    )
                )
            ),
            viewModel: viewModel
        )
    }
}

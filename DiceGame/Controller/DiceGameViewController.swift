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
        let contentView: DiceGameView.Configuration
    }

    private struct ControlButtonItem {

        let control: DiceGameControl
        let button: UIButton
    }

    private enum Metrics {
        static let controlButtonSize: CGFloat = 56
        static let controlButtonSpacing: CGFloat = 16
        static let edgeInset: CGFloat = 16
        static let resultViewHeight: CGFloat = 88
    }

    // MARK: - Dependencies

    private let configuration: Configuration
    private let viewModel: any DiceGameViewModeling
    private lazy var router = BaseRouter(sourceViewController: self)

    // MARK: - State

    private let confirmedResultSubject = PassthroughSubject<DiceRollResult, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: DiceGameState

    // MARK: - UI Elements

    private let diceGameView: DiceGameView
    private let resultView = DiceGameResultView()

    private lazy var controlButtons = DiceGameControl.allCases.map { control in
        ControlButtonItem(
            control: control,
            button: ViewFactory.makeIconButton(systemName: systemName(for: control))
        )
    }

    private lazy var controlStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: controlButtons.map(\.button)
        )
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = Metrics.controlButtonSpacing
        stackView.isOpaque = false
        stackView.clipsToBounds = false
        return stackView
    }()

    // MARK: - Lifecycle

    init(
        configuration: Configuration,
        viewModel: any DiceGameViewModeling
    ) {
        self.configuration = configuration
        self.viewModel = viewModel
        diceGameView = DiceGameView(configuration: configuration.contentView)
        renderedState = configuration.contentView.initialState
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
        view.addSubview(controlStackView)
        setupControlActions()
    }

    override func setLayout() {
        diceGameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        resultView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.height.equalTo(Metrics.resultViewHeight)
        }

        controlStackView.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
        }

        controlButtons.forEach { item in
            item.button.snp.makeConstraints { make in
                make.size.equalTo(Metrics.controlButtonSize)
            }
        }
    }

    override func setAppearance() {
        configureResultView()
        configureControlButtons()
    }

    override func setNavigation() {
        title = configuration.title
    }

    override func bind() {
        let input = DiceGameViewModelInput(
            confirmedResult: confirmedResultSubject.eraseToAnyPublisher(),
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

    private func setupControlActions() {
        controlButtons.forEach { item in
            let control = item.control
            item.button.addAction(
                UIAction { [weak self] _ in
                    self?.didSelectControl(control)
                },
                for: .primaryActionTriggered
            )
        }
    }

    // MARK: - State Updates

    private func apply(_ state: DiceGameState) {
        diceGameView.configure(with: state)

        if renderedState != state {
            renderedState = state
            configureResultView()
            configureControlButtons()
        }
    }

    // MARK: - UI Configuration

    private func configureResultView() {
        resultView.configure(result: renderedState.result)
    }

    private func configureControlButtons() {
        controlButtons.forEach { item in
            configure(item.button, for: item.control)
        }
    }

    private func configure(_ button: UIButton, for control: DiceGameControl) {
        let foregroundColor: UIColor

        switch control {
        case .action:
            foregroundColor = .label

        case .exit:
            foregroundColor = .label
        }

        var configuration = button.configuration
        configuration?.image = UIImage(systemName: systemName(for: control))
        configuration?.baseForegroundColor = foregroundColor
        button.configuration = configuration

        switch control {
        case .action:
            button.isEnabled = !renderedState.isDiceLocked
        case .exit:
            button.isEnabled = true
        }
    }

    private func systemName(for control: DiceGameControl) -> String {
        switch control {
        case .action:
            return "checkmark"
        case .exit:
            return "arrow.down.right.and.arrow.up.left"
        }
    }

    // MARK: - Actions

    private func didSelectControl(_ control: DiceGameControl) {
        switch control {
        case .action:
            let result = diceGameView.lockAndCaptureResult()
            confirmedResultSubject.send(result)
        case .exit:
            showExitConfirmation()
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

    convenience init(configuration: DiceGameConfiguration = .standard) {
        let initialState = configuration.initialState
        let viewModel = DiceGameViewModel(initialState: initialState)

        self.init(
            configuration: Configuration(
                title: configuration.title,
                contentView: DiceGameView.Configuration(
                    initialState: initialState,
                    gameDiceView: GameDiceView.Configuration(
                        initialDiceCount: configuration.initialDiceCount,
                        maximumDiceCount: configuration.maximumDiceCount
                    )
                )
            ),
            viewModel: viewModel
        )
    }
}

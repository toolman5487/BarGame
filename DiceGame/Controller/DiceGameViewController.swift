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
        let unlockedHintText: String
        let lockedHintText: String
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
    }

    // MARK: - Dependencies

    private let configuration: Configuration
    private let viewModel: any DiceGameViewModeling
    private lazy var router = BaseRouter(sourceViewController: self)

    // MARK: - State

    private let selectedControlSubject = PassthroughSubject<DiceGameControl, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: DiceGameState

    // MARK: - UI Elements

    private let diceGameView: DiceGameView

    private let hintLabel = ViewFactory.makeGlassLabel(
        textStyle: .subheadline,
        textColor: .label,
        textAlignment: .center,
        numberOfLines: 1
    )

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
        view.addSubview(hintLabel)
        view.addSubview(controlStackView)
        setupControlActions()
    }

    override func setLayout() {
        diceGameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.centerX.equalToSuperview()
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
        configureHintLabel()
        configureControlButtons()
    }

    override func setNavigation() {
        title = configuration.title
    }

    override func bind() {
        let input = DiceGameViewModelInput(
            selectedControl: selectedControlSubject.eraseToAnyPublisher(),
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
            configureHintLabel()
            configureControlButtons()
        }
    }

    // MARK: - UI Configuration

    private func configureHintLabel() {
        hintLabel.configure(
            text: renderedState.isDiceLocked
                ? configuration.lockedHintText
                : configuration.unlockedHintText
        )
    }

    private func configureControlButtons() {
        controlButtons.forEach { item in
            configure(item.button, for: item.control)
        }
    }

    private func configure(_ button: UIButton, for control: DiceGameControl) {
        let foregroundColor: UIColor

        switch control {
        case .lock:
            foregroundColor = renderedState.isDiceLocked ? .systemOrange : .label

        case .action:
            foregroundColor = .label

        case .exit:
            foregroundColor = .systemRed
        }

        var configuration = button.configuration
        configuration?.image = UIImage(systemName: systemName(for: control))
        configuration?.baseForegroundColor = foregroundColor
        button.configuration = configuration
        button.isEnabled = renderedState.isEnabled(control)
    }

    private func systemName(for control: DiceGameControl) -> String {
        switch control {
        case .lock:
            return renderedState.isDiceLocked ? "lock.fill" : "lock.open"
        case .action:
            return actionImageName
        case .exit:
            return "xmark"
        }
    }

    private var actionImageName: String {
        switch renderedState.viewMode {
        case .perspective:
            return "checkmark"
        case .topDown:
            return "arrow.backward"
        }
    }

    // MARK: - Actions

    private func didSelectControl(_ control: DiceGameControl) {
        switch control {
        case .lock, .action:
            selectedControlSubject.send(control)
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
                unlockedHintText: configuration.unlockedHintText,
                lockedHintText: configuration.lockedHintText,
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

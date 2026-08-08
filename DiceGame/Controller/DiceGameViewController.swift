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

    private enum Metrics {
        static let controlButtonSize: CGFloat = 56
        static let controlButtonSpacing: CGFloat = 16
        static let controlStackCenterYOffset: CGFloat = 80
        static let edgeInset: CGFloat = 16
    }

    // MARK: - Dependencies

    private let configuration: Configuration
    private let viewModel: any DiceGameViewModeling

    // MARK: - State

    private let selectedControlSubject = PassthroughSubject<DiceGameControl, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: DiceGameState

    // MARK: - UI Elements

    private let diceGameView: DiceGameView

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        return label
    }()

    private lazy var controlButtons = DiceGameControl.allCases.map { control in
        DiceControlButton(control: control)
    }

    private lazy var controlStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: controlButtons)
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
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
        }

        controlStackView.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
            make.centerY
                .equalTo(view.safeAreaLayoutGuide)
                .offset(Metrics.controlStackCenterYOffset)
                .priority(.high)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(Metrics.edgeInset)
        }

        controlButtons.forEach { button in
            button.snp.makeConstraints { make in
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
        controlButtons.forEach { button in
            button.addTarget(
                self,
                action: #selector(didSelectControl(_:)),
                for: .touchUpInside
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
        hintLabel.text = renderedState.isDiceLocked
            ? configuration.lockedHintText
            : configuration.unlockedHintText
    }

    private func configureControlButtons() {
        controlButtons.forEach { button in
            configure(button, for: button.control)
        }
    }

    private func configure(_ button: DiceControlButton, for control: DiceGameControl) {
        let configuration: DiceControlButton.Configuration

        switch control {
        case .lock:
            configuration = DiceControlButton.Configuration(
                image: UIImage(
                    systemName: renderedState.isDiceLocked ? "lock.fill" : "lock.open"
                ),
                foregroundColor: renderedState.isDiceLocked ? .systemOrange : .label,
                isEnabled: renderedState.isEnabled(.lock)
            )

        case .add:
            configuration = DiceControlButton.Configuration(
                image: UIImage(systemName: "plus"),
                foregroundColor: .label,
                isEnabled: renderedState.isEnabled(.add)
            )

        case .action:
            configuration = DiceControlButton.Configuration(
                image: UIImage(systemName: actionImageName),
                foregroundColor: .label,
                isEnabled: renderedState.isEnabled(.action)
            )
        }

        button.configure(with: configuration)
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

    @objc
    private func didSelectControl(_ button: DiceControlButton) {
        selectedControlSubject.send(button.control)
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

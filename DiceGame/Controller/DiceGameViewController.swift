//
//  DiceGameViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import UIKit

@MainActor
final class DiceGameViewController: UIViewController {

    // MARK: - Types

    struct Configuration {

        let title: String
        let contentView: DiceGameView.Configuration
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let contentView: DiceGameView
    private let viewModel: any DiceGameViewModeling
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(
        configuration: Configuration,
        viewModel: any DiceGameViewModeling
    ) {
        self.configuration = configuration
        contentView = DiceGameView(configuration: configuration.contentView)
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = configuration.title
        bindViewModel()
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

    // MARK: - Binding

    private func bindViewModel() {
        let input = DiceGameViewModelInput(
            selectedControl: contentView.selectedControlPublisher,
            shakeMotion: shakeMotionSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak contentView] state in
                contentView?.configure(with: state)
            }
            .store(in: &cancellables)

        output.command
            .sink { [weak contentView] command in
                contentView?.execute(command)
            }
            .store(in: &cancellables)
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
                        maximumDiceCount: configuration.maximumDiceCount,
                        unlockedHintText: configuration.unlockedHintText,
                        lockedHintText: configuration.lockedHintText
                    )
                )
            ),
            viewModel: viewModel
        )
    }
}

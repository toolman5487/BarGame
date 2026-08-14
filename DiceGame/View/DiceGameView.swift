//
//  DiceGameView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import SnapKit
import UIKit

nonisolated struct DiceGameViewConfiguration: Sendable {

    let initialState: DiceGameState
    let gameDiceView: GameDiceViewConfiguration
}

@MainActor
final class DiceGameView: UIView {

    // MARK: - UI Elements

    private let gameDiceView: GameDiceView

    // MARK: - State

    private var renderedState: DiceGameState

    // MARK: - Lifecycle

    init(configuration: DiceGameViewConfiguration) {
        gameDiceView = GameDiceView(configuration: configuration.gameDiceView)
        renderedState = configuration.initialState
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupViewHierarchy()
        setupViewLayout()
        applyRenderedState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with state: DiceGameState) {
        let previousState = renderedState
        renderedState = state

        if previousState.isDiceLocked != state.isDiceLocked {
            gameDiceView.setInteractionLocked(state.isDiceLocked)
        }

        if previousState.viewMode != state.viewMode {
            switch state.viewMode {
            case .perspective:
                gameDiceView.showPerspectiveView()
            case .topDown:
                gameDiceView.showTopDownView()
            }
        }
    }

    func execute(_ command: DiceGameSceneCommand) {
        switch command {
        case .shakeDice:
            gameDiceView.shake()
        case .prepareNextRound:
            gameDiceView.prepareForNextRound()
        }
    }

    func lockAndCaptureResult() -> DiceRollResult {
        gameDiceView.setInteractionLocked(true)
        return DiceRollResult(values: gameDiceView.currentValues())
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        addSubview(gameDiceView)
    }

    private func setupViewLayout() {
        gameDiceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func applyRenderedState() {
        gameDiceView.setInteractionLocked(renderedState.isDiceLocked)

        switch renderedState.viewMode {
        case .perspective:
            gameDiceView.showPerspectiveView()
        case .topDown:
            gameDiceView.showTopDownView()
        }
    }
}

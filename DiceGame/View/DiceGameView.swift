//
//  DiceGameView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import SnapKit
import UIKit

@MainActor
final class DiceGameView: UIView {

    // MARK: - Types

    nonisolated struct Configuration: Sendable {

        let initialState: DiceGameState
        let gameDiceView: GameDiceView.Configuration
    }

    private enum Layout {
        static let controlItemSize: CGFloat = 56
        static let controlItemSpacing: CGFloat = 12
        static let edgeInset: CGFloat = 16
        static let controlCollectionHeight = controlItemSize * 3 + controlItemSpacing * 2
    }

    // MARK: - Properties

    private let gameDiceView: GameDiceView
    private lazy var controlCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(
            width: Layout.controlItemSize,
            height: Layout.controlItemSize
        )
        layout.minimumLineSpacing = Layout.controlItemSpacing

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            DiceControlCollectionViewCell.self,
            forCellWithReuseIdentifier: DiceControlCollectionViewCell.reuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let selectedControlSubject = PassthroughSubject<DiceGameControl, Never>()
    private var renderedState: DiceGameState

    var selectedControlPublisher: AnyPublisher<DiceGameControl, Never> {
        selectedControlSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle

    init(configuration: Configuration) {
        gameDiceView = GameDiceView(configuration: configuration.gameDiceView)
        renderedState = configuration.initialState
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupViewHierarchy()
        setupViewLayout()
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

        if previousState != state {
            controlCollectionView.reloadData()
        }
    }

    func execute(_ command: DiceGameViewCommand) {
        switch command {
        case .addDice:
            gameDiceView.addDice()
        case .shakeDice:
            gameDiceView.shake()
        }
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        addSubview(gameDiceView)
        addSubview(controlCollectionView)
    }

    private func setupViewLayout() {
        gameDiceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        controlCollectionView.snp.makeConstraints { make in
            make.right.bottom.equalTo(safeAreaLayoutGuide).inset(Layout.edgeInset)
            make.width.equalTo(Layout.controlItemSize)
            make.height.equalTo(Layout.controlCollectionHeight)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension DiceGameView: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        DiceGameControl.allCases.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let control = DiceGameControl(rawValue: indexPath.item),
              let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DiceControlCollectionViewCell.reuseIdentifier,
                for: indexPath
              ) as? DiceControlCollectionViewCell else {
            return UICollectionViewCell()
        }

        configure(cell, for: control)
        return cell
    }

    // MARK: - Cell Configuration

    private func configure(
        _ cell: DiceControlCollectionViewCell,
        for control: DiceGameControl
    ) {
        switch control {
        case .lock:
            cell.configure(
                with: DiceControlCollectionViewCell.Configuration(
                    image: UIImage(
                        systemName: renderedState.isDiceLocked ? "lock.fill" : "lock.open"
                    ),
                    foregroundColor: renderedState.isDiceLocked ? .systemOrange : .label,
                    isEnabled: renderedState.isEnabled(.lock)
                )
            )

        case .add:
            cell.configure(
                with: DiceControlCollectionViewCell.Configuration(
                    image: UIImage(systemName: "plus"),
                    foregroundColor: .label,
                    isEnabled: renderedState.isEnabled(.add)
                )
            )

        case .action:
            cell.configure(
                with: DiceControlCollectionViewCell.Configuration(
                    image: UIImage(systemName: actionImageName),
                    foregroundColor: .label,
                    isEnabled: renderedState.isEnabled(.action)
                )
            )
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
}

// MARK: - UICollectionViewDelegate

extension DiceGameView: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let control = DiceGameControl(rawValue: indexPath.item) else { return }
        selectedControlSubject.send(control)
    }
}

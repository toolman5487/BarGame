//
//  GameDetailViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Combine
import SnapKit
import UIKit

@MainActor
final class GameDetailViewController: DetailBaseViewController {

    // MARK: - Dependencies

    private let viewModel: any GameDetailViewModeling
    private let screenBuilder: any AppScreenBuilding
    private lazy var router: any GameDetailRouting = GameDetailRouter(
        sourceViewController: self,
        screenBuilder: screenBuilder
    )

    // MARK: - State

    private let settingChangeSubject = PassthroughSubject<
        GameDetailSettingChange,
        Never
    >()
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let locationRequestSubject = PassthroughSubject<Void, Never>()
    private let startGameSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedState: GameDetailState

    private var sections: [GameDetailSection] {
        renderedState.sections
    }

    // MARK: - UI Elements

    private let bottomBar = BottomBar(title: "進入遊戲")

    // MARK: - Lifecycle

    init(
        title: String,
        initialState: GameDetailState,
        viewModel: any GameDetailViewModeling,
        screenBuilder: any AppScreenBuilding
    ) {
        self.viewModel = viewModel
        self.screenBuilder = screenBuilder
        renderedState = initialState
        super.init(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.dataSource = self
        collectionView.register(GameDetailRuleCell.self)
        collectionView.register(GameDetailSettingCell.self)
        collectionView.register(GameDetailLocationCell.self)
        collectionView.register(GameDetailStatisticsCell.self)
        collectionView.register(GameDetailRecentRecordsCell.self)
        collectionView.register(GameDetailTitleHeader.self)
        view.addSubview(bottomBar)
    }

    override func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize {
        guard sections.indices.contains(indexPath.section) else {
            return super.collectionViewItemSize(in: collectionView, at: indexPath)
        }

        switch sections[indexPath.section] {
        case .rules(let rules):
            let standardSize = super.collectionViewItemSize(
                in: collectionView,
                at: indexPath
            )
            return CGSize(
                width: standardSize.width,
                height: GameDetailRuleCell.preferredHeight(
                    for: rules,
                    width: standardSize.width
                )
            )

        case .statistics:
            let standardSize = super.collectionViewItemSize(
                in: collectionView,
                at: indexPath
            )
            return CGSize(
                width: standardSize.width,
                height: GameDetailStatisticsCell.Metrics.preferredHeight
            )

        case .recentRecords(let state):
            return CGSize(
                width: collectionView.bounds.width,
                height: GameDetailRecentRecordsCell.Metrics.preferredHeight(
                    for: state
                )
            )

        case .location:
            let standardSize = super.collectionViewItemSize(
                in: collectionView,
                at: indexPath
            )
            return CGSize(
                width: standardSize.width,
                height: GameDetailLocationCell.Metrics.preferredHeight
            )

        case .settings:
            return super.collectionViewItemSize(in: collectionView, at: indexPath)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard sections.indices.contains(section) else {
            return collectionViewSectionInset
        }

        switch sections[section] {
        case .recentRecords:
            return .zero

        case .rules:
            return collectionViewSectionInset

        case .settings:
            return collectionViewSectionInset

        case .location:
            return collectionViewSectionInset

        case .statistics:
            return collectionViewSectionInset
        }
    }

    override func setLayout() {
        super.setLayout()

        bottomBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        collectionView.contentInset.bottom = BottomBar.contentHeight
        collectionView.verticalScrollIndicatorInsets.bottom = BottomBar.contentHeight
        bottomBar.tapHandler = { [weak self] in
            self?.startGame()
        }
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        guard sections.indices.contains(section),
              sections[section].headerTitle != nil
        else { return .zero }

        return CGSize(
            width: collectionView.bounds.width,
            height: GameDetailTitleHeader.Metrics.preferredHeight
        )
    }

    override func bind() {
        let input = GameDetailViewModelInput(
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            settingChange: settingChangeSubject.eraseToAnyPublisher(),
            locationRequest: locationRequestSubject.eraseToAnyPublisher(),
            startGame: startGameSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)

        output.launchConfiguration
            .sink { [weak self] configuration in
                self?.router.route(to: .startGame(configuration))
            }
            .store(in: &cancellables)
    }

    // MARK: - State Updates

    private func apply(_ state: GameDetailState) {
        renderedState = state
        bottomBar.isEnabled = !state.isLocationRequestInProgress
        collectionView.reloadData()
    }

    // MARK: - Actions

    private func startGame() {
        startGameSubject.send()
    }
}

// MARK: - UICollectionViewDataSource

extension GameDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard sections.indices.contains(section) else { return 0 }

        switch sections[section] {
        case .rules(let rules):
            return rules.isEmpty ? 0 : 1

        case .settings(let settings):
            return settings.count

        case .location:
            return 1

        case .statistics:
            return 1

        case .recentRecords:
            return 1
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard sections.indices.contains(indexPath.section) else {
            preconditionFailure("Invalid GameDetail section index: \(indexPath.section)")
        }

        switch sections[indexPath.section] {
        case .rules(let rules):
            let cell = collectionView.dequeueReusableCell(
                GameDetailRuleCell.self,
                for: indexPath
            )
            cell.configure(rules: rules)
            return cell

        case .settings(let settings):
            guard settings.indices.contains(indexPath.item) else {
                preconditionFailure("Invalid GameDetail setting index: \(indexPath.item)")
            }

            let cell = collectionView.dequeueReusableCell(
                GameDetailSettingCell.self,
                for: indexPath
            )
            cell.configure(setting: settings[indexPath.item])
            cell.valueChanged = { [weak self] value in
                self?.settingChangeSubject.send(.diceCount(value))
            }
            return cell

        case .location(let state):
            let cell = collectionView.dequeueReusableCell(
                GameDetailLocationCell.self,
                for: indexPath
            )
            cell.configure(state: state)
            cell.locationRequest = { [weak self] in
                self?.locationRequestSubject.send()
            }
            return cell

        case .statistics(let state):
            let cell = collectionView.dequeueReusableCell(
                GameDetailStatisticsCell.self,
                for: indexPath
            )
            cell.configure(state: state)
            return cell

        case .recentRecords(let state):
            let cell = collectionView.dequeueReusableCell(
                GameDetailRecentRecordsCell.self,
                for: indexPath
            )
            cell.configure(state: state)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == GameDetailTitleHeader.elementKind,
              sections.indices.contains(indexPath.section),
              let title = sections[indexPath.section].headerTitle
        else { return UICollectionReusableView() }

        let header = collectionView.dequeueReusableHeader(
            GameDetailTitleHeader.self,
            for: indexPath
        )
        header.configure(title: title)
        return header
    }
}

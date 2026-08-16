//
//  MainGameHistoryViewController.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Combine
import UIKit

@MainActor
final class MainGameHistoryViewController: MainBaseViewController {

    // MARK: - Metrics

    private enum Metrics {
        static let skeletonItemCount = 5
    }

    // MARK: - Dependencies

    private let viewModel: any MainGameHistoryViewModeling

    // MARK: - Input

    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let filterChangeSubject = PassthroughSubject<
        MainGameHistoryFilterChange,
        Never
    >()
    private let retryRequestSubject = PassthroughSubject<Void, Never>()

    // MARK: - State

    private var state = MainGameHistoryViewState.initial
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private lazy var filterBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "line.3.horizontal.decrease"),
        menu: makeSecondaryFilterMenu(for: state.filter)
    )

    // MARK: - Lifecycle

    init(
        title: String,
        viewModel: any MainGameHistoryViewModeling
    ) {
        self.viewModel = viewModel
        super.init(title: title)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.register(MainGameHistoryRecordCell.self)
        collectionView.register(MainGameHistoryStateCell.self)
        collectionView.register(MainGameHistoryFilterHeader.self)
        collectionView.dataSource = self
        collectionView.allowsSelection = false

        guard let layout = collectionView.collectionViewLayout
            as? UICollectionViewFlowLayout else {
            return
        }
        layout.sectionHeadersPinToVisibleBounds = true
    }

    override func setNavigation() {
        super.setNavigation()
        navigationItem.rightBarButtonItem = filterBarButtonItem
    }

    override func bind() {
        let input = MainGameHistoryViewModelInput(
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            filterChange: filterChangeSubject.eraseToAnyPublisher(),
            retryRequest: retryRequestSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)
    }

    override func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize {
        let inset = collectionViewSectionInset
        let width = max(
            0,
            collectionView.bounds.width - inset.left - inset.right
        )

        switch state.contentState {
        case .loading, .records:
            return CGSize(
                width: width,
                height: MainGameHistoryRecordCell.Metrics.preferredHeight
            )

        case .idle, .empty, .failed:
            let adjustedInset = collectionView.adjustedContentInset
            let availableHeight = collectionView.bounds.height
                - adjustedInset.top
                - adjustedInset.bottom
                - MainGameHistoryFilterHeader.Metrics.preferredHeight
            return CGSize(
                width: width,
                height: max(
                    BaseHintView.Metrics.preferredHeight,
                    availableHeight
                )
            )
        }
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: MainGameHistoryFilterHeader.Metrics.preferredHeight
        )
    }

    // MARK: - State Updates

    private func apply(_ state: MainGameHistoryViewState) {
        self.state = state
        filterBarButtonItem.menu = makeSecondaryFilterMenu(for: state.filter)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func makeSecondaryFilterMenu(
        for filter: MainGameHistoryFilter
    ) -> UIMenu {
        let newestAction = UIAction(
            title: "最新",
            image: UIImage(systemName: "arrow.down"),
            state: filter.sortOrder == .newest ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.sortOrder(.newest))
        }
        let oldestAction = UIAction(
            title: "最舊",
            image: UIImage(systemName: "arrow.up"),
            state: filter.sortOrder == .oldest ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.sortOrder(.oldest))
        }
        let sortMenu = UIMenu(
            title: "排序",
            options: .displayInline,
            children: [newestAction, oldestAction]
        )

        let allOutcomesAction = UIAction(
            title: "全部結果",
            image: UIImage(systemName: "flag.checkered"),
            state: filter.outcome == nil ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.outcome(nil))
        }
        let winAction = UIAction(
            title: "勝利",
            image: UIImage(systemName: "trophy.fill"),
            state: filter.outcome == .win ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.outcome(.win))
        }
        let lossAction = UIAction(
            title: "敗北",
            image: UIImage(systemName: "flag.fill"),
            state: filter.outcome == .loss ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.outcome(.loss))
        }
        let drawAction = UIAction(
            title: "平手",
            image: UIImage(systemName: "equal.circle.fill"),
            state: filter.outcome == .draw ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(.outcome(.draw))
        }
        let outcomeMenu = UIMenu(
            title: "結果",
            options: .displayInline,
            children: [allOutcomesAction, winAction, lossAction, drawAction]
        )

        return UIMenu(children: [sortMenu, outcomeMenu])
    }
}

// MARK: - UICollectionViewDataSource

extension MainGameHistoryViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        switch state.contentState {
        case .idle:
            return 0

        case .loading:
            return Metrics.skeletonItemCount

        case .records(let records):
            return records.count

        case .empty, .failed:
            return 1
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch state.contentState {
        case .idle:
            preconditionFailure("Idle history state must not request a cell")

        case .loading:
            let cell = collectionView.dequeueReusableCell(
                MainGameHistoryRecordCell.self,
                for: indexPath
            )
            cell.showLoadingState()
            return cell

        case .records(let records):
            let cell = collectionView.dequeueReusableCell(
                MainGameHistoryRecordCell.self,
                for: indexPath
            )
            cell.configure(item: records[indexPath.item])
            return cell

        case .empty, .failed:
            let cell = collectionView.dequeueReusableCell(
                MainGameHistoryStateCell.self,
                for: indexPath
            )
            cell.configure(contentState: state.contentState)
            cell.retryHandler = { [weak self] in
                self?.retryRequestSubject.send()
            }
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == MainGameHistoryFilterHeader.elementKind else {
            return UICollectionReusableView()
        }

        let header = collectionView.dequeueReusableHeader(
            MainGameHistoryFilterHeader.self,
            for: indexPath
        )
        header.configure(filter: state.filter) { [weak self] change in
            self?.filterChangeSubject.send(change)
        }
        return header
    }
}

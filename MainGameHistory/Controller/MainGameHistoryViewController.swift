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
    private let screenBuilder: any AppScreenBuilding
    private lazy var router: any MainGameHistoryRouting = MainGameHistoryRouter(
        sourceViewController: self,
        screenBuilder: screenBuilder
    )

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

    private lazy var sortBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.up.arrow.down"),
        menu: makeSortMenu(for: state.filter)
    )

    private lazy var filterBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "line.3.horizontal.decrease"),
        menu: makeOutcomeFilterMenu(for: state.filter)
    )

    private lazy var sortBarButtonItemGroup = UIBarButtonItemGroup.fixedGroup(
        items: [sortBarButtonItem]
    )

    private lazy var filterBarButtonItemGroup = UIBarButtonItemGroup.fixedGroup(
        items: [filterBarButtonItem]
    )

    // MARK: - Lifecycle

    init(
        title: String,
        viewModel: any MainGameHistoryViewModeling,
        screenBuilder: any AppScreenBuilding
    ) {
        self.viewModel = viewModel
        self.screenBuilder = screenBuilder
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
        collectionView.allowsSelection = true

        guard let layout = collectionView.collectionViewLayout
            as? UICollectionViewFlowLayout else {
            return
        }
        layout.sectionHeadersPinToVisibleBounds = true
    }

    override func setNavigation() {
        super.setNavigation()
        navigationItem.trailingItemGroups = [
            sortBarButtonItemGroup,
            .fixedSpace(),
            filterBarButtonItemGroup
        ]
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
        sortBarButtonItem.menu = makeSortMenu(for: state.filter)
        filterBarButtonItem.menu = makeOutcomeFilterMenu(for: state.filter)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func makeSortMenu(
        for filter: MainGameHistoryFilter
    ) -> UIMenu {
        UIMenu(
            children: SortMenuOption.allCases.map { option in
                makeFilterAction(
                    title: option.title,
                    systemImage: option.systemImage,
                    isSelected: option.isSelected(in: filter),
                    change: option.change
                )
            }
        )
    }

    private func makeOutcomeFilterMenu(
        for filter: MainGameHistoryFilter
    ) -> UIMenu {
        UIMenu(
            children: OutcomeMenuOption.allCases.map { option in
                makeFilterAction(
                    title: option.title,
                    systemImage: option.systemImage,
                    isSelected: option.isSelected(in: filter),
                    change: option.change
                )
            }
        )
    }

    private func makeFilterAction(
        title: String,
        systemImage: String,
        isSelected: Bool,
        change: MainGameHistoryFilterChange
    ) -> UIAction {
        UIAction(
            title: title,
            image: UIImage(systemName: systemImage),
            state: isSelected ? .on : .off
        ) { [weak self] _ in
            self?.filterChangeSubject.send(change)
        }
    }

    // MARK: - Selection

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .records(let records) = state.contentState,
              records.indices.contains(indexPath.item)
        else { return }

        let record = records[indexPath.item]
        router.route(
            to: .matchDetail(
                recordID: record.id,
                gameID: record.gameID,
                outcome: record.outcome
            )
        )
    }
}

// MARK: - Filter Menu Options

private enum SortMenuOption: CaseIterable {
    case newest
    case oldest

    var title: String {
        switch self {
        case .newest:
            return "最新"

        case .oldest:
            return "最舊"
        }
    }

    var systemImage: String {
        switch self {
        case .newest:
            return "arrow.down"

        case .oldest:
            return "arrow.up"
        }
    }

    var change: MainGameHistoryFilterChange {
        switch self {
        case .newest:
            return .sortOrder(.newest)

        case .oldest:
            return .sortOrder(.oldest)
        }
    }

    func isSelected(in filter: MainGameHistoryFilter) -> Bool {
        switch self {
        case .newest:
            return filter.sortOrder == .newest

        case .oldest:
            return filter.sortOrder == .oldest
        }
    }
}

private enum OutcomeMenuOption: CaseIterable {
    case all
    case win
    case loss
    case draw

    var title: String {
        switch self {
        case .all:
            return "全部結果"

        case .win:
            return "勝利"

        case .loss:
            return "敗北"

        case .draw:
            return "平手"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "flag.checkered"

        case .win:
            return "trophy.fill"

        case .loss:
            return "flag.fill"

        case .draw:
            return "flag.and.flag.filled.crossed"
        }
    }

    var change: MainGameHistoryFilterChange {
        switch self {
        case .all:
            return .outcome(nil)

        case .win:
            return .outcome(.win)

        case .loss:
            return .outcome(.loss)

        case .draw:
            return .outcome(.draw)
        }
    }

    func isSelected(in filter: MainGameHistoryFilter) -> Bool {
        switch self {
        case .all:
            return filter.outcome == nil

        case .win:
            return filter.outcome == .win

        case .loss:
            return filter.outcome == .loss

        case .draw:
            return filter.outcome == .draw
        }
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

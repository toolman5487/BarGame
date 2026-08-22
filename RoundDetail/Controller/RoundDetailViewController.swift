//
//  RoundDetailViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/22.
//

import Combine
import UIKit

@MainActor
final class RoundDetailViewController: DetailBaseViewController {

    // MARK: - Dependencies

    private let viewModel: any RoundDetailViewModeling

    // MARK: - Input

    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let retryRequestSubject = PassthroughSubject<Void, Never>()

    // MARK: - State

    private var state = RoundDetailViewState.idle
    private var sections: [RoundDetailSection] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(viewModel: any RoundDetailViewModeling) {
        self.viewModel = viewModel
        super.init(title: "回合詳情")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        collectionView.dataSource = self
        collectionView.allowsSelection = false
        collectionView.register(RoundDetailSummaryCell.self)
        collectionView.register(RoundDetailDiceResultCell.self)
        collectionView.register(RoundDetailDistributionCell.self)
        collectionView.register(RoundDetailStateCell.self)
        collectionView.register(RoundDetailTitleHeader.self)
    }

    override func bind() {
        let input = RoundDetailViewModelInput(
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
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
        let width = max(
            0,
            collectionView.bounds.width
                - collectionViewSectionInset.left
                - collectionViewSectionInset.right
        )

        guard case .content(let presentation) = state,
              sections.indices.contains(indexPath.section)
        else {
            let adjustedInset = collectionView.adjustedContentInset
            let height = collectionView.bounds.height
                - adjustedInset.top
                - adjustedInset.bottom
            return CGSize(
                width: width,
                height: max(BaseHintView.Metrics.preferredHeight, height)
            )
        }

        let height: CGFloat
        switch sections[indexPath.section] {
        case .summary:
            height = RoundDetailSummaryCell.Metrics.preferredHeight

        case .diceResult:
            height = RoundDetailDiceResultCell.preferredHeight(
                diceCount: presentation.dice.count,
                width: width
            )

        case .distribution:
            height = RoundDetailDistributionCell.Metrics.preferredHeight
        }

        return CGSize(width: width, height: height)
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        guard sections.indices.contains(section),
              sections[section].title != nil
        else { return .zero }

        return CGSize(
            width: collectionView.bounds.width,
            height: RoundDetailTitleHeader.Metrics.preferredHeight
        )
    }

    // MARK: - State Updates

    private func apply(_ state: RoundDetailViewState) {
        self.state = state

        switch state {
        case .idle, .loading, .failed:
            sections = []
            title = "回合詳情"

        case .content(let presentation):
            sections = [
                .summary,
                .diceResult,
                .distribution,
            ]
            title = presentation.navigationTitle
        }

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionViewDataSource

extension RoundDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch state {
        case .idle, .loading, .failed:
            return 1

        case .content:
            return sections.count
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard case .content(let presentation) = state else {
            let cell = collectionView.dequeueReusableCell(
                RoundDetailStateCell.self,
                for: indexPath
            )
            cell.configure(state: state)
            cell.retryHandler = { [weak self] in
                self?.retryRequestSubject.send()
            }
            return cell
        }

        guard sections.indices.contains(indexPath.section) else {
            preconditionFailure(
                "Invalid RoundDetail section index: \(indexPath.section)"
            )
        }

        switch sections[indexPath.section] {
        case .summary:
            let cell = collectionView.dequeueReusableCell(
                RoundDetailSummaryCell.self,
                for: indexPath
            )
            cell.configure(presentation: presentation)
            return cell

        case .diceResult:
            let cell = collectionView.dequeueReusableCell(
                RoundDetailDiceResultCell.self,
                for: indexPath
            )
            cell.configure(items: presentation.dice)
            return cell

        case .distribution:
            let cell = collectionView.dequeueReusableCell(
                RoundDetailDistributionCell.self,
                for: indexPath
            )
            cell.configure(items: presentation.distribution)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == RoundDetailTitleHeader.elementKind,
              sections.indices.contains(indexPath.section),
              let title = sections[indexPath.section].title
        else { return UICollectionReusableView() }

        let header = collectionView.dequeueReusableHeader(
            RoundDetailTitleHeader.self,
            for: indexPath
        )
        header.configure(title: title)
        return header
    }
}

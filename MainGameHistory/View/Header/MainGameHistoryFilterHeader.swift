//
//  MainGameHistoryFilterHeader.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import SnapKit
import UIKit

// MARK: - Filter Header

@MainActor
final class MainGameHistoryFilterHeader: StandardBaseTitleHeader {

    // MARK: - Layout

    enum Metrics {
        static let preferredHeight: CGFloat = 64
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let itemSpacing: CGFloat = 8
    }

    // MARK: - Callback

    private var changeHandler: ((MainGameHistoryFilterChange) -> Void)?

    // MARK: - State

    private let gameIDs: [DiceGameID?] = [nil]
        + DiceGameID.allCases.map(Optional.some)
    private var filter = MainGameHistoryFilter.standard
    private var hasConfiguredFilter = false

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.isDirectionalLockEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MainGameHistoryFilterItemCell.self)
        return collectionView
    }()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        changeHandler = nil
    }

    // MARK: - Overridable

    override func setHierarchy() {
        addSubview(collectionView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        backgroundColor = .clear
    }

    // MARK: - Configuration

    func configure(
        filter: MainGameHistoryFilter,
        changeHandler: @escaping (MainGameHistoryFilterChange) -> Void
    ) {
        let previousGameID = self.filter.gameID
        let hasGameSelectionChanged = previousGameID != filter.gameID

        self.filter = filter
        self.changeHandler = changeHandler

        guard !hasConfiguredFilter || hasGameSelectionChanged else {
            return
        }

        if hasConfiguredFilter {
            reloadSelectionItems(
                previousGameID: previousGameID,
                selectedGameID: filter.gameID
            )
        } else {
            hasConfiguredFilter = true
            collectionView.reloadData()
        }

        restoreSelectedItemVisibility()
    }

    // MARK: - Private

    private func makeCollectionViewLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metrics.itemSpacing
        layout.minimumInteritemSpacing = Metrics.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: Metrics.verticalInset,
            left: Metrics.horizontalInset,
            bottom: Metrics.verticalInset,
            right: Metrics.horizontalInset
        )
        return layout
    }

    private func gameID(at indexPath: IndexPath) -> DiceGameID? {
        gameIDs[indexPath.item]
    }

    private func indexPath(for gameID: DiceGameID?) -> IndexPath? {
        guard let item = gameIDs.firstIndex(where: { $0 == gameID }) else {
            return nil
        }
        return IndexPath(item: item, section: 0)
    }

    private func reloadSelectionItems(
        previousGameID: DiceGameID?,
        selectedGameID: DiceGameID?
    ) {
        let indexPaths = [
            indexPath(for: previousGameID),
            indexPath(for: selectedGameID)
        ].compactMap { $0 }
        collectionView.reloadItems(at: indexPaths)
    }

    private func restoreSelectedItemVisibility() {
        guard let indexPath = indexPath(for: filter.gameID) else {
            return
        }

        collectionView.layoutIfNeeded()
        guard !collectionView.indexPathsForVisibleItems.contains(indexPath) else {
            return
        }

        collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: false
        )
    }

    private func title(for gameID: DiceGameID?) -> String {
        gameID?.title ?? "全部遊戲"
    }
}

// MARK: - UICollectionViewDataSource

extension MainGameHistoryFilterHeader: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        gameIDs.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            MainGameHistoryFilterItemCell.self,
            for: indexPath
        )
        let gameID = gameID(at: indexPath)
        cell.configure(
            title: title(for: gameID),
            isSelected: filter.gameID == gameID
        )
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainGameHistoryFilterHeader: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        changeHandler?(.game(gameID(at: indexPath)))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = title(for: gameID(at: indexPath))
        return CGSize(
            width: MainGameHistoryFilterItemCell.preferredWidth(for: title),
            height: Metrics.preferredHeight - Metrics.verticalInset * 2
        )
    }
}

// MARK: - Filter Item Cell

@MainActor
private final class MainGameHistoryFilterItemCell: MainBaseCollectionViewCell {

    // MARK: - Layout

    private enum Metrics {
        static let minimumWidth: CGFloat = 64
        static let horizontalInset: CGFloat = 12
    }

    // MARK: - UI Elements

    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.isUserInteractionEnabled = false
        return button
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(filterButton)
    }

    override func setLayout() {
        filterButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        filterButton.configuration = nil
    }

    // MARK: - Configuration

    func configure(title: String, isSelected: Bool) {
        var configuration = UIButton.Configuration.prominentGlass()
        configuration.title = title
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = isSelected ? .label : .clear
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: Metrics.horizontalInset,
            bottom: 8,
            trailing: Metrics.horizontalInset
        )
        configuration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .preferredFont(forTextStyle: .subheadline)
                return outgoing
            }
        filterButton.configuration = configuration
        filterButton.tintColor = isSelected
            ? .systemBackground
            : .secondaryLabel
    }

    static func preferredWidth(for title: String) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let textWidth = (title as NSString).size(
            withAttributes: [.font: font]
        ).width
        return max(
            Metrics.minimumWidth,
            ceil(textWidth) + Metrics.horizontalInset * 2
        )
    }
}

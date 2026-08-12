//
//  MainHomeGameListCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

@MainActor
final class MainHomeGameListCell: MainBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let columns = 3
        static let interitemSpacing: CGFloat = 12
        static let lineSpacing: CGFloat = 12
        static let sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MainHomeGameCell.self)
        return collectionView
    }()

    // MARK: - State

    private var games: [MainHomeGame] = []

    // MARK: - Preferred Size

    static func preferredHeight(
        forWidth width: CGFloat,
        itemCount: Int
    ) -> CGFloat {
        guard itemCount > 0, width > 0 else {
            return 0
        }

        let side = itemSideLength(forWidth: width)
        let rows = Int(ceil(Double(itemCount) / Double(Metrics.columns)))
        let rowsHeight = CGFloat(rows) * side
        let spacingHeight = CGFloat(max(0, rows - 1)) * Metrics.lineSpacing
        let inset = Metrics.sectionInset

        return inset.top + inset.bottom + rowsHeight + spacingHeight
    }

    static func itemSideLength(forWidth width: CGFloat) -> CGFloat {
        let inset = Metrics.sectionInset
        let totalSpacing = Metrics.interitemSpacing * CGFloat(Metrics.columns - 1)
        let availableWidth = width - inset.left - inset.right - totalSpacing
        return floor(max(0, availableWidth / CGFloat(Metrics.columns)))
    }

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(collectionView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        games = []
        collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Configuration

    func configure(games: [MainHomeGame]) {
        self.games = games
        collectionView.reloadData()
    }

    // MARK: - Private

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Metrics.interitemSpacing
        layout.minimumLineSpacing = Metrics.lineSpacing
        layout.sectionInset = Metrics.sectionInset
        return layout
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeGameListCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        games.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            MainHomeGameCell.self,
            for: indexPath
        )
        cell.configure(title: games[indexPath.item].title)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainHomeGameListCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let side = Self.itemSideLength(forWidth: collectionView.bounds.width)
        return CGSize(width: side, height: side)
    }
}

// MARK: - MainHomeGameCell

@MainActor
final class MainHomeGameCell: MainBaseCollectionViewCell {

    // MARK: - UI Elements

    private let actionButton = ViewFactory.makeButton()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(actionButton)
    }

    override func setLayout() {
        actionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTitle(nil)
    }

    // MARK: - Configuration

    func configure(title: String) {
        applyTitle(title)
    }

    // MARK: - Private

    private func applyTitle(_ title: String?) {
        var configuration = actionButton.configuration ?? .glass()
        configuration.title = title
        actionButton.configuration = configuration
    }
}

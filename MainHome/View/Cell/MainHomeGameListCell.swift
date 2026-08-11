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

    // MARK: - Layout

    enum Layout {
        static let columns = 3
        static let interitemSpacing: CGFloat = 12
        static let lineSpacing: CGFloat = 12
        static let sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let defaultItemCount = 20
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
        collectionView.register(
            PlaceholderCell.self,
            forCellWithReuseIdentifier: String(describing: PlaceholderCell.self)
        )
        return collectionView
    }()

    // MARK: - State

    private var itemCount = Layout.defaultItemCount

    // MARK: - Preferred Size

    static func preferredHeight(
        forWidth width: CGFloat,
        itemCount: Int = Layout.defaultItemCount
    ) -> CGFloat {
        guard itemCount > 0, width > 0 else {
            return 0
        }

        let side = itemSideLength(forWidth: width)
        let rows = Int(ceil(Double(itemCount) / Double(Layout.columns)))
        let rowsHeight = CGFloat(rows) * side
        let spacingHeight = CGFloat(max(0, rows - 1)) * Layout.lineSpacing
        let inset = Layout.sectionInset

        return inset.top + inset.bottom + rowsHeight + spacingHeight
    }

    static func itemSideLength(forWidth width: CGFloat) -> CGFloat {
        let inset = Layout.sectionInset
        let totalSpacing = Layout.interitemSpacing * CGFloat(Layout.columns - 1)
        let availableWidth = width - inset.left - inset.right - totalSpacing
        return floor(max(0, availableWidth / CGFloat(Layout.columns)))
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
        itemCount = Layout.defaultItemCount
        collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Configuration

    func configure(itemCount: Int = Layout.defaultItemCount) {
        self.itemCount = max(0, itemCount)
        collectionView.reloadData()
    }

    // MARK: - Private

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Layout.interitemSpacing
        layout.minimumLineSpacing = Layout.lineSpacing
        layout.sectionInset = Layout.sectionInset
        return layout
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeGameListCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        itemCount
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: PlaceholderCell.self),
            for: indexPath
        )
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

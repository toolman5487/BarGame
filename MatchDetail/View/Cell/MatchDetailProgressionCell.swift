//
//  MatchDetailProgressionCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import SnapKit
import UIKit

@MainActor
final class MatchDetailProgressionCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 88
        static let verticalCardInset: CGFloat = 4
        static let horizontalInset: CGFloat = 16
        static let itemWidth: CGFloat = 40
        static let itemSpacing: CGFloat = 8
    }

    // MARK: - State

    private var items: [MatchDetailProgressionItem] = []

    // MARK: - UI Elements

    private let backgroundButton = ViewFactory.makeButton()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: Metrics.horizontalInset,
            bottom: 0,
            right: Metrics.horizontalInset
        )
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MatchDetailProgressionItemCell.self)
        return collectionView
    }()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(collectionView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalCardInset)
        }

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundButton)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        items = []
        collectionView.reloadData()
    }

    func configure(items: [MatchDetailProgressionItem]) {
        self.items = items
        collectionView.reloadData()
    }

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metrics.itemSpacing
        layout.minimumInteritemSpacing = Metrics.itemSpacing
        return layout
    }
}

// MARK: - UICollectionViewDataSource

extension MatchDetailProgressionCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard items.indices.contains(indexPath.item) else {
            preconditionFailure(
                "Invalid MatchDetail progression index: \(indexPath.item)"
            )
        }

        let cell = collectionView.dequeueReusableCell(
            MatchDetailProgressionItemCell.self,
            for: indexPath
        )
        cell.configure(item: items[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MatchDetailProgressionCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard items.indices.contains(indexPath.item) else { return .zero }
        return CGSize(
            width: Metrics.itemWidth,
            height: collectionView.bounds.height
        )
    }
}

@MainActor
private final class MatchDetailProgressionItemCell: DetailBaseCollectionViewCell {

    private enum Metrics {
        static let indicatorSize: CGFloat = 28
        static let spacing: CGFloat = 2
    }

    private let indicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textAlignment = .center
        label.layer.cornerRadius = Metrics.indicatorSize / 2
        label.layer.masksToBounds = true
        return label
    }()

    private let sequenceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            indicatorLabel,
            sequenceLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Metrics.spacing
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(stackView)
    }

    override func setLayout() {
        indicatorLabel.snp.makeConstraints { make in
            make.size.equalTo(Metrics.indicatorSize)
        }
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        indicatorLabel.text = nil
        indicatorLabel.textColor = nil
        indicatorLabel.backgroundColor = nil
        sequenceLabel.text = nil
    }

    func configure(item: MatchDetailProgressionItem) {
        sequenceLabel.text = String(item.sequence)

        switch item.outcome {
        case .win:
            indicatorLabel.text = "勝"
            indicatorLabel.textColor = .black
            indicatorLabel.backgroundColor = .systemYellow

        case .loss:
            indicatorLabel.text = "敗"
            indicatorLabel.textColor = .systemBackground
            indicatorLabel.backgroundColor = ThemeColor.primary
        }
    }
}

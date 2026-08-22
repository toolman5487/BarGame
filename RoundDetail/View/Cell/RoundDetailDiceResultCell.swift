//
//  RoundDetailDiceResultCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import SnapKit
import UIKit

@MainActor
final class RoundDetailDiceResultCell: DetailBaseCollectionViewCell {

    private enum Metrics {
        static let verticalInset: CGFloat = 4
        static let horizontalInset: CGFloat = 16
        static let itemSize: CGFloat = 56
        static let itemSpacing: CGFloat = 8
    }

    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(
            width: Metrics.itemSize,
            height: Metrics.itemSize
        )
        layout.minimumLineSpacing = Metrics.itemSpacing
        layout.minimumInteritemSpacing = Metrics.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: Metrics.verticalInset,
            left: Metrics.horizontalInset,
            bottom: Metrics.verticalInset,
            right: Metrics.horizontalInset
        )
        return layout
    }()

    private lazy var diceCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.allowsSelection = false
        collectionView.register(RoundDetailDieCell.self)
        return collectionView
    }()

    private var items: [RoundDetailDieItem] = []

    static func preferredHeight(
        diceCount: Int,
        width: CGFloat
    ) -> CGFloat {
        let availableWidth = max(0, width - Metrics.horizontalInset * 2)
        let columnCount = max(
            1,
            Int(
                (availableWidth + Metrics.itemSpacing)
                    / (Metrics.itemSize + Metrics.itemSpacing)
            )
        )
        let rowCount = max(
            1,
            Int(ceil(Double(diceCount) / Double(columnCount)))
        )
        return Metrics.verticalInset * 2
            + CGFloat(rowCount) * Metrics.itemSize
            + CGFloat(max(rowCount - 1, 0)) * Metrics.itemSpacing
    }

    override func setHierarchy() {
        contentView.addSubview(diceCollectionView)
    }

    override func setLayout() {
        diceCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        items = []
        diceCollectionView.reloadData()
    }

    func configure(items: [RoundDetailDieItem]) {
        self.items = items
        diceCollectionView.reloadData()
    }
}

extension RoundDetailDiceResultCell: UICollectionViewDataSource {

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
                "Invalid RoundDetail die index: \(indexPath.item)"
            )
        }
        let cell = collectionView.dequeueReusableCell(
            RoundDetailDieCell.self,
            for: indexPath
        )
        cell.configure(item: items[indexPath.item])
        return cell
    }
}

@MainActor
private final class RoundDetailDieCell: DetailBaseCollectionViewCell {

    private let backgroundButton = ViewFactory.makeButton()

    private let faceImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.primary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .largeTitle
        )
        return imageView
    }()

    private let fallbackLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(faceImageView)
        contentView.addSubview(fallbackLabel)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        faceImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        fallbackLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        faceImageView.image = nil
        fallbackLabel.text = nil
        fallbackLabel.isHidden = true
    }

    func configure(item: RoundDetailDieItem) {
        let image = UIImage(
            systemName: "die.face.\(item.faceValue).fill"
        )
        faceImageView.image = image
        fallbackLabel.text = String(item.faceValue)
        fallbackLabel.isHidden = image != nil
    }
}

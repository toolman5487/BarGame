//
//  MainHomeGameResultsCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

// MARK: - MainHomeResultEmptyView

@MainActor
final class MainHomeResultEmptyView: BaseHintView {

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    // MARK: - Private

    private func applyDefaultContent() {
        symbolEffect = .wiggle(.repeating)
        configure(
            image: UIImage(systemName: "flag.pattern.checkered.2.crossed"),
            title: "尚無戰績",
            subtitle: "完成一場遊戲吧！"
        )
    }
}

@MainActor
final class MainHomeGameResultsCell: MainBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let preferredHeight = BaseHintView.Metrics.preferredHeight
        static let itemSize = CGSize(width: 280, height: 128)
        static let interitemSpacing: CGFloat = 12
        static let contentInset = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
    }

    // MARK: - UI Elements

    private let emptyView = MainHomeResultEmptyView()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.isDirectionalLockEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.register(MainHomeGameResultItemCell.self)
        return collectionView
    }()

    // MARK: - State

    private var results: [MainHomeGameResult] = []

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(collectionView)
        contentView.addSubview(emptyView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        results = []
        collectionView.setContentOffset(.zero, animated: false)
        updateContentVisibility()
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(results: [MainHomeGameResult]) {
        self.results = results
        updateContentVisibility()
        collectionView.reloadData()
    }

    // MARK: - Private

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = Metrics.itemSize
        layout.minimumLineSpacing = Metrics.interitemSpacing
        layout.sectionInset = Metrics.contentInset
        return layout
    }

    private func updateContentVisibility() {
        let isEmpty = results.isEmpty
        collectionView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeGameResultsCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        results.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            MainHomeGameResultItemCell.self,
            for: indexPath
        )
        cell.configure(result: results[indexPath.item])
        return cell
    }
}

// MARK: - MainHomeGameResultItemCell

@MainActor
final class MainHomeGameResultItemCell: MainBaseCollectionViewCell {

    // MARK: - Layout

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 20
    }

    // MARK: - UI Elements

    private let gameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let winsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let drawsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let lossesLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(gameTitleLabel)
        contentView.addSubview(winsLabel)
        contentView.addSubview(drawsLabel)
        contentView.addSubview(lossesLabel)
    }

    override func setLayout() {
        gameTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.contentInset)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
        }

        winsLabel.snp.makeConstraints { make in
            make.top.equalTo(gameTitleLabel.snp.bottom).offset(Layout.contentSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
        }

        drawsLabel.snp.makeConstraints { make in
            make.top.equalTo(winsLabel.snp.bottom).offset(Layout.contentSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
        }

        lossesLabel.snp.makeConstraints { make in
            make.top.equalTo(drawsLabel.snp.bottom).offset(Layout.contentSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
            make.bottom.lessThanOrEqualToSuperview().inset(Layout.contentInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gameTitleLabel.text = nil
        winsLabel.text = nil
        drawsLabel.text = nil
        lossesLabel.text = nil
    }

    // MARK: - Configuration

    func configure(result: MainHomeGameResult) {
        gameTitleLabel.text = result.gameTitle
        winsLabel.text = "勝 \(result.detail.wins)"
        drawsLabel.text = "和 \(result.detail.draws)"
        lossesLabel.text = "負 \(result.detail.losses)"
    }
}

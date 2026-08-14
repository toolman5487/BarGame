//
//  GameDetailRecentRecordsCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import SnapKit
import UIKit

// MARK: - Empty View

@MainActor
final class GameDetailRecentRecordsEmptyView: BaseHintView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    private func applyDefaultContent() {
        symbolEffect = .wiggle(.repeating)
        configure(
            image: UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90"),
            title: "尚無近況紀錄",
            subtitle: "完成一場遊戲後會顯示在這裡"
        )
    }
}

// MARK: - Error View

@MainActor
final class GameDetailRecentRecordsErrorView: BaseHintView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    private func applyDefaultContent() {
        symbolEffect = .pulse(.repeating)
        configure(
            image: UIImage(systemName: "exclamationmark.triangle"),
            title: "無法載入紀錄",
            subtitle: "請稍後再試"
        )
    }

    func configure(message: String) {
        super.configure(
            image: UIImage(systemName: "exclamationmark.triangle"),
            title: "無法載入紀錄",
            subtitle: message
        )
    }
}

// MARK: - Records Cell

@MainActor
final class GameDetailRecentRecordsCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let itemSize = CGSize(width: 144, height: 112)
        static let interitemSpacing: CGFloat = 12
        static let contentInset = UIEdgeInsets(
            top: 8,
            left: 16,
            bottom: 8,
            right: 16
        )
        static let preferredHeight = itemSize.height
            + contentInset.top
            + contentInset.bottom
    }

    // MARK: - UI Elements

    private let emptyView = GameDetailRecentRecordsEmptyView()
    private let errorView = GameDetailRecentRecordsErrorView()
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
        collectionView.delaysContentTouches = false
        collectionView.dataSource = self
        collectionView.register(GameDetailRecentRecordItemCell.self)
        return collectionView
    }()

    // MARK: - State

    private var records: [GameDetailRecentRecord] = []

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(collectionView)
        contentView.addSubview(emptyView)
        contentView.addSubview(errorView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        records = []
        collectionView.setContentOffset(.zero, animated: false)
        apply(state: .empty)
    }

    // MARK: - Configuration

    func configure(state: GameDetailRecentRecordsState) {
        apply(state: state)
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

    private func apply(state: GameDetailRecentRecordsState) {
        switch state {
        case .empty:
            records = []
            collectionView.isHidden = true
            emptyView.isHidden = false
            errorView.isHidden = true

        case .content(let records):
            self.records = Array(records.prefix(GameDetailRecentRecordsState.maximumRecordCount))
            collectionView.isHidden = false
            emptyView.isHidden = true
            errorView.isHidden = true

        case .error(let message):
            records = []
            collectionView.isHidden = true
            emptyView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: message)
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension GameDetailRecentRecordsCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        records.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            GameDetailRecentRecordItemCell.self,
            for: indexPath
        )
        cell.configure(record: records[indexPath.item])
        return cell
    }
}

// MARK: - Item Cell

@MainActor
final class GameDetailRecentRecordItemCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    private enum Metrics {
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let iconSize: CGFloat = 28
    }

    // MARK: - UI Elements

    private let backgroundButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    private let outcomeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
            weight: .semibold
        )
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeIconView,
            titleLabel,
            subtitleLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        outcomeIconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Metrics.contentInset)
            make.top.greaterThanOrEqualToSuperview().inset(Metrics.contentInset)
            make.bottom.lessThanOrEqualToSuperview().inset(Metrics.contentInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        outcomeIconView.image = nil
        outcomeIconView.tintColor = ThemeColor.secondary
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(record: GameDetailRecentRecord) {
        titleLabel.text = record.scoreText
        subtitleLabel.text = record.subtitle

        switch record.outcome {
        case .win:
            outcomeIconView.image = UIImage(systemName: "trophy.fill")
            outcomeIconView.tintColor = .systemYellow

        case .loss:
            outcomeIconView.image = UIImage(systemName: "flag.fill")
            outcomeIconView.tintColor = .label
        }
    }
}

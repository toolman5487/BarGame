//
//  DiceGameResultView.swift
//  BarGame
//
//  Created by Codex on 2026/8/13.
//

import SnapKit
import UIKit

@MainActor
final class DiceGameResultView: UIView {

    // MARK: - Types

    private enum Item: Equatable {
        case face(value: Int, count: Int)
        case total(Int)

        var title: String {
            switch self {
            case .face(let value, _):
                return "\(value) 點"
            case .total:
                return "總和"
            }
        }

        var detailText: String {
            switch self {
            case .face(_, let count):
                return "\(count) 顆"
            case .total(let value):
                return String(value)
            }
        }
    }

    private enum Metrics {
        static let itemSpacing: CGFloat = 8
    }

    // MARK: - State

    private var items: [Item] = []

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metrics.itemSpacing
        layout.minimumInteritemSpacing = Metrics.itemSpacing
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.register(DiceGameResultItemCell.self)
        return collectionView
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(result: DiceRollResult?) {
        guard let result else {
            items = []
            isHidden = true
            collectionView.reloadData()
            return
        }

        items = (1...6).compactMap { value in
            let count = result.count(of: value)
            guard count > 0 else { return nil }
            return .face(value: value, count: count)
        } + [.total(result.total)]
        isHidden = false
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension DiceGameResultView: UICollectionViewDataSource {

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
            preconditionFailure("Invalid dice result index: \(indexPath.item)")
        }

        let cell = collectionView.dequeueReusableCell(
            DiceGameResultItemCell.self,
            for: indexPath
        )
        let item = items[indexPath.item]
        cell.configure(title: item.title, detailText: item.detailText)
        return cell
    }
}

// MARK: - Result Item Cell

@MainActor
private final class DiceGameResultItemCell: StandardBaseCollectionViewCell {

    private enum Metrics {
        static let contentSpacing: CGFloat = 4
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
    }

    private let backgroundButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.contentSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        valueLabel.text = nil
    }

    func configure(title: String, detailText: String) {
        titleLabel.text = title
        valueLabel.text = detailText
    }
}

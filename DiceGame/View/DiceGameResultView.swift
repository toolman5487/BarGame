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
        static let itemsPerRow = 3
        static let itemSpacing: CGFloat = 8
        static let animationDuration: TimeInterval = 0.42
        static let animationDampingRatio: CGFloat = 0.82
        static let minimumCollapsedScale: CGFloat = 0.2
        static let hiddenContentAlpha: CGFloat = 0.2
        static let hintContractedScale: CGFloat = 0.86

        static var itemHeight: CGFloat {
            UIFont.preferredFont(forTextStyle: .title2).lineHeight +
                UIFont.preferredFont(forTextStyle: .caption1).lineHeight +
                DiceGameResultItemCell.Metrics.contentSpacing +
                DiceGameResultItemCell.Metrics.verticalInset * 2
        }

        static var collapsedHeight: CGFloat {
            UIFont.preferredFont(forTextStyle: .subheadline).lineHeight + 16
        }
    }

    // MARK: - State

    private var items: [Item] = []
    private var result: DiceRollResult?
    private var isExpanded = false
    private var previousLayoutWidth: CGFloat = 0
    private var transitionAnimator: UIViewPropertyAnimator?

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Metrics.itemSpacing
        layout.minimumInteritemSpacing = Metrics.itemSpacing

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundView = collectionGlassView
        collectionView.register(DiceGameResultItemCell.self)
        return collectionView
    }()

    private let collectionGlassView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        view.cornerConfiguration = .uniformCorners(radius: 16)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let hintLabel = ViewFactory.makeGlassLabel(
        textStyle: .subheadline,
        textColor: .label,
        textAlignment: .center,
        numberOfLines: 1
    )

    // MARK: - Lifecycle

    init(hintText: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        hintLabel.configure(text: hintText)
        addSubview(collectionView)
        addSubview(hintLabel)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(toggleExpansion)
        )
        tapGestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapGestureRecognizer)
        updatePresentation(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let height: CGFloat

        if isExpanded, result != nil {
            let rowCount = Int(
                ceil(Double(items.count) / Double(Metrics.itemsPerRow))
            )
            height = CGFloat(rowCount) * Metrics.itemHeight +
                CGFloat(max(rowCount - 1, 0)) * Metrics.itemSpacing
        } else {
            height = Metrics.collapsedHeight
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard previousLayoutWidth != bounds.width else { return }
        previousLayoutWidth = bounds.width
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Configuration

    func configure(result: DiceRollResult?) {
        guard let result else {
            self.result = nil
            items = []
            isExpanded = false
            collectionView.reloadData()
            updatePresentation(animated: false)
            return
        }

        let isNewResult = self.result != result
        self.result = result
        items = (1...6).compactMap { value in
            let count = result.count(of: value)
            guard count > 0 else { return nil }
            return .face(value: value, count: count)
        } + [.total(result.total)]
        if isNewResult {
            isExpanded = true
        }
        collectionView.reloadData()
        updatePresentation(animated: isNewResult)
    }

    // MARK: - Actions

    @objc
    private func toggleExpansion() {
        guard result != nil else { return }
        isExpanded.toggle()
        updatePresentation(animated: true)
    }

    private func updatePresentation(animated: Bool) {
        let shouldExpand = isExpanded && result != nil
        transitionAnimator?.stopAnimation(true)

        guard animated else {
            collectionView.isHidden = !shouldExpand
            collectionView.alpha = 1
            collectionView.transform = .identity
            hintLabel.isHidden = shouldExpand
            hintLabel.alpha = 1
            hintLabel.transform = .identity
            invalidateIntrinsicContentSize()
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        superview?.layoutIfNeeded()

        collectionView.isHidden = false
        hintLabel.isHidden = false

        if shouldExpand {
            collectionView.alpha = Metrics.hiddenContentAlpha
            collectionView.transform = collapsedCollectionTransform
            hintLabel.alpha = 1
            hintLabel.transform = .identity
        } else {
            collectionView.alpha = 1
            collectionView.transform = .identity
            hintLabel.alpha = 0
            hintLabel.transform = CGAffineTransform(
                scaleX: Metrics.hintContractedScale,
                y: Metrics.hintContractedScale
            )
        }

        invalidateIntrinsicContentSize()
        collectionView.collectionViewLayout.invalidateLayout()

        let animator = UIViewPropertyAnimator(
            duration: Metrics.animationDuration,
            dampingRatio: Metrics.animationDampingRatio
        ) {
            self.superview?.layoutIfNeeded()

            if shouldExpand {
                self.collectionView.alpha = 1
                self.collectionView.transform = .identity
                self.hintLabel.alpha = 0
                self.hintLabel.transform = CGAffineTransform(
                    scaleX: Metrics.hintContractedScale,
                    y: Metrics.hintContractedScale
                )
            } else {
                self.collectionView.alpha = Metrics.hiddenContentAlpha
                self.collectionView.transform = self.collapsedCollectionTransform
                self.hintLabel.alpha = 1
                self.hintLabel.transform = .identity
            }
        }

        animator.addCompletion { [weak self] position in
            guard let self, position == .end else { return }
            self.collectionView.isHidden = !shouldExpand
            self.collectionView.alpha = 1
            self.collectionView.transform = .identity
            self.hintLabel.isHidden = shouldExpand
            self.hintLabel.alpha = 1
            self.hintLabel.transform = .identity
            self.transitionAnimator = nil
        }
        transitionAnimator = animator
        animator.startAnimation()
    }

    private var collapsedCollectionTransform: CGAffineTransform {
        let collectionWidth = max(collectionView.bounds.width, 1)
        let fittingHintWidth = hintLabel.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        ).width
        let hintWidth = min(fittingHintWidth, collectionWidth)
        let scale = max(
            hintWidth / collectionWidth,
            Metrics.minimumCollapsedScale
        )
        return CGAffineTransform(scaleX: scale, y: 1)
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

// MARK: - UICollectionViewDelegateFlowLayout

extension DiceGameResultView: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = Metrics.itemSpacing * CGFloat(Metrics.itemsPerRow - 1)
        let availableWidth = max(collectionView.bounds.width - totalSpacing, 0)
        return CGSize(
            width: availableWidth / CGFloat(Metrics.itemsPerRow),
            height: Metrics.itemHeight
        )
    }
}

// MARK: - Result Item Cell

@MainActor
private final class DiceGameResultItemCell: StandardBaseCollectionViewCell {

    fileprivate enum Metrics {
        static let contentSpacing: CGFloat = 4
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
    }

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
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
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

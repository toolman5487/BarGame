//
//  DiceGameResultView.swift
//  BarGame
//
//  Created by Codex on 2026/8/13.
//

import SnapKit
import UIKit

@MainActor
private func makeDiceResultValueFont() -> UIFont {
    .monospacedDigitSystemFont(
        ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
        weight: .semibold
    )
}

@MainActor
final class DiceGameResultView: UIView {

    // MARK: - Types

    fileprivate enum Metrics {
        static let itemCount = 6
        static let itemsPerRow = 3
        static let itemSpacing: CGFloat = 8
        static let itemContentSpacing: CGFloat = 4
        static let itemHorizontalInset: CGFloat = 16
        static let itemVerticalInset: CGFloat = 8
        static let contentSpacing: CGFloat = 8
        static let contentInset: CGFloat = 8
        static let hintHorizontalInset: CGFloat = 12
        static let animationDuration: TimeInterval = 0.42
        static let animationDampingRatio: CGFloat = 0.82

        static var itemHeight: CGFloat {
            makeDiceResultValueFont().lineHeight +
                UIFont.preferredFont(forTextStyle: .caption1).lineHeight +
                itemContentSpacing +
                itemVerticalInset * 2
        }

        static var collectionHeight: CGFloat {
            let rowCount = Int(ceil(Double(itemCount) / Double(itemsPerRow)))
            return CGFloat(rowCount) * itemHeight +
                CGFloat(max(rowCount - 1, 0)) * itemSpacing
        }

        static var expandedHeight: CGFloat {
            makeDiceResultValueFont().lineHeight +
                contentInset * 2 +
                contentSpacing +
                collectionHeight
        }

        static var collapsedHeight: CGFloat {
            UIFont.preferredFont(forTextStyle: .subheadline).lineHeight +
                contentInset * 2
        }
    }

    // MARK: - State

    private var renderedState: DiceGameResultViewState?
    private var previousLayoutWidth: CGFloat = 0
    private var transitionAnimator: UIViewPropertyAnimator?
    private var expandedWidthConstraint: Constraint?
    private var collapsedWidthConstraint: Constraint?
    private var collectionHeightConstraint: Constraint?

    var onExpansionToggle: (() -> Void)?

    // MARK: - UI Elements

    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = makeDiceResultValueFont()
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

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
        collectionView.register(DiceGameResultItemCell.self)
        return collectionView
    }()

    private lazy var expandedContentView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [totalLabel, collectionView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Metrics.contentInset,
            leading: Metrics.contentInset,
            bottom: Metrics.contentInset,
            trailing: Metrics.contentInset
        )
        return stackView
    }()

    private let containerGlassView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        view.cornerConfiguration = .uniformCorners(radius: 16)
        view.clipsToBounds = true
        view.contentView.clipsToBounds = true
        return view
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Lifecycle

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        setupViewHierarchy()
        setupViewLayout()
        setupActions()
        registerForContentSizeCategoryChanges()
        updatePresentation(for: .collapsed, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let height = presentationState == .expanded
            ? Metrics.expandedHeight
            : Metrics.collapsedHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard previousLayoutWidth != bounds.width else { return }
        previousLayoutWidth = bounds.width
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        addSubview(containerGlassView)
        containerGlassView.contentView.addSubview(expandedContentView)
        containerGlassView.contentView.addSubview(hintLabel)
    }

    private func setupViewLayout() {
        containerGlassView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            expandedWidthConstraint = make.width.equalToSuperview().constraint
            collapsedWidthConstraint = make.width
                .equalTo(collapsedContainerWidth)
                .constraint
        }
        expandedWidthConstraint?.deactivate()
        expandedContentView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            collectionHeightConstraint = make.height
                .equalTo(Metrics.collectionHeight)
                .constraint
        }
        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(Metrics.contentInset)
            make.right.lessThanOrEqualToSuperview().inset(Metrics.contentInset)
        }
    }

    private func setupActions() {
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(toggleExpansion)
        )
        tapGestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapGestureRecognizer)
    }

    private func registerForContentSizeCategoryChanges() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (view: DiceGameResultView, _) in
            view.updateFontsAndLayoutMetrics()
        }
    }

    // MARK: - Configuration

    func configure(with state: DiceGameResultViewState) {
        let previousPresentation = renderedState?.presentation
        renderedState = state
        hintLabel.text = state.hintText
        totalLabel.text = state.totalText
        collapsedWidthConstraint?.update(offset: collapsedContainerWidth)
        collectionView.reloadData()
        updatePresentation(
            for: state.presentation,
            animated: previousPresentation != nil &&
                previousPresentation != state.presentation
        )
    }

    // MARK: - Actions

    @objc
    private func toggleExpansion() {
        onExpansionToggle?()
    }

    private func updatePresentation(
        for targetState: DiceGameResultViewState.Presentation,
        animated: Bool
    ) {
        stopTransitionAnimation()

        guard animated else {
            applyContainerWidth(for: targetState)
            applyContentVisibility(for: targetState, hidesInactiveContent: true)
            invalidateIntrinsicContentSize()
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        superview?.layoutIfNeeded()

        expandedContentView.isHidden = false
        hintLabel.isHidden = false

        applyContainerWidth(for: targetState)
        invalidateIntrinsicContentSize()
        collectionView.collectionViewLayout.invalidateLayout()

        let animator = UIViewPropertyAnimator(
            duration: Metrics.animationDuration,
            dampingRatio: Metrics.animationDampingRatio
        ) {
            self.superview?.layoutIfNeeded()
            self.applyContentVisibility(
                for: targetState,
                hidesInactiveContent: false
            )
        }

        animator.addCompletion { [weak self] position in
            guard let self, position == .end else { return }
            self.applyContentVisibility(
                for: targetState,
                hidesInactiveContent: true
            )
            self.transitionAnimator = nil
        }
        transitionAnimator = animator
        animator.startAnimation()
    }

    private var presentationState: DiceGameResultViewState.Presentation {
        renderedState?.presentation ?? .collapsed
    }

    private var collapsedContainerWidth: CGFloat {
        hintLabel.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        ).width + Metrics.hintHorizontalInset * 2
    }

    private func updateFontsAndLayoutMetrics() {
        totalLabel.font = makeDiceResultValueFont()
        hintLabel.font = .preferredFont(forTextStyle: .subheadline)
        collectionHeightConstraint?.update(offset: Metrics.collectionHeight)
        collapsedWidthConstraint?.update(offset: collapsedContainerWidth)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func applyContainerWidth(
        for state: DiceGameResultViewState.Presentation
    ) {
        switch state {
        case .expanded:
            collapsedWidthConstraint?.deactivate()
            expandedWidthConstraint?.activate()

        case .collapsed:
            expandedWidthConstraint?.deactivate()
            collapsedWidthConstraint?.activate()
        }
    }

    private func applyContentVisibility(
        for state: DiceGameResultViewState.Presentation,
        hidesInactiveContent: Bool
    ) {
        let isExpanded = state == .expanded
        expandedContentView.alpha = isExpanded ? 1 : 0
        hintLabel.alpha = isExpanded ? 0 : 1
        expandedContentView.isHidden = hidesInactiveContent && !isExpanded
        hintLabel.isHidden = hidesInactiveContent && isExpanded
    }

    private func stopTransitionAnimation() {
        guard let transitionAnimator else { return }
        transitionAnimator.stopAnimation(false)
        transitionAnimator.finishAnimation(at: .current)
        self.transitionAnimator = nil
    }
}

// MARK: - UICollectionViewDataSource

extension DiceGameResultView: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        renderedState?.items.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let items = renderedState?.items,
            items.indices.contains(indexPath.item)
        else {
            preconditionFailure("Invalid dice result index: \(indexPath.item)")
        }

        let cell = collectionView.dequeueReusableCell(
            DiceGameResultItemCell.self,
            for: indexPath
        )
        let item = items[indexPath.item]
        cell.configure(
            title: item.title,
            detailText: item.countText
        )
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

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = makeDiceResultValueFont()
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = DiceGameResultView.Metrics.itemContentSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(
                DiceGameResultView.Metrics.itemHorizontalInset
            )
            make.top.bottom.equalToSuperview().inset(
                DiceGameResultView.Metrics.itemVerticalInset
            )
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
        valueLabel.font = makeDiceResultValueFont()
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.text = title
        valueLabel.text = detailText
    }

}

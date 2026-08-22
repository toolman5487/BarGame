//
//  GameSettingRuleCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SnapKit
import UIKit

// MARK: - Rules Container Cell

@MainActor
final class GameSettingRuleCell: DetailBaseCollectionViewCell {

    // MARK: - State

    private var rules: [GameSettingRule] = []
    private var previousLayoutWidth: CGFloat = 0

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GameSettingRuleItemCell.self)
        return collectionView
    }()

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        guard previousLayoutWidth != bounds.width else { return }
        previousLayoutWidth = bounds.width
        collectionView.collectionViewLayout.invalidateLayout()
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
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        rules = []
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(rules: [GameSettingRule]) {
        self.rules = rules
        collectionView.reloadData()
    }

    static func preferredHeight(
        for rules: [GameSettingRule],
        width: CGFloat
    ) -> CGFloat {
        rules.reduce(0) { height, rule in
            height + GameSettingRuleItemCell.preferredHeight(
                for: rule.text,
                width: width
            )
        }
    }

    // MARK: - Private

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }
}

// MARK: - UICollectionViewDataSource

extension GameSettingRuleCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        rules.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard rules.indices.contains(indexPath.item) else {
            preconditionFailure("Invalid GameSetting rule index: \(indexPath.item)")
        }

        let cell = collectionView.dequeueReusableCell(
            GameSettingRuleItemCell.self,
            for: indexPath
        )
        cell.configure(rule: rules[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GameSettingRuleCell: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard rules.indices.contains(indexPath.item) else {
            return .zero
        }

        let width = collectionView.bounds.width
        return CGSize(
            width: width,
            height: GameSettingRuleItemCell.preferredHeight(
                for: rules[indexPath.item].text,
                width: width
            )
        )
    }
}

// MARK: - Rule Item Cell

@MainActor
private final class GameSettingRuleItemCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    private enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 4
        static let contentSpacing: CGFloat = 12
        static let stepSize: CGFloat = 44
        static let minimumHeight: CGFloat = 56
    }

    // MARK: - UI Elements

    private let stepLabelView: GlassLabelView = {
        let baseFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
            weight: .regular
        )
        return ViewFactory.makeGlassLabel(
            font: baseFont,
            textColor: ThemeColor.primary,
            textAlignment: .center,
            numberOfLines: 1,
            contentInsets: .zero
        )
    }()

    private let ruleLabelView: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(stepLabelView)
        contentView.addSubview(ruleLabelView)
    }

    override func setLayout() {
        stepLabelView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Metrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Metrics.stepSize)
        }

        ruleLabelView.snp.makeConstraints { make in
            make.left.equalTo(stepLabelView.snp.right).offset(Metrics.contentSpacing)
            make.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stepLabelView.configure(text: nil)
        ruleLabelView.text = nil
    }

    // MARK: - Configuration

    func configure(rule: GameSettingRule) {
        stepLabelView.configure(text: String(rule.step))
        ruleLabelView.text = rule.text
    }

    static func preferredHeight(for text: String, width: CGFloat) -> CGFloat {
        let textWidth = max(
            0,
            width
                - Metrics.horizontalInset * 2
                - Metrics.stepSize
                - Metrics.contentSpacing
        )
        let textHeight = (text as NSString).boundingRect(
            with: CGSize(
                width: textWidth,
                height: .greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline),
            ],
            context: nil
        ).height.rounded(.up)
        let contentHeight = textHeight + Metrics.verticalInset * 2
        return max(Metrics.minimumHeight, contentHeight.rounded(.up))
    }
}

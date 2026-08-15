//
//  MainGameHistoryRecordCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import SnapKit
import SkeletonView
import UIKit

@MainActor
final class MainGameHistoryRecordCell: MainBaseCollectionViewCell {

    // MARK: - Layout

    enum Layout {
        static let preferredHeight: CGFloat = 112
        static let verticalCardInset: CGFloat = 4
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 4
        static let outcomeSpacing: CGFloat = 4
        static let outcomeIconSize: CGFloat = 20
    }

    // MARK: - UI Elements

    private let backgroundButton = ViewFactory.makeButton()

    private let gameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let outcomeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .headline
        )
        return imageView
    }()

    private let outcomeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        return label
    }()

    private lazy var outcomeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeImageView,
            outcomeLabel,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.outcomeSpacing
        stackView.setContentHuggingPriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stackView
    }()

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            gameTitleLabel,
            outcomeStackView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleStackView,
            resultLabel,
            metadataLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Layout.contentSpacing
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
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Layout.verticalCardInset)
        }

        outcomeImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.outcomeIconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.left.right.equalTo(backgroundButton).inset(Layout.contentInset)
            make.top.greaterThanOrEqualTo(backgroundButton).inset(Layout.contentInset)
            make.bottom.lessThanOrEqualTo(backgroundButton).inset(Layout.contentInset)
            make.centerY.equalTo(backgroundButton)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        isSkeletonable = true
        contentView.isSkeletonable = true
        contentStackView.isSkeletonable = true
        titleStackView.isSkeletonable = true
        gameTitleLabel.isSkeletonable = true
        outcomeStackView.isSkeletonable = true
        outcomeImageView.isSkeletonable = true
        outcomeLabel.isSkeletonable = true
        resultLabel.isSkeletonable = true
        metadataLabel.isSkeletonable = true

        [
            gameTitleLabel,
            outcomeImageView,
            outcomeLabel,
            resultLabel,
            metadataLabel,
        ].forEach { view in
            view.skeletonCornerRadius = 4
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton(reloadDataAfter: false, transition: .none)
        gameTitleLabel.text = nil
        outcomeImageView.image = nil
        outcomeLabel.text = nil
        resultLabel.text = nil
        metadataLabel.text = nil
    }

    // MARK: - Configuration

    func showLoadingState() {
        hideSkeleton(reloadDataAfter: false, transition: .none)
        gameTitleLabel.text = "遊戲名稱"
        outcomeImageView.image = UIImage(systemName: "circle.fill")
        outcomeLabel.text = "結果"
        resultLabel.text = "00 點 · 0、0、0"
        metadataLabel.text = "今天 00:00 · 地點"
        layoutIfNeeded()
        showAnimatedGradientSkeleton(transition: .none)
    }

    func configure(item: MainGameHistoryRecordItem) {
        hideSkeleton(
            reloadDataAfter: false,
            transition: .crossDissolve(0.2)
        )
        gameTitleLabel.text = item.gameTitle
        outcomeLabel.text = item.outcomeText
        resultLabel.text = item.resultText
        metadataLabel.text = item.metadataText

        switch item.outcome {
        case .win:
            outcomeImageView.image = UIImage(systemName: "trophy.fill")
            outcomeImageView.tintColor = .systemYellow
            outcomeLabel.textColor = .systemYellow

        case .loss:
            outcomeImageView.image = UIImage(systemName: "flag.fill")
            outcomeImageView.tintColor = .systemRed
            outcomeLabel.textColor = .systemRed
        }
    }
}

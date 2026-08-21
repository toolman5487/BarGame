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

    enum Metrics {
        static let preferredHeight: CGFloat = 112
        static let verticalCardInset: CGFloat = 4
        static let horizontalContentInset: CGFloat = 16
        static let verticalContentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 4
        static let outcomeSpacing: CGFloat = 4
        static let outcomeIconSize: CGFloat = 20
        static let disclosureIconSize: CGFloat = 16
        static let disclosureSpacing: CGFloat = 12
    }

    // MARK: - UI Elements

    private let backgroundButton = ViewFactory.makeButton()

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
            resultLabel,
            outcomeLabel,
            outcomeImageView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.outcomeSpacing
        return stackView
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        return label
    }()

    private let gameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        return label
    }()

    private let disclosureImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "chevron.right")
        )
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .caption1,
            scale: .small
        )
        return imageView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeStackView,
            gameTitleLabel,
            timeLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.contentSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
        contentView.addSubview(disclosureImageView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalCardInset)
        }

        outcomeImageView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.outcomeIconSize)
        }

        disclosureImageView.snp.makeConstraints { make in
            make.right.equalTo(backgroundButton)
                .inset(Metrics.horizontalContentInset)
            make.centerY.equalTo(backgroundButton)
            make.size.equalTo(Metrics.disclosureIconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.left.equalTo(backgroundButton)
                .inset(Metrics.horizontalContentInset)
            make.right.equalTo(disclosureImageView.snp.left)
                .offset(-Metrics.disclosureSpacing)
            make.top.greaterThanOrEqualTo(backgroundButton)
                .inset(Metrics.verticalContentInset)
            make.bottom.lessThanOrEqualTo(backgroundButton)
                .inset(Metrics.verticalContentInset)
            make.centerY.equalTo(backgroundButton)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        isSkeletonable = true
        contentView.isSkeletonable = true
        contentStackView.isSkeletonable = true
        outcomeStackView.isSkeletonable = true
        outcomeImageView.isSkeletonable = true
        outcomeLabel.isSkeletonable = true
        resultLabel.isSkeletonable = true
        gameTitleLabel.isSkeletonable = true
        timeLabel.isSkeletonable = true

        [
            outcomeImageView,
            outcomeLabel,
            resultLabel,
            gameTitleLabel,
            timeLabel,
        ].forEach { view in
            view.skeletonCornerRadius = 4
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton(reloadDataAfter: false, transition: .none)
        outcomeImageView.image = nil
        outcomeLabel.text = nil
        resultLabel.text = nil
        gameTitleLabel.text = nil
        timeLabel.text = nil
    }

    // MARK: - Configuration

    func showLoadingState() {
        hideSkeleton(reloadDataAfter: false, transition: .none)
        outcomeImageView.image = UIImage(systemName: "circle.fill")
        outcomeLabel.text = "結果"
        resultLabel.text = "0 - 0"
        gameTitleLabel.text = "遊戲種類"
        timeLabel.text = "今天 00:00"
        layoutIfNeeded()
        showAnimatedGradientSkeleton(transition: .none)
    }

    func configure(item: MainGameHistoryRecordItem) {
        hideSkeleton(
            reloadDataAfter: false,
            transition: .crossDissolve(0.2)
        )
        outcomeLabel.text = item.outcomeText
        resultLabel.text = item.resultText
        gameTitleLabel.text = item.gameTitleText
        timeLabel.text = item.timeText

        switch item.outcome {
        case .win:
            outcomeImageView.image = UIImage(systemName: "trophy.fill")
            outcomeImageView.tintColor = .systemYellow
            outcomeLabel.textColor = .systemYellow

        case .loss:
            outcomeImageView.image = UIImage(systemName: "flag.fill")
            outcomeImageView.tintColor = .label
            outcomeLabel.textColor = .label

        case .draw:
            outcomeImageView.image = UIImage(
                systemName: "flag.and.flag.filled.crossed"
            )
            outcomeImageView.tintColor = ThemeColor.secondary
            outcomeLabel.textColor = ThemeColor.secondary
        }
    }
}

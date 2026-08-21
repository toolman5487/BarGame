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
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 4
        static let outcomeSpacing: CGFloat = 4
        static let outcomeIconSize: CGFloat = 20
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

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeStackView,
            timeLabel,
            locationLabel,
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
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalCardInset)
        }

        outcomeImageView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.outcomeIconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.left.right.equalTo(backgroundButton).inset(Metrics.contentInset)
            make.top.greaterThanOrEqualTo(backgroundButton).inset(Metrics.contentInset)
            make.bottom.lessThanOrEqualTo(backgroundButton).inset(Metrics.contentInset)
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
        timeLabel.isSkeletonable = true
        locationLabel.isSkeletonable = true

        [
            outcomeImageView,
            outcomeLabel,
            resultLabel,
            timeLabel,
            locationLabel,
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
        timeLabel.text = nil
        locationLabel.text = nil
    }

    // MARK: - Configuration

    func showLoadingState() {
        hideSkeleton(reloadDataAfter: false, transition: .none)
        outcomeImageView.image = UIImage(systemName: "circle.fill")
        outcomeLabel.text = "結果"
        resultLabel.text = "0 - 0"
        timeLabel.text = "今天 00:00"
        locationLabel.text = "詳細地址"
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
        timeLabel.text = item.timeText
        locationLabel.text = item.locationText

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

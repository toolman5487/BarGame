//
//  MatchDetailRoundCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import SnapKit
import UIKit

@MainActor
final class MatchDetailRoundCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 88
        static let verticalCardInset: CGFloat = 4
        static let contentInset: CGFloat = 16
        static let horizontalSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        static let outcomeIconSize: CGFloat = 24
        static let disclosureIconSize: CGFloat = 16
    }

    private let backgroundButton = ViewFactory.makeButton()

    private let outcomeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .headline
        )
        return imageView
    }()

    private let sequenceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        return label
    }()

    private let diceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize,
            weight: .regular
        )
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private let disclosureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.secondary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .caption1,
            scale: .small
        )
        return imageView
    }()

    private lazy var leadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [sequenceLabel, diceLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.textSpacing
        return stackView
    }()

    private lazy var trailingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [pointsLabel, timeLabel])
        stackView.axis = .vertical
        stackView.alignment = .trailing
        stackView.spacing = Metrics.textSpacing
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeImageView,
            leadingStackView,
            trailingStackView,
            disclosureImageView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.horizontalSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

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

        disclosureImageView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.disclosureIconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundButton).inset(Metrics.contentInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        leadingStackView.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        trailingStackView.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        outcomeImageView.image = nil
        sequenceLabel.text = nil
        diceLabel.text = nil
        pointsLabel.text = nil
        timeLabel.text = nil
    }

    func configure(item: MatchDetailRoundItem) {
        sequenceLabel.text = item.sequenceText
        diceLabel.text = item.diceText
        pointsLabel.text = item.pointsText
        timeLabel.text = item.timeText

        switch item.outcome {
        case .win:
            outcomeImageView.image = UIImage(systemName: "checkmark.circle.fill")
            outcomeImageView.tintColor = .systemYellow

        case .loss:
            outcomeImageView.image = UIImage(systemName: "xmark.circle.fill")
            outcomeImageView.tintColor = ThemeColor.primary
        }
    }
}
